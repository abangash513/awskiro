# Quick Test - CloudOptima AI

## 🚀 One-Command Test

```powershell
cd 03-Projects/cloudoptima-ai
.\run-demo-tests.ps1
```

## 🌐 Open in Browser

```powershell
# API Documentation (Interactive)
Start-Process 'http://52.179.209.239:8000/docs'

# Frontend Application
Start-Process 'http://52.179.209.239:3000'
```

## 📊 View Sample Data

### Get All Recommendations
```powershell
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/"
```

**Expected Result**: 5 recommendations with total savings of $627.85/month

### Get Cost Summary
```powershell
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/costs/summary"
```

**Expected Result**: Total cost of $2,878.60 across 5 Azure services

### Get Recommendations Summary
```powershell
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/summary"
```

**Expected Result**: 
- 5 total recommendations
- $627.85 monthly savings potential
- $7,534.20 annual savings potential

## ✅ What You Should See

### Cost Data
- ✅ 20 cost records loaded
- ✅ 5 Azure services (VMs, SQL, Storage, App Service, AKS)
- ✅ Total: $2,878.60 USD

### Recommendations
- ✅ 5 optimization recommendations
- ✅ Detailed savings calculations
- ✅ Implementation steps for each

### Budgets
- ✅ 3 budget configurations
- ✅ Current spend tracking
- ✅ Alert thresholds

## 🔑 Important: No Login Required

This POC has **NO AUTHENTICATION**. All endpoints are public. No username or password needed.

## 📝 Full Documentation

- `TESTING-GUIDE.md` - Complete testing instructions
- `MOCK-DATA-SUMMARY.md` - Data overview
- `DEMO-GUIDE.md` - Step-by-step demo walkthrough

## 🔄 Reload Data

If you need to reload the mock data:
```powershell
.\load-mock-data.ps1
```

## 🎯 Application URLs

- **Frontend**: http://52.179.209.239:3000
- **Backend API**: http://52.179.209.239:8000
- **API Docs**: http://52.179.209.239:8000/docs
- **Health Check**: http://52.179.209.239:8000/health
