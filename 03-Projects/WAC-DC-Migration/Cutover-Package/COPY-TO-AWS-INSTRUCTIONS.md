# HOW TO COPY CUTOVER PACKAGE TO AWS

**Goal**: Copy this entire folder to WACPRODDC01 for execution

---

## METHOD 1: RDP with Drive Sharing (EASIEST)

### Step 1: Enable Drive Sharing in RDP
1. Open **Remote Desktop Connection** on your local machine
2. Click **Show Options**
3. Go to **Local Resources** tab
4. Click **More...** under "Local devices and resources"
5. Check **Drives** (or select specific drive)
6. Click **OK**

### Step 2: Connect to WACPRODDC01
1. Enter computer: **10.70.10.10**
2. Enter username: **WAC\Administrator** (or your Domain Admin)
3. Click **Connect**
4. Enter password
5. Log in

### Step 3: Copy Files
On WACPRODDC01:
```
1. Open File Explorer
2. Navigate to \\tsclient\C\ (your local C: drive)
3. Find: AWSKiro\03-Projects\WAC-DC-Migration\Cutover-Package\
4. Copy the entire "Cutover-Package" folder
5. Paste to C:\ on WACPRODDC01
6. Rename to "Cutover" (optional, or keep as "Cutover-Package")
```

### Step 4: Verify
On WACPRODDC01:
```
1. Open C:\Cutover\ (or C:\Cutover-Package\)
2. Verify you see:
   - README.md
   - START-HERE.md
   - Documentation\ folder
   - Scripts\ folder
   - Reports\ folder
```

---

## METHOD 2: Copy via Network Share

### Step 1: Create Temporary Share
On your local machine:
```powershell
# Create share
New-SmbShare -Name "CutoverTemp" -Path "C:\AWSKiro\03-Projects\WAC-DC-Migration\Cutover-Package" -ReadAccess "Everyone"

# Note your computer name
$env:COMPUTERNAME
```

### Step 2: Copy from WACPRODDC01
On WACPRODDC01:
```powershell
# Replace YOUR_COMPUTER_NAME with your actual computer name
Copy-Item "\\YOUR_COMPUTER_NAME\CutoverTemp\*" -Destination "C:\Cutover\" -Recurse -Force
```

### Step 3: Remove Share
On your local machine:
```powershell
Remove-SmbShare -Name "CutoverTemp" -Force
```

---

## METHOD 3: USB Drive (If RDP Doesn't Work)

### Step 1: Copy to USB
On your local machine:
```
1. Insert USB drive
2. Copy entire "Cutover-Package" folder to USB
3. Safely eject USB
```

### Step 2: Physical Access
```
1. Take USB to data center (if WACPRODDC01 is physical)
2. Or attach USB to VM (if WACPRODDC01 is virtual)
```

### Step 3: Copy from USB
On WACPRODDC01:
```
1. Insert/attach USB
2. Copy "Cutover-Package" folder to C:\
3. Rename to "Cutover" (optional)
```

---

## METHOD 4: AWS S3 (If Available)

### Step 1: Upload to S3
On your local machine:
```powershell
# Compress folder
Compress-Archive -Path "C:\AWSKiro\03-Projects\WAC-DC-Migration\Cutover-Package" -DestinationPath "C:\Temp\Cutover-Package.zip"

# Upload to S3 (requires AWS CLI)
aws s3 cp "C:\Temp\Cutover-Package.zip" s3://your-bucket/cutover/
```

### Step 2: Download on WACPRODDC01
On WACPRODDC01:
```powershell
# Download from S3
aws s3 cp s3://your-bucket/cutover/Cutover-Package.zip C:\Temp\

# Extract
Expand-Archive -Path "C:\Temp\Cutover-Package.zip" -DestinationPath "C:\"

# Rename
Rename-Item "C:\Cutover-Package" "C:\Cutover"
```

---

## VERIFICATION CHECKLIST

After copying, verify on WACPRODDC01:

```powershell
# Check folder exists
Test-Path "C:\Cutover"

# Count files
(Get-ChildItem "C:\Cutover" -Recurse -File).Count
# Should be approximately 15-20 files

# Check key files exist
Test-Path "C:\Cutover\README.md"
Test-Path "C:\Cutover\START-HERE.md"
Test-Path "C:\Cutover\Scripts\RUN-CUTOVER.bat"
Test-Path "C:\Cutover\Scripts\1-PRE-CUTOVER-CHECK.ps1"
Test-Path "C:\Cutover\Scripts\2-EXECUTE-CUTOVER.ps1"
Test-Path "C:\Cutover\Scripts\3-POST-CUTOVER-VERIFY.ps1"
Test-Path "C:\Cutover\Scripts\4-ROLLBACK.ps1"

# List all files
Get-ChildItem "C:\Cutover" -Recurse | Select-Object FullName
```

Expected output:
```
C:\Cutover\README.md
C:\Cutover\START-HERE.md
C:\Cutover\COPY-TO-AWS-INSTRUCTIONS.md
C:\Cutover\Documentation\01-CRITICAL-CLARIFICATIONS.md
C:\Cutover\Documentation\02-CUTOVER-SUMMARY.md
C:\Cutover\Documentation\03-CUTOVER-EXECUTION-PLAN.md
C:\Cutover\Documentation\04-CUTOVER-CHECKLIST.md
C:\Cutover\Documentation\05-DECOMMISSION-PLAN.md
C:\Cutover\Documentation\06-GO-NO-GO-REPORT.md
C:\Cutover\Documentation\07-INDEX.md
C:\Cutover\Scripts\RUN-CUTOVER.bat
C:\Cutover\Scripts\RUN-ROLLBACK.bat
C:\Cutover\Scripts\1-PRE-CUTOVER-CHECK.ps1
C:\Cutover\Scripts\2-EXECUTE-CUTOVER.ps1
C:\Cutover\Scripts\3-POST-CUTOVER-VERIFY.ps1
C:\Cutover\Scripts\4-ROLLBACK.ps1
C:\Cutover\Scripts\Demote-DC.ps1
C:\Cutover\Scripts\Cleanup-DC-Metadata.ps1
C:\Cutover\Reports\AD01-Verification-Analysis.md
```

---

## TROUBLESHOOTING

### Issue: RDP drive sharing not working
**Solution**: Use Method 2 (Network Share) or Method 3 (USB)

### Issue: Network share access denied
**Solution**: 
1. Check firewall allows SMB (port 445)
2. Verify credentials
3. Try Method 1 (RDP) or Method 3 (USB)

### Issue: Files won't copy (access denied)
**Solution**: 
1. Run as Administrator
2. Check NTFS permissions
3. Try copying to different location first, then move

### Issue: Scripts blocked by execution policy
**Solution**: 
```powershell
# On WACPRODDC01, unblock files
Get-ChildItem "C:\Cutover\Scripts\*.ps1" | Unblock-File
```

---

## NEXT STEPS

After copying and verifying:

1. **Read**: C:\Cutover\START-HERE.md
2. **Review**: C:\Cutover\Documentation\01-CRITICAL-CLARIFICATIONS.md
3. **Execute**: C:\Cutover\Scripts\RUN-CUTOVER.bat

---

## RECOMMENDED: RDP with Drive Sharing

**Why?**
- Easiest method
- No network configuration needed
- No USB required
- Direct copy from your machine

**How?**
1. Enable drive sharing in RDP settings
2. Connect to WACPRODDC01
3. Copy from \\tsclient\C\ to C:\Cutover\
4. Done!

---

**Questions?** See README.md or START-HERE.md in the Cutover-Package folder.

**Ready?** Copy the folder and start the cutover!
