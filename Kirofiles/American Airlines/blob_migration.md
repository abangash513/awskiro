# Azure Blob Migration to AWS S3

## Overview

FXIP's objective of transitioning from Azure to AWS requires that flight events and corresponding metadata are transferred from Azure to AWS.  Business requirements dictate a cutover to transition from Azure to AWS with an ability to rollback if necessary.  Due to this requirement, after the cutover period begins objects and metadata stored in AWS need to be copied to Azure.

To achieve this in an automated fashion, we recommend leveraging AWS DataSync to copy objects from Azure Blob Storage to AWS S3.  AWS DataSync has built-in error handling and [object validation](https://docs.aws.amazon.com/datasync/latest/userguide/how-datasync-transfer-works.html#how-verifying-works) to ensure successful transmission of objects and robust [error handling](https://docs.aws.amazon.com/datasync/latest/userguide/troubleshooting-task-verification.html) to troubleshoot issues.  AWS DataSync supports [transfers from Azure Blob Storage](https://docs.aws.amazon.com/datasync/latest/userguide/creating-azure-blob-location.html) to AWS S3.  DataSync should be configured in [enhanced mode](https://docs.aws.amazon.com/datasync/latest/userguide/choosing-task-mode.html) to enable parallel task execution for higher performance, eliminate the need for agents, and avoid [quota limits](https://docs.aws.amazon.com/datasync/latest/userguide/datasync-limits.html#task-hard-limits) that apply to basic mode.

Corresponding metadata is retrieved separately from Azure Tables and ingested into AWS DocumentDB using AWS Lambda functions. Queries are made based on the object name (which contains the Partition Key) when copied to AWS S3.  Access to Azure requires a Shared Access Signature token, also known as a [SAS token](https://learn.microsoft.com/en-us/azure/ai-services/Translator/document-translation/how-to-guides/create-sas-tokens?tabs=Containers).   Reference the [example code](https://github.com/AAInternal/nxop-infra/tree/feature/blob-mirgation/data_sync) for snippets of functionality that parse Partition Keys from object names in Azure Blob Storage and demonstrates additional operations.

### Security Requirements

- AWS DataSync requires access to Azure Blob Storage containers along with read and put operations on objects in Azure Blob Storage containers.
- The Lambda function must be granted access to the source Azure Tables resources. The Lambda function must be deployed into the NXOP environment's VPC and allowed access to DocumentDB clusters.
- The Azure Function processing blob uploads must be granted network access to AWS DocumentDB, requiring:
  - DocumentDB security group rules allowing inbound connections from Azure Function
  - AWS credentials management and secure storage in Azure
  - Network routing and firewall rules between Azure and AWS environments
  - TLS/SSL certificates for encrypted connections to DocumentDB

A [scheduled](https://docs.aws.amazon.com/datasync/latest/userguide/task-scheduling.html) task enables AWS DataSync to regularly copy objects from Azure Blob Storage to AWS S3.  A second scheduled task enables AWS DataSync to copy objects from AWS S3 to Azure Blob Storage.  Once an object is copied into AWS S3, a Lambda function is triggered which parses the Partition Key from the object's name, queries Azure Tables, and inserts the corresponding metadata into the AWS DocumentDB collection. In the Lambda function, exception handling and error logging should exist to address issues with failures during this phase of processing.  A CloudWatch Dashboard monitoring the Lambda function should be configured to display errors for evaluation purposes.  CloudWatch Alerts for multiple consecutive failures and eclipsed failure percentage thresholds should also exist.

## Pre-Cutover Setup  

![AWS DataSync](images/pre-cutover-object-copy.png)

Due to potential issues that can occur when running compute operations (Lambda functions), a downstream validation process needs to exist to ensure metadata has been ingested for each object.  This periodic check ensures added objects have corresponding metadata in DocumentDB.  If objects exist in AWS S3 but don't have corresponding records in AWS DocumentDB, metadata needs to be queried in Azure Tables (once again by parsing the Partition Key from the object name) to be ingested.  This process should include exception handling and error logging along with CloudWatch Dashboards that display errors for evaluation purposes.  Again, CloudWatch Alerts for multiple consecutive failures and eclipsed failure percentage thresholds should exist.

Additionally, this process needs to ensure that a failure with a specific object is non-blocking so other objects can be processed.

![AWS DataSync](images/pre-cutover-metadata-check.png)

## Post-Cutover Setup

Objects uploaded to S3 are copied to Azure Blob Storage and metadata is inserted into Azure Tables.  An Azure Function parses the object name and uses the Partition Key to query AWS DocumentDB to retrieve metadata and insert the metadata into Azure Tables.  Once again, exception handling and error logging should exist in the Azure Function to address issues with failures or other issues with processing. Azure Monitoring should be configured with reporting on errors similar to the CloudWatch Dashboard setup in AWS.  Alerts should be implemented for multiple consecutive failures and eclipsed failure percentage thresholds should exist.

![Azure metadata sync](images/post-cutover-object-copy.png)

Similar to the AWS side of this process, a downstream validation process needs to exist to ensure metadata has been ingested for each object.  Previously mentioned exception handling, error logging, and correlating Azure Monitoring should be configured similar to AWS CloudWatch Dashboards and Alerts.
![Azure metadata sync](images/post-cutover-metadata-check.png)

## Confirmed Process Dependencies

- The FXIP application uploads the object to Azure Blob Storage and then writes to Azure Tables with no explicit lag.  Thus, metadata records should theoretically exist for every object.

## Risks and Assumptions

### Risks

- **Performance**: Lambda concurrent execution limits (default 1000 per region) could impact metadata migration at scale and cause throttling during high-volume sync operations. VPC-attached Lambda functions consume ENIs with a default quota of 500 per VPC, which could also limit scaling. The default AWS Lambda timeout is 3 seconds and should be increased to account for processing and network latency.  We recommend a minimum of 30 seconds.
- **Error Handling**: Missing monitoring/alerting/retry strategy for failed operations or metadata queries could delay issue detection.
- **Filtering Limitations**: DataSync does not support age-based filtering out of the box, requiring advanced solutions such as pre-generating manifests, filtering by naming conventions, etc.
- Azure Tables are limited to retrieving 100 entities with a payload limit of 4 MiB per query.

### Assumptions

- Object names consistently contain parsable partition keys for metadata lookups
- Sufficient network bandwidth and reliability exists between Azure and AWS
- Business can tolerate eventual consistency during the migration period
- Required cross-cloud permissions and access will be granted
