# GitHub Setup Guide - Windows & WSL

## ✅ Step 1: Git Configuration (COMPLETE)

**Windows:**
- Username: agbangash
- Email: agbangash@gmail.com

**WSL:**
- Username: agbangash
- Email: agbangash@gmail.com

## Step 2: Generate GitHub Personal Access Token (PAT)

You need to create a Personal Access Token to authenticate with GitHub.

### Instructions:

1. **Go to GitHub Settings:**
   - Visit: https://github.com/settings/tokens
   - Or: GitHub.com → Click your profile → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Generate New Token:**
   - Click "Generate new token (classic)"
   - Give it a name: "Kiro-Clawbot-Access"
   - Set expiration: 90 days (or No expiration if you prefer)

3. **Select Scopes (Permissions):**
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
   - ✅ `write:packages` (Upload packages)
   - ✅ `read:org` (Read org and team membership)
   - ✅ `user:email` (Access user email addresses)

4. **Generate and Copy Token:**
   - Click "Generate token"
   - **IMPORTANT**: Copy the token immediately (you won't see it again!)
   - It looks like: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## Step 3: Configure Git Credential Manager

Once you have your token, come back and tell me:
"I have my GitHub token: ghp_xxxxx..."

I'll then configure both Windows and WSL to use it.

## Alternative: SSH Keys (More Secure)

If you prefer SSH keys instead of PAT:
1. Tell me "use SSH instead"
2. I'll generate SSH keys for both Windows and WSL
3. You'll add the public keys to GitHub

---
**Current Status**: Waiting for GitHub Personal Access Token
