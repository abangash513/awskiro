# NXOP Dev Network Configuration

This page documents the NXOP Dev VPC. The VPC and its primary CIDR allocation of `10.218.32.0/20` was deployed by the AA Network team.

Additional modifications such as subnets, route tables, secondary CIDR ranges, and VPC endpoints were deployed by the NXOP team into the VPC.

This documentation is specific to NXOP. For documentation of the broader AA network, please see the [AA AWS Networking Guide](https://github.com/AAInternal/governance-as-a-service/blob/main/docs/aws/aws-network-architecture.md) published by the Governance-as-a-Service (GaaS) team.

>❗**AA Networking Requests and Support**
>
> For new VPC requests, or requests for support from the AA Networking Team, the best method
> of contact is via Slack in the **#global-network-solutions** channel.

## Account/VPC Info

| AWS Resource     | Name                    |
|------------------|-------------------------|
| Account Name     | aa-aws-nxop-dev         |
| Account ID       | 178549792225            |
| VPC ID           | vpc-0b0f8ffc4d4d9c203   |
| VPC Name         | AA_NXOP_DEV_N_EA_10.218.32.0_20_VPC   |

## VPC Overview

**VPC CIDR Blocks:**

- Primary: `10.218.32.0/20` (4,096 IPs)

**IP Ranges:**

- `10.218.32.0 - 10.218.47.255`

## Transit Gateway Subnets (Deployed by AA Network Team)

| Subnet Name      | CIDR Block      | Availability Zone |
|------------------|-----------------|-------------------|
| nxop_dev_non-prod_us-east-1a_tgw_snet   | 10.218.32.0/28  | us-east-1a        |
| nxop_dev_non-prod_us-east-1b_tgw_snet   | 10.218.36.0/28  | us-east-1b        |
| nxop_dev_non-prod_us-east-1c_tgw_snet   | 10.218.40.0/28  | us-east-1c        |

## NXOP Subnets (Deployed by NXOP Team)

### Availability Zone 1 (us-east-1a - use1-az2)

| Subnet Type      | CIDR Block      | IP Count |
|------------------|-----------------|----------|
| aot-d-data-us-east-1a         | 10.218.34.0/24  | 256      |
| aot-d-general-purpose-us-east-1a | 10.218.35.0/24 | 256      |

### Availability Zone 2 (us-east-1b - use1-az4)

| Subnet Name      | CIDR Block      | IP Count |
|------------------|-----------------|----------|
| aot-d-data-us-east-1b         | 10.218.38.0/24  | 256      |
| aot-d-general-purpose-us-east-1b | 10.218.39.0/24 | 256      |

### Availability Zone 3 (us-east-1c - use1-az6)

| Subnet Name      | CIDR Block      | IP Count |
|------------------|-----------------|----------|
| aot-d-data-us-east-1c         | 10.218.42.0/24  | 256      |
| aot-d-general-purpose-us-east-1c | 10.218.43.0/24 | 256      |

## Extraneous IP Space

| CIDR Block       | IP Count | Purpose           |
|------------------|----------|-------------------|
| 10.218.44.0/22   | 1,024    | Future expansion  |

## Routing

Interconnectivity to other AA Networks is handled via Transit Gateway. Generally speaking, traffic leaving the VPC is routed via TGW. TGW route tables dictate the next hop en route to the destination.

### Primary Subnet Route Table

The route table below is associated with NXOP subnets.

| Destination              |  Target   |
|--------------------------|-----------|
| S3 Managed Prefix List   | S3 VPCE   |
| 0.0.0.0/0                | TGW       |
| 10.218.32.0/20           | local     |

## Subnet Design Diagram

![NXOP VPCs](../../images/nxop-vpcs.png)
