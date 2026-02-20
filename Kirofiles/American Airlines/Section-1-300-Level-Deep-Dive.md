# NXOP Message Flow Analysis - 300 Level Deep Dive

## Document Overview

**Purpose**: Provide AWS 300-level technical depth on NXOP message flow architecture, integration patterns, and infrastructure dependencies.

**Scope**: Deep technical analysis of 25 message flows covering:
- Detailed protocol mechanics and message formats
- Infrastructure component interactions and data paths
- Cross-region replication and failover mechanisms
- Performance characteristics and optimization strategies
- Security and authentication patterns
- Monitoring and observability implementation

**Target Audience**: Solutions Architects, Platform Engineers, DevOps Engineers

**Document Version**: 2.0 (300-Level Deep Dive)  
**Last Updated**: 2026-01-28

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Deep Dive](#architecture-deep-dive)
3. [MSK Infrastructure Analysis](#msk-infrastructure-analysis)
4. [DocumentDB Architecture](#documentdb-architecture)
5. [Integration Pattern Deep Dive](#integration-pattern-deep-dive)
6. [Protocol Analysis](#protocol-analysis)
7. [Cross-Region Architecture](#cross-region-architecture)
8. [Security and Authentication](#security-and-authentication)
9. [Performance and Optimization](#performance-and-optimization)
10. [Monitoring and Observability](#monitoring-and-observability)
11. [Cost Analysis](#cost-analysis)
12. [Flow-by-Flow Technical Analysis](#flow-by-flow-technical-analysis)

---

## Executive Summary

### Platform Overview

The NXOP (Network Operations Platform) is a multi-region, event-driven integration platform that orchestrates 25 distinct message flows across airline operations systems. The platform operates in AWS (us-east-1 and us-west-2) with parallel processing in Azure FXIP and on-premises systems.

### Key Statistics

- **Total Message Flows**: 25 distinct integration patterns
- **NXOP Active Flows**: 19 flows (76%) - NXOP Platform actively processes messages
- **NXOP Passive Flows**: 6 flows (24%) - No NXOP involvement (Flows 11, 12, 13, 15, 21, 25)
- **Primary Integration Hub**: OpsHub On-Prem (100% of flows)
- **Primary Data Source**: Flightkeys (20 flows, 80%)
- **Communication Protocols**: 6 protocols (HTTPS, AMQP, Kafka, MQ, ACARS, TCP)
- **Infrastructure Cost**: ~$20,690/month (MSK + DocumentDB)


### Infrastructure Components

#### Core AWS Services
- **EKS (via KPaaS)**: 20+ microservices across 2 regions
- **MSK**: 12 brokers (6 per region), 1TB storage per broker
- **DocumentDB Global Cluster**: 6 instances (3 per region), auto-scaling storage
- **S3**: Document storage with cross-region replication
- **Route53**: DNS for MSK bootstrap (kafka.nxop.com)
- **NLB**: Network load balancer for MSK access
- **Akamai GTM**: Global traffic manager for inbound API endpoints

#### Integration Patterns
1. **Inbound Data Ingestion** (10 flows): External → NXOP → On-Prem
2. **Outbound Data Publishing** (2 flows): On-Prem → NXOP → External
3. **Bidirectional Sync** (6 flows): Two-way data synchronization
4. **Notification/Alert** (3 flows): Event-driven notifications
5. **Document Assembly** (1 flow): Multi-service document generation
6. **Authorization** (2 flows): Electronic signature workflows
7. **Data Maintenance** (1 flow): Reference data management

---

## Architecture Deep Dive

### Multi-Region Architecture


#### Region Configuration

**Primary Region (us-east-1)**:
```
VPC: 10.100.0.0/16
├── Public Subnets (3 AZs): 10.100.0.0/20, 10.100.16.0/20, 10.100.32.0/20
├── Private Subnets (3 AZs): 10.100.48.0/20, 10.100.64.0/20, 10.100.80.0/20
├── Database Subnets (3 AZs): 10.100.96.0/20, 10.100.112.0/20, 10.100.128.0/20
└── Transit Gateway Attachment: tgw-0abc123 (to KPaaS VPC)

EKS Cluster: nxop-prod-use1
├── Node Groups: 3 (1 per AZ)
├── Instance Type: m5.2xlarge
├── Min/Max/Desired: 3/12/6 nodes
└── Pod Identity: Enabled (cross-account IAM)

MSK Cluster: nxop-prod-msk-use1
├── Brokers: 6 (2 per AZ)
├── Instance Type: kafka.m5.2xlarge
├── Storage: 1TB EBS gp3 per broker
├── Replication Factor: 3
└── Min ISR: 2

DocumentDB Cluster: nxop-prod-docdb-global
├── Primary: us-east-1
├── Instances: 3 (1 primary, 2 read replicas)
├── Instance Type: db.r6g.2xlarge
└── Storage: Auto-scaling (up to 64 TB)
```

**Secondary Region (us-west-2)**:
```
VPC: 10.101.0.0/16
├── Public Subnets (3 AZs): 10.101.0.0/20, 10.101.16.0/20, 10.101.32.0/20
├── Private Subnets (3 AZs): 10.101.48.0/20, 10.101.64.0/20, 10.101.80.0/20
├── Database Subnets (3 AZs): 10.101.96.0/20, 10.101.112.0/20, 10.101.128.0/20
└── Transit Gateway Attachment: tgw-0def456 (to KPaaS VPC)

EKS Cluster: nxop-prod-usw2
├── Node Groups: 3 (1 per AZ)
├── Instance Type: m5.2xlarge
├── Min/Max/Desired: 3/12/6 nodes
└── Pod Identity: Enabled (cross-account IAM)

MSK Cluster: nxop-prod-msk-usw2
├── Brokers: 6 (2 per AZ)
├── Instance Type: kafka.m5.2xlarge
├── Storage: 1TB EBS gp3 per broker
├── Replication Factor: 3
└── Min ISR: 2

DocumentDB Cluster: nxop-prod-docdb-global (Secondary)
├── Secondary: us-west-2
├── Instances: 3 (read replicas)
├── Instance Type: db.r6g.2xlarge
└── Storage: Replicated from primary
```


#### Cross-Account Architecture (NXOP ↔ KPaaS)

**Account Structure**:
```
AWS Organization
├── NXOP Account (123456789012)
│   ├── MSK Clusters (us-east-1, us-west-2)
│   ├── DocumentDB Global Cluster
│   ├── S3 Buckets (Multi-Region Access Points)
│   ├── Route53 Hosted Zone (kafka.nxop.com)
│   └── NLB (MSK bootstrap)
│
└── KPaaS Account (987654321098)
    ├── EKS Clusters (us-east-1, us-west-2)
    ├── NXOP Microservices (20+ services)
    ├── Pod Identity IAM Roles
    └── Transit Gateway (cross-account peering)
```

**Cross-Account Access Pattern**:
```
EKS Pod (KPaaS Account)
  ↓ [Pod Identity]
IAM Role: nxop-service-role (KPaaS Account)
  ↓ [AssumeRole]
IAM Role: nxop-cross-account-role (NXOP Account)
  ↓ [IAM Policy]
MSK/DocumentDB/S3 Resources (NXOP Account)
```

**IAM Role Chain Example**:
```json
// KPaaS Account - Pod Identity Role
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::123456789012:role/nxop-cross-account-role"
    }
  ]
}

// NXOP Account - Cross-Account Role
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kafka:DescribeCluster",
        "kafka:GetBootstrapBrokers",
        "kafka-cluster:Connect",
        "kafka-cluster:DescribeTopic",
        "kafka-cluster:ReadData",
        "kafka-cluster:WriteData"
      ],
      "Resource": [
        "arn:aws:kafka:us-east-1:123456789012:cluster/nxop-prod-msk-use1/*",
        "arn:aws:kafka:us-west-2:123456789012:cluster/nxop-prod-msk-usw2/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBClusters",
        "rds:DescribeDBInstances",
        "rds:Connect"
      ],
      "Resource": "arn:aws:rds:*:123456789012:cluster:nxop-prod-docdb-global"
    }
  ]
}
```


### Network Architecture

#### MSK Bootstrap Flow (Route53 + NLB)

**Problem**: EKS pods in KPaaS account need to discover MSK brokers in NXOP account across regions.

**Solution**: DNS-based bootstrap with NLB fronting MSK brokers.

**Architecture**:
```
EKS Pod (KPaaS Account)
  ↓ [DNS Query: kafka.nxop.com]
Route53 (NXOP Account)
  ↓ [Geolocation Routing Policy]
  ├── us-east-1: kafka-use1.nxop.com → NLB (10.100.48.10)
  └── us-west-2: kafka-usw2.nxop.com → NLB (10.101.48.10)
  ↓ [NLB Target Group]
MSK Brokers (NXOP Account)
  ├── Broker 1: 10.100.48.20:9094 (AZ1)
  ├── Broker 2: 10.100.48.21:9094 (AZ1)
  ├── Broker 3: 10.100.64.20:9094 (AZ2)
  ├── Broker 4: 10.100.64.21:9094 (AZ2)
  ├── Broker 5: 10.100.80.20:9094 (AZ3)
  └── Broker 6: 10.100.80.21:9094 (AZ3)
```

**Bootstrap Sequence**:
1. **Initial Connection**: EKS pod resolves `kafka.nxop.com` via Route53
2. **Geolocation Routing**: Route53 returns regional NLB endpoint based on pod location
3. **NLB Connection**: Pod connects to NLB on port 9094 (TLS)
4. **Broker Discovery**: MSK returns list of all broker endpoints
5. **Direct Connection**: Pod establishes direct connections to broker IPs
6. **Partition Assignment**: Kafka client assigns partitions to pod (consumer group)

**Route53 Configuration**:
```json
{
  "Name": "kafka.nxop.com",
  "Type": "A",
  "SetIdentifier": "us-east-1",
  "GeoLocation": {
    "ContinentCode": "NA",
    "CountryCode": "US",
    "SubdivisionCode": "VA"
  },
  "AliasTarget": {
    "HostedZoneId": "Z35SXDOTRQ7X7K",
    "DNSName": "kafka-use1-nlb-abc123.elb.us-east-1.amazonaws.com",
    "EvaluateTargetHealth": true
  }
}
```

**NLB Target Group Configuration**:
```json
{
  "Protocol": "TCP",
  "Port": 9094,
  "TargetType": "ip",
  "HealthCheckProtocol": "TCP",
  "HealthCheckPort": "9094",
  "HealthCheckIntervalSeconds": 10,
  "HealthyThresholdCount": 2,
  "UnhealthyThresholdCount": 2,
  "Targets": [
    {"Id": "10.100.48.20", "Port": 9094},
    {"Id": "10.100.48.21", "Port": 9094},
    {"Id": "10.100.64.20", "Port": 9094},
    {"Id": "10.100.64.21", "Port": 9094},
    {"Id": "10.100.80.20", "Port": 9094},
    {"Id": "10.100.80.21", "Port": 9094}
  ]
}
```


#### Transit Gateway Architecture

**Purpose**: Enable private connectivity between KPaaS VPC (EKS) and NXOP VPC (MSK/DocumentDB).

**Configuration**:
```
Transit Gateway: tgw-nxop-kpaas
├── Attachments:
│   ├── KPaaS VPC (us-east-1): 10.200.0.0/16
│   ├── NXOP VPC (us-east-1): 10.100.0.0/16
│   ├── KPaaS VPC (us-west-2): 10.201.0.0/16
│   └── NXOP VPC (us-west-2): 10.101.0.0/16
├── Route Tables:
│   ├── KPaaS Route Table:
│   │   ├── 10.100.0.0/16 → NXOP VPC (us-east-1)
│   │   └── 10.101.0.0/16 → NXOP VPC (us-west-2)
│   └── NXOP Route Table:
│       ├── 10.200.0.0/16 → KPaaS VPC (us-east-1)
│       └── 10.201.0.0/16 → KPaaS VPC (us-west-2)
└── Cross-Region Peering: Enabled (us-east-1 ↔ us-west-2)
```

**VPC Route Table Updates**:
```
KPaaS VPC (us-east-1) - Private Subnet Route Table:
├── 10.200.0.0/16 → local
├── 10.100.0.0/16 → tgw-nxop-kpaas (NXOP VPC us-east-1)
├── 10.101.0.0/16 → tgw-nxop-kpaas (NXOP VPC us-west-2)
└── 0.0.0.0/0 → nat-gateway

NXOP VPC (us-east-1) - Private Subnet Route Table:
├── 10.100.0.0/16 → local
├── 10.200.0.0/16 → tgw-nxop-kpaas (KPaaS VPC us-east-1)
├── 10.201.0.0/16 → tgw-nxop-kpaas (KPaaS VPC us-west-2)
└── 0.0.0.0/0 → nat-gateway
```

**Security Group Configuration**:
```
MSK Security Group (NXOP Account):
├── Inbound Rules:
│   ├── TCP 9094 from KPaaS VPC CIDR (10.200.0.0/16, 10.201.0.0/16)
│   └── TCP 2181 from KPaaS VPC CIDR (ZooKeeper - deprecated)
└── Outbound Rules:
    └── All traffic to 0.0.0.0/0

DocumentDB Security Group (NXOP Account):
├── Inbound Rules:
│   └── TCP 27017 from KPaaS VPC CIDR (10.200.0.0/16, 10.201.0.0/16)
└── Outbound Rules:
    └── All traffic to 0.0.0.0/0

EKS Pod Security Group (KPaaS Account):
├── Inbound Rules:
│   └── All traffic from EKS cluster security group
└── Outbound Rules:
    ├── TCP 9094 to NXOP VPC CIDR (10.100.0.0/16, 10.101.0.0/16) - MSK
    ├── TCP 27017 to NXOP VPC CIDR (10.100.0.0/16, 10.101.0.0/16) - DocumentDB
    └── TCP 443 to 0.0.0.0/0 - External APIs
```


---

## MSK Infrastructure Analysis

### Cluster Architecture

#### Broker Configuration

**Instance Specifications**:
```
Instance Type: kafka.m5.2xlarge
├── vCPUs: 8
├── Memory: 32 GiB
├── Network: Up to 10 Gbps
├── EBS Bandwidth: Up to 4,750 Mbps
└── Storage: 1 TB EBS gp3 per broker
    ├── IOPS: 3,000 (baseline)
    ├── Throughput: 125 MB/s (baseline)
    └── Provisioned IOPS: 16,000 (max)
```

**Broker Placement**:
```
us-east-1 (6 brokers):
├── AZ1 (us-east-1a): Broker 1, Broker 2
├── AZ2 (us-east-1b): Broker 3, Broker 4
└── AZ3 (us-east-1c): Broker 5, Broker 6

us-west-2 (6 brokers):
├── AZ1 (us-west-2a): Broker 1, Broker 2
├── AZ2 (us-west-2b): Broker 3, Broker 4
└── AZ3 (us-west-2c): Broker 5, Broker 6
```

**Replication Strategy**:
```
Topic Configuration:
├── Replication Factor: 3
├── Min In-Sync Replicas: 2
├── Partitions: 12 (per topic)
└── Partition Distribution:
    ├── Each broker hosts 6 partitions (leader or replica)
    ├── Leader partitions evenly distributed across brokers
    └── Replica partitions placed in different AZs
```

#### Topic Architecture

**Topic Naming Convention**:
```
{environment}.{domain}.{entity}.{version}
Example: prod.flight.events.v1
```

**Key Topics**:
```
1. prod.flight.events.v1
   ├── Partitions: 12
   ├── Replication Factor: 3
   ├── Retention: 7 days
   ├── Producers: Flight Data Adapter, Aircraft Data Adapter
   ├── Consumers: MQ-Kafka adapter, Kafka Connector (Azure)
   └── Message Rate: 1,000-2,000 msg/min

2. prod.flight.plans.v1
   ├── Partitions: 12
   ├── Replication Factor: 3
   ├── Retention: 7 days
   ├── Producers: Flight Plan Processor
   ├── Consumers: MQ-Kafka adapter, FXIP processors
   └── Message Rate: 500-1,000 msg/min

3. prod.audit.logs.v1
   ├── Partitions: 12
   ├── Replication Factor: 3
   ├── Retention: 7 days
   ├── Producers: FXIP Audit Log Processor
   ├── Consumers: Kafka Connector (Azure)
   └── Message Rate: 2,000-3,000 msg/min

4. prod.position.reports.v1
   ├── Partitions: 12
   ├── Replication Factor: 3
   ├── Retention: 7 days
   ├── Producers: MQ-Kafka adapter (On-Prem)
   ├── Consumers: Aircraft Data Adapter
   └── Message Rate: 100-500 msg/min

5. prod.signature.events.v1
   ├── Partitions: 12
   ├── Replication Factor: 3
   ├── Retention: 7 days
   ├── Producers: Flightkeys Event Processor, Flight Data Adapter
   ├── Consumers: MQ-Kafka adapter (On-Prem)
   └── Message Rate: 50-200 msg/min

6. prod.fusion.movements.v1
   ├── Partitions: 12
   ├── Replication Factor: 3
   ├── Retention: 7 days
   ├── Producers: Fusion Flight Movement Adapter
   ├── Consumers: MQ-Kafka adapter (On-Prem)
   └── Message Rate: 200-800 msg/min
```


#### Cross-Region Replication

**MSK Replicator Configuration**:
```
Replicator: nxop-prod-msk-replicator
├── Source Cluster: nxop-prod-msk-use1 (us-east-1)
├── Target Cluster: nxop-prod-msk-usw2 (us-west-2)
├── Direction: Bidirectional
├── Topics: All topics matching pattern "prod.*"
├── Replication Factor: Preserved (3)
├── Consumer Group Replication: Enabled
└── Offset Translation: Enabled

Replication Metrics:
├── Lag Target: < 30 seconds
├── Typical Lag: 5-15 seconds (P95)
├── Throughput: 50-100 MB/s
└── Latency: 200-500 ms (cross-region network)
```

**Replication Flow**:
```
Producer (us-east-1)
  ↓ [Write to MSK us-east-1]
MSK Broker (us-east-1)
  ↓ [MSK Replicator]
MSK Broker (us-west-2)
  ↓ [Consumer reads from us-west-2]
Consumer (us-west-2)

Bidirectional:
Producer (us-west-2) → MSK (us-west-2) → MSK (us-east-1) → Consumer (us-east-1)
```

**Replication Lag Monitoring**:
```
CloudWatch Metrics:
├── ReplicationLatency: Time between source write and target availability
├── ReplicationThroughput: Bytes/sec replicated
├── ReplicationLag: Number of messages behind
└── ReplicationErrors: Failed replication attempts

Alarms:
├── ReplicationLatency > 60 seconds → Critical
├── ReplicationLag > 10,000 messages → Warning
└── ReplicationErrors > 0 → Critical
```

#### Producer Configuration

**Java Producer Example** (Flight Data Adapter):
```java
Properties props = new Properties();
props.put("bootstrap.servers", "kafka.nxop.com:9094");
props.put("security.protocol", "SSL");
props.put("ssl.truststore.location", "/etc/kafka/truststore.jks");
props.put("ssl.truststore.password", System.getenv("TRUSTSTORE_PASSWORD"));

// Performance tuning
props.put("acks", "all"); // Wait for all in-sync replicas
props.put("retries", 3);
props.put("max.in.flight.requests.per.connection", 5);
props.put("enable.idempotence", true); // Exactly-once semantics

// Batching for throughput
props.put("batch.size", 16384); // 16 KB
props.put("linger.ms", 10); // Wait 10ms for batching
props.put("compression.type", "snappy");

// Serialization
props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
props.put("value.serializer", "org.apache.kafka.common.serialization.ByteArraySerializer");

KafkaProducer<String, byte[]> producer = new KafkaProducer<>(props);

// Send with callback
ProducerRecord<String, byte[]> record = new ProducerRecord<>(
    "prod.flight.events.v1",
    flightNumber, // Key for partitioning
    eventData
);

producer.send(record, (metadata, exception) -> {
    if (exception != null) {
        logger.error("Failed to send message", exception);
        // Retry logic or dead-letter queue
    } else {
        logger.info("Message sent to partition {} offset {}", 
            metadata.partition(), metadata.offset());
    }
});
```


#### Consumer Configuration

**Java Consumer Example** (Aircraft Data Adapter):
```java
Properties props = new Properties();
props.put("bootstrap.servers", "kafka.nxop.com:9094");
props.put("security.protocol", "SSL");
props.put("ssl.truststore.location", "/etc/kafka/truststore.jks");
props.put("ssl.truststore.password", System.getenv("TRUSTSTORE_PASSWORD"));

// Consumer group configuration
props.put("group.id", "aircraft-data-adapter-group");
props.put("enable.auto.commit", false); // Manual commit for reliability
props.put("auto.offset.reset", "earliest"); // Start from beginning if no offset

// Performance tuning
props.put("fetch.min.bytes", 1024); // 1 KB minimum fetch
props.put("fetch.max.wait.ms", 500); // Wait up to 500ms for fetch.min.bytes
props.put("max.poll.records", 500); // Process 500 records per poll
props.put("max.poll.interval.ms", 300000); // 5 minutes max processing time

// Deserialization
props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("value.deserializer", "org.apache.kafka.common.serialization.ByteArrayDeserializer");

KafkaConsumer<String, byte[]> consumer = new KafkaConsumer<>(props);
consumer.subscribe(Arrays.asList("prod.flight.events.v1"));

while (true) {
    ConsumerRecords<String, byte[]> records = consumer.poll(Duration.ofMillis(100));
    
    for (ConsumerRecord<String, byte[]> record : records) {
        try {
            // Process message
            processFlightEvent(record.key(), record.value());
            
            // Manual commit after successful processing
            consumer.commitSync(Collections.singletonMap(
                new TopicPartition(record.topic(), record.partition()),
                new OffsetAndMetadata(record.offset() + 1)
            ));
        } catch (Exception e) {
            logger.error("Failed to process message", e);
            // Send to dead-letter queue or retry
        }
    }
}
```

**Consumer Group Rebalancing**:
```
Scenario: New consumer joins group

Initial State:
├── Consumer 1: Partitions 0-5
└── Consumer 2: Partitions 6-11

Consumer 3 Joins:
├── Rebalance Triggered
├── Partitions Reassigned:
│   ├── Consumer 1: Partitions 0-3
│   ├── Consumer 2: Partitions 4-7
│   └── Consumer 3: Partitions 8-11
└── Consumers Resume from Last Committed Offset

Rebalance Duration: 5-10 seconds
Impact: Brief processing pause during rebalance
```

#### Partition Strategy

**Partitioning by Flight Number**:
```java
// Custom partitioner for flight events
public class FlightNumberPartitioner implements Partitioner {
    @Override
    public int partition(String topic, Object key, byte[] keyBytes,
                        Object value, byte[] valueBytes, Cluster cluster) {
        String flightNumber = (String) key;
        int numPartitions = cluster.partitionCountForTopic(topic);
        
        // Hash flight number to partition
        // Ensures all events for same flight go to same partition (ordering)
        return Math.abs(flightNumber.hashCode()) % numPartitions;
    }
}

// Usage
props.put("partitioner.class", "com.aa.nxop.FlightNumberPartitioner");
```

**Partition Distribution Example**:
```
Topic: prod.flight.events.v1 (12 partitions)

Flight AA100 → Partition 3
Flight AA200 → Partition 7
Flight AA300 → Partition 11
Flight AA400 → Partition 2

Benefits:
├── Ordering: All events for AA100 processed in order
├── Parallelism: Different flights processed concurrently
└── Load Balancing: Hash function distributes flights evenly
```


#### Performance Characteristics

**Throughput Metrics**:
```
Peak Throughput (per cluster):
├── Messages/sec: 5,000 msg/s
├── Bytes/sec: 250 MB/s (avg 50 KB/msg)
├── Partitions: 72 total (6 topics × 12 partitions)
└── Brokers: 6 (load distributed)

Per-Broker Load:
├── Messages/sec: ~833 msg/s
├── Bytes/sec: ~42 MB/s
├── CPU Utilization: 30-50%
├── Network Utilization: 20-40%
└── Disk I/O: 15-30% (gp3 baseline)

Latency Metrics:
├── Producer Latency (P95): 50-100 ms
├── Consumer Latency (P95): 100-200 ms
├── End-to-End Latency (P95): 200-500 ms
└── Cross-Region Replication Lag (P95): 5-15 seconds
```

**Capacity Planning**:
```
Current Utilization:
├── Storage: 200 GB / 6 TB (3.3%)
├── Throughput: 250 MB/s / 600 MB/s (42%)
├── Messages: 5,000 msg/s / 50,000 msg/s (10%)
└── Headroom: 90% capacity available

Growth Projections (12 months):
├── Message Volume: +50% (7,500 msg/s)
├── Storage: +100% (400 GB)
├── Throughput: +50% (375 MB/s)
└── Action: No scaling required (within capacity)

Scaling Triggers:
├── Storage > 80% → Add broker storage
├── Throughput > 70% → Add brokers or upgrade instance type
├── CPU > 70% → Upgrade instance type
└── Partition Count > 1,000 → Review topic design
```

---

## DocumentDB Architecture

### Global Cluster Configuration

#### Cluster Topology

**Global Cluster Structure**:
```
DocumentDB Global Cluster: nxop-prod-docdb-global
├── Primary Region: us-east-1
│   ├── Primary Instance: nxop-prod-docdb-use1-primary
│   │   ├── Instance Type: db.r6g.2xlarge
│   │   ├── vCPUs: 8
│   │   ├── Memory: 64 GiB
│   │   └── Role: Read/Write
│   ├── Read Replica 1: nxop-prod-docdb-use1-replica-1
│   │   ├── Instance Type: db.r6g.2xlarge
│   │   └── Role: Read-only
│   └── Read Replica 2: nxop-prod-docdb-use1-replica-2
│       ├── Instance Type: db.r6g.2xlarge
│       └── Role: Read-only
│
└── Secondary Region: us-west-2
    ├── Read Replica 1: nxop-prod-docdb-usw2-replica-1
    │   ├── Instance Type: db.r6g.2xlarge
    │   └── Role: Read-only (can be promoted to primary)
    ├── Read Replica 2: nxop-prod-docdb-usw2-replica-2
    │   ├── Instance Type: db.r6g.2xlarge
    │   └── Role: Read-only
    └── Read Replica 3: nxop-prod-docdb-usw2-replica-3
        ├── Instance Type: db.r6g.2xlarge
        └── Role: Read-only
```

**Replication Mechanism**:
```
Primary Instance (us-east-1)
  ↓ [Write Operation]
Storage Layer (Replicated across 3 AZs)
  ↓ [Asynchronous Replication]
Read Replicas (us-east-1)
  ↓ [Cross-Region Replication]
Read Replicas (us-west-2)

Replication Lag:
├── Within Region: < 100 ms (P95)
├── Cross-Region: < 1 second (P95)
└── Typical: 200-500 ms
```


#### Database Schema Design

**Database Structure**:
```
Database: nxop_prod
├── Collections:
│   ├── aircraft_configurations (Reference Data)
│   ├── flight_plans (Operational Data)
│   ├── crew_credentials (Authorization Data)
│   ├── position_reports (Tracking Data)
│   ├── signature_audit (Compliance Data)
│   └── briefing_metadata (Document Assembly)
└── Indexes: 45 total across all collections
```

**Collection: aircraft_configurations**:
```javascript
{
  "_id": ObjectId("..."),
  "tail_number": "N12345",
  "aircraft_type": "737-800",
  "configuration": {
    "seats": 160,
    "fuel_capacity": 6875,
    "max_takeoff_weight": 174200,
    "engines": "CFM56-7B27"
  },
  "fuel_bias": {
    "climb": 1.02,
    "cruise": 0.98,
    "descent": 1.01
  },
  "last_updated": ISODate("2026-01-28T10:00:00Z"),
  "version": 3
}

Indexes:
├── tail_number (unique)
├── aircraft_type
└── last_updated
```

**Collection: flight_plans**:
```javascript
{
  "_id": ObjectId("..."),
  "flight_number": "AA100",
  "departure_time": ISODate("2026-01-28T14:30:00Z"),
  "origin": "DFW",
  "destination": "LAX",
  "tail_number": "N12345",
  "route": {
    "waypoints": [...],
    "distance": 1235,
    "flight_time": 180
  },
  "fuel": {
    "required": 12500,
    "contingency": 1250,
    "alternate": 2500,
    "total": 16250
  },
  "crew": {
    "captain": "EMP123456",
    "first_officer": "EMP789012"
  },
  "status": "ACTIVE",
  "created_at": ISODate("2026-01-28T10:00:00Z"),
  "updated_at": ISODate("2026-01-28T12:00:00Z")
}

Indexes:
├── flight_number + departure_time (compound, unique)
├── tail_number + departure_time (compound)
├── status
└── created_at
```

**Collection: signature_audit**:
```javascript
{
  "_id": ObjectId("..."),
  "flight_number": "AA100",
  "departure_time": ISODate("2026-01-28T14:30:00Z"),
  "signature_type": "FLIGHT_RELEASE",
  "signer": {
    "employee_id": "EMP123456",
    "name": "John Smith",
    "role": "CAPTAIN"
  },
  "signature_data": {
    "method": "ACARS",
    "timestamp": ISODate("2026-01-28T13:45:00Z"),
    "ip_address": "10.100.48.50",
    "device": "ACARS_TERMINAL"
  },
  "validation": {
    "credentials_verified": true,
    "authorization_level": "CAPTAIN",
    "verification_timestamp": ISODate("2026-01-28T13:45:01Z")
  },
  "compliance": {
    "regulation": "FAR_121",
    "retention_period": 2555, // days
    "archived": false
  }
}

Indexes:
├── flight_number + departure_time (compound)
├── signer.employee_id
├── signature_data.timestamp
└── compliance.archived
```


#### Connection Management

**Connection Pool Configuration** (Java):
```java
MongoClientSettings settings = MongoClientSettings.builder()
    .applyConnectionString(new ConnectionString(
        "mongodb://nxop-prod-docdb-use1-primary.cluster-abc123.us-east-1.docdb.amazonaws.com:27017/" +
        "?tls=true&tlsCAFile=/etc/ssl/rds-combined-ca-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred"
    ))
    .applyToConnectionPoolSettings(builder -> builder
        .maxSize(100) // Max connections per instance
        .minSize(10)  // Min connections to maintain
        .maxWaitTime(30, TimeUnit.SECONDS)
        .maxConnectionIdleTime(60, TimeUnit.SECONDS)
        .maxConnectionLifeTime(1800, TimeUnit.SECONDS) // 30 minutes
    )
    .applyToSocketSettings(builder -> builder
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
    )
    .retryWrites(true)
    .retryReads(true)
    .build();

MongoClient mongoClient = MongoClients.create(settings);
```

**Read Preference Strategy**:
```
Application Read Patterns:

1. Flight Data Adapter (Flow 1):
   ├── Read Preference: secondaryPreferred
   ├── Rationale: Reference data reads, eventual consistency acceptable
   └── Fallback: Primary if no secondary available

2. Pilot Document Service (Flow 8):
   ├── Read Preference: primary
   ├── Rationale: Critical document assembly, strong consistency required
   └── Fallback: None (fail if primary unavailable)

3. Signature Validation (Flow 10):
   ├── Read Preference: primary
   ├── Rationale: Authorization check, must be current
   └── Write Concern: majority (wait for 2 of 3 replicas)

4. Position Report Enrichment (Flow 18):
   ├── Read Preference: secondaryPreferred
   ├── Rationale: High read volume, eventual consistency acceptable
   └── Fallback: Primary if no secondary available
```

**Write Concern Configuration**:
```java
// Critical writes (signatures, compliance)
MongoCollection<Document> signatureAudit = database
    .getCollection("signature_audit")
    .withWriteConcern(WriteConcern.MAJORITY); // Wait for majority ack

// Reference data updates (less critical)
MongoCollection<Document> aircraftConfig = database
    .getCollection("aircraft_configurations")
    .withWriteConcern(WriteConcern.W1); // Wait for primary ack only
```

#### Failover Mechanism

**Automatic Failover Sequence**:
```
1. Primary Instance Failure Detected
   ├── Health Check Failure: 3 consecutive failures (30 seconds)
   ├── DocumentDB Control Plane Notified
   └── Failover Decision: Promote read replica to primary

2. Replica Promotion (us-east-1)
   ├── Select Replica: Lowest replication lag
   ├── Promote to Primary: 30-60 seconds
   ├── DNS Update: nxop-prod-docdb-use1-primary → new primary IP
   └── DNS TTL: 30 seconds

3. Application Reconnection
   ├── Connection Pool Detects Failure
   ├── Retry Logic: 3 attempts with exponential backoff
   ├── DNS Resolution: New primary IP
   └── Connection Established: 10-30 seconds

Total Failover Time: 60-120 seconds (P95)
```

**Cross-Region Failover** (Manual):
```
Scenario: us-east-1 region failure

1. Detect Regional Failure
   ├── CloudWatch Alarms: All instances unreachable
   ├── Route53 Health Checks: Failed
   └── Manual Decision: Initiate cross-region failover

2. Promote us-west-2 Replica to Primary
   ├── AWS CLI Command:
   │   aws docdb promote-read-replica \
   │     --db-cluster-identifier nxop-prod-docdb-global \
   │     --target-region us-west-2
   ├── Promotion Time: 5-10 minutes
   └── New Primary: nxop-prod-docdb-usw2-replica-1

3. Update Application Configuration
   ├── Connection String Update:
   │   mongodb://nxop-prod-docdb-usw2-replica-1.cluster-def456.us-west-2.docdb.amazonaws.com:27017/
   ├── Deployment: Rolling update of EKS pods
   └── Verification: Connection tests

4. Replication Direction Reversal
   ├── New Primary: us-west-2
   ├── Replication Target: us-east-1 (when recovered)
   └── Monitoring: Replication lag

Total Cross-Region Failover Time: 10-15 minutes
```


---

## Integration Pattern Deep Dive

### Pattern 1: Asynchronous Ingestion → Synchronous Delivery

**Flows**: 3, 4, 6, 7, 14  
**Example**: Flow 7 - Flight Release Update Notifications

**Architecture**:
```
Flightkeys (AWS)
  ↓ [AMQP - RabbitMQ]
Notification Service (EKS - KPaaS)
  ├── [AMQP Consumer]
  ├── [Message Validation]
  ├── [Routing Logic]
  └── [Parallel Delivery]
      ├── Path A: FTM Uplink Proxy → AIRCOM → Aircraft (HTTPS → ACARS)
      ├── Path B: FlightInfo API → CCI (HTTPS)
      └── Path C: FlightInfo API → FOS (HTTPS)
```

**AMQP Consumer Implementation**:
```java
@Component
public class FlightkeyNotificationConsumer {
    
    @RabbitListener(queues = "flightkeys.notifications.queue")
    public void handleNotification(Message message) {
        try {
            // Parse AMQP message
            FlightReleaseNotification notification = 
                parseNotification(message.getBody());
            
            // Validate message
            if (!validateNotification(notification)) {
                sendToDeadLetterQueue(message);
                return;
            }
            
            // Parallel delivery to multiple destinations
            CompletableFuture<Void> acarsFuture = 
                deliverToACARS(notification);
            CompletableFuture<Void> cciFuture = 
                deliverToCCI(notification);
            CompletableFuture<Void> fosFuture = 
                deliverToFOS(notification);
            
            // Wait for all deliveries
            CompletableFuture.allOf(acarsFuture, cciFuture, fosFuture)
                .get(30, TimeUnit.SECONDS);
            
            // Acknowledge AMQP message
            channel.basicAck(message.getMessageProperties().getDeliveryTag(), false);
            
        } catch (Exception e) {
            logger.error("Failed to process notification", e);
            // Negative acknowledge - requeue message
            channel.basicNack(message.getMessageProperties().getDeliveryTag(), 
                false, true);
        }
    }
    
    private CompletableFuture<Void> deliverToACARS(FlightReleaseNotification notification) {
        return CompletableFuture.runAsync(() -> {
            // Call FTM Uplink Proxy
            HttpResponse response = httpClient.post()
                .uri("https://ftm-uplink-proxy.nxop.com/api/v1/acars/uplink")
                .header("Content-Type", "application/json")
                .body(BodyPublishers.ofString(toJson(notification)))
                .send();
            
            if (response.statusCode() != 200) {
                throw new DeliveryException("ACARS delivery failed");
            }
        });
    }
}
```

**AMQP Queue Configuration**:
```
Queue: flightkeys.notifications.queue
├── Durable: true
├── Auto-delete: false
├── Arguments:
│   ├── x-message-ttl: 3600000 (1 hour)
│   ├── x-max-length: 10000
│   ├── x-dead-letter-exchange: flightkeys.dlx
│   └── x-dead-letter-routing-key: notifications.failed
└── Bindings:
    ├── Exchange: flightkeys.notifications
    └── Routing Key: flight.release.#
```


### Pattern 2: Synchronous Ingestion → Asynchronous Distribution

**Flows**: 18, 19  
**Example**: Flow 18 - Position Reports to Flightkeys

**Architecture**:
```
FOS (On-Prem)
  ↓ [MQ - IBM MQ]
MQ-Kafka Adapter (On-Prem)
  ↓ [Kafka Producer - TLS]
MSK (NXOP Account)
  ↓ [Kafka Consumer]
Aircraft Data Adapter (EKS - KPaaS)
  ├── [DocumentDB Lookup - Reference Data]
  ├── [Data Enrichment]
  └── [HTTPS POST]
Flightkeys (AWS)
```

**MQ-Kafka Adapter Implementation**:
```java
@Component
public class MQKafkaAdapter {
    
    private final JmsTemplate jmsTemplate;
    private final KafkaTemplate<String, byte[]> kafkaTemplate;
    
    @JmsListener(destination = "FOS.POSITION.REPORTS")
    public void consumeFromMQ(Message message) {
        try {
            // Extract MQ message
            String messageBody = ((TextMessage) message).getText();
            PositionReport report = parsePositionReport(messageBody);
            
            // Transform to Kafka message
            ProducerRecord<String, byte[]> kafkaRecord = new ProducerRecord<>(
                "prod.position.reports.v1",
                report.getFlightNumber(), // Key for partitioning
                serializeToAvro(report)
            );
            
            // Send to Kafka with callback
            kafkaTemplate.send(kafkaRecord).addCallback(
                result -> {
                    logger.info("Position report sent to Kafka: {}", 
                        result.getRecordMetadata());
                    // Acknowledge MQ message
                    message.acknowledge();
                },
                ex -> {
                    logger.error("Failed to send to Kafka", ex);
                    // Do not acknowledge - message will be redelivered
                }
            );
            
        } catch (Exception e) {
            logger.error("Failed to process MQ message", e);
            throw new RuntimeException(e); // Trigger MQ redelivery
        }
    }
}
```

**Aircraft Data Adapter - Enrichment Logic**:
```java
@Component
public class AircraftDataAdapter {
    
    private final MongoTemplate mongoTemplate;
    private final RestTemplate restTemplate;
    
    @KafkaListener(topics = "prod.position.reports.v1", 
                   groupId = "aircraft-data-adapter-group")
    public void processPositionReport(ConsumerRecord<String, byte[]> record) {
        try {
            // Deserialize Kafka message
            PositionReport report = deserializeFromAvro(record.value());
            
            // Enrich with reference data from DocumentDB
            AircraftConfiguration config = mongoTemplate.findOne(
                Query.query(Criteria.where("tail_number").is(report.getTailNumber())),
                AircraftConfiguration.class
            );
            
            RouteInformation route = mongoTemplate.findOne(
                Query.query(Criteria.where("origin").is(report.getOrigin())
                    .and("destination").is(report.getDestination())),
                RouteInformation.class
            );
            
            // Create enriched position report
            EnrichedPositionReport enriched = EnrichedPositionReport.builder()
                .flightNumber(report.getFlightNumber())
                .position(report.getPosition())
                .altitude(report.getAltitude())
                .speed(report.getSpeed())
                .aircraftType(config.getAircraftType())
                .fuelRemaining(report.getFuelRemaining())
                .estimatedArrival(calculateETA(report, route))
                .build();
            
            // Send to Flightkeys via HTTPS
            HttpEntity<EnrichedPositionReport> request = 
                new HttpEntity<>(enriched, createHeaders());
            
            ResponseEntity<String> response = restTemplate.postForEntity(
                "https://api.flightkeys.com/v1/position-reports",
                request,
                String.class
            );
            
            if (response.getStatusCode().is2xxSuccessful()) {
                logger.info("Position report delivered to Flightkeys");
            } else {
                throw new DeliveryException("Flightkeys returned " + 
                    response.getStatusCode());
            }
            
        } catch (Exception e) {
            logger.error("Failed to process position report", e);
            // Send to dead-letter topic for manual review
            sendToDeadLetterTopic(record);
        }
    }
}
```


### Pattern 3: Document Assembly (Multi-Service Orchestration)

**Flow**: 8 - Retrieve Pilot Briefing Package  
**Complexity**: High - Orchestrates 3 services with parallel data retrieval

**Architecture**:
```
Flightkeys (AWS)
  ↓ [HTTPS GET Request]
Akamai GTM
  ↓ [Route to nearest region]
Flightkeys Integration Service (EKS - KPaaS)
  ├── [Orchestration Logic]
  ├── Parallel Calls:
  │   ├── Flight Plan Service → DocumentDB (flight metadata)
  │   ├── Pilot Document Service → DocumentDB + S3 (documents)
  │   └── Weather Service → External API (weather data)
  ├── [Document Assembly]
  └── [Response Generation]
  ↓ [HTTPS Response]
Flightkeys (AWS)
  ↓ [Distribution]
  ├── FOS Business Resumption (On-Prem)
  └── CCI (Azure FXIP)
```

**Orchestration Implementation**:
```java
@RestController
@RequestMapping("/api/v1/briefing")
public class BriefingPackageController {
    
    private final FlightPlanService flightPlanService;
    private final PilotDocumentService pilotDocumentService;
    private final WeatherService weatherService;
    
    @GetMapping("/{flightNumber}/{departureTime}")
    public ResponseEntity<BriefingPackage> getBriefingPackage(
            @PathVariable String flightNumber,
            @PathVariable String departureTime) {
        
        try {
            // Parse departure time
            Instant departure = Instant.parse(departureTime);
            
            // Parallel data retrieval
            CompletableFuture<FlightPlan> flightPlanFuture = 
                CompletableFuture.supplyAsync(() -> 
                    flightPlanService.getFlightPlan(flightNumber, departure));
            
            CompletableFuture<List<Document>> documentsFuture = 
                CompletableFuture.supplyAsync(() -> 
                    pilotDocumentService.getDocuments(flightNumber, departure));
            
            CompletableFuture<WeatherData> weatherFuture = 
                CompletableFuture.supplyAsync(() -> 
                    weatherService.getWeather(flightNumber, departure));
            
            // Wait for all futures with timeout
            CompletableFuture.allOf(flightPlanFuture, documentsFuture, weatherFuture)
                .get(10, TimeUnit.SECONDS);
            
            // Retrieve results
            FlightPlan flightPlan = flightPlanFuture.get();
            List<Document> documents = documentsFuture.get();
            WeatherData weather = weatherFuture.get();
            
            // Assemble briefing package
            BriefingPackage briefing = BriefingPackage.builder()
                .flightNumber(flightNumber)
                .departureTime(departure)
                .flightPlan(flightPlan)
                .documents(documents)
                .weather(weather)
                .generatedAt(Instant.now())
                .build();
            
            // Cache for 5 minutes
            cacheService.put(getCacheKey(flightNumber, departure), briefing, 
                Duration.ofMinutes(5));
            
            return ResponseEntity.ok()
                .cacheControl(CacheControl.maxAge(5, TimeUnit.MINUTES))
                .body(briefing);
            
        } catch (TimeoutException e) {
            logger.error("Timeout assembling briefing package", e);
            return ResponseEntity.status(HttpStatus.GATEWAY_TIMEOUT)
                .body(null);
        } catch (Exception e) {
            logger.error("Failed to assemble briefing package", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(null);
        }
    }
}
```

**Flight Plan Service - DocumentDB Query**:
```java
@Service
public class FlightPlanService {
    
    private final MongoTemplate mongoTemplate;
    
    public FlightPlan getFlightPlan(String flightNumber, Instant departureTime) {
        // Query DocumentDB with compound index
        Query query = Query.query(
            Criteria.where("flight_number").is(flightNumber)
                .and("departure_time").is(departureTime)
        );
        
        FlightPlan plan = mongoTemplate.findOne(query, FlightPlan.class);
        
        if (plan == null) {
            throw new FlightPlanNotFoundException(
                "Flight plan not found: " + flightNumber);
        }
        
        return plan;
    }
}
```

**Pilot Document Service - S3 Retrieval**:
```java
@Service
public class PilotDocumentService {
    
    private final MongoTemplate mongoTemplate;
    private final S3Client s3Client;
    
    public List<Document> getDocuments(String flightNumber, Instant departureTime) {
        // Query DocumentDB for document metadata
        Query query = Query.query(
            Criteria.where("flight_number").is(flightNumber)
                .and("departure_time").is(departureTime)
        );
        
        List<DocumentMetadata> metadata = 
            mongoTemplate.find(query, DocumentMetadata.class);
        
        // Parallel S3 retrieval
        return metadata.parallelStream()
            .map(meta -> retrieveFromS3(meta))
            .collect(Collectors.toList());
    }
    
    private Document retrieveFromS3(DocumentMetadata metadata) {
        GetObjectRequest request = GetObjectRequest.builder()
            .bucket("nxop-pilot-documents")
            .key(metadata.getS3Key())
            .build();
        
        ResponseBytes<GetObjectResponse> response = 
            s3Client.getObjectAsBytes(request);
        
        return Document.builder()
            .type(metadata.getType())
            .name(metadata.getName())
            .content(response.asByteArray())
            .build();
    }
}
```


---

## Protocol Analysis

### AMQP (Advanced Message Queuing Protocol)

**Usage**: 15 flows (60%) - Primary protocol for Flightkeys integration

**Connection Configuration**:
```java
ConnectionFactory factory = new ConnectionFactory();
factory.setHost("amqp.flightkeys.com");
factory.setPort(5671); // TLS
factory.setUsername(System.getenv("AMQP_USERNAME"));
factory.setPassword(System.getenv("AMQP_PASSWORD"));
factory.setVirtualHost("/nxop");

// TLS Configuration
factory.useSslProtocol("TLSv1.3");
factory.setSslContext(createSSLContext());

// Connection pooling
factory.setConnectionTimeout(30000); // 30 seconds
factory.setRequestedHeartbeat(60); // 60 seconds
factory.setAutomaticRecoveryEnabled(true);
factory.setNetworkRecoveryInterval(10000); // 10 seconds

Connection connection = factory.newConnection();
Channel channel = connection.createChannel();
```

**Message Format** (Flight Release Notification):
```json
{
  "message_id": "msg-12345-67890",
  "timestamp": "2026-01-28T14:30:00Z",
  "type": "FLIGHT_RELEASE_UPDATE",
  "version": "1.0",
  "payload": {
    "flight_number": "AA100",
    "departure_time": "2026-01-28T16:00:00Z",
    "origin": "DFW",
    "destination": "LAX",
    "release_status": "APPROVED",
    "dispatcher": {
      "employee_id": "EMP123456",
      "name": "Jane Doe"
    },
    "fuel": {
      "required": 12500,
      "loaded": 13000
    },
    "notifications": {
      "acars": true,
      "cci": true,
      "fos": true
    }
  },
  "routing": {
    "exchange": "flightkeys.notifications",
    "routing_key": "flight.release.AA100"
  }
}
```

**Quality of Service (QoS)**:
```
Delivery Guarantee: At-least-once
├── Publisher Confirms: Enabled
├── Consumer Acknowledgments: Manual
├── Prefetch Count: 10 messages
└── Requeue on Failure: Yes (max 3 attempts)

Durability:
├── Queue: Durable (survives broker restart)
├── Messages: Persistent (written to disk)
└── Exchange: Durable

Performance:
├── Throughput: 1,000-2,000 msg/s
├── Latency: 10-50 ms (P95)
└── Connection Pooling: 5 connections per service
```

### Kafka Protocol

**Usage**: 10 flows (40%) - Event streaming backbone

**Producer Configuration** (Detailed):
```properties
# Bootstrap and Security
bootstrap.servers=kafka.nxop.com:9094
security.protocol=SSL
ssl.truststore.location=/etc/kafka/truststore.jks
ssl.truststore.password=${TRUSTSTORE_PASSWORD}
ssl.keystore.location=/etc/kafka/keystore.jks
ssl.keystore.password=${KEYSTORE_PASSWORD}
ssl.key.password=${KEY_PASSWORD}
ssl.endpoint.identification.algorithm=https

# Reliability
acks=all
retries=2147483647
max.in.flight.requests.per.connection=5
enable.idempotence=true
transactional.id=flight-data-adapter-${POD_NAME}

# Performance
batch.size=16384
linger.ms=10
compression.type=snappy
buffer.memory=33554432

# Monitoring
metrics.recording.level=INFO
metric.reporters=io.confluent.metrics.reporter.ConfluentMetricsReporter
```

**Message Format** (Avro Schema):
```avro
{
  "type": "record",
  "name": "FlightEvent",
  "namespace": "com.aa.nxop.events",
  "fields": [
    {"name": "event_id", "type": "string"},
    {"name": "event_type", "type": "string"},
    {"name": "timestamp", "type": "long", "logicalType": "timestamp-millis"},
    {"name": "flight_number", "type": "string"},
    {"name": "departure_time", "type": "long", "logicalType": "timestamp-millis"},
    {"name": "tail_number", "type": ["null", "string"], "default": null},
    {"name": "origin", "type": "string"},
    {"name": "destination", "type": "string"},
    {"name": "event_data", "type": {
      "type": "map",
      "values": "string"
    }},
    {"name": "metadata", "type": {
      "type": "record",
      "name": "EventMetadata",
      "fields": [
        {"name": "source", "type": "string"},
        {"name": "version", "type": "string"},
        {"name": "correlation_id", "type": "string"}
      ]
    }}
  ]
}
```

**Serialization Example**:
```java
// Avro serialization
Schema schema = new Schema.Parser().parse(schemaString);
GenericRecord record = new GenericData.Record(schema);
record.put("event_id", UUID.randomUUID().toString());
record.put("event_type", "DEPARTURE");
record.put("timestamp", Instant.now().toEpochMilli());
record.put("flight_number", "AA100");
// ... set other fields

ByteArrayOutputStream out = new ByteArrayOutputStream();
DatumWriter<GenericRecord> writer = new GenericDatumWriter<>(schema);
Encoder encoder = EncoderFactory.get().binaryEncoder(out, null);
writer.write(record, encoder);
encoder.flush();

byte[] serialized = out.toByteArray();
```


### HTTPS/REST API

**Usage**: 21 flows (84%) - Primary synchronous communication protocol

**API Design Standards**:
```
Base URL: https://api.nxop.com/v1
├── Versioning: URI path (/v1, /v2)
├── Authentication: OAuth 2.0 + mTLS
├── Content-Type: application/json
├── Rate Limiting: 1000 req/min per client
└── Compression: gzip (Accept-Encoding: gzip)

Endpoint Patterns:
├── GET /flights/{flightNumber} - Retrieve flight
├── POST /flights - Create flight
├── PUT /flights/{flightNumber} - Update flight
├── DELETE /flights/{flightNumber} - Delete flight
└── POST /flights/{flightNumber}/actions/{action} - Execute action
```

**Request/Response Example** (Flight Release Notification):
```http
POST /api/v1/notifications/flight-release HTTP/1.1
Host: api.nxop.com
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
X-Correlation-ID: corr-12345-67890
X-Request-ID: req-98765-43210
Accept-Encoding: gzip

{
  "flight_number": "AA100",
  "departure_time": "2026-01-28T16:00:00Z",
  "notification_type": "FLIGHT_RELEASE",
  "destinations": ["ACARS", "CCI", "FOS"],
  "priority": "HIGH",
  "metadata": {
    "dispatcher_id": "EMP123456",
    "release_time": "2026-01-28T14:30:00Z"
  }
}
```

```http
HTTP/1.1 202 Accepted
Content-Type: application/json
X-Correlation-ID: corr-12345-67890
X-Request-ID: req-98765-43210
Location: /api/v1/notifications/notif-abc123

{
  "notification_id": "notif-abc123",
  "status": "PROCESSING",
  "created_at": "2026-01-28T14:30:01Z",
  "estimated_completion": "2026-01-28T14:30:05Z",
  "_links": {
    "self": "/api/v1/notifications/notif-abc123",
    "status": "/api/v1/notifications/notif-abc123/status"
  }
}
```

**Error Response Format**:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid flight number format",
    "details": [
      {
        "field": "flight_number",
        "issue": "Must match pattern [A-Z]{2}\\d{1,4}",
        "provided": "AA"
      }
    ],
    "request_id": "req-98765-43210",
    "timestamp": "2026-01-28T14:30:01Z"
  }
}
```

**Retry Strategy**:
```java
@Configuration
public class RestTemplateConfig {
    
    @Bean
    public RestTemplate restTemplate() {
        RestTemplate restTemplate = new RestTemplate();
        
        // Add retry interceptor
        restTemplate.setInterceptors(Collections.singletonList(
            new RetryInterceptor()
        ));
        
        // Configure timeouts
        HttpComponentsClientHttpRequestFactory factory = 
            new HttpComponentsClientHttpRequestFactory();
        factory.setConnectTimeout(10000); // 10 seconds
        factory.setReadTimeout(30000); // 30 seconds
        restTemplate.setRequestFactory(factory);
        
        return restTemplate;
    }
}

public class RetryInterceptor implements ClientHttpRequestInterceptor {
    
    private static final int MAX_RETRIES = 3;
    private static final long INITIAL_BACKOFF = 1000; // 1 second
    
    @Override
    public ClientHttpResponse intercept(HttpRequest request, byte[] body,
                                       ClientHttpRequestExecution execution) 
            throws IOException {
        
        int attempt = 0;
        while (attempt < MAX_RETRIES) {
            try {
                ClientHttpResponse response = execution.execute(request, body);
                
                // Retry on 5xx errors
                if (response.getStatusCode().is5xxServerError()) {
                    attempt++;
                    if (attempt < MAX_RETRIES) {
                        Thread.sleep(INITIAL_BACKOFF * (long) Math.pow(2, attempt));
                        continue;
                    }
                }
                
                return response;
                
            } catch (IOException | InterruptedException e) {
                attempt++;
                if (attempt >= MAX_RETRIES) {
                    throw new IOException("Max retries exceeded", e);
                }
                try {
                    Thread.sleep(INITIAL_BACKOFF * (long) Math.pow(2, attempt));
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    throw new IOException("Retry interrupted", ie);
                }
            }
        }
        
        throw new IOException("Max retries exceeded");
    }
}
```

### ACARS Protocol

**Usage**: 10 flows (40%) - Aircraft communication

**Message Format** (ACARS Uplink):
```
.DFW AA100 281430
FLIGHT RELEASE APPROVED
FUEL: 13000 LBS
DEPARTURE: 1600Z
DISPATCHER: J DOE
```

**ACARS Message Structure**:
```
Message Components:
├── Header:
│   ├── Station ID: .DFW (3-4 chars)
│   ├── Flight Number: AA100
│   └── Timestamp: 281430 (DDHHMM)
├── Body:
│   ├── Message Type: FLIGHT RELEASE
│   ├── Content: Free text or structured data
│   └── Max Length: 220 characters
└── Footer:
    └── Checksum: CRC-16

Delivery:
├── Protocol: VHF or SATCOM
├── Latency: 30-120 seconds
├── Reliability: At-most-once (no ack)
└── Retry: Application-level (3 attempts)
```

**AIRCOM Server Integration**:
```java
@Service
public class AcarsUplinkService {
    
    private final RestTemplate restTemplate;
    
    public void sendAcarsMessage(String flightNumber, String message) {
        // Format ACARS message
        String acarsMessage = formatAcarsMessage(flightNumber, message);
        
        // Send to AIRCOM Server
        AcarsRequest request = AcarsRequest.builder()
            .flightNumber(flightNumber)
            .message(acarsMessage)
            .priority("HIGH")
            .deliveryMethod("VHF_PRIMARY")
            .build();
        
        try {
            ResponseEntity<AcarsResponse> response = restTemplate.postForEntity(
                "https://aircom.aa.com/api/v1/acars/uplink",
                request,
                AcarsResponse.class
            );
            
            if (response.getStatusCode().is2xxSuccessful()) {
                logger.info("ACARS message sent: {}", response.getBody().getMessageId());
            } else {
                throw new AcarsDeliveryException("AIRCOM returned " + 
                    response.getStatusCode());
            }
            
        } catch (Exception e) {
            logger.error("Failed to send ACARS message", e);
            // Retry with SATCOM backup
            retrySatcom(request);
        }
    }
    
    private String formatAcarsMessage(String flightNumber, String message) {
        String timestamp = LocalDateTime.now()
            .format(DateTimeFormatter.ofPattern("ddHHmm"));
        
        return String.format(".DFW %s %s\n%s", 
            flightNumber, timestamp, message);
    }
}
```


---

## Security and Authentication

### OAuth 2.0 + mTLS Architecture

**Authentication Flow**:
```
Client Application
  ↓ [1. Request Access Token]
OAuth 2.0 Authorization Server (AWS Cognito)
  ├── [2. Validate Client Credentials]
  ├── [3. Verify mTLS Certificate]
  └── [4. Issue JWT Access Token]
  ↓ [5. Return Token]
Client Application
  ↓ [6. API Request + Token + Client Cert]
API Gateway (Akamai GTM)
  ├── [7. Verify JWT Signature]
  ├── [8. Verify mTLS Certificate]
  └── [9. Forward to Backend]
  ↓ [10. Authorized Request]
NXOP Service (EKS)
```

**JWT Token Structure**:
```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT",
    "kid": "key-12345"
  },
  "payload": {
    "iss": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_ABC123",
    "sub": "service-account-flight-data-adapter",
    "aud": "api.nxop.com",
    "exp": 1706454000,
    "iat": 1706450400,
    "scope": "flight:read flight:write position:read",
    "client_id": "flight-data-adapter",
    "custom:service": "flight-data-adapter",
    "custom:region": "us-east-1",
    "custom:environment": "production"
  },
  "signature": "..."
}
```

**mTLS Certificate Configuration**:
```
Client Certificate:
├── Subject: CN=flight-data-adapter.nxop.com, O=American Airlines, C=US
├── Issuer: CN=NXOP Internal CA, O=American Airlines, C=US
├── Validity: 365 days
├── Key Usage: Digital Signature, Key Encipherment
├── Extended Key Usage: TLS Web Client Authentication
└── SAN: DNS:flight-data-adapter.nxop.com, DNS:*.nxop.com

Certificate Chain:
├── Root CA: NXOP Root CA (offline, 10-year validity)
├── Intermediate CA: NXOP Internal CA (online, 5-year validity)
└── Client Certificate: Service-specific (1-year validity)
```

**API Gateway Validation**:
```java
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    
    private final JwtDecoder jwtDecoder;
    
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                   HttpServletResponse response,
                                   FilterChain filterChain) 
            throws ServletException, IOException {
        
        // Extract JWT from Authorization header
        String token = extractToken(request);
        if (token == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        try {
            // Decode and validate JWT
            Jwt jwt = jwtDecoder.decode(token);
            
            // Verify claims
            if (!jwt.getAudience().contains("api.nxop.com")) {
                throw new InvalidTokenException("Invalid audience");
            }
            
            if (jwt.getExpiresAt().isBefore(Instant.now())) {
                throw new InvalidTokenException("Token expired");
            }
            
            // Extract scopes
            List<String> scopes = jwt.getClaimAsStringList("scope");
            
            // Verify mTLS certificate
            X509Certificate clientCert = extractClientCertificate(request);
            if (clientCert == null) {
                throw new InvalidTokenException("Client certificate required");
            }
            
            // Verify certificate subject matches JWT subject
            String certSubject = clientCert.getSubjectDN().getName();
            String jwtSubject = jwt.getSubject();
            if (!certSubject.contains(jwtSubject)) {
                throw new InvalidTokenException("Certificate subject mismatch");
            }
            
            // Create authentication object
            Authentication auth = new JwtAuthentication(jwt, scopes);
            SecurityContextHolder.getContext().setAuthentication(auth);
            
            filterChain.doFilter(request, response);
            
        } catch (Exception e) {
            logger.error("Authentication failed", e);
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        }
    }
}
```

### IAM Roles and Policies

**EKS Pod Identity Role** (KPaaS Account):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "pods.eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "987654321098",
          "eks:cluster-name": "nxop-prod-use1"
        }
      }
    }
  ]
}
```

**Cross-Account Role** (NXOP Account):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "MSKAccess",
      "Effect": "Allow",
      "Action": [
        "kafka:DescribeCluster",
        "kafka:GetBootstrapBrokers",
        "kafka-cluster:Connect",
        "kafka-cluster:DescribeTopic",
        "kafka-cluster:ReadData",
        "kafka-cluster:WriteData"
      ],
      "Resource": [
        "arn:aws:kafka:us-east-1:123456789012:cluster/nxop-prod-msk-use1/*",
        "arn:aws:kafka:us-west-2:123456789012:cluster/nxop-prod-msk-usw2/*"
      ],
      "Condition": {
        "StringEquals": {
          "kafka-cluster:topic": [
            "prod.flight.events.v1",
            "prod.flight.plans.v1",
            "prod.position.reports.v1"
          ]
        }
      }
    },
    {
      "Sid": "DocumentDBAccess",
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBClusters",
        "rds:DescribeDBInstances",
        "rds:Connect"
      ],
      "Resource": "arn:aws:rds:*:123456789012:cluster:nxop-prod-docdb-global"
    },
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::nxop-pilot-documents/*"
    }
  ]
}
```

### Encryption

**Data in Transit**:
```
Protocol Encryption:
├── HTTPS: TLS 1.3 (minimum TLS 1.2)
├── Kafka: TLS 1.3 (port 9094)
├── DocumentDB: TLS 1.3 (port 27017)
├── AMQP: TLS 1.3 (port 5671)
└── MQ: TLS 1.2 (port 1414)

Cipher Suites (Preferred):
├── TLS_AES_256_GCM_SHA384
├── TLS_CHACHA20_POLY1305_SHA256
└── TLS_AES_128_GCM_SHA256
```

**Data at Rest**:
```
MSK:
├── EBS Encryption: AWS KMS (CMK)
├── Key: arn:aws:kms:us-east-1:123456789012:key/msk-encryption-key
└── Rotation: Automatic (365 days)

DocumentDB:
├── Storage Encryption: AWS KMS (CMK)
├── Key: arn:aws:kms:us-east-1:123456789012:key/docdb-encryption-key
└── Rotation: Automatic (365 days)

S3:
├── Encryption: SSE-KMS
├── Key: arn:aws:kms:us-east-1:123456789012:key/s3-encryption-key
└── Bucket Policy: Enforce encryption
```


---

## Performance and Optimization

### Throughput Analysis

**Peak Load Characteristics**:
```
Daily Peak Hours: 06:00-09:00 and 17:00-20:00 (local time)

Peak Metrics:
├── Total Messages: 5,000 msg/s
├── MSK Throughput: 250 MB/s
├── DocumentDB Queries: 10,000 IOPS (read)
├── DocumentDB Writes: 1,000 IOPS
├── API Requests: 15,000 req/min
└── ACARS Messages: 500 msg/min

Message Distribution:
├── Flight Events (Flow 1): 2,000 msg/s (40%)
├── Flight Plans (Flow 2): 1,000 msg/s (20%)
├── Audit Logs (Flow 5): 1,500 msg/s (30%)
└── Other Flows: 500 msg/s (10%)
```

**Latency Breakdown** (End-to-End):
```
Flow 1: FOS Events to Flightkeys
├── FOS → MQ: 10 ms
├── MQ → MQ-Kafka Adapter: 20 ms
├── Adapter → MSK: 50 ms (P95)
├── MSK → Aircraft Data Adapter: 100 ms (P95)
├── DocumentDB Lookup: 20 ms (P95)
├── Adapter → Flightkeys: 150 ms (P95)
└── Total: 350 ms (P95)

Flow 8: Pilot Briefing Package
├── Flightkeys → Akamai: 50 ms
├── Akamai → EKS: 20 ms
├── Parallel Data Retrieval:
│   ├── Flight Plan Service: 50 ms (P95)
│   ├── Pilot Document Service: 200 ms (P95) - S3 retrieval
│   └── Weather Service: 100 ms (P95)
├── Document Assembly: 50 ms
├── Response → Flightkeys: 50 ms
└── Total: 520 ms (P95)
```

### Caching Strategy

**Application-Level Caching**:
```java
@Configuration
@EnableCaching
public class CacheConfig {
    
    @Bean
    public CacheManager cacheManager() {
        RedisCacheManager cacheManager = RedisCacheManager.builder(
            redisConnectionFactory())
            .cacheDefaults(defaultCacheConfig())
            .withCacheConfiguration("aircraft-config", 
                aircraftConfigCacheConfig())
            .withCacheConfiguration("flight-plans", 
                flightPlanCacheConfig())
            .build();
        
        return cacheManager;
    }
    
    private RedisCacheConfiguration defaultCacheConfig() {
        return RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(5))
            .serializeValuesWith(RedisSerializationContext
                .SerializationPair.fromSerializer(
                    new GenericJackson2JsonRedisSerializer()));
    }
    
    private RedisCacheConfiguration aircraftConfigCacheConfig() {
        return RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofHours(24)) // Reference data changes infrequently
            .serializeValuesWith(RedisSerializationContext
                .SerializationPair.fromSerializer(
                    new GenericJackson2JsonRedisSerializer()));
    }
    
    private RedisCacheConfiguration flightPlanCacheConfig() {
        return RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(15)) // Flight plans change frequently
            .serializeValuesWith(RedisSerializationContext
                .SerializationPair.fromSerializer(
                    new GenericJackson2JsonRedisSerializer()));
    }
}

@Service
public class AircraftConfigService {
    
    @Cacheable(value = "aircraft-config", key = "#tailNumber")
    public AircraftConfiguration getConfiguration(String tailNumber) {
        // Query DocumentDB (cache miss)
        return mongoTemplate.findOne(
            Query.query(Criteria.where("tail_number").is(tailNumber)),
            AircraftConfiguration.class
        );
    }
    
    @CacheEvict(value = "aircraft-config", key = "#tailNumber")
    public void updateConfiguration(String tailNumber, 
                                   AircraftConfiguration config) {
        mongoTemplate.save(config);
    }
}
```

**Redis Cluster Configuration**:
```
Redis Cluster: nxop-prod-redis
├── Node Type: cache.r6g.xlarge
├── Nodes: 6 (3 primary, 3 replica)
├── Memory: 26 GiB per node
├── Replication: Automatic
├── Multi-AZ: Enabled
└── Encryption: In-transit and at-rest

Cache Hit Rates:
├── Aircraft Config: 95% (24-hour TTL)
├── Flight Plans: 70% (15-minute TTL)
├── Briefing Packages: 60% (5-minute TTL)
└── Overall: 80%

Performance Impact:
├── Cache Hit Latency: 5 ms (P95)
├── Cache Miss Latency: 50 ms (P95) - DocumentDB query
└── Latency Reduction: 90% for cached data
```

### Connection Pooling

**HikariCP Configuration** (DocumentDB):
```java
@Configuration
public class DocumentDBConfig {
    
    @Bean
    public MongoClient mongoClient() {
        MongoClientSettings settings = MongoClientSettings.builder()
            .applyConnectionString(new ConnectionString(connectionString))
            .applyToConnectionPoolSettings(builder -> builder
                .maxSize(100) // Max connections
                .minSize(10)  // Min connections
                .maxWaitTime(30, TimeUnit.SECONDS)
                .maxConnectionIdleTime(60, TimeUnit.SECONDS)
                .maxConnectionLifeTime(1800, TimeUnit.SECONDS)
                .maintenanceInitialDelay(0, TimeUnit.SECONDS)
                .maintenanceFrequency(60, TimeUnit.SECONDS)
            )
            .applyToSocketSettings(builder -> builder
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(30, TimeUnit.SECONDS)
            )
            .build();
        
        return MongoClients.create(settings);
    }
}
```

**Connection Pool Monitoring**:
```
Metrics:
├── Active Connections: 40-60 (peak)
├── Idle Connections: 10-20
├── Wait Time: < 100 ms (P95)
├── Connection Errors: < 0.1%
└── Pool Exhaustion Events: 0

Tuning:
├── Max Size: 100 (sufficient for peak load)
├── Min Size: 10 (warm pool for fast response)
├── Idle Timeout: 60 seconds (balance between reuse and resource usage)
└── Max Lifetime: 30 minutes (prevent stale connections)
```

### Auto-Scaling Configuration

**EKS Horizontal Pod Autoscaler**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: flight-data-adapter-hpa
  namespace: nxop-prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: flight-data-adapter
  minReplicas: 3
  maxReplicas: 12
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: kafka_consumer_lag
      target:
        type: AverageValue
        averageValue: "1000"
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 25
        periodSeconds: 60
      selectPolicy: Min
```

**Scaling Behavior**:
```
Normal Load (06:00-22:00):
├── Replicas: 6 pods
├── CPU: 40-50%
├── Memory: 50-60%
└── Kafka Lag: < 500 messages

Peak Load (07:00-09:00, 17:00-20:00):
├── Replicas: 9-12 pods (auto-scaled)
├── CPU: 60-70%
├── Memory: 70-80%
└── Kafka Lag: < 1,000 messages

Off-Peak (22:00-06:00):
├── Replicas: 3 pods (minimum)
├── CPU: 20-30%
├── Memory: 30-40%
└── Kafka Lag: < 100 messages

Scale-Up Trigger:
├── CPU > 70% for 60 seconds → Add 50% more pods (max 2 pods)
├── Memory > 80% for 60 seconds → Add 50% more pods
└── Kafka Lag > 1,000 messages → Add 2 pods

Scale-Down Trigger:
├── CPU < 50% for 300 seconds → Remove 25% of pods
├── Memory < 60% for 300 seconds → Remove 25% of pods
└── Kafka Lag < 100 messages → Remove 1 pod
```


---

## Monitoring and Observability

### CloudWatch Metrics

**MSK Metrics**:
```
Broker-Level Metrics:
├── BytesInPerSec: Incoming throughput (target: < 400 MB/s per broker)
├── BytesOutPerSec: Outgoing throughput (target: < 400 MB/s per broker)
├── MessagesInPerSec: Message rate (target: < 10,000 msg/s per broker)
├── CpuUser: CPU utilization (alarm: > 70%)
├── MemoryUsed: Memory usage (alarm: > 80%)
└── NetworkRxPackets/NetworkTxPackets: Network activity

Topic-Level Metrics:
├── BytesInPerSec: Per-topic throughput
├── MessagesInPerSec: Per-topic message rate
├── FetchConsumerTotalTimeMs: Consumer fetch latency
└── ProduceTotalTimeMs: Producer latency

Partition-Level Metrics:
├── UnderReplicatedPartitions: Replication health (alarm: > 0)
├── OfflinePartitionsCount: Partition availability (alarm: > 0)
└── ActiveControllerCount: Controller health (alarm: != 1)

Cross-Region Replication:
├── ReplicationLatency: Lag between regions (alarm: > 60 seconds)
├── ReplicationThroughput: Bytes/sec replicated
└── ReplicationLag: Messages behind (alarm: > 10,000)
```

**DocumentDB Metrics**:
```
Instance-Level Metrics:
├── CPUUtilization: Compute usage (alarm: > 80%)
├── DatabaseConnections: Active connections (alarm: > 90)
├── FreeableMemory: Available memory (alarm: < 20%)
├── ReadLatency: Query latency (alarm: > 100 ms)
├── WriteLatency: Write latency (alarm: > 100 ms)
└── NetworkThroughput: Network I/O

Cluster-Level Metrics:
├── VolumeBytesUsed: Storage usage
├── VolumeReadIOPs: Read IOPS
├── VolumeWriteIOPs: Write IOPS
└── ReplicationLag: Global cluster lag (alarm: > 5 seconds)

Query Performance:
├── DocumentsReturned: Query result size
├── DocumentsScanned: Index efficiency
└── OplogLag: Replication lag within cluster
```

**Application Metrics** (Custom):
```java
@Component
public class MetricsPublisher {
    
    private final CloudWatchAsyncClient cloudWatch;
    
    public void publishMessageProcessingMetrics(String flowName, 
                                               long processingTime,
                                               boolean success) {
        PutMetricDataRequest request = PutMetricDataRequest.builder()
            .namespace("NXOP/MessageFlows")
            .metricData(
                MetricDatum.builder()
                    .metricName("ProcessingTime")
                    .value((double) processingTime)
                    .unit(StandardUnit.MILLISECONDS)
                    .timestamp(Instant.now())
                    .dimensions(
                        Dimension.builder()
                            .name("FlowName")
                            .value(flowName)
                            .build(),
                        Dimension.builder()
                            .name("Success")
                            .value(String.valueOf(success))
                            .build()
                    )
                    .build(),
                MetricDatum.builder()
                    .metricName("MessageCount")
                    .value(1.0)
                    .unit(StandardUnit.COUNT)
                    .timestamp(Instant.now())
                    .dimensions(
                        Dimension.builder()
                            .name("FlowName")
                            .value(flowName)
                            .build()
                    )
                    .build()
            )
            .build();
        
        cloudWatch.putMetricData(request);
    }
}
```

### Distributed Tracing

**AWS X-Ray Integration**:
```java
@Configuration
public class XRayConfig {
    
    @Bean
    public Filter tracingFilter() {
        return AWSXRayServletFilter.builder()
            .withSegmentName("nxop-flight-data-adapter")
            .build();
    }
}

@Service
public class FlightDataService {
    
    @XRayEnabled
    public void processFlightEvent(FlightEvent event) {
        // Create subsegment for DocumentDB query
        Subsegment docdbSegment = AWSXRay.beginSubsegment("DocumentDB Query");
        try {
            AircraftConfiguration config = 
                aircraftConfigService.getConfiguration(event.getTailNumber());
            docdbSegment.putMetadata("tail_number", event.getTailNumber());
            docdbSegment.putAnnotation("cache_hit", config.isCached());
        } finally {
            AWSXRay.endSubsegment();
        }
        
        // Create subsegment for Flightkeys API call
        Subsegment apiSegment = AWSXRay.beginSubsegment("Flightkeys API");
        try {
            HttpResponse response = sendToFlightkeys(event);
            apiSegment.putMetadata("response_code", response.statusCode());
            apiSegment.putAnnotation("success", response.statusCode() == 200);
        } finally {
            AWSXRay.endSubsegment();
        }
    }
}
```

**Trace Example**:
```
Trace ID: 1-63f8a2b0-12345678901234567890abcd
Duration: 350 ms

Segments:
├── nxop-flight-data-adapter (350 ms)
│   ├── Kafka Consumer (50 ms)
│   ├── DocumentDB Query (20 ms)
│   │   ├── Cache Lookup (5 ms) - Cache Miss
│   │   └── Database Query (15 ms)
│   ├── Data Enrichment (30 ms)
│   └── Flightkeys API (150 ms)
│       ├── DNS Resolution (10 ms)
│       ├── TLS Handshake (20 ms)
│       ├── HTTP Request (100 ms)
│       └── Response Processing (20 ms)
└── Annotations:
    ├── flight_number: AA100
    ├── cache_hit: false
    └── success: true
```

### Logging Strategy

**Structured Logging**:
```java
@Slf4j
@Component
public class FlightEventProcessor {
    
    public void processEvent(FlightEvent event) {
        MDC.put("correlation_id", event.getCorrelationId());
        MDC.put("flight_number", event.getFlightNumber());
        MDC.put("event_type", event.getEventType());
        
        try {
            logger.info("Processing flight event", 
                kv("event_id", event.getEventId()),
                kv("timestamp", event.getTimestamp()),
                kv("source", event.getSource())
            );
            
            // Process event
            processEventLogic(event);
            
            logger.info("Flight event processed successfully",
                kv("processing_time_ms", getProcessingTime())
            );
            
        } catch (Exception e) {
            logger.error("Failed to process flight event",
                kv("error_message", e.getMessage()),
                kv("error_type", e.getClass().getSimpleName()),
                e
            );
            throw e;
        } finally {
            MDC.clear();
        }
    }
}
```

**Log Aggregation** (CloudWatch Logs Insights):
```sql
-- Query: Find slow flight event processing
fields @timestamp, flight_number, processing_time_ms
| filter event_type = "FLIGHT_EVENT_PROCESSED"
| filter processing_time_ms > 500
| sort processing_time_ms desc
| limit 100

-- Query: Error rate by flow
fields @timestamp, flow_name, error_type
| filter level = "ERROR"
| stats count() as error_count by flow_name, error_type
| sort error_count desc

-- Query: Message throughput by hour
fields @timestamp, flow_name
| filter event_type = "MESSAGE_PROCESSED"
| stats count() as message_count by bin(1h) as hour, flow_name
| sort hour desc
```


---

## Cost Analysis

### Infrastructure Cost Breakdown

**MSK Costs** (Monthly):
```
Broker Instances:
├── Instance Type: kafka.m5.2xlarge
├── Price: $1,200/month per broker
├── Brokers: 12 (6 per region × 2 regions)
└── Subtotal: $14,400/month

Storage:
├── Type: EBS gp3
├── Size: 1 TB per broker × 12 brokers = 12 TB
├── Price: $0.10/GB-month
└── Subtotal: $1,200/month

Data Transfer:
├── Cross-Region Replication: 10 TB/month
├── Price: $0.02/GB
└── Subtotal: $200/month

Total MSK: $15,800/month ($189,600/year)
```

**DocumentDB Costs** (Monthly):
```
Instances:
├── Instance Type: db.r6g.2xlarge
├── Price: $800/month per instance
├── Instances: 6 (3 per region × 2 regions)
└── Subtotal: $4,800/month

Storage:
├── Size: 500 GB
├── Price: $0.10/GB-month
└── Subtotal: $50/month

Backup Storage:
├── Size: 1 TB (automated backups)
├── Price: $0.02/GB-month
└── Subtotal: $20/month

I/O Operations:
├── Read IOPS: 10,000 IOPS × 2.6M seconds/month = 26B operations
├── Write IOPS: 1,000 IOPS × 2.6M seconds/month = 2.6B operations
├── Price: $0.20 per million operations
└── Subtotal: $5,720/month

Data Transfer:
├── Cross-Region Replication: 1 TB/month
├── Price: $0.02/GB
└── Subtotal: $20/month

Total DocumentDB: $10,610/month ($127,320/year)
```

**EKS Costs** (Monthly):
```
Control Plane:
├── Clusters: 2 (us-east-1, us-west-2)
├── Price: $0.10/hour per cluster
└── Subtotal: $144/month

Worker Nodes:
├── Instance Type: m5.2xlarge
├── Price: $0.384/hour
├── Nodes: 12 (6 per region × 2 regions, average)
└── Subtotal: $3,317/month

EBS Volumes (Node Storage):
├── Size: 100 GB per node × 12 nodes = 1.2 TB
├── Price: $0.10/GB-month
└── Subtotal: $120/month

Total EKS: $3,581/month ($42,972/year)
```

**Other AWS Services** (Monthly):
```
S3:
├── Storage: 2 TB
├── Requests: 10M GET, 1M PUT
└── Subtotal: $50/month

Route53:
├── Hosted Zones: 2
├── Queries: 100M/month
└── Subtotal: $60/month

NLB:
├── Load Balancers: 2 (1 per region)
├── LCU Hours: 1,000 LCU-hours/month
└── Subtotal: $40/month

CloudWatch:
├── Metrics: 1,000 custom metrics
├── Logs: 100 GB ingestion, 500 GB storage
└── Subtotal: $200/month

X-Ray:
├── Traces: 10M traces/month
└── Subtotal: $50/month

Total Other: $400/month ($4,800/year)
```

**Total Infrastructure Cost**:
```
Monthly: $30,391
Annual: $364,692

Cost per Message:
├── Total Messages: 5,000 msg/s × 86,400 s/day × 30 days = 13B msg/month
├── Cost per Million Messages: $2.34
└── Cost per Message: $0.00000234
```

### Cost Optimization Opportunities

**Reserved Instances**:
```
Current On-Demand Cost: $30,391/month

With 1-Year Reserved Instances (40% savings):
├── MSK: $15,800 → $9,480 (save $6,320/month)
├── DocumentDB: $10,610 → $6,366 (save $4,244/month)
├── EKS Nodes: $3,317 → $1,990 (save $1,327/month)
└── Total Savings: $11,891/month ($142,692/year)

New Monthly Cost: $18,500 (39% reduction)
```

**Right-Sizing**:
```
MSK Broker Utilization:
├── Current: 30-50% CPU, 20-40% network
├── Recommendation: Downgrade to kafka.m5.xlarge
├── Savings: $7,200/month

DocumentDB Instance Utilization:
├── Current: 40-60% CPU, 50-70% memory
├── Recommendation: Downgrade to db.r6g.xlarge
├── Savings: $2,400/month

Total Right-Sizing Savings: $9,600/month
```

**Data Transfer Optimization**:
```
Current Cross-Region Transfer: 11 TB/month ($220/month)

Optimization Strategies:
├── Compress Kafka messages (snappy): 30% reduction → $154/month (save $66)
├── Reduce DocumentDB replication frequency: 20% reduction → $176/month (save $44)
└── Total Savings: $110/month
```

---

## Summary and Key Takeaways

### Architecture Highlights

**Multi-Region Resilience**:
- Active-active deployment across us-east-1 and us-west-2
- MSK bidirectional replication with < 30 second lag target
- DocumentDB Global Cluster with automatic failover (< 1 minute)
- Cross-account architecture (NXOP ↔ KPaaS) with IAM role chaining

**Integration Patterns**:
- 25 message flows across 7 integration patterns
- 19 flows (76%) actively processed by NXOP Platform
- 6 flows (24%) bypass NXOP (legacy FXIP/OpsHub only)
- Hybrid communication: AMQP, Kafka, HTTPS, MQ, ACARS, TCP

**Performance Characteristics**:
- Peak throughput: 5,000 msg/s, 250 MB/s
- End-to-end latency: 200-500 ms (P95)
- Cache hit rate: 80% (Redis)
- Auto-scaling: 3-12 pods per service


### Technical Deep Dive Summary

**MSK Infrastructure**:
- 12 brokers (6 per region), kafka.m5.2xlarge
- 6 topics, 12 partitions each, replication factor 3
- Cross-region replication: 5-15 seconds lag (P95)
- TLS 1.3 encryption, IAM authentication
- Route53 + NLB for bootstrap discovery

**DocumentDB Architecture**:
- Global Cluster: 6 instances (3 per region)
- db.r6g.2xlarge, 64 GiB memory, 8 vCPUs
- Replication lag: < 1 second (P95)
- Connection pooling: 100 max, 10 min connections
- Read preference: secondaryPreferred for most flows

**Security Model**:
- OAuth 2.0 + mTLS for API authentication
- IAM role chaining for cross-account access
- TLS 1.3 for all data in transit
- KMS encryption for data at rest
- Certificate rotation: 365 days

**Monitoring and Observability**:
- CloudWatch metrics: 1,000+ custom metrics
- X-Ray distributed tracing: 10M traces/month
- Structured logging with correlation IDs
- CloudWatch Logs Insights for analysis
- Alarms: 50+ critical and warning alarms

### Flow-Specific Insights

**High-Volume Flows** (> 1,000 msg/s):
1. **Flow 1** (FOS Events to Flightkeys): 2,000 msg/s
   - Uses MSK + DocumentDB
   - Enrichment with aircraft reference data
   - Cross-region replication for resilience

2. **Flow 5** (Audit Logs, Weather, OFP): 1,500 msg/s
   - MSK → Azure Event Hubs bridge
   - 7-day retention for compliance
   - Kafka Connector for Azure integration

3. **Flow 2** (Flight Plans from Flightkeys): 1,000 msg/s
   - AMQP → MSK → MQ distribution
   - Critical for flight operations
   - Multi-consumer pattern

**Complex Flows** (Multi-Service Orchestration):
1. **Flow 8** (Pilot Briefing Package):
   - Orchestrates 3 services in parallel
   - DocumentDB + S3 data retrieval
   - 520 ms end-to-end latency (P95)
   - Caching for 5 minutes

2. **Flow 10** (eSignature - ACARS):
   - Hybrid AMQP + HTTPS + Kafka + ACARS
   - Parallel processing: AWS NXOP + Azure FXIP
   - DocumentDB for signature validation
   - Compliance audit trail

**Critical Dependencies**:
1. **OpsHub On-Prem**: 100% of flows (Tier 1)
2. **Flightkeys**: 80% of flows (Tier 1)
3. **FOS**: 76% of flows (Tier 1)
4. **AIRCOM Server**: 40% of flows (Tier 2)
5. **MSK**: 24% of flows (Tier 2)
6. **DocumentDB**: 20% of flows (Tier 2)

### Optimization Recommendations

**Performance**:
1. Increase Redis cache TTL for reference data (24h → 48h)
2. Implement read replicas for DocumentDB in additional AZs
3. Optimize Kafka partition count based on consumer parallelism
4. Enable Kafka compression (snappy) for all producers

**Cost**:
1. Purchase 1-year Reserved Instances (save $142,692/year)
2. Right-size MSK brokers (kafka.m5.2xlarge → m5.xlarge, save $86,400/year)
3. Right-size DocumentDB instances (db.r6g.2xlarge → r6g.xlarge, save $28,800/year)
4. Implement S3 Intelligent-Tiering for document storage

**Reliability**:
1. Implement circuit breakers for external API calls
2. Add dead-letter queues for all Kafka consumers
3. Increase MSK replication factor to 4 for critical topics
4. Implement blue-green deployment for zero-downtime updates

**Security**:
1. Rotate mTLS certificates every 90 days (currently 365 days)
2. Implement AWS Secrets Manager for credential rotation
3. Enable VPC Flow Logs for network traffic analysis
4. Implement AWS GuardDuty for threat detection

### Next Steps

**Immediate Actions** (0-30 days):
1. Review and optimize Kafka partition strategy
2. Implement comprehensive alerting for all critical flows
3. Conduct load testing for peak scenarios (2x current load)
4. Document runbooks for common failure scenarios

**Short-Term** (30-90 days):
1. Implement Reserved Instances for cost savings
2. Right-size infrastructure based on utilization metrics
3. Enhance monitoring with custom business metrics
4. Conduct disaster recovery drill (cross-region failover)

**Long-Term** (90+ days):
1. Evaluate migration to MSK Serverless for cost optimization
2. Implement multi-region active-active for all flows
3. Enhance observability with OpenTelemetry
4. Develop self-healing automation for common failures

---

## Appendix: Flow Reference Matrix

| Flow # | Name | Pattern | MSK | DocumentDB | Throughput | Latency (P95) | Criticality |
|--------|------|---------|-----|------------|------------|---------------|-------------|
| 1 | FOS Events to Flightkeys | Outbound | ✓ | ✓ | 2,000 msg/s | 350 ms | HIGH |
| 2 | Flight Plans from Flightkeys | Inbound | ✓ | - | 1,000 msg/s | 500 ms | CRITICAL |
| 3 | Flightkeys Events to FOS | Inbound | - | - | 500 msg/s | 200 ms | HIGH |
| 4 | Flightplan Data to FOS | Inbound | - | - | 300 msg/s | 200 ms | HIGH |
| 5 | Audit Logs, Weather, OFP | Inbound | ✓ | - | 1,500 msg/s | 300 ms | HIGH |
| 6 | Summary Flight Plans | Inbound | - | - | 100 msg/s | 150 ms | MEDIUM |
| 7 | Flight Release Notifications | Notification | - | - | 200 msg/s | 250 ms | HIGH |
| 8 | Pilot Briefing Package | Document | - | ✓ | 50 req/s | 520 ms | CRITICAL |
| 9 | eSignature - CCI | Authorization | - | - | 100 msg/s | 300 ms | HIGH |
| 10 | eSignature - ACARS | Authorization | ✓ | ✓ | 50 msg/s | 400 ms | HIGH |
| 11 | Events to CyberJet | Outbound | - | - | N/A | N/A | N/A |
| 12 | Flight Plans to CyberJet | Inbound | - | - | N/A | N/A | N/A |
| 13 | FMS Init & ACARS Requests | Bidirectional | - | - | N/A | N/A | N/A |
| 14 | ACARS Free Text | Notification | - | - | 100 msg/s | 200 ms | MEDIUM |
| 15 | Flight Progress Reports | Bidirectional | - | - | N/A | N/A | N/A |
| 16 | Fleet Reference Data | Bidirectional | - | - | 10 req/s | 100 ms | MEDIUM |
| 17 | Fuel Data Updates | Bidirectional | - | - | 10 req/s | 100 ms | MEDIUM |
| 18 | Position Reports to FK | Outbound | ✓ | ✓ | 300 msg/s | 400 ms | HIGH |
| 19 | Events to Fusion | Inbound | ✓ | ✓ | 500 msg/s | 350 ms | HIGH |
| 20 | Flight Plans to Fusion | Bidirectional | - | - | 200 msg/s | 250 ms | MEDIUM |
| 21 | Position Reports to Fusion | Inbound | - | - | N/A | N/A | N/A |
| 22 | Fusion ACARS Messaging | Notification | - | - | 100 msg/s | 200 ms | MEDIUM |
| 23 | Special Info Messages | Outbound | - | - | 20 req/s | 150 ms | LOW |
| 24 | TAF Deletions | Outbound | - | - | 10 req/s | 150 ms | LOW |
| 25 | ACARS REQLDI | Bidirectional | - | - | N/A | N/A | N/A |

**Legend**:
- ✓ = Used by flow
- \- = Not used by flow
- N/A = NXOP not involved (no metrics available)

---

**Document End**

**Version**: 2.0 (300-Level Deep Dive)  
**Last Updated**: 2026-01-28  
**Author**: NXOP Platform Architecture Team  
**Classification**: Internal Use Only

