import * as cdk from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export interface MemberStackProps extends cdk.StackProps {
  /**
   * Management account ID that will assume this role
   */
  readonly managementAccountId: string;

  /**
   * External ID for cross-account role assumption
   */
  readonly externalId: string;

  /**
   * Role name
   * @default 'HRI-ScannerRole'
   */
  readonly roleName?: string;
}

/**
 * Member Account Stack
 * 
 * Deploys:
 * - HRI-ScannerRole with read-only permissions for all scanned services
 * - Trust policy restricted to management account principal
 * - Least-privilege permissions with explicit deny for write operations
 */
export class MemberStack extends cdk.Stack {
  public readonly scannerRole: iam.Role;

  constructor(scope: Construct, id: string, props: MemberStackProps) {
    super(scope, id, props);

    // Create HRI-ScannerRole with trust policy
    this.scannerRole = new iam.Role(this, 'ScannerRole', {
      roleName: props.roleName || 'HRI-ScannerRole',
      description: 'Cross-account role for HRI Fast Scanner with read-only permissions',
      assumedBy: new iam.AccountPrincipal(props.managementAccountId),
      externalIds: [props.externalId],
      maxSessionDuration: cdk.Duration.hours(1),
    });

    // S3 read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'S3ReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        's3:GetBucketPublicAccessBlock',
        's3:GetBucketAcl',
        's3:GetBucketPolicy',
        's3:ListBucket',
        's3:GetEncryptionConfiguration',
        's3:GetBucketVersioning',
        's3:GetBucketLogging',
      ],
      resources: ['*'],
    }));

    // EC2 read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'EC2ReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'ec2:DescribeVolumes',
        'ec2:DescribeInstances',
        'ec2:DescribeVpcs',
        'ec2:DescribeFlowLogs',
        'ec2:DescribeAddresses',
        'ec2:DescribeRegions',
        'ec2:DescribeAvailabilityZones',
      ],
      resources: ['*'],
    }));

    // RDS read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'RDSReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'rds:DescribeDBInstances',
        'rds:DescribeDBClusters',
        'rds:DescribeDBSnapshots',
      ],
      resources: ['*'],
    }));

    // IAM read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'IAMReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'iam:GetAccountSummary',
        'iam:ListUsers',
        'iam:ListAccessKeys',
        'iam:GetAccountPasswordPolicy',
        'iam:GetCredentialReport',
        'iam:GenerateCredentialReport',
        'iam:GetUser',
        'iam:ListMFADevices',
      ],
      resources: ['*'],
    }));

    // Security Hub read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'SecurityHubReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'securityhub:GetFindings',
        'securityhub:DescribeHub',
        'securityhub:GetEnabledStandards',
      ],
      resources: ['*'],
    }));

    // Config read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'ConfigReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'config:DescribeConfigurationRecorders',
        'config:DescribeDeliveryChannels',
        'config:DescribeConfigurationRecorderStatus',
      ],
      resources: ['*'],
    }));

    // CloudWatch read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'CloudWatchReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'cloudwatch:DescribeAlarms',
        'cloudwatch:GetMetricStatistics',
        'cloudwatch:ListMetrics',
      ],
      resources: ['*'],
    }));

    // GuardDuty read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'GuardDutyReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'guardduty:ListDetectors',
        'guardduty:GetDetector',
        'guardduty:ListFindings',
      ],
      resources: ['*'],
    }));

    // CloudTrail read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'CloudTrailReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'cloudtrail:DescribeTrails',
        'cloudtrail:GetTrailStatus',
        'cloudtrail:GetEventSelectors',
      ],
      resources: ['*'],
    }));

    // Cost Explorer read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'CostExplorerReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'ce:GetCostAndUsage',
        'ce:GetSavingsPlansUtilizationDetails',
        'ce:GetReservationUtilization',
        'ce:GetSavingsPlansCoverage',
        'ce:GetReservationCoverage',
      ],
      resources: ['*'],
    }));

    // Compute Optimizer read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'ComputeOptimizerReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'compute-optimizer:GetEC2InstanceRecommendations',
        'compute-optimizer:GetLambdaFunctionRecommendations',
        'compute-optimizer:GetEnrollmentStatus',
      ],
      resources: ['*'],
    }));

    // Backup read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'BackupReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'backup:ListBackupPlans',
        'backup:ListProtectedResources',
        'backup:DescribeBackupVault',
      ],
      resources: ['*'],
    }));

    // Auto Scaling read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'AutoScalingReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'autoscaling:DescribeAutoScalingGroups',
        'autoscaling:DescribePolicies',
        'autoscaling:DescribeScalingActivities',
      ],
      resources: ['*'],
    }));

    // Elastic Load Balancing read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'ELBReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'elasticloadbalancing:DescribeLoadBalancers',
        'elasticloadbalancing:DescribeTargetHealth',
        'elasticloadbalancing:DescribeTargetGroups',
        'elasticloadbalancing:DescribeListeners',
      ],
      resources: ['*'],
    }));

    // Lambda read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'LambdaReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'lambda:ListFunctions',
        'lambda:GetFunction',
        'lambda:GetFunctionConfiguration',
      ],
      resources: ['*'],
    }));

    // KMS read-only permissions
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'KMSReadOnly',
      effect: iam.Effect.ALLOW,
      actions: [
        'kms:ListKeys',
        'kms:DescribeKey',
        'kms:GetKeyPolicy',
      ],
      resources: ['*'],
    }));

    // Explicit deny for write operations (least-privilege principle)
    this.scannerRole.addToPolicy(new iam.PolicyStatement({
      sid: 'DenyWriteOperations',
      effect: iam.Effect.DENY,
      actions: [
        '*:Create*',
        '*:Delete*',
        '*:Update*',
        '*:Put*',
        '*:Modify*',
        '*:Set*',
        '*:Add*',
        '*:Remove*',
        '*:Attach*',
        '*:Detach*',
      ],
      resources: ['*'],
    }));

    // Stack outputs
    new cdk.CfnOutput(this, 'ScannerRoleArn', {
      value: this.scannerRole.roleArn,
      description: 'HRI-ScannerRole ARN',
      exportName: 'HRIScannerRoleArn',
    });

    new cdk.CfnOutput(this, 'ScannerRoleName', {
      value: this.scannerRole.roleName,
      description: 'HRI-ScannerRole Name',
      exportName: 'HRIScannerRoleName',
    });
  }
}
