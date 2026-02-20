import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import { Construct } from 'constructs';

export interface FindingsTableProps {
  /**
   * Optional TTL in days for automatic cleanup of old findings
   * @default - No TTL
   */
  readonly ttlDays?: number;

  /**
   * Enable point-in-time recovery for the table
   * @default true
   */
  readonly pointInTimeRecovery?: boolean;
}

/**
 * DynamoDB table for storing HRI findings
 * 
 * Schema:
 * - Partition Key: account_id (String)
 * - Sort Key: check_id (String) - format: {pillar}#{check_name}
 * - GSI1: pillar (PK) + timestamp (SK)
 * - GSI2: execution_id (PK) + timestamp (SK)
 */
export class FindingsTable extends Construct {
  public readonly table: dynamodb.Table;

  constructor(scope: Construct, id: string, props: FindingsTableProps = {}) {
    super(scope, id);

    // Create DynamoDB table with on-demand billing
    this.table = new dynamodb.Table(this, 'Table', {
      tableName: 'hri_findings',
      partitionKey: {
        name: 'account_id',
        type: dynamodb.AttributeType.STRING,
      },
      sortKey: {
        name: 'check_id',
        type: dynamodb.AttributeType.STRING,
      },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      pointInTimeRecovery: props.pointInTimeRecovery ?? true,
      removalPolicy: cdk.RemovalPolicy.RETAIN, // Retain table on stack deletion for data safety
      encryption: dynamodb.TableEncryption.AWS_MANAGED,
    });

    // GSI1: Query findings by pillar
    this.table.addGlobalSecondaryIndex({
      indexName: 'pillar-timestamp-index',
      partitionKey: {
        name: 'pillar',
        type: dynamodb.AttributeType.STRING,
      },
      sortKey: {
        name: 'timestamp',
        type: dynamodb.AttributeType.STRING,
      },
      projectionType: dynamodb.ProjectionType.ALL,
    });

    // GSI2: Query findings by execution_id
    this.table.addGlobalSecondaryIndex({
      indexName: 'execution-timestamp-index',
      partitionKey: {
        name: 'execution_id',
        type: dynamodb.AttributeType.STRING,
      },
      sortKey: {
        name: 'timestamp',
        type: dynamodb.AttributeType.STRING,
      },
      projectionType: dynamodb.ProjectionType.ALL,
    });

    // Optional TTL for automatic cleanup
    if (props.ttlDays) {
      // TTL attribute will be set by Lambda functions as epoch timestamp
      // calculated as: current_time + (ttlDays * 86400)
      cdk.Tags.of(this.table).add('TTLDays', props.ttlDays.toString());
    }

    // Output table name and ARN
    new cdk.CfnOutput(this, 'TableName', {
      value: this.table.tableName,
      description: 'HRI Findings DynamoDB Table Name',
      exportName: 'HRIFindingsTableName',
    });

    new cdk.CfnOutput(this, 'TableArn', {
      value: this.table.tableArn,
      description: 'HRI Findings DynamoDB Table ARN',
      exportName: 'HRIFindingsTableArn',
    });
  }
}
