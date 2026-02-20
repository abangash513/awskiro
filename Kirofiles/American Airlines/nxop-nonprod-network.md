# NXOP Nonprod Network Configuration

This page documents the NXOP Nonprod VPCs. The VPCs and their primary CIDR allocations were deployed by the AA Network team.

Additional modifications such as subnets, route tables, and VPC endpoints were deployed by the NXOP team into the VPCs.

This documentation is specific to NXOP. For documentation of the broader AA network, please see the [AA AWS Networking Guide](https://github.com/AAInternal/governance-as-a-service/blob/main/docs/aws/aws-network-architecture.md) published by the Governance-as-a-Service (GaaS) team.

>❗**AA Networking Requests and Support**
>
> For new VPC requests, or requests for support from the AA Networking Team, the best method
> of contact is via Slack in the **#global-network-solutions** channel.

## Account/VPC Info

### us-east-1

| AWS Resource     | Name                    |
|------------------|-------------------------|
| Account Name     | aa-aws-nxop-nonprod     |
| Account ID       | 972818039298            |
| VPC ID           | vpc-0c24fd1f81cb9954c   |
| VPC Name         | AA_NXOP_N_EA_10.218.48.0_22_VPC   |

### us-west-2

| AWS Resource     | Name                    |
|------------------|-------------------------|
| Account Name     | aa-aws-nxop-nonprod     |
| Account ID       | 972818039298            |
| VPC ID           | vpc-04c4ce5b6b542ba6f   |
| VPC Name         | AA_NXOP_N_WE_10.219.48.0_22_VPC  |

## VPC Overview

### us-east-1

**VPC CIDR Blocks:**

- Primary: `10.218.48.0/22` (1,024 IPs)

**IP Ranges:**

- `10.218.48.0 - 10.218.51.255`

### us-west-2

**VPC CIDR Blocks:**

- Primary: `10.219.48.0/22` (1,024 IPs)

**IP Ranges:**

- `10.219.48.0 - 10.219.51.255`

## Transit Gateway Subnets (Deployed by AA Network Team)

### us-east-1

| Subnet Name      | CIDR Block      | Availability Zone |
|------------------|-----------------|-------------------|
| nxop_non-prod_us-east-1a_tgw_snet   | 10.218.51.128/28  | us-east-1a        |
| nxop_non-prod_us-east-1b_tgw_snet   | 10.218.51.144/28  | us-east-1b        |
| nxop_non-prod_us-east-1c_tgw_snet   | 10.218.51.160/28  | us-east-1c        |

### us-west-2

| Subnet Name      | CIDR Block      | Availability Zone |
|------------------|----------------- |-------------------|
| nxop_non-prod_us-west-2a_tgw_snet   | 10.219.51.128/28  | us-west-2a        |
| nxop_non-prod_us-west-2b_tgw_snet   | 10.219.51.144/28  | us-west-2b        |
| nxop_non-prod_us-west-2c_tgw_snet   | 10.219.51.160/28  | us-west-2c        |

## NXOP Subnets (Deployed by NXOP Team)

### us-east-1

#### Availability Zone 1 (us-east-1a - use1-az1)

| Subnet Type      | CIDR Block      | IP Count |
|------------------|-----------------|----------|
| aot-n-data-us-east-1a         | 10.218.48.0/25  | 128      |
| aot-n-general-purpose-us-east-1a | 10.218.48.128/25 | 128      |

#### Availability Zone 2 (us-east-1b - use1-az2)

| Subnet Name      | CIDR Block      | IP Count |
|------------------|-----------------|----------|
| aot-n-data-us-east-1b         | 10.218.49.0/25  | 128      |
| aot-n-general-purpose-us-east-1b | 10.218.49.128/25 | 128      |

#### Availability Zone 3 (us-east-1c - use1-az4)

| Subnet Name      | CIDR Block      | IP Count |
|------------------|-----------------|----------|
| aot-n-data-us-east-1c         | 10.218.50.0/25  | 128      |
| aot-n-general-purpose-us-east-1c | 10.218.50.128/25 | 128      |

### us-west-2

> **⚠️NXOP subnets in us-west-2 have not yet been deployed. They are part of the future state design.**

#### Availability Zone 1 (us-west-2a - usw2-az2)

| Subnet Type      | CIDR Block      | IP Count |
|------------------|-----------------|----------|
| aot-n-data-us-west-2a         | 10.219.48.0/25  | 128      |
| aot-n-general-purpose-us-west-2a | 10.219.48.128/25 | 128      |

#### Availability Zone 2 (us-west-2b - usw2-az1)

| Subnet Name      | CIDR Block      | IP Count |
|------------------|-----------------|----------|
| aot-n-data-us-west-2b         | 10.219.49.0/25  | 128      |
| aot-n-general-purpose-us-west-2b | 10.219.49.128/25 | 128      |

#### Availability Zone 3 (us-west-2c - usw2-az3)

| Subnet Name      | CIDR Block      | IP Count |
|------------------|-----------------|----------|
| aot-n-data-us-west-2c         | 10.219.50.0/25  | 128      |
| aot-n-general-purpose-us-west-2c | 10.219.50.128/25 | 128      |

## Extraneous IP Space

### us-east-1

| CIDR Block       | IP Count | Purpose           |
|------------------|----------|-------------------|
| 10.218.51.0/25   | 128      | Future expansion  |

### us-west-2

| CIDR Block       | IP Count | Purpose           |
|------------------|----------|-------------------|
| 10.219.51.0/25   | 128      | Future expansion  |

## Routing

Interconnectivity to other AA Networks is handled via Transit Gateway. Generally speaking, traffic leaving the VPC is routed via TGW. TGW route tables dictate the next hop en route to the destination.

### Primary Subnet Route Table

#### us-east-1

| Destination              |  Target   |
|--------------------------|-----------|
| S3 Managed Prefix List   | S3 VPCE   |
| 0.0.0.0/0                | TGW       |
| 10.218.48.0/22           | local     |

#### us-west-2

| Destination              |  Target   |
|--------------------------|-----------|
| S3 Managed Prefix List   | S3 VPCE   |
| 0.0.0.0/0                | TGW       |
| 10.219.48.0/22           | local     |

## Subnet Design Diagram

![NXOP VPCs](../../images/nxop-vpcs.png)
