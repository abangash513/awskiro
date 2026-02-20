# Requirements Document

## Introduction

Nuri is a family-safe, age-aware AI companion system that provides ChatGPT-like conversational capabilities while maintaining strict safety controls, age-appropriate personas, and responsible memory management. The system uses AWS Bedrock with custom guardrails to ensure production-ready, identity-driven interactions that cannot be bypassed through prompt manipulation.

## Glossary

- **Nuri**: The AI companion system name and brand
- **Persona**: Age-based behavioral profile that determines interaction style and content appropriateness
- **Identity_Service**: Authentication system that determines user age group
- **Bedrock_Service**: AWS Bedrock AI service providing the underlying language model
- **Guardrails_Service**: AWS Bedrock Guardrails providing content filtering and safety controls
- **Memory_Service**: System component managing conversation history and user preferences
- **Chat_Interface**: Frontend application providing user interaction capabilities

## Requirements

### Requirement 1: Identity-Based Persona Management

**User Story:** As a parent, I want the AI to automatically adapt its behavior based on my child's verified age, so that interactions are always age-appropriate without manual configuration.

#### Acceptance Criteria

1. WHEN a user authenticates with the system, THE Identity_Service SHALL determine their age group from verified identity data
2. WHEN an age group is determined, THE Nuri SHALL assign the corresponding persona (child_u12, teen_13_17, teen_adult_18_25, adult_25_plus, or guest)
3. WHEN a persona is assigned, THE Nuri SHALL make it immutable for the session duration
4. IF no verified age is available, THEN THE Nuri SHALL assign guest persona with maximum restrictions
5. THE Nuri SHALL prevent users from overriding or negotiating their assigned persona through conversation

### Requirement 2: Age-Appropriate Content Filtering

**User Story:** As a parent, I want different safety levels for different age groups, so that younger children receive more protection while older users have appropriate access.

#### Acceptance Criteria

1. WHEN interacting with child_u12 persona, THE Nuri SHALL use simple, encouraging language and block all mature, risky, or sensitive topics
2. WHEN interacting with teen_13_17 persona, THE Nuri SHALL use respectful, age-appropriate tone and block adult or risky guidance
3. WHEN interacting with teen_adult_18_25 persona, THE Nuri SHALL allow adult topics at conceptual level while maintaining guided autonomy
4. WHEN interacting with adult_25_plus persona, THE Nuri SHALL provide full depth reasoning while avoiding professional advice
5. WHEN interacting with guest persona, THE Nuri SHALL apply maximum content restrictions equivalent to child_u12

### Requirement 3: Runtime Control Management

**User Story:** As a user, I want to control how the AI responds to me through mode and tone settings, so that I can get the type of help I need.

#### Acceptance Criteria

1. WHEN a user selects a mode (Explain, Do, Write, Teach, Talk), THE Nuri SHALL adapt its response style accordingly
2. WHEN a user selects a tone (Friendly, Professional, Calm, Encouraging, Direct), THE Nuri SHALL adjust its communication style
3. WHEN a user selects depth (Short, Medium, Deep), THE Nuri SHALL provide responses at the appropriate detail level
4. THE Nuri SHALL honor these runtime controls while maintaining persona-based safety boundaries
5. THE Nuri SHALL prevent runtime controls from overriding safety restrictions

### Requirement 4: Secure Memory Management

**User Story:** As a parent, I want strict controls on what information the AI remembers about my family, so that sensitive data is never stored inappropriately.

#### Acceptance Criteria

1. THE Nuri SHALL never store emotional confessions, health details, financial information, identity data, or location data for any persona
2. WHEN storing allowed information, THE Nuri SHALL require explicit user consent
3. WHEN interacting with child_u12 or teen_13_17 personas, THE Nuri SHALL only store learning preferences and study goals
4. WHEN interacting with teen_adult_18_25 persona, THE Nuri SHALL store preferences and learning goals only
5. WHEN interacting with adult_25_plus persona, THE Nuri SHALL store preferences, goals, and household rules only
6. WHEN interacting with guest persona, THE Nuri SHALL store no information
7. WHEN memory storage is blocked, THE Nuri SHALL inform the user with the message: "I can help with this right now, but I won't store details like that to keep things safe."

### Requirement 5: Human-Friendly Refusal System

**User Story:** As a user, I want the AI to decline inappropriate requests in a helpful and calm manner, so that I understand the boundaries without feeling rejected.

#### Acceptance Criteria

1. THE Nuri SHALL never use phrases like "I'm not allowed to", "Policy doesn't allow", or "This violates guidelines"
2. WHEN refusing child_u12 requests, THE Nuri SHALL say "I can't help with that, but I can explain something similar in a safe way."
3. WHEN refusing teen_13_17 requests, THE Nuri SHALL say "I can't help with that directly, but I can explain the idea safely or help with something related."
4. WHEN refusing teen_adult_18_25 requests, THE Nuri SHALL say "I can't help with that directly, but I can walk through the general concept, risks, or a safer alternative."
5. WHEN refusing adult_25_plus requests, THE Nuri SHALL say "I can't do that, but I can explain the principles or suggest a safer approach."
6. THE Nuri SHALL always offer a safe alternative when refusing requests
7. THE Nuri SHALL maintain a calm and respectful tone in all refusals

### Requirement 6: AWS Bedrock Integration

**User Story:** As a system administrator, I want the AI to use AWS Bedrock with proper guardrails, so that we have enterprise-grade safety and reliability.

#### Acceptance Criteria

1. THE Nuri SHALL integrate with AWS Bedrock as the primary language model service
2. THE Bedrock_Service SHALL receive system prompts that treat persona as immutable
3. THE Bedrock_Service SHALL honor Mode, Tone, and Depth controls exactly as specified
4. THE Nuri SHALL configure AWS Bedrock Guardrails for PII detection, content filtering, and safety enforcement
5. THE Guardrails_Service SHALL block sexual content, violence, self-harm, drugs, illegal activities, and hate speech
6. THE Nuri SHALL apply persona-specific behavior through application logic rather than relying solely on model decisions

### Requirement 7: Conversation Interface

**User Story:** As a user, I want a clean chat interface that feels as helpful as ChatGPT, so that I can have natural conversations with appropriate safety.

#### Acceptance Criteria

1. THE Chat_Interface SHALL provide a conversational interface similar to ChatGPT in usability
2. THE Chat_Interface SHALL display the user's current persona and runtime controls
3. THE Chat_Interface SHALL allow users to modify Mode, Tone, and Depth settings
4. THE Chat_Interface SHALL prevent users from modifying persona settings
5. THE Chat_Interface SHALL provide clear feedback when memory storage is blocked
6. THE Chat_Interface SHALL maintain conversation history within session boundaries
7. THE Chat_Interface SHALL provide a responsive and intuitive user experience

### Requirement 8: System Architecture

**User Story:** As a system architect, I want a clean separation between frontend, API, and AI services, so that the system is maintainable and secure.

#### Acceptance Criteria

1. THE Nuri SHALL implement a three-tier architecture: Chat_Interface → API → Bedrock_Service
2. THE Identity_Service SHALL authenticate users and determine age groups server-side
3. THE API SHALL validate all requests and enforce persona-based restrictions
4. THE Memory_Service SHALL handle conversation history and preference storage
5. THE Guardrails_Service SHALL provide an additional safety layer beyond application logic
6. THE Nuri SHALL ensure persona determination cannot be bypassed through any interface
7. THE Nuri SHALL maintain clear separation of concerns between all system components

### Requirement 9: Security and Authentication

**User Story:** As a security administrator, I want robust authentication and data protection, so that user data and system access are properly secured.

#### Acceptance Criteria

1. THE Nuri SHALL implement password hashing using PBKDF2 with appropriate salt and iterations
2. THE Nuri SHALL use JWT tokens for session management with secrets stored in AWS Secrets Manager
3. THE Nuri SHALL implement proper session timeout and token refresh mechanisms
4. THE Nuri SHALL encrypt all sensitive data at rest and in transit
5. THE Nuri SHALL implement rate limiting to prevent abuse
6. THE Nuri SHALL log security events for monitoring and audit purposes
7. THE Nuri SHALL validate all input data to prevent injection attacks

### Requirement 10: Infrastructure and Deployment

**User Story:** As a DevOps engineer, I want automated deployment and scalable infrastructure, so that the system can be reliably deployed and maintained.

#### Acceptance Criteria

1. THE Nuri SHALL use AWS CloudFront CDN for frontend content delivery
2. THE Nuri SHALL implement Infrastructure as Code using AWS CloudFormation or CDK
3. THE Nuri SHALL provide automated CI/CD pipeline for deployment
4. THE Nuri SHALL implement proper monitoring and alerting using AWS CloudWatch
5. THE Nuri SHALL use AWS Lambda for serverless API functions where appropriate
6. THE Nuri SHALL implement proper backup and disaster recovery procedures
7. THE Nuri SHALL support multiple deployment environments (dev, staging, production)

### Requirement 11: Enhanced Memory Consent System

**User Story:** As a user, I want explicit control over what information is remembered about me, so that I can make informed decisions about my privacy.

#### Acceptance Criteria

1. THE Nuri SHALL present a clear consent interface before storing any user information
2. THE Nuri SHALL allow users to view all stored information about them
3. THE Nuri SHALL provide options to delete specific stored information
4. THE Nuri SHALL implement granular consent for different types of information storage
5. THE Nuri SHALL respect user consent choices and never store information without permission
6. THE Nuri SHALL provide clear explanations of what information will be stored and why
7. THE Nuri SHALL allow users to withdraw consent and delete all stored information