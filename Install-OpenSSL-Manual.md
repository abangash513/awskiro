# Manual OpenSSL Installation Guide
## No Administrator Rights Required

**Date**: January 20, 2026  
**User Directory**: C:\Users\Minip\OpenSSL

---

## Step 1: Download OpenSSL

**Download Link**: https://slproweb.com/products/Win32OpenSSL.html

**Which file to download:**
- Look for: **Win64 OpenSSL v3.x.x** (NOT the Light version)
- File name will be something like: `Win64OpenSSL-3_x_x.exe`
- File size: ~50-60 MB (the Light version is only ~5MB - don't use that one)

**Direct download link** (if available):
- https://slproweb.com/download/Win64OpenSSL-3_4_0.exe

---

## Step 2: Install OpenSSL

1. **Run the downloaded installer** (`Win64OpenSSL-3_x_x.exe`)

2. **Accept the license agreement**

3. **IMPORTANT - Change Installation Directory:**
   - Default will be: `C:\Program Files\OpenSSL-Win64` (requires admin)
   - **Change to**: `C:\Users\Minip\OpenSSL`
   - This is your user directory - no admin needed!

4. **Select Components:**
   - Keep all default selections
   - Make sure "OpenSSL binaries" is checked

5. **Select Additional Tasks:**
   - Choose: **"Copy OpenSSL DLLs to the OpenSSL binaries directory"**
   - This is important!

6. **Click Install**

7. **Wait for installation to complete**

8. **Click Finish**

---

## Step 3: Add OpenSSL to PATH (This Session)

After installation, run this in PowerShell:

```powershell
# Add OpenSSL to PATH for current session
$env:Path += ";C:\Users\Minip\OpenSSL\bin"
```

---

## Step 4: Verify Installation

```powershell
# Check if OpenSSL is accessible
openssl version

# Should show something like:
# OpenSSL 3.4.0 or similar
```

---

## Step 5: Make PATH Permanent (Optional)

If you want OpenSSL available in future PowerShell sessions:

```powershell
# Get current user PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)

# Add OpenSSL if not already there
if ($currentPath -notlike "*OpenSSL*") {
    $newPath = $currentPath + ";C:\Users\Minip\OpenSSL\bin"
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)
    Write-Host "OpenSSL added to user PATH permanently" -ForegroundColor Green
}
```

---

## Step 6: Run Phase 3 Implementation

Once OpenSSL is verified:

```powershell
# Navigate to workspace
cd C:\AWSKiro

# Run the Phase 3 implementation script
.\Phase3-Implementation-Steps.ps1
```

---

## Troubleshooting

### Issue: "openssl: command not found"

**Solution:**
```powershell
# Verify the installation directory exists
Test-Path "C:\Users\Minip\OpenSSL\bin\openssl.exe"

# If True, add to PATH again:
$env:Path += ";C:\Users\Minip\OpenSSL\bin"

# Try again:
openssl version
```

### Issue: "DLL not found" error

**Solution:**
- Reinstall OpenSSL
- Make sure you selected "Copy OpenSSL DLLs to the OpenSSL binaries directory" during installation

### Issue: Download link doesn't work

**Alternative download sites:**
- Official OpenSSL: https://www.openssl.org/source/
- GitHub releases: https://github.com/openssl/openssl/releases

---

## Quick Reference

**Installation Path**: `C:\Users\Minip\OpenSSL`  
**Binary Path**: `C:\Users\Minip\OpenSSL\bin`  
**Executable**: `C:\Users\Minip\OpenSSL\bin\openssl.exe`

**Add to PATH (temporary)**:
```powershell
$env:Path += ";C:\Users\Minip\OpenSSL\bin"
```

**Verify**:
```powershell
openssl version
```

**Next Step**:
```powershell
cd C:\AWSKiro
.\Phase3-Implementation-Steps.ps1
```

---

**Ready to proceed once OpenSSL is installed!**

