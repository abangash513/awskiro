# How to Get a GitHub Personal Access Token

## Step-by-Step Instructions

### Step 1: Go to GitHub Settings
1. Open your browser
2. Go to: **https://github.com/settings/tokens**
   - Or: Click your profile picture (top right) → Settings → Developer settings → Personal access tokens → Tokens (classic)

### Step 2: Generate New Token
1. Click the green button: **"Generate new token"**
2. Select: **"Generate new token (classic)"**

### Step 3: Configure Token
1. **Note**: Enter a name like "Kiro-Clawbot-Access"
2. **Expiration**: Select "90 days" (or "No expiration" if you prefer)

### Step 4: Select Permissions (CRITICAL!)

Scroll down and check these boxes:

✅ **repo** (Full control of private repositories)
   - This will automatically check all sub-items:
     - repo:status
     - repo_deployment
     - public_repo
     - repo:invite
     - security_events

✅ **workflow** (Update GitHub Action workflows)

✅ **write:packages** (Upload packages)

✅ **delete:packages** (Delete packages)

✅ **admin:org** (Full control of orgs and teams) - Optional

✅ **user** (Update ALL user data) - Optional

### Step 5: Generate Token
1. Scroll to the bottom
2. Click the green button: **"Generate token"**

### Step 6: Copy Token
1. You'll see a green box with your token
2. It starts with `ghp_` or `github_pat_`
3. **IMPORTANT**: Copy it NOW - you won't see it again!
4. Example: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### Step 7: Give Me the Token
Paste the token here in chat:
```
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## Quick Link
👉 **Direct link**: https://github.com/settings/tokens/new

---

## What I'll Do With It
Once you give me the token, I'll:
1. Update WSL git credentials
2. Update Windows git credentials  
3. Push your clawd repository to GitHub
4. Push your AWSKiro repository to GitHub

---

## Security Note
- This token gives access to your GitHub repositories
- Keep it private (don't share publicly)
- You can revoke it anytime at: https://github.com/settings/tokens
