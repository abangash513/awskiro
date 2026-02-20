# EBS Volumes - Complete Analysis Report
**Account:** Charles Mount (198161015548)  
**Analysis Date:** December 3, 2025  
**Total Monthly EBS Cost:** ~$14,443/month

---

## 📊 EXECUTIVE SUMMARY

### Overall Statistics:
- **Total EBS Volumes:** 179
- **Total Storage:** 144,426 GB (144.4 TB)
- **Attached Volumes:** 108 (60%)
- **Unattached Volumes:** 71 (40%) ⚠️
- **Monthly Cost:** ~$14,443

### Volume Type Breakdown:
- **GP3 (Modern):** 121 volumes (68%) - 107,896 GB
- **GP2 (Legacy):** 45 volumes (25%) - 2,490 GB
- **SC1 (Cold HDD):** 13 volumes (7%) - 34,040 GB

### Critical Issues:
- 🔴 **71 unattached volumes** (49.2 TB) - Wasting $4,920/month!
- 🔴 **45 GP2 volumes** - Should migrate to GP3 (save $50/month)
- 🔴 **0 snapshots found** - No backup strategy! ⚠️
- 🔴 **0 lifecycle policies** - No automated management
- 🔴 **Only 7 encrypted volumes** (4%) - Security risk!

---

## 📍 BREAKDOWN BY REGION

### us-east-1 (Primary Region)
- **Volumes:** 127
- **Storage:** 107,896 GB (107.9 TB)
- **Attached:** 77
- **Unattached:** 50 ⚠️
- **Cost:** ~$10,790/month

### us-east-2
- **Volumes:** 17
- **Storage:** 1,690 GB (1.7 TB)
- **Attached:** 6
- **Unattached:** 11 ⚠️
- **Cost:** ~$169/month

### us-west-1
- **Vo