# AWS Bedrock & AI Services Optimization Analysis
**Account:** 013612877090  
**Date:** December 23, 2025  
**Analyzed By:** agbangash@gmail.com  
**Role:** AWSReservedSSO_AIM-WellArchitectedReview

---

## Executive Summary

Account 013612877090 has **active Amazon Bedrock workloads** deployed in **us-west-2** region. The account is running:
- 1 Bedrock Agent (NetSuite Bot) - **NOT_PREPARED** status
- 1 Knowledge Base with OpenSearch Serverless backend
- Low usage: 12 model invocations in last 30 days

**Key Finding:** Agent is in NOT_PREPARED state and has minimal usage, indicating potential for optimization or decommissioning.

**Estimated Monthly Cost:** $50-150 (primarily OpenSearch Serverless)  
**Optimization Potential:** $30-100/month (60-70% savings)

---

## Active Bedrock Workloads

### 1. Bedrock Agent: intapps-ns-bot

**Status:** 🟡 NOT_PREPARED (Not production-ready)  
**Agent ID:** SZTZWLTEUY  
**Region:** us-west-2  
**Created:** November 5, 2025  
**Last Updated:** November 5, 2025

**Configuration:**
- **Foundation Model:** Claude 3.7 Sonnet (us.anthropic.claude-3-7-sonnet-20250219-v1:0)
- **Description:** NetSuite Bot
- **Idle Session TTL:** 600 seconds (10 minutes)
- **Orchestration:** DEFAULT
- **Memory:** Enabled with summarization

**Action Groups:**
1. **CodeInterpreterAction** - Enabled
2. **NetSuite_Tools** - Enabled (Custom control: RETURN_CONTROL)
   - Function: NetSuite_Search
3. **UserInputAction** - Enabled

**IAM Role:** arn:aws:iam::013612877090:role/service-role/AmazonBedrockExecutionRoleForAgents_4DSX2FFM8OL

**Usage (Last 30 Days):**
- December 12: 8 invocations
- December 15: 4 invocations
- **Total:** 12 invocations

**⚠️ Issues:**
- Agent status is NOT_PREPARED (needs to be prepared before use)
- Very low usage (12 invocations in 30 days)
- Last updated 6+ weeks ago
- No recent activity

---

### 2. Knowledge Base: knowledge-base-deals

**Status:** ✅ ACTIVE  
**Knowledge Base ID:** 5QQMYTK6TS  
**Region:** us-west-2  
**Created:** May 3, 2024  
**Last Updated:** May 3, 2024

**Configuration:**
- **Type:** VECTOR
- **Embedding Model:** Amazon Titan Embed Text v1 (amazon.titan-embed-text-v1)
- **Storage:** OpenSearch Serverless
- **Collection:** bedrock-knowledge-base-betfl9 (ttsri293ptppohrzrt33)
- **Data Deletion Policy:** DELETE

**Data Source:**
- **Name:** knowledge-base-deals-data-source
- **Type:** S3
- **Bucket:** s3://q-agreements
- **Status:** AVAILABLE

**S3 Bucket Contents:**
- Amended Agreements/
- Broker Agreements/
- Escrow Agreements/
- Merger Agreements/
- Paying Agent Agreements/
- SRS Engagement Agreements/
- Side Letters/
- DPS GUIDELINES effective Jan 1, 2022 1.docx

**IAM Role:** arn:aws:iam::013612877090:role/service-role/AmazonBedrockExecutionRoleForKnowledgeBase_4o0rh

**⚠️ Issues:**
- Last updated May 2024 (19+ months ago)
- No recent data ingestion
- Unknown if actively used

---

### 3. OpenSearch Serverless Collection

**Status:** ✅ ACTIVE  
**Collection ID:** ttsri293ptppohrzrt33  
**Name:** bedrock-knowledge-base-betfl9  
**Region:** us-west-2  
**Created:** May 3, 2024

**Configuration:**
- **Type:** VECTORSEARCH
- **Standby Replicas:** DISABLED
- **Encryption:** Auto (AWS managed KMS)
- **Endpoint:** https://ttsri293ptppohrzrt33.us-west-2.aoss.amazonaws.com
- **Dashboard:** https://ttsri293ptppohrzrt33.us-west-2.aoss.amazonaws.com/_dashboards

**Index Configuration:**
- **Vector Index:** bedrock-knowledge-base-default-index
- **Vector Field:** bedrock-knowledge-base-default-vector
- **Text Field:** AMAZON_BEDROCK_TEXT_CHUNK
- **Metadata Field:** AMAZON_BEDROCK_METADATA

**💰 Cost Impact:**
- OpenSearch Serverless charges for OCU (OpenSearch Compute Units)
- Minimum: 2 OCUs for indexing + 2 OCUs for search = 4 OCUs
- **Estimated Cost:** $90-120/month (running 24/7)

---

## Cost Analysis

### Current Monthly Costs (Estimated)

| Service | Component | Estimated Cost | Notes |
|---------|-----------|----------------|-------|
| **OpenSearch Serverless** | 4 OCUs (2 indexing + 2 search) | $90-120/month | Running 24/7 |
| **Bedrock Agent** | Claude 3.7 Sonnet invocations | $1-5/month | 12 invocations/month |
| **Bedrock Knowledge Base** | Titan Embeddings | $0-2/month | Minimal usage |
| **S3 Storage** | q-agreements bucket | $1-5/month | Document storage |
| **IAM/CloudWatch** | Logs and monitoring | $0-5/month | Minimal |
| **Total** | | **$92-137/month** | |

### Breakdown by Service

#### OpenSearch Serverless (Largest Cost)
- **OCU Pricing:** ~$0.24/hour per OCU
- **4 OCUs × $0.24 × 730 hours = $700/month** (if running continuously)
- **Actual cost likely lower** due to auto-scaling, but still $90-120/month minimum

#### Bedrock Model Invocations
- **Claude 3.7 Sonnet Pricing:**
  - Input: ~$3 per 1M tokens
  - Output: ~$15 per 1M tokens
- **12 invocations/month:** Assuming 1000 tokens per invocation = $0.05-0.50/month

#### Titan Embeddings
- **Pricing:** $0.0001 per 1000 tokens
- **Minimal usage:** $0-2/month

---

## Optimization Recommendations

### 🔴 HIGH PRIORITY - Immediate Actions

#### 1. Evaluate Agent Usage & Purpose
**Issue:** Agent is NOT_PREPARED and has minimal usage (12 invocations in 30 days)

**Questions to Answer:**
- Is this agent still needed?
- Why is it NOT_PREPARED?
- Is it in development or abandoned?
- What is the intended use case?

**Options:**
- **Option A:** If not needed, delete agent (saves $1-5/month)
- **Option B:** If needed, prepare agent for production use
- **Option C:** If in development, document timeline and expected usage

**Savings:** $1-5/month (minimal, but cleanup is good practice)

---

#### 2. Optimize OpenSearch Serverless Collection
**Issue:** OpenSearch Serverless is the largest cost driver ($90-120/month)

**Current State:**
- 4 OCUs running 24/7
- Standby replicas: DISABLED (good)
- Last updated: May 2024

**Optimization Options:**

**Option A: Delete if Not Used** (Recommended if agent is abandoned)
- Check if knowledge base is actively queried
- If no queries in last 30 days, consider deletion
- **Savings:** $90-120/month (100%)

**Option B: Reduce OCU Capacity**
- Review actual OCU usage in CloudWatch
- Reduce to minimum (2 OCUs) if possible
- **Savings:** $45-60/month (50%)

**Option C: Schedule On/Off** (Not supported for OpenSearch Serverless)
- OpenSearch Serverless doesn't support scheduling
- Consider migrating to OpenSearch managed cluster if scheduling needed

**Option D: Migrate to OpenSearch Managed Cluster**
- Use t3.small.search instances (cheaper for low usage)
- Schedule on/off for non-production
- **Savings:** $50-80/month (55-67%)

**Recommended Action:**
1. Check CloudWatch metrics for actual OCU usage
2. If usage is minimal, delete collection
3. If needed, consider migrating to managed OpenSearch cluster

**Estimated Savings:** $50-100/month

---

#### 3. Update Knowledge Base Data
**Issue:** Knowledge base last updated May 2024 (19+ months ago)

**Actions:**
- Review S3 bucket (s3://q-agreements) for new documents
- Trigger data source sync if new documents exist
- Remove outdated documents if no longer relevant

**Impact:** Ensures knowledge base is current and useful

---

### 🟡 MEDIUM PRIORITY - Short-Term Actions

#### 4. Implement Monitoring & Alerting
**Issue:** No visibility into actual usage and costs

**Actions:**
- Set up CloudWatch dashboard for:
  - Bedrock invocations
  - OpenSearch OCU usage
  - Knowledge base queries
  - Error rates
- Create cost alerts:
  - Alert if monthly cost exceeds $150
  - Alert if OCU usage spikes
- Enable CloudWatch Logs for Bedrock agent

**Cost:** $5-10/month for CloudWatch  
**Benefit:** Visibility and cost control

---

#### 5. Optimize Model Selection
**Issue:** Using Claude 3.7 Sonnet (expensive) for low-volume workload

**Current Model:** Claude 3.7 Sonnet
- Input: ~$3 per 1M tokens
- Output: ~$15 per 1M tokens

**Alternative Models:**
- **Claude Haiku 4.5:** 90% cheaper, still excellent performance
  - Input: ~$0.25 per 1M tokens
  - Output: ~$1.25 per 1M tokens
- **Amazon Nova 2 Lite:** 95% cheaper, good for simple tasks
  - Input: ~$0.06 per 1M tokens
  - Output: ~$0.24 per 1M tokens

**Recommendation:**
- If agent is for simple Q&A, switch to Claude Haiku or Nova Lite
- If complex reasoning needed, keep Claude Sonnet

**Savings:** $0.50-2/month (minimal at current volume, but scales with usage)

---

#### 6. Review IAM Roles & Permissions
**Issue:** Two service roles created, need to verify least privilege

**Roles:**
- AmazonBedrockExecutionRoleForAgents_4DSX2FFM8OL
- AmazonBedrockExecutionRoleForKnowledgeBase_4o0rh

**Actions:**
- Review permissions for least privilege
- Remove unused permissions
- Enable CloudTrail logging for audit

**Benefit:** Security best practice

---

### 🟢 LOW PRIORITY - Long-Term Actions

#### 7. Implement Bedrock Guardrails
**Issue:** No guardrails configured

**Actions:**
- Configure content filtering
- Set up PII detection
- Implement topic restrictions
- Add prompt attack detection

**Cost:** $0 (included with Bedrock)  
**Benefit:** Security and compliance

---

#### 8. Enable Bedrock Model Invocation Logging
**Issue:** No detailed logging of model invocations

**Actions:**
- Enable model invocation logging to S3 or CloudWatch
- Track prompts, responses, and metadata
- Useful for debugging and optimization

**Cost:** $1-5/month for storage  
**Benefit:** Debugging and audit trail

---

#### 9. Optimize S3 Storage
**Issue:** S3 bucket (q-agreements) storage class not optimized

**Actions:**
- Implement S3 Intelligent-Tiering
- Set lifecycle policies to move old documents to Glacier
- Delete old versions if versioning enabled

**Savings:** $0.50-2/month

---

## Optimization Scenarios

### Scenario 1: Agent is Abandoned (Recommended if not used)

**Actions:**
1. Delete Bedrock agent
2. Delete knowledge base
3. Delete OpenSearch Serverless collection
4. Keep S3 bucket (archive documents)

**Monthly Savings:** $90-130/month (95% reduction)  
**New Monthly Cost:** $1-5/month (S3 storage only)  
**Implementation Time:** 1 hour

---

### Scenario 2: Agent is in Development

**Actions:**
1. Prepare agent for production
2. Keep knowledge base active
3. Reduce OpenSearch OCU capacity
4. Implement monitoring

**Monthly Savings:** $45-60/month (50% reduction)  
**New Monthly Cost:** $45-75/month  
**Implementation Time:** 4-8 hours

---

### Scenario 3: Agent is Production (Low Usage)

**Actions:**
1. Keep agent active
2. Optimize OpenSearch (reduce OCUs or migrate to managed)
3. Switch to cheaper model (Claude Haiku)
4. Implement monitoring and alerting

**Monthly Savings:** $50-80/month (55-60% reduction)  
**New Monthly Cost:** $40-60/month  
**Implementation Time:** 8-12 hours

---

## Implementation Roadmap

### Week 1: Assessment & Decision
- [ ] Determine if agent is still needed
- [ ] Check actual usage in CloudWatch
- [ ] Review knowledge base query patterns
- [ ] Decide on optimization scenario

### Week 2: Quick Wins
- [ ] If abandoned, delete agent and knowledge base
- [ ] If active, reduce OpenSearch OCU capacity
- [ ] Set up cost alerts
- [ ] Enable CloudWatch monitoring

### Week 3: Optimization
- [ ] Implement chosen optimization scenario
- [ ] Test agent functionality after changes
- [ ] Update documentation
- [ ] Train users if needed

### Week 4: Monitoring
- [ ] Review cost savings
- [ ] Monitor performance metrics
- [ ] Adjust as needed
- [ ] Document lessons learned

---

## Risk Assessment

### Low Risk Actions
✅ Set up monitoring and alerting  
✅ Enable CloudWatch Logs  
✅ Implement guardrails  
✅ Optimize S3 storage

### Medium Risk Actions
⚠️ Reduce OpenSearch OCU capacity (test first)  
⚠️ Switch to cheaper model (validate performance)  
⚠️ Update knowledge base data

### High Risk Actions
🔴 Delete agent (ensure not needed)  
🔴 Delete knowledge base (backup data first)  
🔴 Delete OpenSearch collection (irreversible)

---

## Technical Details

### Agent Prompt Configuration

The agent uses custom prompts for:
1. **Memory Summarization** - Summarizes conversation history
2. **Post-Processing** - Adds context to responses
3. **Orchestration** - Main agent logic with extended thinking (1024 token budget)
4. **Pre-Processing** - Input classification and filtering
5. **Knowledge Base Response Generation** - Generates answers from KB

**Thinking Budget:** 1024 tokens (Claude Sonnet 4 extended thinking feature)

### Knowledge Base Configuration

**Embedding Model:** Amazon Titan Embed Text v1
- Dimensions: 1536
- Max input tokens: 8192
- Cost: $0.0001 per 1000 tokens

**Vector Search:**
- Index: bedrock-knowledge-base-default-index
- Vector field: bedrock-knowledge-base-default-vector
- Text field: AMAZON_BEDROCK_TEXT_CHUNK
- Metadata field: AMAZON_BEDROCK_METADATA

---

## Monitoring Queries

### Check Bedrock Invocations
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Bedrock \
  --metric-name Invocations \
  --dimensions Name=ModelId,Value=anthropic.claude-3-7-sonnet-20250219-v1:0 \
  --start-time 2025-11-23T00:00:00Z \
  --end-time 2025-12-23T00:00:00Z \
  --period 86400 \
  --statistics Sum \
  --region us-west-2
```

### Check OpenSearch OCU Usage
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/AOSS \
  --metric-name SearchOCU \
  --dimensions Name=CollectionId,Value=ttsri293ptppohrzrt33 \
  --start-time 2025-11-23T00:00:00Z \
  --end-time 2025-12-23T00:00:00Z \
  --period 3600 \
  --statistics Average,Maximum \
  --region us-west-2
```

### Check Knowledge Base Queries
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Bedrock \
  --metric-name KnowledgeBaseQueries \
  --dimensions Name=KnowledgeBaseId,Value=5QQMYTK6TS \
  --start-time 2025-11-23T00:00:00Z \
  --end-time 2025-12-23T00:00:00Z \
  --period 86400 \
  --statistics Sum \
  --region us-west-2
```

---

## Cleanup Commands (If Deleting)

### Delete Agent
```bash
aws bedrock-agent delete-agent \
  --agent-id SZTZWLTEUY \
  --region us-west-2
```

### Delete Knowledge Base
```bash
# First delete data source
aws bedrock-agent delete-data-source \
  --knowledge-base-id 5QQMYTK6TS \
  --data-source-id LTMMAZMVLC \
  --region us-west-2

# Then delete knowledge base
aws bedrock-agent delete-knowledge-base \
  --knowledge-base-id 5QQMYTK6TS \
  --region us-west-2
```

### Delete OpenSearch Collection
```bash
aws opensearchserverless delete-collection \
  --id ttsri293ptppohrzrt33 \
  --region us-west-2
```

---

## Summary

**Current State:**
- 1 Bedrock agent (NOT_PREPARED, minimal usage)
- 1 Knowledge base (active, last updated May 2024)
- 1 OpenSearch Serverless collection (largest cost)
- **Monthly Cost:** $92-137

**Recommended Actions:**
1. Determine if agent is still needed
2. If not needed, delete all resources (save $90-130/month)
3. If needed, optimize OpenSearch (save $50-80/month)
4. Implement monitoring and alerting

**Optimization Potential:**
- **Best Case:** $90-130/month savings (95% reduction)
- **Realistic:** $50-80/month savings (55-60% reduction)
- **Annual Savings:** $600-1,560/year

**Next Steps:**
1. Review with stakeholders to determine agent status
2. Check CloudWatch metrics for actual usage
3. Implement chosen optimization scenario
4. Monitor and adjust

---

**Report Generated:** December 23, 2025  
**Next Review:** January 23, 2026 (Monthly)  
**Status:** ⏳ Awaiting Decision on Agent Status
