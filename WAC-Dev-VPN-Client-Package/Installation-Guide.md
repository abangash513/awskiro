# WAC Dev VPN - Installation Guide

Complete step-by-step instructions for installing and configuring the AWS VPN Client.

---

## Table of Contents
1. [Windows Installation](#windows-installation)
2. [macOS Installation](#macos-installation)
3. [Linux Installation](#linux-installation)
4. [Profile Configuration](#profile-configuration)
5. [Verification](#verification)

---

## Windows Installation

### Step 1: Download AWS VPN Client

1. Open your web browser
2. Navigate to: https://d20adtppz83p9s.cloudfront.net/WPF/latest/AWS_VPN_Client.msi
3. Save the installer to your Downloads folder

### Step 2: Install the Client

1. Locate `AWS_VPN_Client.msi` in your Downloads folder
2. **Right-click** → **Run as administrator**
3. Click **Yes** when prompted by User Account Control
4. Follow the installation wizard:
   - Click **Next**
   - Accept the license agreement
   - Choose installation location (default is recommended)
   - Click **Install**
5. Wait for installation to complete
6. Click **Finish**

### Step 3: Verify Installation

1. Press **Windows Key** and type "AWS VPN"
2. You should see "AWS VPN Client" in the results
3. Click to launch the application

---

## macOS Installation

### Step 1: Download AWS VPN Client

1. Open Safari or your preferred browser
2. Navigate to: https://d20adtppz83p9s.cloudfront.net/OSX/latest/AWS_VPN_Client.pkg
3. Save the installer to your Downloads folder

### Step 2: Install the Client

1. Open Finder → Downloads
2. Double-click `AWS_VPN_Client.pkg`
3. Click **Continue** on the introduction screen
4. Click **Continue** to accept the license
5. Click **Agree**
6. Click **Install**
7. Enter your Mac password when prompted
8. Wait for installation to complete
9. Click **Close**

### Step 3: Grant Permissions

1. Open **System Preferences** → **Security & Privacy**
2. Click the **Privacy** tab
3. Select **Full Disk Access** from the left sidebar
4. Click the lock icon and enter your password
5. Click **+** and add AWS VPN Client
6. Restart the AWS VPN Client application

---

## Linux Installation (Ubuntu/Debian)

### Step 1: Download AWS VPN Client

```bash
cd ~/Downloads
wget https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_amd64.deb
```

### Step 2: Install Dependencies

```bash
sudo apt update
sudo apt install -y openvpn network-manager-openvpn network-manager-openvpn-gnome
```

### Step 3: Install the Client

```bash
sudo dpkg -i awsvpnclient_amd64.deb
sudo apt-get install -f
```

### Step 4: Launch the Client

```bash
/opt/awsvpnclient/AWS\ VPN\ Client &
```

Or search for "AWS VPN Client" in your application menu.

---

## Profile Configuration

### Step 1: Locate Your VPN Configuration File

Ensure you have the file: **wac-dev-admin-vpn-FIXED.ovpn**

**Important:** Use the FIXED version, not the original file.

### Step 2: Import the Profile

#### Windows & macOS:

1. Launch **AWS VPN Client**
2. Click **File** → **Manage Profiles**
3. Click **Add Profile**
4. Click **Browse** next to "VPN Configuration File"
5. Navigate to `wac-dev-admin-vpn-FIXED.ovpn`
6. Select the file and click **Open**
7. In the **Display Name** field, enter: `WAC Dev Admin VPN`
8. Click **Add Profile**
9. Click **Done**

#### Linux:

1. Launch AWS VPN Client
2. Click the menu icon (three horizontal lines)
3. Select **Manage Profiles**
4. Click **Add Profile**
5. Browse to `wac-dev-admin-vpn-FIXED.ovpn`
6. Display Name: `WAC Dev Admin VPN`
7. Click **Add Profile**

### Step 3: Verify Profile Import

You should now see "WAC Dev Admin VPN" in your profile list with:
- Status: Ready to connect
- Server: cvpn-endpoint-02fbfb0cd399c382c.prod.clientvpn.us-west-2.amazonaws.com

---

## Verification

### Test Connection

1. Select **WAC Dev Admin VPN** from the profile list
2. Click **Connect**
3. Wait 10-30 seconds for connection to establish
4. Look for **green status indicator** and "Connected" message

### Verify Network Access

#### Check VPN IP Address:

**Windows:**
```cmd
ipconfig | findstr "10.100"
```

**macOS/Linux:**
```bash
ifconfig | grep "10.100"
```

You should see an IP address in the 10.100.0.0/16 range.

#### Test Connectivity to Dev VPC:

```bash
ping 10.60.0.2
```

This should successfully ping the DNS server in the Dev VPC.

---

## Troubleshooting Installation

### Windows Issues

**"Windows protected your PC" message:**
- Click **More info**
- Click **Run anyway**
- This is normal for MSI installers

**Installation fails:**
- Ensure you're running as Administrator
- Disable antivirus temporarily
- Check you have 100MB free disk space

### macOS Issues

**"Cannot open because it is from an unidentified developer":**
- Open **System Preferences** → **Security & Privacy**
- Click **Open Anyway** next to the AWS VPN Client message
- Enter your password

**Installation requires password:**
- This is normal - enter your Mac admin password
- The VPN client needs system-level access

### Linux Issues

**Dependency errors:**
```bash
sudo apt-get install -f
```

**Permission denied:**
- Ensure you're using `sudo` for installation commands
- Check you're in the sudoers group

**Client won't launch:**
```bash
sudo chmod +x /opt/awsvpnclient/AWS\ VPN\ Client
```

---

## Post-Installation Configuration

### Windows Firewall

If prompted by Windows Firewall:
1. Check **both** "Private networks" and "Public networks"
2. Click **Allow access**

### macOS Firewall

If prompted:
1. Click **Allow**
2. Enter your password if requested

### Linux Firewall (UFW)

```bash
sudo ufw allow 443/udp
sudo ufw reload
```

---

## Auto-Start Configuration (Optional)

### Windows

1. Press **Windows Key + R**
2. Type: `shell:startup`
3. Press **Enter**
4. Create a shortcut to AWS VPN Client in this folder

### macOS

1. Open **System Preferences** → **Users & Groups**
2. Select your user account
3. Click **Login Items** tab
4. Click **+** and add AWS VPN Client

### Linux

Add to startup applications through your desktop environment's settings.

---

## Uninstallation (If Needed)

### Windows

1. Open **Settings** → **Apps**
2. Search for "AWS VPN Client"
3. Click **Uninstall**
4. Follow the prompts

### macOS

1. Open **Finder** → **Applications**
2. Drag **AWS VPN Client** to Trash
3. Empty Trash
4. Remove configuration files:
```bash
rm -rf ~/Library/Application\ Support/AWSVPNClient
```

### Linux

```bash
sudo apt remove awsvpnclient
sudo apt autoremove
```

---

## Next Steps

After successful installation:

1. ✅ Review the **Connection-Guide.md** for usage instructions
2. ✅ Test connectivity to Dev environment resources
3. ✅ Bookmark this guide for future reference
4. ✅ Configure auto-connect if desired

---

## Support

If you encounter issues during installation:

1. Check the troubleshooting section above
2. Verify system requirements are met
3. Review CloudWatch logs: `/aws/clientvpn/dev-admin-vpn`
4. Contact your AWS administrator

---

**Guide Version:** 1.0  
**Last Updated:** January 31, 2026  
**Tested On:** Windows 11, macOS 14, Ubuntu 22.04
