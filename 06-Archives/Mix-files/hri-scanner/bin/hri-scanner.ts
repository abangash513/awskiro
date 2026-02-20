#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { ManagementStack } from '../lib/management-stack';
import { MemberStack } from '../lib/member-stack';

const app = new cdk.App();

// Get configuration from context or environment variables
const managementAccountId = app.node.tryGetContext('managementAccountId') || process.env.MANAGEMENT_ACCOUNT_ID;
const region = app.node.tryGetContext('region') || process.env.AWS_REGION || 'us-east-1';
const externalId = app.node.tryGetContext('externalId') || process.env.EXTERNAL_ID || 'hri-scanner-' + Date.now();

// Management Account Stack - deploys Lambda functions, DynamoDB, S3, EventBridge
new ManagementStack(app, 'ManagementStack', {
  env: {
    account: managementAccountId,
    region: region,
  },
  description: 'HRI Fast Scanner - Management Account Resources',
  externalId: externalId,
});

// Member Account Stack - deploys HRI-ScannerRole
// This stack should be deployed to each member account via StackSets
new MemberStack(app, 'MemberStack', {
  env: {
    region: region,
  },
  description: 'HRI Fast Scanner - Member Account Role',
  managementAccountId: managementAccountId,
  externalId: externalId,
});

app.synth();
