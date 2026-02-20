# AWS MCP Servers Setup Guide

## Overview
This guide helps you set up AWS Model Context Protocol (MCP) servers for enhanced AWS integration and architectural diagram design.

## Prerequisites

### Required Software
1. **Node.js** (v18 or higher) - Download from: https://nodejs.org/
2. **Python** (3.10+) - Download from: https://www.python.org/downloads/
3. **AWS CLI** - Already configured with profiles
4. **Git** - Download from: https://git-scm.com/

## AWS MCP Servers to Install

### 1. AWS KB Retrieval MCP Server
- **Purpose**: Query AWS documentation and best practices
- **Repository**: https://github.com/aws-samples/mcp-server-aws-kb-retrieval

### 2. AWS MCP Server (Official)
- **Purpose**: Interact with AWS services via MCP
- **Repository**: https://github.com/modelcontextprotocol/servers/tree/main/src/aws

### 3. AWS Architecture Diagram MCP
- **Purpose**: Design and generate AWS architecture diagrams
- **Repository**: https://github.com/aws-samples/mcp-server-diagram-as-code

## Installation Steps

### Step 1: Install Node.js
1. Download Node.js LTS from https://nodejs.org/
2. Run the installer
3. Verify installation: `node --version` and `npm --version`

### Step 2: Install Python (if needed)
1. Download Python from https://www.python.org/downloads/
2. Check "Add Python to PATH" during installation
3. Verify: `python --version` and `pip --version`

### Step 3: Run Installation Scripts
Execute the PowerShell scripts in this directory:
- `install-aws-mcp-servers.ps1` - Installs all AWS MCP servers
- `configure-mcp-claude.ps1` - Configures MCP for Claude Desktop

### Step 4: Configure AWS Credentials
Ensure your AWS credentials are configured:
```powershell
aws configure list-profiles
```

## Quick Start Commands

After installation, you can use these MCP servers with compatible clients like Claude Desktop.

## Troubleshooting

### Node.js Not Found
- Restart your terminal after installing Node.js
- Verify PATH includes Node.js installation directory

### Python Not Found
- Ensure "Add to PATH" was checked during installation
- Manually add Python to system PATH

### AWS Credentials Issues
- Run `aws configure` to set up credentials
- Verify with `aws sts get-caller-identity`

## Additional Resources
- MCP Documentation: https://modelcontextprotocol.io/
- AWS MCP Samples: https://github.com/aws-samples/
