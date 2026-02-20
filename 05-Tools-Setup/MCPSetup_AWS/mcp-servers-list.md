# AWS MCP Servers Reference

## 1. AWS KB Retrieval MCP Server
**Repository**: https://github.com/aws-samples/mcp-server-aws-kb-retrieval

**Purpose**: Query AWS Knowledge Base and documentation
- Search AWS documentation
- Get best practices
- Query AWS service information
- Retrieve troubleshooting guides

**Use Cases**:
- Finding AWS service documentation
- Getting architecture best practices
- Troubleshooting AWS issues
- Learning about AWS services

---

## 2. AWS MCP Server (Official)
**Repository**: https://github.com/modelcontextprotocol/servers/tree/main/src/aws

**Purpose**: Direct interaction with AWS services via MCP
- Execute AWS CLI commands
- Manage AWS resources
- Query AWS service status
- Automate AWS operations

**Supported Services**:
- EC2 (instances, volumes, snapshots)
- S3 (buckets, objects)
- Lambda (functions, invocations)
- IAM (users, roles, policies)
- CloudWatch (metrics, logs)
- And more...

**Use Cases**:
- Infrastructure management
- Resource monitoring
- Automated deployments
- Cost optimization

---

## 3. AWS Diagram as Code MCP Server
**Repository**: https://github.com/aws-samples/mcp-server-diagram-as-code

**Purpose**: Design and generate AWS architecture diagrams
- Create architecture diagrams programmatically
- Generate diagrams from code
- Visualize AWS infrastructure
- Document cloud architectures

**Features**:
- Text-to-diagram conversion
- AWS service icons and symbols
- Best practice templates
- Export to multiple formats

**Use Cases**:
- Architecture documentation
- Design reviews
- Proposal presentations
- Infrastructure planning
- Compliance documentation

**Supported Diagram Types**:
- Network architectures
- Application architectures
- Security architectures
- Data flow diagrams
- Multi-region setups

---

## Additional MCP Servers (Optional)

### AWS CloudFormation MCP
- Template validation
- Stack management
- Resource tracking

### AWS CDK MCP
- Infrastructure as Code
- TypeScript/Python support
- Construct library access

### AWS Security Hub MCP
- Security findings
- Compliance checks
- Vulnerability scanning

---

## Configuration Example

After installation, your Claude Desktop config will look like:

```json
{
  "mcpServers": {
    "aws-kb-retrieval": {
      "command": "node",
      "args": ["path/to/mcp-server-aws-kb-retrieval/build/index.js"]
    },
    "aws": {
      "command": "node",
      "args": ["path/to/mcp-servers-official/src/aws/dist/index.js"]
    },
    "aws-diagram": {
      "command": "node",
      "args": ["path/to/mcp-server-diagram-as-code/build/index.js"]
    }
  }
}
```

---

## Usage Tips

### With Claude Desktop
1. Start a conversation
2. Reference MCP tools naturally
3. Ask for AWS documentation
4. Request architecture diagrams
5. Execute AWS operations

### Example Prompts
- "Show me the AWS Well-Architected Framework for serverless"
- "Create an architecture diagram for a 3-tier web application"
- "List all my EC2 instances in us-east-1"
- "Generate a diagram for a microservices architecture on EKS"
- "What are the best practices for S3 security?"

---

## Troubleshooting

### MCP Server Not Starting
- Check Node.js version (18+)
- Verify npm install completed
- Check AWS credentials configured

### AWS Credentials Issues
- Run `aws configure`
- Verify IAM permissions
- Check profile configuration

### Diagram Generation Fails
- Ensure all dependencies installed
- Check output directory permissions
- Verify diagram syntax

---

## Resources

- **MCP Documentation**: https://modelcontextprotocol.io/
- **AWS Samples**: https://github.com/aws-samples/
- **Claude Desktop**: https://claude.ai/download
- **AWS CLI Guide**: https://docs.aws.amazon.com/cli/
