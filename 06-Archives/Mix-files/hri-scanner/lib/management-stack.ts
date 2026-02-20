import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as sns from 'aws-cdk-lib/aws-sns';
import { Construct } from 'constructs';
import { FindingsTable } from './constructs/findings-table';
import { ScannerLambda } from './constructs/scanner-lambda';

export interface ManagementStackProps extends cdk.StackProps {
  /**
   * External ID for cross-account role assumption
   */
  readonly externalId: string;

  /**
   * Comma-separated list of AWS regions to scan
   * @default 'us-east-1,us-west-2,eu-west-1'
   */
  readonly scanRegions?: string;

  /**
   * Log level for Lambda functions
   * @default 'INFO'
   */
  readonly logLevel?: string;

  /**
   * CloudWatch Logs retention in days
   * @default 30
   */
  readonly logRetentionDays?: number;

  /**
   * Email address for SNS error notifications
   */
  readonly notificationEmail?: string;
}

/**
 * Management Account Stack
 * 
 * Deploys:
 * - Lambda 1: discover_accounts
 * - Lambda 2: scan_account
 * - Lambda 3: partner_sync
 * - DynamoDB table: hri_findings
 * - S3 bucket: hri_exports
 * - SNS topic for error notifications
 * - IAM roles and policies
 */
export class ManagementStack extends cdk.Stack {
  public readonly findingsTable: FindingsTable;
  public readonly exportsBucket: s3.Bucket;
  public readonly discoverAccountsLambda: ScannerLambda;
  public readonly scanAccountLambda: ScannerLambda;
  public readonly partnerSyncLambda: ScannerLambda;
  public readonly errorTopic: sns.Topic;

  constructor(scope: Construct, id: string, props: ManagementStackProps) {
    super(scope, id, props);

    // Create DynamoDB table for findings
    this.findingsTable = new FindingsTable(this, 'FindingsTable', {
      ttlDays: 90, // Optional: cleanup findings after 90 days
      pointInTimeRecovery: true,
    });

    // Create S3 bucket for exports
    this.exportsBucket = new s3.Bucket(this, 'ExportsBucket', {
      bucketName: `hri-exports-${this.account}-${this.region}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      versioned: true,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      lifecycleRules: [
        {
          id: 'TransitionToIA',
          enabled: true,
          transitions: [
            {
              storageClass: s3.StorageClass.INFREQUENT_ACCESS,
              transitionAfter: cdk.Duration.days(30),
            },
            {
              storageClass: s3.StorageClass.GLACIER,
              transitionAfter: cdk.Duration.days(90),
            },
          ],
          expiration: cdk.Duration.days(365),
        },
      ],
    });

    // Create SNS topic for error notifications
    this.errorTopic = new sns.Topic(this, 'ErrorTopic', {
      displayName: 'HRI Scanner Error Notifications',
      topicName: 'hri-scanner-errors',
    });

    // Subscribe email to error topic if provided
    if (props.notificationEmail) {
      new sns.Subscription(this, 'ErrorEmailSubscription', {
        topic: this.errorTopic,
        protocol: sns.SubscriptionProtocol.EMAIL,
        endpoint: props.notificationEmail,
      });
    }

    // Lambda 1: discover_accounts
    this.discoverAccountsLambda = new ScannerLambda(this, 'DiscoverAccountsLambda', {
      functionName: 'hri-discover-accounts',
      description: 'Discover all active member accounts in AWS Organization',
      codePath: 'lambda/discover_accounts',
      memorySize: 256,
      timeoutMinutes: 2,
      environment: {
        DYNAMODB_TABLE: this.findingsTable.table.tableName,
        LOG_LEVEL: props.logLevel || 'INFO',
        ERROR_TOPIC_ARN: this.errorTopic.topicArn,
      },
      policyStatements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            'organizations:ListAccounts',
            'organizations:DescribeAccount',
          ],
          resources: ['*'],
        }),
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: ['sns:Publish'],
          resources: [this.errorTopic.topicArn],
        }),
      ],
    });

    // Lambda 2: scan_account
    this.scanAccountLambda = new ScannerLambda(this, 'ScanAccountLambda', {
      functionName: 'hri-scan-account',
      description: 'Execute all 30 HRI checks for a single member account',
      codePath: 'lambda/scan_account',
      memorySize: 1024,
      timeoutMinutes: 10,
      environment: {
        SCANNER_ROLE_NAME: 'HRI-ScannerRole',
        DYNAMODB_TABLE: this.findingsTable.table.tableName,
        S3_BUCKET: this.exportsBucket.bucketName,
        REGIONS: props.scanRegions || 'us-east-1,us-west-2,eu-west-1',
        LOG_LEVEL: props.logLevel || 'INFO',
        EXTERNAL_ID: props.externalId,
        ERROR_TOPIC_ARN: this.errorTopic.topicArn,
      },
      policyStatements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: ['sts:AssumeRole'],
          resources: ['arn:aws:iam::*:role/HRI-ScannerRole'],
        }),
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: ['sns:Publish'],
          resources: [this.errorTopic.topicArn],
        }),
      ],
    });

    // Grant Lambda 2 permissions to write to DynamoDB and S3
    this.findingsTable.table.grantWriteData(this.scanAccountLambda.function);
    this.exportsBucket.grantPut(this.scanAccountLambda.function);

    // Grant Lambda 1 permission to invoke Lambda 2
    this.scanAccountLambda.function.grantInvoke(this.discoverAccountsLambda.function);

    // Update Lambda 1 environment with Lambda 2 ARN
    this.discoverAccountsLambda.function.addEnvironment(
      'SCAN_LAMBDA_ARN',
      this.scanAccountLambda.function.functionArn
    );

    // Lambda 3: partner_sync
    this.partnerSyncLambda = new ScannerLambda(this, 'PartnerSyncLambda', {
      functionName: 'hri-partner-sync',
      description: 'Transform HRI findings into AWS Partner Central format and export',
      codePath: 'lambda/partner_sync',
      memorySize: 512,
      timeoutMinutes: 5,
      environment: {
        DYNAMODB_TABLE: this.findingsTable.table.tableName,
        S3_BUCKET: this.exportsBucket.bucketName,
        PARTNER_BUCKET_PREFIX: 'partner-central/',
        LOG_LEVEL: props.logLevel || 'INFO',
        ERROR_TOPIC_ARN: this.errorTopic.topicArn,
      },
      policyStatements: [
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: ['sns:Publish'],
          resources: [this.errorTopic.topicArn],
        }),
      ],
    });

    // Grant Lambda 3 permissions to read from DynamoDB and write to S3
    this.findingsTable.table.grantReadData(this.partnerSyncLambda.function);
    this.exportsBucket.grantPut(this.partnerSyncLambda.function);

    // Stack outputs
    new cdk.CfnOutput(this, 'ExportsBucketName', {
      value: this.exportsBucket.bucketName,
      description: 'S3 bucket for HRI exports',
      exportName: 'HRIExportsBucketName',
    });

    new cdk.CfnOutput(this, 'ErrorTopicArn', {
      value: this.errorTopic.topicArn,
      description: 'SNS topic for error notifications',
      exportName: 'HRIErrorTopicArn',
    });

    new cdk.CfnOutput(this, 'ExternalId', {
      value: props.externalId,
      description: 'External ID for cross-account role assumption',
      exportName: 'HRIExternalId',
    });
  }
}
