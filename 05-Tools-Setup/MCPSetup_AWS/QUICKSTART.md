# Quick Start Guide - AWS MCP Setup

## 3-Step Installation

### Step 1: Check Prerequisites
```powershell
.\download-prerequisites.ps1
```

**Required Software**:
- Node.js (v18+): https://nodejs.org/
- Git: https://git-scm.com/
- AWS CLI: https://aws.amazon.com/cli/

### Step 2: Install MCP Servers
```powershell
.\install-aws-mcp-servers.ps1
```

This downloads and installs:
- AWS KB Retrieval Server
- AWS MCP Server (Official)
- AWS Diagram as Code Server

### Step 3: Configure Claude Desktop
```powershell
.\configure-mcp-claude.ps1
```

Then restart Claude Desktop.

---

## What You Get

### 1. AWS Documentation Access
Ask Claude about AWS services, best practices, and troubleshooting.

**Example**: "What are S3 security best practices?"

### 2. AWS Service Control
Interact with your AWS resources directly through Claude.

**Example**: "List my EC2 instances in us-east-1"

### 3. Architecture Diagrams
Generate AWS architecture diagrams from descriptions.

**Example**: "Create a diagram for a serverless web application with API Gateway, Lambda, and DynamoDB"

---

## Verify Installation

1. Open Claude Desktop
2. Look for MCP indicator (usually in settings or status bar)
3. Try: "List available MCP servers"
4. Test: "Show me AWS Lambda best practices"

---

## Common Issues

**Node.js not found**
- Install from https://nodejs.org/
- Restart PowerShell after installation

**Git not found**
- Install from https://git-scm.com/
- Restart PowerShell after installation

**AWS credentials error**
- Run: `aws configure`
- Enter your AWS Access Key ID and Secret Access Key

**Claude Desktop not detecting MCP**
- Verify config file exists: `%APPDATA%\Claude\claude_desktop_config.json`
- Restart Claude Desktop completely
- Check MCP servers are running

---

## Next Steps

1. Read `mcp-servers-list.md` for detailed server capabilities
2. Check `README.md` for comprehensive documentation
3. Explore AWS architecture diagram examples
4. Configure additional AWS profiles if needed

---

## Support

- MCP Documentation: https://modelcontextprotocol.io/
- AWS Samples: https://github.com/aws-samples/
- Report issues to respective GitHub repositories
