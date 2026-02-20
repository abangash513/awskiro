import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export interface ScannerLambdaProps {
  /**
   * Lambda function name
   */
  readonly functionName: string;

  /**
   * Lambda function description
   */
  readonly description: string;

  /**
   * Path to Lambda function code
   */
  readonly codePath: string;

  /**
   * Lambda handler
   * @default index.handler
   */
  readonly handler?: string;

  /**
   * Lambda runtime
   * @default Python 3.12
   */
  readonly runtime?: lambda.Runtime;

  /**
   * Memory size in MB
   * @default 256
   */
  readonly memorySize?: number;

  /**
   * Timeout in minutes
   * @default 2
   */
  readonly timeoutMinutes?: number;

  /**
   * Environment variables
   */
  readonly environment?: { [key: string]: string };

  /**
   * IAM policy statements to attach to the Lambda execution role
   */
  readonly policyStatements?: iam.PolicyStatement[];

  /**
   * CloudWatch Logs retention period
   * @default 30 days
   */
  readonly logRetention?: logs.RetentionDays;
}

/**
 * Construct for creating Lambda functions for the HRI Scanner
 */
export class ScannerLambda extends Construct {
  public readonly function: lambda.Function;
  public readonly role: iam.Role;

  constructor(scope: Construct, id: string, props: ScannerLambdaProps) {
    super(scope, id);

    // Create IAM role for Lambda execution
    this.role = new iam.Role(this, 'Role', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      description: `Execution role for ${props.functionName}`,
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // Add custom policy statements
    if (props.policyStatements) {
      props.policyStatements.forEach((statement, index) => {
        this.role.addToPolicy(statement);
      });
    }

    // Create Lambda function
    this.function = new lambda.Function(this, 'Function', {
      functionName: props.functionName,
      description: props.description,
      runtime: props.runtime || lambda.Runtime.PYTHON_3_12,
      handler: props.handler || 'index.handler',
      code: lambda.Code.fromAsset(props.codePath),
      role: this.role,
      memorySize: props.memorySize || 256,
      timeout: cdk.Duration.minutes(props.timeoutMinutes || 2),
      environment: props.environment || {},
      logRetention: props.logRetention || logs.RetentionDays.ONE_MONTH,
      tracing: lambda.Tracing.ACTIVE, // Enable X-Ray tracing
      reservedConcurrentExecutions: undefined, // No reserved concurrency by default
    });

    // Output Lambda function ARN
    new cdk.CfnOutput(this, 'FunctionArn', {
      value: this.function.functionArn,
      description: `${props.functionName} Lambda Function ARN`,
      exportName: `${props.functionName}Arn`,
    });

    new cdk.CfnOutput(this, 'FunctionName', {
      value: this.function.functionName,
      description: `${props.functionName} Lambda Function Name`,
      exportName: `${props.functionName}Name`,
    });
  }

  /**
   * Grant the Lambda function permission to invoke another Lambda function
   */
  public grantInvoke(targetFunction: lambda.IFunction): void {
    targetFunction.grantInvoke(this.function);
  }
}
