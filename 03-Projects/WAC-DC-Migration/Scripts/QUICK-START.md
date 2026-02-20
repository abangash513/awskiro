# Quick Start Guide - WAC DC Verification

## 🚀 Super Simple Instructions

### Step 1: Copy Files to WACPRODDC01

1. Connect to WACPRODDC01 via RDP (make sure "Local drives" is enabled in RDP settings)
2. On WACPRODDC01, open File Explorer
3. Navigate to: `\\tsclient\C\` (this is your local C: drive)
4. Find your workspace folder and go to: `03-Projects\WAC-DC-Migration\Scripts\`
5. Copy ALL files to: `C:\Monitoring\WAC DC Cutover\` on the server

### Step 2: Fix Time Sync

1. On WACPRODDC01, go to: `C:\Monitoring\WAC DC Cutover\`
2. **Right-click** `1-Fix-Time-Sync.bat`
3. Select **"Run as Administrator"**
4. Wait for it to complete
5. Wait 5 minutes for time to sync

### Step 3: Run Verification

1. On WACPRODDC01, go to: `C:\Monitoring\WAC DC Cutover\`
2. **Right-click** `2-Run-Verification.bat`
3. Select **"Run as Administrator"**
4. Wait for all tests to complete
5. Note the log directory path shown at the end

### Step 4: Copy Results Back

1. On WACPRODDC01, open File Explorer
2. Go to: `C:\Setup\Logs\`
3. Find the newest folder starting with `QuickVerify-`
4. Copy it to: `\\tsclient\C\Users\YourUsername\Desktop\`
5. On your local machine, the results will be on your Desktop

### Step 5: Share Results with Me

1. Copy the verification results folder into your workspace:
   - From: Desktop
   - To: `03-Projects\WAC-DC-Migration\Reports\`
2. Let me know it's ready and I'll analyze the results

---

## 📋 What Each Script Does

### Fix-TimeSync-Simple.ps1
- Checks if DC is PDC Emulator
- Configures time source (external for PDC, domain for others)
- Forces time sync
- Shows current status

### Quick-Verification.ps1
- Runs 10 essential health checks
- Tests: DC discovery, DNS, time sync, replication, FSMO roles
- Creates detailed logs
- Shows pass/fail summary

---

## ⚠️ Troubleshooting

### "Access Denied" or "Cannot be loaded"
**Solution:** Right-click the .bat file and select "Run as Administrator"

### "Execution Policy" error
**Solution:** The .bat files handle this automatically. If you run .ps1 directly:
```powershell
Set-ExecutionPolicy Bypass -Scope Process
```

### Can't see \\tsclient\ in RDP
**Solution:** 
1. Disconnect from RDP
2. In Remote Desktop Connection, click "Show Options"
3. Go to "Local Resources" tab
4. Click "More..." under "Local devices and resources"
5. Check your C: drive
6. Reconnect

### Time sync still failing
**Check:**
1. Is NTP port (UDP 123) open in security groups?
2. Can you reach time.windows.com?
   ```powershell
   Test-NetConnection time.windows.com -Port 123
   ```
3. Is the PDC Emulator reachable?
   ```powershell
   netdom query fsmo
   Test-Connection <PDC-IP>
   ```

---

## 📁 Files You Need

**Essential files to copy to the server:**
- `Fix-TimeSync-Simple.ps1`
- `Quick-Verification.ps1`
- `1-Fix-Time-Sync.bat` (optional, makes it easier)
- `2-Run-Verification.bat` (optional, makes it easier)

**You can skip these (they're more complex):**
- `Fix-TimeSync.ps1` (original version)
- `Run-Enhanced-Verification.ps1` (20+ tests, overkill)

---

## ✅ Success Indicators

### Time Sync Fixed
```
Leap Indicator: 0(no warning)
Stratum: 2 or 3 (not 0 or "unspecified")
Last Successful Sync Time: <recent time>
Source: <not "Free-running System Clock">
```

### Verification Passed
```
Total Tests: 10
Passed: 10
Failed: 0
```

---

## 🆘 If You Get Stuck

1. Take a screenshot of the error
2. Copy the log files from `C:\Setup\Logs\`
3. Share them with me for analysis

---

**Last Updated:** 2026-02-07
