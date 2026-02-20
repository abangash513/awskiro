# NXOP KPaaS Integration

The AA Kubernetes Platform as a Service (KPaaS) platform serves as the primary compute infrastructure for NXOP.

KPaaS is an internal cloud computing solution that delivers managed compute resources for containerized applications. It leverages AWS and is accessed through AA's internal development portal, Runway. KPaaS abstracts away the complexities of infrastructure management, providing developers with a streamlined platform to deploy, manage, and scale their containerized applications efficiently. By utilizing KPaaS, teams can focus on application development and less on managing the underlying infrastructure, resulting in improved productivity and faster time-to-market for our products.

The KPaaS non-prod environment serves both the NXOP dev and NXOP non-prod environments. The KPaaS prod environment serves the NXOP prod environment.

## KPaaS Network Integration

KPaaS VPCs and NXOP VPCs must be able to pass traffic between one another for the NXOP platform to function. This is because workloads running in KPaaS need to be able to connect to NXOP infrastructure such as DocumentDB clusters, MSK clusters, and more. This is achieved via AWS Transit Gateway (TGW). Both KPaaS and NXOP VPCs route traffic through the TGW which acts as a centralized router.

For single-region traffic, i.e. traffic between KPaaS and NXOP in `us-east-1`, there is no traffic inspection in place and thus no firewall rules are required. Only security groups need to be modified in order to allow traffic to specific resources. For cross-region traffic, such as traffic passing between `us-east-1` and `us-west-2`, that traffic will traverse a firewall and be subject to inspection. Firewall rules may be required.

![NXOP KPaaS network integration diagram](images/nxop-kpaas-network-integration.png)

## Pod Identities

Pod Identities provide secure, credential-free authentication for Kubernetes workloads running in KPaaS to access AWS services in the NXOP account. This mechanism eliminates the need to manage static credentials or embed AWS access keys within applications, following AWS security best practices.

Applications in a pod’s containers can use an AWS SDK or the AWS CLI to make API requests to AWS services using IAM permissions. Applications must sign their AWS API requests with AWS credentials.

Pod Identities provide the ability to manage credentials for your applications, similar to the way that Amazon EC2 instance profiles provide credentials to Amazon EC2 instances. Instead of creating and distributing your AWS credentials to the containers or using the Amazon EC2 instance’s role, you associate an IAM role with a Kubernetes service account and configure your Pods to use the service account.

### Cross-Account Access Pattern

Because EKS clusters are running in one account (KPaaS) and the resources they interact with are in another account (NXOP), a cross-account access pattern must be used. The cross-account access pattern for pod identities involves two roles:

1. **KPaaS Account Role**: Created and managed by the KPaaS team, this role serves as the intermediate role that is assumed directly by a pod before it then assumes another role in the NXOP account.
1. **NXOP Account Role**: Created by the NXOP team, this role defines the actual permissions for accessing NXOP resources (DocumentDB, MSK, S3, etc.)

This dual-role approach provides security boundaries while enabling necessary access to NXOP infrastructure from KPaaS workloads.

### Configuring Pod Identities

The process for configuring a new pod identity is as follows:

1. **Create Target IAM Role in NXOP Account**:
   - Create the target IAM role in the NXOP AWS account, using the appropriate permissions
   - Define least-privilege policies for specific NXOP resources as required
   - Configure the role's trust relationship to allow assumption from the appropriate KPaaS account. The KPaaS NonProd account ID is `285282426848` and the KPaaS Prod account ID is `045755618773`.
   
   This is an example trust policy:

   ```json
   {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": "arn:aws:iam::285282426848:root"
                },
                "Action": [
                    "sts:AssumeRole",
                    "sts:TagSession"
                ],
                "Condition": {
                    "StringEquals": {
                        "aws:RequestTag/kubernetes-namespace": "fxip-ms-dev"
                    },
                    "StringLike": {
                        "aws:RequestTag/eks-cluster-arn": "arn:aws:eks:*:285282426848:cluster/*"
                    }
                }
            }
        ]
    }
   ```

    The policy above allows principals in the KPaaS NonProd AWS account (285282426848) to assume the role, assuming the role assumption is originating from an EKS cluster and using the specified namespace.

    > **⚠️ WARNING: Additional Restriction by Service Account**
    > **Recommended Enhancement:**  It is recommended to further restrict pod identity trust policies by limiting access to specific Kubernetes service accounts. This can be done by adding `"aws:RequestTag/kubernetes-service-account": "<service_acct_name>"`
    > to the first `Condition` statement above.
    >
    > This was originally in place, but has been removed temporarily while the official namespace and service account strategy is further refined by the development team. For additional context, see [this PR](https://github.com/AAInternal/nxop-infra/pull/279).

1. **Include Pod Identity Details in KPaaS WebApp Configuration**
   - Include the `runway.aa.com/pod-identity` annotation in your application's webapp config. This is presented in the format of `<AWS_Account_ID>/<Target_IAM_Role_Name>` For example:

   ``` yaml
   metadata:
   annotations:
     enableCloudIngress: 'true'
     backstageName: hello-app-kopf
     ingressProxyBufferSize: 10k
     largeClientHeaderBuffers: 16k
     runway.aa.com/pod-identity: 178549792225/example-role
   ```

   For more information, see the relevant KPaaS annotations [documentation] (https://developer.aa.com/docs/default/component/runway/getting-started/userguides/webapp/#annotations).


## KPaaS Reference Documentation

- [KPaaS Overview](https://developer.aa.com/docs/default/component/runway/kpaas/kpaas-overview/) --> A comprehensive overview of KPaaS
- [Runway Create/Import UI](https://developer.aa.com/create?filters%5Btags%5D=certified) --> Landing page for selecting and deploying Runway templates to KPaaS clusters
- [Runway Doc for Creating Application](https://developer.aa.com/docs/default/component/runway/getting-started/userguides/create-a-app/) --> Documentation for onboarding an application using Runway templates
- [Runway Doc for Importing Existing Application](https://developer.aa.com/docs/default/component/runway/guides/onboarding-to-runway/#1-import-an-application-into-runway) --> Documentation for importing an existing application to Runway
- [Runway WebApp Spec](https://developer.aa.com/docs/default/component/runway/getting-started/userguides/webapp/) --> Complete WebApp Spec is documented here
- [Runway -- Manage Rancher Project & Namespace](https://developer.aa.com/infrastructure/rancher) --> Landing page for 
managing resource quota for Rancher Project/Namespace
- [Rancher Non-Prod UI](https://master-nprke.ok8s.aa.com/) --> UI for viewing K8s resources deployed on target NXOP cluster

## Support

Support for KPaaS in the context of NXOP should be handled via the [NXOP-KPaaS-AWS-Support](https://teams.microsoft.com/l/chat/19:55bdeb2050154a8081fc6f3f4fa42140@thread.v2/conversations?context=%7B%22contextType%22%3A%22chat%22%7D) Teams channel.
