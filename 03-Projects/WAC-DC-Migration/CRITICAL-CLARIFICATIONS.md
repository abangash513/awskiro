# WAC AD CUTOVER - CRITICAL CLARIFICATIONS

**Date**: February 7, 2026  
**IMPORTANT**: Read this before executing cutover

---

## QUESTION 1: Where to Run Scripts?

### ANSWER: Run on AWS (WACPRODDC01)

**ALL cutover scripts run on WACPRODDC01 (AWS DC)**

**Why?**
- FSMO roles are transferred TO the AWS DCs
- The Move-ADDirectoryServerOperationMasterRole command must run on the TARGET DC
- WACPRODDC01 will become the new PDC Emulator

**Execution Location**:
```
✓ Pre-cutover check: WACPRODDC01 (AWS)
✓ FSMO transfer: WACPRODDC01 (AWS)
✓ Post-cutover verify: WACPRODDC01 (AWS)
✗ Rollback: AD01 (On-Prem) - ONLY IF CUTOVER FAILS
```

**Connection Details**:
- Server: WACPRODDC01
- IP: 10.70.10.10
- Method: RDP
- User: Domain Admin
- Location: AWS VPC

---

## QUESTION 2: DNS Traffic Routing

### ANSWER: Active Directory Integrated DNS (NOT Route 53)

**Current DNS Setup**: Active Directory Integrated DNS

**How it works**:
1. **DNS is hosted ON the Domain Controllers themselves**
   - All 10 DCs host DNS zones
   - DNS zones replicate via AD replication
   - NOT using AWS Route 53
   - NOT using external DNS servers

2. **DNS Records** (from verification):
   - wac.net has 10 A records (one per DC)
   - 10.70.10.10 = WACPRODDC01 (AWS)
   - 10.70.11.10 = WACPRODDC02 (AWS)
   - 10.1.220.x = On-Prem DCs

3. **Client DNS Resolution**:
   - Clients query ANY DC for DNS
   - All DCs have identical DNS data (replicated)
   - Round-robin between all 10 DCs
   - Priority/Weight: All equal (0/100)

**After FSMO Transfer**:
- DNS continues working EXACTLY the same
- No DNS changes required
- No Route 53 involvement
- Clients continue using same DNS servers
- DNS replication continues via AD

**DNS Traffic Flow**:
```
Client Workstation
    ↓
    ↓ DNS Query (wac.net)
    ↓
Any DC (Round-robin):
    - WACPRODDC01 (AWS) ← Can answer
    - WACPRODDC02 (AWS) ← Can answer
    - AD01 (On-Prem) ← Can answer
    - AD02 (On-Prem) ← Can answer
    - [Other 6 DCs] ← Can answer
    ↓
    ↓ DNS Response
    ↓
Client Workstation
```

**Key Point**: 
- FSMO roles do NOT affect DNS
- DNS is distributed across all DCs
- No DNS routing changes needed
- No Route 53 configuration needed

---

## QUESTION 3: What Changes During Cutover?

### ANSWER: Only FSMO Role Ownership Changes

**What CHANGES**:
1. PDC Emulator: AD01 → WACPRODDC01
2. Schema Master: AD01 → WACPRODDC01
3. Domain Naming Master: AD01 → WACPRODDC01
4. RID Master: AD02 → WACPRODDC02
5. Infrastructure Master: AD02 → WACPRODDC02

**What DOES NOT CHANGE**:
- DNS records (stay the same)
- DNS servers (all 10 DCs still host DNS)
- Client DNS settings (no change)
- Replication topology (no change)
- Authentication (all DCs still authenticate)
- Group Policy (all DCs still serve GPOs)
- LDAP queries (all DCs still respond)
- Network routing (no change)
- Firewall rules (no change)

**Impact on Clients**: ZERO
- Clients don't know or care who holds FSMO roles
- Clients continue using any DC for authentication
- Clients continue using any DC for DNS
- No client configuration changes needed

---

## QUESTION 4: Network Traffic Flow

### ANSWER: Hybrid On-Prem + AWS (No Change)

**Current Network Setup**:
```
On-Premises Network (10.1.220.0/24)
    ↕ VPN/Direct Connect
AWS VPC (10.70.0.0/16)
```

**Client Authentication Flow** (No change after cutover):
```
Client Workstation (On-Prem or AWS)
    ↓
    ↓ Kerberos/LDAP Query
    ↓
Nearest DC (determined by site):
    - If on-prem client → Usually on-prem DC
    - If AWS client → Usually AWS DC
    - Can use ANY DC if needed
    ↓
    ↓ Authentication Response
    ↓
Client Workstation
```

**FSMO Operations** (Only when needed):
```
Any DC
    ↓
    ↓ FSMO Operation (rare)
    ↓
FSMO Role Holder:
    BEFORE: AD01/AD02 (On-Prem)
    AFTER: WACPRODDC01/02 (AWS)
    ↓
    ↓ FSMO Response
    ↓
Requesting DC
```

**Key Point**:
- FSMO operations are RARE (password changes, schema updates, etc.)
- 99.9% of traffic is authentication/DNS (any DC can handle)
- Network traffic patterns do NOT change
- No routing changes needed

---

## QUESTION 5: DNS Server Configuration

### ANSWER: Clients Use On-Prem DCs for DNS (No Change)

**Typical Client DNS Configuration**:
```
Primary DNS: 10.1.220.8 (AD01) or 10.1.220.9 (AD02)
Secondary DNS: 10.1.220.5 (WACHFDC01) or other on-prem DC
Tertiary DNS: 10.70.10.10 (WACPRODDC01) - optional
```

**After Cutover**:
- Client DNS settings: NO CHANGE
- Clients still query on-prem DCs first
- On-prem DCs still have all DNS records
- DNS replication ensures all DCs have same data

**Why No Change Needed?**
- DNS is replicated to ALL DCs
- AD01 still functions as DNS server (even without FSMO roles)
- FSMO roles don't affect DNS functionality
- Only affects who can make certain AD changes

---

## QUESTION 6: AWS Route 53 Involvement

### ANSWER: Route 53 is NOT Involved

**Route 53 is NOT used for**:
- Active Directory DNS
- Internal domain (wac.net)
- DC discovery
- Client authentication

**Route 53 MIGHT be used for** (separate from AD):
- External website DNS (if you have public websites)
- Public-facing services
- External DNS resolution

**For this cutover**:
- Route 53: NOT involved
- No Route 53 changes needed
- No Route 53 configuration required

---

## CORRECTED EXECUTION PLAN

### Step 1: Preparation (On your local machine)
1. Copy scripts from workspace to USB drive or network share
2. Prepare to RDP to WACPRODDC01

### Step 2: Connect to AWS DC
1. RDP to WACPRODDC01 (10.70.10.10)
2. Log in as Domain Admin
3. Copy scripts to C:\Cutover\ on WACPRODDC01

### Step 3: Execute Cutover (On WACPRODDC01)
1. Open C:\Cutover\
2. Right-click RUN-CUTOVER.bat
3. Select "Run as Administrator"
4. Follow prompts

### Step 4: Monitor (On WACPRODDC01)
1. Stay logged into WACPRODDC01
2. Run monitoring commands
3. Check logs in C:\Cutover\Logs\

### Step 5: Rollback (ONLY IF NEEDED)
1. RDP to AD01 (10.1.220.8) - On-Prem
2. Copy 4-ROLLBACK.ps1 to C:\Cutover\
3. Run RUN-ROLLBACK.bat
4. Follow prompts

---

## NETWORK DIAGRAM

### Current Setup (Before Cutover)
```
┌─────────────────────────────────────────────────────────┐
│ On-Premises Network (10.1.220.0/24)                     │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │   AD01   │  │   AD02   │  │ Other DCs│             │
│  │ (PDC+3)  │  │  (RID+1) │  │  (6 DCs) │             │
│  │10.1.220.8│  │10.1.220.9│  │          │             │
│  └──────────┘  └──────────┘  └──────────┘             │
│       ↑             ↑              ↑                    │
│       └─────────────┴──────────────┘                   │
│              AD Replication                             │
└─────────────────────────────────────────────────────────┘
                       ↕
              VPN/Direct Connect
                       ↕
┌─────────────────────────────────────────────────────────┐
│ AWS VPC (10.70.0.0/16)                                  │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │ WACPRODDC01  │  │ WACPRODDC02  │                    │
│  │   (No FSMO)  │  │   (No FSMO)  │                    │
│  │ 10.70.10.10  │  │ 10.70.11.10  │                    │
│  └──────────────┘  └──────────────┘                    │
│         ↑                 ↑                              │
│         └─────────────────┘                             │
│         AD Replication                                  │
└─────────────────────────────────────────────────────────┘
```

### After Cutover (Target State)
```
┌─────────────────────────────────────────────────────────┐
│ On-Premises Network (10.1.220.0/24)                     │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │   AD01   │  │   AD02   │  │ Other DCs│             │
│  │(No FSMO) │  │(No FSMO) │  │  (6 DCs) │             │
│  │10.1.220.8│  │10.1.220.9│  │          │             │
│  └──────────┘  └──────────┘  └──────────┘             │
│       ↑             ↑              ↑                    │
│       └─────────────┴──────────────┘                   │
│              AD Replication                             │
└─────────────────────────────────────────────────────────┘
                       ↕
              VPN/Direct Connect
                       ↕
┌─────────────────────────────────────────────────────────┐
│ AWS VPC (10.70.0.0/16)                                  │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │ WACPRODDC01  │  │ WACPRODDC02  │                    │
│  │  (PDC+2)     │  │   (RID+1)    │                    │
│  │ 10.70.10.10  │  │ 10.70.11.10  │                    │
│  └──────────────┘  └──────────────┘                    │
│         ↑                 ↑                              │
│         └─────────────────┘                             │
│         AD Replication                                  │
└─────────────────────────────────────────────────────────┘

Legend:
PDC+2 = PDC Emulator + Schema Master + Domain Naming Master
RID+1 = RID Master + Infrastructure Master
```

**What Changed**: Only FSMO role ownership  
**What Stayed Same**: Everything else (DNS, replication, authentication, network)

---

## DNS RESOLUTION EXAMPLE

### Before and After Cutover (IDENTICAL)

**Client queries: "What is the IP of fileserver.wac.net?"**

```
1. Client sends DNS query to configured DNS server
   (Usually AD01 or AD02 - on-prem DC)

2. DNS server responds with answer
   (DNS data is replicated to ALL DCs)

3. Client receives IP address

FSMO roles are NOT involved in this process!
```

**Client authenticates: "Let me log in"**

```
1. Client sends Kerberos request to nearest DC
   (Could be any of the 10 DCs)

2. DC authenticates user
   (All DCs can authenticate)

3. Client receives Kerberos ticket

FSMO roles are NOT involved in normal authentication!
```

**When FSMO roles ARE used**:
- User changes password → PDC Emulator contacted
- Schema update → Schema Master contacted
- Create new domain → Domain Naming Master contacted
- Create new user → RID Master contacted (for new SID)
- Update cross-domain references → Infrastructure Master contacted

**Frequency**: RARE (maybe 1-10 times per day across entire domain)

---

## SUMMARY OF CLARIFICATIONS

| Question | Answer |
|----------|--------|
| Where to run scripts? | WACPRODDC01 (AWS) |
| Where to run rollback? | AD01 (On-Prem) |
| DNS routing? | Active Directory Integrated DNS (all DCs) |
| Route 53 involved? | NO |
| Client DNS changes? | NO |
| Network routing changes? | NO |
| Impact on users? | ZERO |
| Traffic flow changes? | NO |

---

## UPDATED QUICK START

**Correct Execution Steps**:

1. **On your local machine**:
   - Copy scripts to USB or network share

2. **RDP to WACPRODDC01** (10.70.10.10):
   - Log in as Domain Admin
   - Copy scripts to C:\Cutover\

3. **On WACPRODDC01**:
   - Right-click RUN-CUTOVER.bat
   - Select "Run as Administrator"
   - Follow prompts

4. **Stay on WACPRODDC01**:
   - Monitor for 2 hours
   - Run verification commands

5. **If rollback needed**:
   - RDP to AD01 (10.1.220.8)
   - Run RUN-ROLLBACK.bat

---

## CRITICAL CORRECTIONS TO PLAN

The original plan is CORRECT. Scripts run on WACPRODDC01 (AWS).

**No corrections needed** - the plan already specifies:
- "Run on: WACPRODDC01 (AWS DC)"
- "Location: WACPRODDC01"
- "Verify running on WACPRODDC01"

**Rollback correctly specifies**:
- "Run on: AD01 (On-Prem DC)"
- "Only if cutover fails"

---

**CONFIRMED**: The plan is correct as written. Execute on WACPRODDC01 (AWS).
