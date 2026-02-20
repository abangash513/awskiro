# Architecture Considerations
![alt text](../fxip/images/high_level_architecture_documentDb.png)
<details>
<summary>Table of Contents</summary>

</details>

**Ingest & Edge**

- Data Sources --- producers of events (apps, 3rd-party feeds -
  FlightKeys, LPS, TPS, Crew Pay).

- API Gateway / EKS --- HTTP/webhooks, pre-validation or adapters before
  events hit the streaming layer.

**Streaming / Messaging**

- Amazon MSK (Kafka) --- durable, partitioned event bus for
  high-throughput ingestion and replay.

**Stream Processing**

- Amazon Managed Service for Apache Flink --- real-time processing,
  enrichment, windowing and routing of events; writes to downstream
  sinks.

**Operational (OLTP) Store & API Layer**

- Amazon DocumentDb (operational store) --- low-latency
  key/value/document store for real-time app reads and state.

- AWS AppSync (GraphQL) --- unified API façade for clients (reads/writes
  to DocumentDb and invokes Lambda for analytics).

**CDC / Synchronization**

- DocumentDb Streams (or equivalent CDC) --- change feed of operational
  updates.

- Flink CDC job (or Glue/Lambda) --- consumes streams and upserts into
  analytics tables (Iceberg).

- Glue vs Lambda for CDC job - evaluation

**Analytical Lakehouse & Storage**

- Apache Iceberg tables on Amazon S3 --- authoritative analytical store
  (time travel, schema evolution, large-scale queries).

- S3 (object storage) --- durable file store for Iceberg table data and
  metadata.

- Apache Iceberg on S3 vs Delta Lake on ADLS -- evaluation from
  resiliency standpoint

**Governance & Catalog**

- Use existing Databricks Unity Catalog --- central metadata, lineage
  and **fine-grained access control for Iceberg tables** (governed
  analytics plane).

**Analytical & Query Engines (consumers)**

- Trino / Athena / EMR (Spark) --- SQL query engines for ad-hoc and
  scheduled analytics on Iceberg.

- Amazon Redshift Spectrum --- query Iceberg data from Redshift for
  integrated warehousing.\*\*

  - Needs more evaluation

- AWS Glue vs Databricks, UC --- ETL jobs, cataloging, and optional
  batch ingestion/transforms.

  - Needs more evaluation

- Amazon QuickSight vs Power BI vs Tableau --- BI/visualization
  dashboards consuming aggregated datasets.

  - Needs more evaluation

- AWS Lambda --- serverless functions for query orchestration, API
  backends or lightweight transforms.

  - Needs more evaluation

**Observability, Ops & Security -- to be evaluated in detail**

- CloudWatch / Logging / Metrics / Alerts --- monitoring and alerting
  for streams, Flink jobs, DB, and query failures.

- IAM / KMS / Secrets Manager --- authentication, authorization, and
  encryption of data at rest/in flight.

- VPC / PrivateLink / Networking --- secure private connectivity between
  services (MSK, Atlas if used, Databricks, etc.).

- Backup / Snapshot / Lifecycle Policies --- S3 lifecycle, database
  backups, and Iceberg snapshot retention.

**Design Impacts**

- Critical path:

  - MSK → Flink → DocumentDb is low-latency path;

  - DocumentDb Streams → Flink → Iceberg is analytics sync path.

- Single points to harden:

  - Catalog availability (Unity Catalog/Metastore), MSK broker
    availability (use MSK Serverless or replication), and the Flink
    checkpointing/store.

- Cost/latency tradeoffs:

  - NoSQL Db writes are costly at high throughput (WCUs);

  - Iceberg write costs are dominated by S3 PUTs and compaction compute.

  - Flink concurrent sinks are efficient but increase KPU usage.

- Open-source friendliness:

  - MSK, Flink, Iceberg, Trino are OSS-native;

  - Unity Catalog is Databricks-managed (governance) so factor that into
    lock-in decisions.

- AppSync cannot natively target DocumentDB.

  - AppSync → Lambda resolvers (or HTTP resolvers) talk to DocumentDB.

- Architecture uses **Lambda** resolvers which call DocumentDB drivers.

  - Adds a tiny read latency (Lambda cold starts possible).

  - What does this latency look like?

- Flink writes operational state directly into DocumentDB;

  - Separate Flink CDC job reads DocumentDB change stream and writes to
    Iceberg (keeps analytics in sync).

- Unity Catalog governs Iceberg on S3 as before.

**Overview of Technologies by use case**

- **Apache Iceberg (on S3)\**
  Open-table format for large-scale analytic data lakes with ACID
  guarantees, schema evolution, time travel, and broad engine support
  (Spark, Flink, Trino, Athena).

- **Apache Pinot\**
  Real-time OLAP datastore designed for sub-second slice-and-dice
  queries on event streams. Offers native streaming ingestion (Kafka,
  Pulsar), built-in indexing, and horizontal scale-out.

- **Amazon DocumentDB**\
  MongoDB-compatible, fully managed document database optimized for
  low-latency CRUD, flexible JSON schemas, automatic scaling, change
  streams, and operational workloads.

Key Scenario Comparisons -- when to use?
| **Scenario** | **Iceberg** | **Pinot** | **DocumentDB** |
| --- | --- | --- | --- |
| 1\. Petabyte-Scale Batch Analytics | Ideal for historical, batch queries; time travel | Limited (no bulk ETL) | Not suited |
| 2\. Real-Time OLAP Dashboards | Designed for batch; can pre-aggregate & query via Trino | Native sub-second aggregations & filters | Limited aggregation performance |
| 3\. Operational CRUD & APIs | Not supported | Not supported | Best for low-latency document reads/writes |
| 4\. Streaming CDC Ingestion | Via Flink/Spark → Iceberg sink | Native Kafka/Pulsar ingestion | Change Streams support |
| 5\. Schema Evolution & Versioning | First-class (add/drop/rename) + snapshot rollback | Limited; schema changes expensive | Flexible JSON (no strict schema) |
| 6\. Time Travel & Audit | Native snapshots & rollback | None | None |
| 7\. High-Concurrency Ad-Hoc Queries | Via Trino/Athena | Native | Poor at complex joins/aggregations |
| 8\. ML Feature Store & Reproducibility | Snapshots + metadata lineage | Not typical | Not designed |
| 9\. Cold Data Cost Efficiency | S3 storage + pay-per-query | Not a storage engine | Always-on cluster costs |
| 10\. Data Governance (Unity Catalog) | Native integration, fine-grained controls | No native support (external catalog needed) | Not supported |
| 11\. Open-Source Format Compatibility | Fully OSS-standard<br><br>(Parquet/ORC, Iceberg spec) | Fully OSS-standard for OLAP | MongoDB API-compatible but proprietary |

**Usage Recommendations**

- Apache Iceberg

  - When to choose: Batch analytics at scale, complex historical
    queries, regulatory compliance, multi-engine access, governed
    lakehouse deployments.

  - Example: Monthly financial close analytics over years of data with
    rollback and auditability.

- Apache Pinot

  - When to choose: Real-time dashboards, slice-and-dice OLAP on event
    streams, high-concurrency KPI queries.

  - Example: User-facing analytics dashboards showing live website
    clickstream metrics, ad-hoc drill-downs in milliseconds.

- Amazon DocumentDB

  - When to choose: Operational microservices, content management, user
    profiles, session stores requiring flexible JSON documents and low
    latency.

  - Example: E-commerce cart storage with fast add/remove operations and
    dynamic product data per user session.

**Hybrid Patterns**

- Operational + Analytics

  - Pipeline: Event streams → MSK → Flink → DocumentDB (operational) +
    Iceberg (analytical)

  - Governance: Unity Catalog on Iceberg for analytics; IAM/Lake
    Formation for DocumentDB

  - Analytics: Ad-hoc via Trino/Athena on Iceberg; real-time via Pinot
    if sub-second is required.

Conclusion:\
Choose Iceberg for governed, large-scale analytics with rich historical
and schema-evolution capabilities; Pinot for sub-second OLAP on
streaming data; and DocumentDB for real-time, document-driven
operational workloads. Mix as needed for hybrid real-time + batch use
cases.

**Apache Iceberg on S3 + UC** vs **Delta Lake on ADLS + UC** for
Analytical Store

\*\*\*Architecture from Resiliency standpoint

\*\*\* Consider most of our workloads are on Databricks

**Resiliency comparison**

\*\*focusing on durability, availability, commit/transaction safety,
recovery, and disaster-recovery patterns.

**Big picture**

- **Both are resilient if you configure the cloud storage +
  metadata/catalog correctly.**

- The **object store** provides durability/geo options; the **table
  format** (Iceberg/Delta) has ACID commits, recovery, and time-travel.

- **Weakest link** is usually the **catalog/transaction log and
  cross-region setup**, not the raw files.

**Head-to-head (resiliency only)**
| **Dimension** | **Iceberg on S3** | **Delta on ADLS Gen2** |
| --- | --- | --- |
| **Underlying storage durability** | S3 standard durability **11×9s**; multi-AZ by default. | ADLS Gen2 uses Azure Blob—durability depends on replication: **LRS/ZRS/GZRS/GRS** (ZRS/GZRS = zone-redundant). |
| **Availability options** | Regional service with high availability; bucket policies/endpoint SLAs. | Storage account SLA; **RA-GRS / RA-GZRS** allow read-access from secondary region. |
| **Consistency model** | **Strong read-after-write** (for PUTs/overwrites & LIST) across regions. | **Strong consistency** for blobs/ADLS. |
| **ACID mechanism** | **Snapshot-based**: atomic pointer swap to a new table metadata file; manifest lists ensure atomic visibility; optimistic concurrency + optional external lock (e.g., DocumentDb). | **Transaction log** (\_delta_log) with append-only JSON + Parquet checkpoints; optimistic concurrency with atomic file creation. |
| **Commit failure handling** | Writer creates new metadata + manifests, then **atomic commit** (if conflict, retry). Partial data files are orphaned but invisible; can be cleaned with **expire snapshots**. | Writer appends a new log JSON; conflicts cause commit retry. Checkpoints & **VACUUM** handle old files; failed writes are not committed. |
| **Corruption blast radius** | Snapshots are immutable; **time travel** can restore a prior snapshot; manifest rewrite can heal small-file rot. | Log history + **RESTORE** (to version/timestamp) and **CLONE** reduce blast radius; checkpoints let readers recover fast. |
| **Multi-writer safety** | Designed for concurrent writers across engines (Spark, Flink, Trino); optimistic concurrency at snapshot level. | Very mature with Spark/Databricks; high-throughput multi-writer via log append & conflict resolution. |
| **Catalog/metadata resiliency** | Needs a **reliable catalog** (Unity Catalog external tables). **Replicate/back up** the catalog; it’s critical for recovery. | Log is in storage; on Databricks the **metastore/Unity Catalog** stores perms/lineage—run in same or paired regions; data+log live in ADLS. |
| **Cross-region DR pattern** | **S3 CRR** (cross-region replication) for table data + metadata files **and** replicate/DR the catalog (\*\* Needs evaluation). Promote the replica bucket and point engines to the failover catalog. | Use **GRS/GZRS + RA** to replicate data & log cross-region; pair with a **secondary Databricks workspace/metastore**. Failover can be manual; reads from secondary are possible (RA-\*). |
| **Read-path resilience** | Readers pick the latest committed snapshot; if commit in flight, they keep using the last stable snapshot. | Readers use latest committed log version; if checkpoint lagging, engine replays log; stable under partial failures. |
| **Operational guardrails** | Periodic **snapshot expiration** & **rewrite manifests/files** to bound metadata and recover from orphaned writes; versioning + Object Lock optional. | Routine **OPTIMIZE/Z-Order** + **VACUUM** + **CHECKPOINT**; **RESTORE** for fast recovery; can combine with storage soft-delete/versioning. |
| **Engine/ecosystem tightness** | Very resilient **multi-engine** (Spark/Flink/Trino/Athena/Redshift Spectrum) if catalog is healthy. | Deepest resilience ergonomics on **Databricks** (automatic checkpoints, optimize jobs, UI tooling). |

**Gotcha's**

**Iceberg on S3**

**Strengths**

- Snapshot model = clean rollback and reader isolation even under
  partial failures.

- Works the same across engines---good resilience to engine-level
  outages.

- S3 versioning + **Object Lock** + CRR give robust immutability/DR.

**Watch-outs**

- **Catalog** must be backed up/replicated; if it's down, the table is
  hard to discover even though files are safe.

- Streaming writers: tune commit frequency/file sizes to avoid manifest
  bloat (affects recovery speed).

**Delta on ADLS**

**Strengths**

- Transaction log + checkpoints make recovery fast; **RESTORE** is
  simple.

- Databricks manages many resilience jobs (OPTIMIZE/CHECKPOINT)
  automatically or on schedule.

- **RA-GZRS/GRS** with read-access secondaries = strong DR story for
  read-only scenarios.

**Watch-outs**

- **Workspace/metastore locality**: for regional outages, plan
  a **paired workspace** and tested failover runbooks.

- VACUUM settings: be conservative with retention to avoid deleting
  files needed for recovery/streaming.

**What to choose (based on resiliency)**

- **Multi-engine + cloud-neutral resilience**: **Iceberg on S3** with a
  replicated catalog and S3 CRR is excellent. Very resilient so long as
  you treat the catalog like gold.

- **Databricks-centric, turnkey operations**: **Delta on ADLS** gives
  the smoothest resilience ergonomics (checkpoints, restore, optimize)
  and pairs well with Azure's **RA-GZRS/GRS** for DR.

**Minimum viable DR checklist**

**Iceberg/S3**

- Enable **S3 versioning** (+ optional **Object Lock** for
  immutability).

- Configure **CRR** for table & metadata prefixes.

- Use a **replicated catalog** (e.g., Glue in secondary region or Nessie
  multi-region). Test failover.

- Schedule **expire snapshots** + **rewrite manifests/files**.

**Delta/ADLS**

- Use **GZRS or GRS** with **RA** for cross-region reads.

- Automate **OPTIMIZE**, **CHECKPOINT**, and **VACUUM** with safe
  retention.

- Maintain a **secondary Databricks workspace** bound to the secondary
  storage account; rehearse **RESTORE/failover**.

- Keep metastore/UC artifacts backed up and policy-as-code for quick
  recreation.

Bottom line: We need to decide on engine strategy and the operational
model that suffices our need---\*\*\***S3+Iceberg** for open,
multi-engine resilience; 

**\*\*\*ADLS+Delta** for Databricks-first resilience with strong
built-in recovery tooling.

**1 --- Global / end-to-end (business-facing)**

These capture the user / business experience and should be our top SLOs.

- **End-to-end freshness (latency)**

  - *What:* Time from event produced (MSK) → visible in Iceberg and/or
    available via BI.

  - *Why:* Measures pipeline freshness.

  - *How to measure:* Attach ingest timestamp to events and measure
    (now - lastProcessedTs) at the Iceberg writer & consumer queries.

  - *Example SLOs:* p95 \< 30s for near-real-time analytics; p99 \< 2m.

  - *Alert:* p95 \> 60s or p99 \> 5m.

- **Data completeness / correctness (per logical stream/table)**

  - *What:* Count of events produced vs consumed vs written to Iceberg
    per minute/hour.

  - *Why:* Detects data loss, dropped messages, or backfill needs.

  - *Alert:* \>1% delta sustained for 5--15 mins.

- **CDC lag (change-stream lag)**

  - *What:* Time difference between the newest event in Atlas change
    stream and last event processed by Flink CDC job.

  - *Why:* Critical for real-time analytics correctness.

  - *SLO:* p95 \< 5s (real-time), p99 \< 30s.

  - *Alert:* lag \> 30s or rising trend for 5 mins.

**2 --- Ingestion (MSK / Kafka)**

Monitor producers, brokers, topics, and consumer lag.

- **MessagesInPerSec / BytesInPerSec** (per topic)

  - *Why:* Throughput scaling and billing planning.

- **ProducerRequestLatency**

  - *Why:* Downstream delays if producers are slow.

- **UnderReplicatedPartitions / OfflinePartitions /
  ActiveControllerCount**

  - *Why:* Broker health. Any non-zero UnderReplicatedPartitions or
    OfflinePartitions is high severity.

- **Broker CPUUtilization / NetworkIn/Out / DiskUsed%**

  - *Alert:* CPU \> 70% sustained, DiskUsed \> 80%.

- **Consumer Group Lag (per group, per partition)**

  - *Why:* Actual backlog for each Flink consumer.

  - *SLO/Alert:* Lag \> configured thresholds (e.g., messages lag \> 1M
    or time lag \> 1 minute) → alert immediately.

- **RequestLatency (produce/fetch)** --- alert on spikes.

**3 --- Stream Processing (Managed Flink)**

Flink is the heart of processing; checkpointing & backpressure are key.

- **Checkpoint metrics**

  - checkpointSuccessRate (success/fail count)

  - checkpointDuration (ms) and lastCheckpointAge

  - *Why:* If checkpoints fail, you lose exactly-once guarantees;
    recovery will be slow.

  - *Alert:* \>1 failed checkpoint in 10 mins OR checkpointDuration \>
    2× checkpoint interval.

- **Backpressure / Task subtask latency / operator queue sizes**

  - *Why:* Indicates sink slowness (DocumentDB/Iceberg) or resource
    shortage.

  - *Alert:* sustained backpressure \> 30s.

- **Task/Job failures & restarts**

  - *Alert:* Any job restart or task manager failure → Pager.

- **Throughput: recordsInPerSecond / recordsOutPerSecond**

  - *Why:* Validate expected throughput and detect drops.

- **State size per operator / checkpoint size**

  - *Why:* Large state increases checkpoint time & recovery.

  - *Alert:* sudden growth \>20% day-over-day.

- **KPU / resource usage** (if Managed Flink exposes)

  - *Alert:* Insufficient KPUs causing high CPU/GC.

**4 --- Operational DB (MongoDB Atlas)**

Key for latency & operational correctness.

- **Connections (current)** and **connection churn**

  - *Alert:* connections approaching plan limit; high connection churn
    indicates client misconfig.

- **CPUUtilization / MemoryUsage / PageFaults**

  - *Alert:* CPU \> 75% sustained or memory pressure causing page
    faults.

- **Opcounters (insert/update/delete/get)** and **ops/sec**

  - *Why:* Workload characterization; sudden spikes may cause
    throttling.

- **Read/Write Latency (p50/p95/p99)**

  - *SLO:* Reads p95 \< 20 ms (depends on instance size), writes p95 \<
    50--100 ms.

  - *Alert:* degradation beyond baseline.

- **Replica lag (seconds)**

  - *Alert:* replica lag \> 1s (for some apps) or \> 5s for critical
    flows.

- **Disk I/O / IOPS / DiskQueueDepth**

  - *Alert:* sustained IOPS near instance limits.

- **Change Stream metrics** (tailable cursor lag, resume tokens)

  - *Alert:* change stream consumer falling behind or cursor errors.

**5 --- Object store & Iceberg specific (S3 + Iceberg)**

Storage health and table metadata.

- **S3: NumberOfObjects / BytesStored / GET/PUT/SELECT requests /
  4xx/5xx errors**

  - *Why:* Cost, throttling, and error detection.

  - *Alert:* sudden increase in PUTs (many small files) or increase in
    4xx/5xx.

- **Iceberg table metrics**

  - **SnapshotCount / SnapshotAge (old snapshots)** --- control
    retention.

  - **Number of metadata files (manifest files, manifest lists)** ---
    when this grows, planning compaction.

  - **Average file size / smallFileCount** (files \< 100MB) --- too many
    small files → query cost & slow scans.

  - **UncompactedFiles / Compaction backlog jobs** --- pending
    compactions.

  - **Commit failures / write exceptions** (per table)

  - *SLO:* average file size target 128--512MB; smallFileCount % \< 10%.

  - *Alert:* small file ratio \> 30% or manifest file count growth \>
    50% in 1 hour.

- **Compaction & rewrite jobs** --- success/failure, duration, bytes
  rewritten.

**6 --- Governance & metadata (Unity Catalog)**

Security & governance hygiene.

- **Unauthorized access attempts / failed grants**

  - *Alert:* any unauthorized data access attempts on sensitive tables.

- **Policy change events / privilege grants**

  - *Why:* audit & detect unexpected privilege escalations.

- **Lineage job success/failure** and **catalog availability**

  - *Alert:* catalog service unreachable → block deployments/querying.

- **Audit log volume / audit events** --- retention and S3 costs.

**7 --- Query engines & BI (Trino, Athena, EMR, Redshift Spectrum,
QuickSight)**

Monitor query performance, queueing, and concurrency.

- **Query SLA: p50/p95/p99 latency** (for typical queries)

  - *Alert:* p95 exceeds target (e.g., \> 3s for interactive queries;
    adjust by workload).

- **Queries per second / concurrent queries / queued queries**

  - *Alert:* queuedQueries \> concurrency threshold.

- **Spilled bytes / memory pool pressure / failed queries due to OOM**

  - *Alert:* spilledBytes \> threshold or increased failed queries.

- **Scan bytes per query (and scanned TB/day)** --- cost control and
  optimization target.

**8 --- Serverless & Glue & Lambda**

Operational function metrics.

- **Lambda**: invocations, errors, duration p95/p99, throttles,
  concurrent executions. Alert on errors \> 1% or throttling.

- **Glue/Databricks jobs**: jobDuration, success/failure, DPU hours;
  alert on failures/skips.

- **EMR jobs**: YARN container failures, job failures, HDFS/S3 errors.

**9 --- Cost & capacity indicators**

Keep cost-aware alerts.

- **DBU / compute hours (Databricks)** --- watch bucketed DBU
  consumption.

- **S3 request count & egress** --- large increases indicate cost
  spikes.

- **MSK broker / partition scaling costs** --- spikes in broker count or
  throughput.

- **MongoDB Atlas cluster tier / scaling events** --- unexpected
  autoscale events = cost signal.

**10 --- Security & infra**

- **KMS key usage & rotation** errors.

- **Secrets Manager access failures** (lambdas can\'t retrieve secret).

- **VPC flow logs** anomalies (unexpected egress).

- **TLS handshake failures** for DB connections.

- **Vulnerability scan results or backup verification failures.**

**Recommended dashboards (minimum)**

1.  **Ingestion Health** --- MSK throughput, under/over-replicated
    partitions, producer latencies, consumer lag by group/topic.

2.  **Processing Health** --- Flink job health, checkpoint success rate,
    backpressure, task failures, throughput.

3.  **Operational Store** --- Atlas metrics: connection count, ops/sec,
    p95 read/write latency, replica lag, CPU/memory/IOPS.

4.  **Analytics / Lake** --- Iceberg per-table file size, snapshot
    count, compaction backlog, S3 requests/storage, query scan bytes,
    query latency.

5.  **Governance & Security** --- Unity Catalog availability, policy
    change events, unauthorized attempts, audit log ingestion.

6.  **Cost & Capacity** --- DBUs, S3 cost drivers (requests & bytes),
    MSK/Atlas scaling events.

**Alerts & severity guidance**

- **P0**: Job restarts (Flink job down), consumer group lag rapidly
  increasing, MSK offline partitions, commit failures to Iceberg, change
  stream consumer stopped.

- **P1**: Sustained CDC lag \> threshold, checkpoint failures \> 1, DB
  CPU \> 90% for 5 mins, large spike in S3 5xx errors.

- **P2**: Increased query p95 beyond SLA, small file ratio increasing,
  DB connections near limit.

- **P3**: Cost anomalies under review, snapshot retention warnings.

**Collection & tooling tips**

- **Collect logs/traces** with Correlation IDs (event id) so you can
  trace a single event across MSK → Flink → Atlas → Iceberg.

- **Use CloudWatch** for AWS-managed components; **Grafana** for Flink &
  Kafka metrics; **Atlas monitoring** or DataDog/Datadog integration for
  MongoDB Atlas.

- **Emit business metrics** (counts by event type / table) to metrics
  system for SLA checks.

- **Periodic data quality jobs**: sample rows in Iceberg vs Atlas to
  check drift and schema mismatches.

**Quick runbook starters**

- **CDC lag rising**: check consumer group lag → Flink job health &
  backpressure → sink write errors (Atlas / Iceberg) → restart/scale
  Flink tasks or increase DB capacity; run backfill for missed window.

- **Checkpoint failures**: inspect logs (OOM, network), check state
  size, increase checkpoint timeout, scale state backend, resume.

- **Many small Iceberg files**: schedule compaction job, increase Flink
  sink batch size, adjust commit frequency, monitor S3 PUT costs.
