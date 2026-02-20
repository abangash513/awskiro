# Implementation Specification: Nuri Family AI System

## Overview

This document provides detailed implementation specifications for the Nuri Family AI System, including technical architecture, deployment procedures, and development guidelines.

## Technology Stack

### Frontend
- **Framework**: React 18+ with TypeScript
- **Styling**: Tailwind CSS for responsive design
- **State Management**: React Context API or Redux Toolkit
- **Build Tool**: Vite or Create React App
- **Testing**: Jest + React Testing Library

### Backend API
- **Runtime**: Node.js 18+ with TypeScript
- **Framework**: Express.js with middleware for security
- **Authentication**: JWT with AWS Secrets Manager
- **Password Security**: PBKDF2 with salt (minimum 10,000 iterations)
- **Validation**: Joi or Zod for input validation
- **Testing**: Jest + Supertest

### AWS Infrastructure
- **Compute**: AWS Lambda for serverless functions
- **Storage**: DynamoDB for user data and conversation history
- **AI Service**: AWS Bedrock with Claude Sonnet models
- **Security**: AWS Bedrock Guardrails + custom content filtering
- **CDN**: CloudFront for frontend distribution
- **Secrets**: AWS Secrets Manager for JWT secrets and API keys
- **Monitoring**: CloudWatch for logs and metrics
- **Deployment**: CloudFormation or AWS CDK

## Implementation Architecture

### Directory Structure
```
nuri-family-ai/
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Chat/
│   │   │   ├── Controls/
│   │   │   └── Auth/
│   │   ├── services/
│   │   ├── types/
│   │   └── utils/
│   ├── public/
│   └── package.json
├── backend/
│   ├── src/
│   │   ├── handlers/
│   │   ├── services/
│   │   ├── middleware/
│   │   ├── models/
│   │   └── utils/
│   ├── tests/
│   └── package.json
├── infrastructure/
│   ├── cloudformation/
│   ├── cdk/
│   └── scripts/
└── docs/
```

### Core Services Implementation

#### 1. Identity Service
```typescript
interface IdentityService {
  authenticateUser(credentials: UserCredentials): Promise<AuthResult>;
  determinePersona(userAge: number): PersonaType;
  validateSession(token: string): Promise<SessionData>;
  refreshToken(refreshToken: string): Promise<TokenPair>;
}

interface AuthResult {
  success: boolean;
  user: UserProfile;
  tokens: TokenPair;
  persona: PersonaType;
}
```

#### 2. Bedrock Integration Service
```typescript
interface BedrockService {
  generateResponse(request: ChatRequest): Promise<ChatResponse>;
  applyGuardrails(content: string, persona: PersonaType): Promise<GuardrailResult>;
  buildSystemPrompt(persona: PersonaType, controls: RuntimeControls): string;
}

interface ChatRequest {
  message: string;
  persona: PersonaType;
  runtimeControls: RuntimeControls;
  conversationHistory: Message[];
}
```

#### 3. Memory Service
```typescript
interface MemoryService {
  storeConversation(sessionId: string, message: Message): Promise<void>;
  getConversationHistory(sessionId: string): Promise<Message[]>;
  storeUserPreference(userId: string, preference: UserPreference): Promise<ConsentResult>;
  getUserMemory(userId: string): Promise<UserMemory>;
  deleteUserMemory(userId: string, memoryType?: string): Promise<void>;
}

interface ConsentResult {
  stored: boolean;
  reason?: string;
  consentRequired: boolean;
}
```

## Security Implementation

### Password Security
```typescript
// PBKDF2 implementation with secure defaults
const hashPassword = async (password: string): Promise<string> => {
  const salt = crypto.randomBytes(32);
  const iterations = 100000; // Minimum 10,000, recommended 100,000
  const keyLength = 64;
  const digest = 'sha512';
  
  const hash = await pbkdf2(password, salt, iterations, keyLength, digest);
  return `${salt.toString('hex')}:${hash.toString('hex')}:${iterations}`;
};
```

### JWT Token Management
```typescript
interface TokenService {
  generateTokens(user: UserProfile): Promise<TokenPair>;
  validateToken(token: string): Promise<TokenPayload>;
  refreshTokens(refreshToken: string): Promise<TokenPair>;
  revokeToken(token: string): Promise<void>;
}

interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}
```

### Input Validation
```typescript
// Example validation schemas
const messageSchema = z.object({
  content: z.string().min(1).max(4000),
  sessionId: z.string().uuid(),
  runtimeControls: z.object({
    mode: z.enum(['Explain', 'Do', 'Write', 'Teach', 'Talk']),
    tone: z.enum(['Friendly', 'Professional', 'Calm', 'Encouraging', 'Direct']),
    depth: z.enum(['Short', 'Medium', 'Deep'])
  })
});
```

## Deployment Specifications

### AWS Lambda Functions
```yaml
# CloudFormation template structure
Resources:
  ChatApiFunction:
    Type: AWS::Lambda::Function
    Properties:
      Runtime: nodejs18.x
      Handler: handlers/chat.handler
      Environment:
        Variables:
          BEDROCK_REGION: !Ref AWS::Region
          DYNAMODB_TABLE: !Ref ConversationTable
          JWT_SECRET_ARN: !Ref JWTSecret
      
  AuthFunction:
    Type: AWS::Lambda::Function
    Properties:
      Runtime: nodejs18.x
      Handler: handlers/auth.handler
```

### DynamoDB Tables
```yaml
ConversationTable:
  Type: AWS::DynamoDB::Table
  Properties:
    AttributeDefinitions:
      - AttributeName: sessionId
        AttributeType: S
      - AttributeName: timestamp
        AttributeType: N
    KeySchema:
      - AttributeName: sessionId
        KeyType: HASH
      - AttributeName: timestamp
        KeyType: RANGE
    TimeToLiveSpecification:
      AttributeName: ttl
      Enabled: true

UserMemoryTable:
  Type: AWS::DynamoDB::Table
  Properties:
    AttributeDefinitions:
      - AttributeName: userId
        AttributeType: S
    KeySchema:
      - AttributeName: userId
        KeyType: HASH
```

### CloudFront Distribution
```yaml
CloudFrontDistribution:
  Type: AWS::CloudFront::Distribution
  Properties:
    DistributionConfig:
      Origins:
        - Id: S3Origin
          DomainName: !GetAtt S3Bucket.DomainName
          S3OriginConfig:
            OriginAccessIdentity: !Sub 'origin-access-identity/cloudfront/${OriginAccessIdentity}'
      DefaultCacheBehavior:
        TargetOriginId: S3Origin
        ViewerProtocolPolicy: redirect-to-https
        CachePolicyId: 658327ea-f89d-4fab-a63d-7e88639e58f6 # Managed-CachingOptimized
```

## Development Guidelines

### Code Quality Standards
- **TypeScript**: Strict mode enabled, no `any` types
- **ESLint**: Airbnb configuration with custom rules
- **Prettier**: Consistent code formatting
- **Testing**: Minimum 80% code coverage
- **Documentation**: JSDoc comments for all public APIs

### Git Workflow
1. Feature branches from `develop`
2. Pull requests require code review
3. Automated testing on all PRs
4. Deployment from `main` branch only

### Environment Configuration
```typescript
// Environment variables
interface Config {
  NODE_ENV: 'development' | 'staging' | 'production';
  AWS_REGION: string;
  BEDROCK_MODEL_ID: string;
  DYNAMODB_TABLE_PREFIX: string;
  JWT_SECRET_ARN: string;
  CORS_ORIGINS: string[];
  RATE_LIMIT_WINDOW: number;
  RATE_LIMIT_MAX_REQUESTS: number;
}
```

## Monitoring and Observability

### CloudWatch Metrics
- API response times and error rates
- Bedrock API usage and costs
- DynamoDB read/write capacity utilization
- Lambda function duration and memory usage

### Logging Strategy
```typescript
// Structured logging with correlation IDs
interface LogEntry {
  timestamp: string;
  level: 'info' | 'warn' | 'error';
  message: string;
  correlationId: string;
  userId?: string;
  persona?: PersonaType;
  metadata?: Record<string, any>;
}
```

### Alerting
- High error rates (>5% over 5 minutes)
- Slow response times (>2s average over 5 minutes)
- DynamoDB throttling events
- Bedrock API quota approaching limits

## Performance Requirements

### Response Time Targets
- Authentication: < 500ms
- Chat responses: < 3s (95th percentile)
- Memory operations: < 200ms
- Frontend load time: < 2s

### Scalability Targets
- Support 1000+ concurrent users
- Handle 10,000+ messages per hour
- Auto-scaling based on demand
- 99.9% uptime SLA

## Security Checklist

### Pre-Deployment Security Review
- [ ] All secrets stored in AWS Secrets Manager
- [ ] Input validation on all endpoints
- [ ] Rate limiting implemented
- [ ] CORS properly configured
- [ ] HTTPS enforced everywhere
- [ ] Security headers implemented
- [ ] Dependency vulnerability scan passed
- [ ] Penetration testing completed

### Runtime Security Monitoring
- [ ] Failed authentication attempts
- [ ] Unusual API usage patterns
- [ ] Persona bypass attempts
- [ ] Memory storage violations
- [ ] Bedrock Guardrails triggers

## Compliance and Privacy

### Data Protection
- Conversation data encrypted at rest and in transit
- User data retention policies enforced
- Right to deletion implemented
- Data processing consent tracked
- Audit logs for all data access

### Content Safety
- Multi-layer content filtering (Bedrock + application)
- Persona restrictions cannot be bypassed
- All AI responses logged for safety review
- Escalation procedures for safety violations