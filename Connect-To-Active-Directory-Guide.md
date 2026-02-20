# How to Connect to Active Directory on AWS Domain Controllers

**Environment:** Production  
**Domain:** wac.local  
**Domain Controllers:**
- WACPRODDC01: 10.70.10.10 (i-0745579f46a34da2e)
- WACPRODDC02: 10.70.11.10 (i-08c78db5cfc6eb412)

---

## Prerequisites

✅ VPN connected (you should have IP in 10.200.0.0/16 range)  
✅ Active Directory credentials (WAC domain account)  
✅ Connectivity verified (ping and RDP working)

---

## Method 1: RDP to Domain Controller (Easiest)

### Connect via RDP

```powershell
# Connect to DC1
mstsc /v:10.70.10.10

# Connect to DC2
mstsc /v:10.70.11.10
```

**Credentials:**
- Username: `WAC\your-username` or `your-username@wac.local`
- Password: Your Active Directory password

### Access AD Tools on the DC

Once logged in via RDP, you have full access to all AD tools:

#### Active Directory Users and Computers
```
Start Menu → Windows Administrative Tools → Active Directory Users and Computers
```
Or press `Windows Key + R` and type: `dsa.msc`

**Common Tasks:**
- Create/modify users and groups
- Reset passwords
- Manage organizational units (OUs)
- Delegate permissions
- View user properties

#### Active Directory Administrative Center
```
Start Menu → Windows Administrative Tools → Active Directory Administrative Center
```
Or press `Windows Key + R` and type: `dsac.exe`

**Features:**
- Modern interface
- PowerShell History Viewer
- Global Search
- Password Settings Objects (PSOs)

#### Group Policy Management
```
Start Menu → Windows Administrative Tools → Group Policy Management
```
Or press `Windows Key + R` and type: `gpmc.msc`

**Common Tasks:**
- Create/edit Group Policy Objects (GPOs)
- Link GPOs to OUs
- View GPO reports
- Manage Group Policy inheritance

#### Active Directory Sites and Services
Press `Windows Key + R` and type: `dssite.msc`

**Common Tasks:**
- Manage replication topology
- Configure site links
- Manage subnets

#### Active Directory Domains and Trusts
Press `Windows Key + R` and type: `domain.msc`

**Common Tasks:**
- Manage domain functional levels
- Configure trust relationships
- Manage UPN suffixes

#### DNS Manager
Press `Windows Key + R` and type: `dnsmgmt.msc`

**Common Tasks:**
- Manage DNS zones
- Create/modify DNS records
- Configure forwarders

---

## Method 2: RSAT Tools from Local Machine

Manage Active Directory from your local Windows machine without RDP.

### Step 1: Install RSAT Tools

#### Windows 10/11 (PowerShell as Administrator)

```powershell
# Install AD DS Tools
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

# Install Group Policy Management
Add-WindowsCapability -Online -Name Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0

# Install DNS Tools
Add-WindowsCapability -Online -Name Rsat.Dns.Tools~~~~0.0.1.0

# Install DHCP Tools (if needed)
Add-WindowsCapability -Online -Name Rsat.DHCP.Tools~~~~0.0.1.0

# Verify installation
Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat*" -and $_.State -eq "Installed"}
```

#### Windows 10/11 (GUI Method)

1. Open **Settings**
2. Go to **Apps** → **Optional Features**
3. Click **Add a feature**
4. Search for "RSAT"
5. Install:
   - RSAT: Active Directory Domain Services and Lightweight Directory Services Tools
   - RSAT: Group Policy Management Tools
   - RSAT: DNS Server Tools

### Step 2: Use RSAT Tools

After installation, you can run AD tools locally:

#### Active Directory Users and Computers

```powershell
# Launch the tool
dsa.msc
```

**Connect to Specific DC:**
1. Right-click "Active Directory Users and Computers" at the top
2. Select "Change Domain Controller..."
3. Enter: `10.70.10.10` or `wacproddc01.wac.local`
4. Click OK

**Or specify DC when launching:**
```powershell
# Connect to specific DC
dsa.msc /server=10.70.10.10
```

#### Group Policy Management

```powershell
# Launch the tool
gpmc.msc
```

#### DNS Manager

```powershell
# Launch the tool
dnsmgmt.msc
```

**Connect to DNS Server:**
1. Right-click "DNS" at the top
2. Select "Connect to DNS Server..."
3. Select "The following computer"
4. Enter: `10.70.10.10`
5. Click OK

---

## Method 3: PowerShell Remote Management

Manage AD using PowerShell commands from your local machine.

### Prerequisites

```powershell
# Verify RSAT AD module is installed
Get-Module -ListAvailable ActiveDirectory

# If not installed, install RSAT tools (see Method 2)
```

### Import AD Module

```powershell
# Import the Active Directory module
Import-Module ActiveDirectory
```

### Common AD PowerShell Commands

#### Get Domain Information

```powershell
# Get domain details
Get-ADDomain -Server 10.70.10.10

# Get forest information
Get-ADForest -Server 10.70.10.10

# Get all domain controllers
Get-ADDomainController -Filter * -Server 10.70.10.10

# Get specific DC info
Get-ADDomainController -Identity "WACPRODDC01" -Server 10.70.10.10
```

#### User Management

```powershell
# Get all users
Get-ADUser -Filter * -Server 10.70.10.10

# Get specific user
Get-ADUser -Identity "username" -Server 10.70.10.10 -Properties *

# Search for users
Get-ADUser -Filter {Name -like "*John*"} -Server 10.70.10.10

# Create new user
New-ADUser -Name "John Doe" `
    -GivenName "John" `
    -Surname "Doe" `
    -SamAccountName "jdoe" `
    -UserPrincipalName "jdoe@wac.local" `
    -Path "OU=Users,DC=wac,DC=local" `
    -AccountPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
    -Enabled $true `
    -Server 10.70.10.10

# Modify user
Set-ADUser -Identity "jdoe" -Title "Manager" -Server 10.70.10.10

# Reset password
Set-ADAccountPassword -Identity "jdoe" -Reset -NewPassword (ConvertTo-SecureString "NewP@ssw0rd!" -AsPlainText -Force) -Server 10.70.10.10

# Unlock account
Unlock-ADAccount -Identity "jdoe" -Server 10.70.10.10

# Disable user
Disable-ADAccount -Identity "jdoe" -Server 10.70.10.10

# Enable user
Enable-ADAccount -Identity "jdoe" -Server 10.70.10.10

# Delete user
Remove-ADUser -Identity "jdoe" -Server 10.70.10.10 -Confirm:$false
```

#### Group Management

```powershell
# Get all groups
Get-ADGroup -Filter * -Server 10.70.10.10

# Get specific group
Get-ADGroup -Identity "Domain Admins" -Server 10.70.10.10 -Properties *

# Get group members
Get-ADGroupMember -Identity "Domain Admins" -Server 10.70.10.10

# Create new group
New-ADGroup -Name "IT Team" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path "OU=Groups,DC=wac,DC=local" `
    -Server 10.70.10.10

# Add user to group
Add-ADGroupMember -Identity "IT Team" -Members "jdoe" -Server 10.70.10.10

# Remove user from group
Remove-ADGroupMember -Identity "IT Team" -Members "jdoe" -Server 10.70.10.10 -Confirm:$false
```

#### Organizational Unit (OU) Management

```powershell
# Get all OUs
Get-ADOrganizationalUnit -Filter * -Server 10.70.10.10

# Create new OU
New-ADOrganizationalUnit -Name "IT Department" `
    -Path "DC=wac,DC=local" `
    -Server 10.70.10.10

# Delete OU (must be empty or use -Recursive)
Remove-ADOrganizationalUnit -Identity "OU=IT Department,DC=wac,DC=local" -Server 10.70.10.10 -Confirm:$false
```

#### Computer Management

```powershell
# Get all computers
Get-ADComputer -Filter * -Server 10.70.10.10

# Get specific computer
Get-ADComputer -Identity "COMPUTER01" -Server 10.70.10.10 -Properties *

# Search for computers
Get-ADComputer -Filter {OperatingSystem -like "*Windows Server*"} -Server 10.70.10.10
```

#### Query AD Objects

```powershell
# Search for any AD object
Get-ADObject -Filter {Name -like "*test*"} -Server 10.70.10.10

# Get deleted objects (AD Recycle Bin)
Get-ADObject -Filter {IsDeleted -eq $true} -IncludeDeletedObjects -Server 10.70.10.10
```

### PowerShell Remoting to DC

```powershell
# Create remote session to DC
$session = New-PSSession -ComputerName 10.70.10.10 -Credential (Get-Credential)

# Run commands on DC
Invoke-Command -Session $session -ScriptBlock {
    Import-Module ActiveDirectory
    Get-ADUser -Filter * | Select-Object Name, Enabled
}

# Close session
Remove-PSSession $session
```

---

## Method 4: AWS Systems Manager (SSM)

Access Domain Controller via AWS Systems Manager Session Manager.

### Start SSM Session

```powershell
# Connect to DC1
aws ssm start-session --target i-0745579f46a34da2e --region us-west-2

# Connect to DC2
aws ssm start-session --target i-08c78db5cfc6eb412 --region us-west-2
```

### Use PowerShell in SSM Session

Once connected:

```powershell
# Switch to PowerShell
powershell

# Import AD module
Import-Module ActiveDirectory

# Run AD commands (no need to specify -Server since you're on the DC)
Get-ADDomain
Get-ADUser -Filter *
Get-ADGroup -Filter *
```

### Run Commands via SSM Without Interactive Session

```powershell
# Run a single command on DC
aws ssm send-command `
    --instance-ids i-0745579f46a34da2e `
    --document-name "AWS-RunPowerShellScript" `
    --parameters 'commands=["Import-Module ActiveDirectory; Get-ADUser -Filter * | Select-Object Name, Enabled"]' `
    --region us-west-2 `
    --query 'Command.CommandId' `
    --output text

# Get command results (replace COMMAND-ID with actual ID from above)
aws ssm get-command-invocation `
    --command-id COMMAND-ID `
    --instance-id i-0745579f46a34da2e `
    --region us-west-2 `
    --query 'StandardOutputContent' `
    --output text
```

---

## Method 5: LDAP/LDAPS Connection

Connect to AD using LDAP protocol (for applications or scripts).

### Connection Details

| Property | Value |
|----------|-------|
| **LDAP Server** | 10.70.10.10 or 10.70.11.10 |
| **LDAP Port** | 389 (LDAP) or 636 (LDAPS) |
| **Base DN** | DC=wac,DC=local |
| **Bind DN** | CN=username,CN=Users,DC=wac,DC=local |

### Test LDAP Connection (PowerShell)

```powershell
# Test LDAP connection
$ldapServer = "10.70.10.10"
$ldapPort = 389
$baseDN = "DC=wac,DC=local"

$connection = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$ldapServer/$baseDN", "username", "password")

if ($connection.Name) {
    Write-Host "LDAP connection successful!" -ForegroundColor Green
    Write-Host "Connected to: $($connection.Name)"
} else {
    Write-Host "LDAP connection failed!" -ForegroundColor Red
}
```

### Test LDAPS (Secure LDAP)

```powershell
# Test LDAPS connection
$ldapServer = "10.70.10.10"
$ldapPort = 636
$baseDN = "DC=wac,DC=local"

$connection = New-Object System.DirectoryServices.DirectoryEntry("LDAPS://$ldapServer:$ldapPort/$baseDN", "username", "password")

if ($connection.Name) {
    Write-Host "LDAPS connection successful!" -ForegroundColor Green
} else {
    Write-Host "LDAPS connection failed!" -ForegroundColor Red
}
```

---

## Troubleshooting

### Cannot Connect to AD

**Check VPN Connection:**
```powershell
# Verify VPN IP
ipconfig | Select-String "10.200"

# Test connectivity to DC
Test-NetConnection -ComputerName 10.70.10.10 -Port 389
Test-NetConnection -ComputerName 10.70.10.10 -Port 636
Test-NetConnection -ComputerName 10.70.10.10 -Port 3389
```

**Check DNS Resolution:**
```powershell
# Test DNS resolution
nslookup wacproddc01.wac.local 10.70.0.2
nslookup wac.local 10.70.0.2
```

### RSAT Tools Not Working

**Verify Installation:**
```powershell
# Check if RSAT is installed
Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat*"}

# Reinstall if needed
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
```

**Check Module:**
```powershell
# Verify AD module
Get-Module -ListAvailable ActiveDirectory

# Import module
Import-Module ActiveDirectory -Verbose
```

### Access Denied Errors

**Verify Credentials:**
- Ensure you're using the correct domain format: `WAC\username`
- Check if account is enabled and not locked
- Verify account has appropriate permissions

**Check Account Status:**
```powershell
# Check your account status (run on DC or with RSAT)
Get-ADUser -Identity "your-username" -Properties * -Server 10.70.10.10 | Select-Object Name, Enabled, LockedOut, PasswordExpired
```

### PowerShell Remoting Issues

**Enable PowerShell Remoting (if needed):**
```powershell
# On the DC (via RDP or SSM)
Enable-PSRemoting -Force

# Configure TrustedHosts (if not domain-joined)
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "10.70.10.10,10.70.11.10" -Force
```

---

## Security Best Practices

### When Using RDP

1. ✅ Always disconnect (don't just close window)
2. ✅ Lock screen when stepping away
3. ✅ Use strong passwords
4. ✅ Enable MFA if available
5. ✅ Disconnect VPN when done

### When Using PowerShell

1. ✅ Never store passwords in scripts
2. ✅ Use `Get-Credential` for interactive password entry
3. ✅ Use secure strings for passwords
4. ✅ Log all administrative actions
5. ✅ Follow least privilege principle

### When Managing AD

1. ✅ Test changes in Dev environment first
2. ✅ Document all changes
3. ✅ Follow change management procedures
4. ✅ Use separate admin accounts (not your regular account)
5. ✅ Review audit logs regularly

---

## Quick Reference Commands

### Connection Tests
```powershell
# Test RDP
mstsc /v:10.70.10.10

# Test LDAP
Test-NetConnection -ComputerName 10.70.10.10 -Port 389

# Test LDAPS
Test-NetConnection -ComputerName 10.70.10.10 -Port 636

# Test DNS
nslookup wac.local 10.70.0.2
```

### Launch AD Tools
```powershell
# Active Directory Users and Computers
dsa.msc

# Active Directory Administrative Center
dsac.exe

# Group Policy Management
gpmc.msc

# Active Directory Sites and Services
dssite.msc

# Active Directory Domains and Trusts
domain.msc

# DNS Manager
dnsmgmt.msc
```

### PowerShell Quick Commands
```powershell
# Import AD module
Import-Module ActiveDirectory

# Get domain info
Get-ADDomain -Server 10.70.10.10

# Get all users
Get-ADUser -Filter * -Server 10.70.10.10

# Get all groups
Get-ADGroup -Filter * -Server 10.70.10.10

# Get all computers
Get-ADComputer -Filter * -Server 10.70.10.10
```

---

## Support

**For AD Issues:**
- Domain Administrators
- Identity Management Team

**For VPN/Connectivity Issues:**
- AWS Administrator
- Network Team

**For Security Concerns:**
- Security Team (immediate)
- Compliance Team

---

**Environment:** Production  
**Last Updated:** February 1, 2026  
**Maintained By:** AWS Administration Team

---

**⚠️ PRODUCTION ENVIRONMENT - HANDLE WITH CARE ⚠️**

**END OF GUIDE**
