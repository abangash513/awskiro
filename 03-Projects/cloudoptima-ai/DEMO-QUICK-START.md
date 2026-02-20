# CloudOptima AI - Quick Demo Start

## 🚀 Fastest Way to Demo (30 seconds)

### Option 1: Automated Demo Launcher

```powershell
cd 03-Projects/cloudoptima-ai
.\open-demo.ps1
```

This will automatically open:
- Frontend application
- API documentation
- Health check endpoint

### Option 2: Run All Tests

```powershell
cd 03-Projects/cloudoptima-ai
.\run-demo-tests.ps1
```

This will test all 10 endpoints and show results.

---

## 🌐 Direct URLs

Just open these in your browser:

1. **Frontend:** http://52.179.209.239:3000
2. **API Docs:** http://52.179.209.239:8000/docs
3. **Health:** http://52.179.209.239:8000/health

---

## 📋 Quick PowerShell Tests

Copy and paste these one-liners:

```powershell
# Test everything is working
Invoke-RestMethod http://52.179.209.239:8000/health

# Get cost summary
Invoke-RestMethod http://52.179.209.239:8000/api/v1/costs/summary

# Get recommendations
Invoke-RestMethod http://52.179.209.239:8000/api/v1/recommendations/summary

# Open frontend in browser
Start-Process http://52.179.209.239:3000

# Open API docs in browser
Start-Process http://52.179.209.239:8000/docs
```

---

## 📚 Full Demo Guide

For detailed step-by-step instructions, see: **DEMO-GUIDE.md**

For deployment details, see: **DEPLOYMENT-SUCCESS-FINAL.md**

---

## ✅ What You'll See

### Empty Data (Initial State)
- All endpoints work but return empty data
- This is expected - no data has been ingested yet

### With Sample Data
- Follow Step 6 in DEMO-GUIDE.md to add sample data
- Then you'll see actual costs and recommendations

---

## 🎯 Key Demo Points

1. ✅ Application is deployed and running
2. ✅ All services are healthy
3. ✅ API endpoints respond correctly
4. ✅ Frontend is accessible
5. ✅ Database is operational
6. ✅ Interactive API documentation available

---

## 🆘 Need Help?

If something doesn't work:

```powershell
# Check service status
wsl ssh azureuser@52.179.209.239 "cd /opt/cloudoptima && docker-compose ps"

# Restart services
wsl ssh azureuser@52.179.209.239 "cd /opt/cloudoptima && docker-compose restart"

# Check logs
wsl ssh azureuser@52.179.209.239 "cd /opt/cloudoptima && docker-compose logs --tail=50 backend"
```

---

## 🎬 Ready to Demo!

Your CloudOptima AI application is fully deployed and ready to demonstrate!
