# Design Document: Nestia Personal Finance Intelligence System

## Overview

Nestia is designed as a privacy-first, locally-processing personal finance intelligence system that transforms raw financial data into calm, actionable insights. The system follows a modular architecture with clear separation between data ingestion, analysis, and presentation layers. The design prioritizes data integrity, user privacy, and gentle communication while providing comprehensive financial intelligence across cashflow, expenses, subscriptions, savings, and investments.

### Design Principles

1. **Privacy by Design**: All sensitive financial data processing occurs locally with optional secure cloud sync
2. **Data Integrity First**: No data fabrication or assumption - analysis based solely on provided data
3. **Calm Intelligence**: Insights delivered in measured, professional tone without urgency or pressure
4. **Focused Output**: Limited to 3-5 key insights and 1-3 gentle recommendations per session
5. **User Autonomy**: Users maintain full control over data, analysis parameters, and insight preferences
6. **Extensible Architecture**: Modular design supporting future enhancements and integrations

## Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Sources  │    │  Core Analysis  │    │  User Interface │
│                 │    │                 │    │                 │
│ • Bank APIs     │───▶│ • Data Engine   │───▶│ • Web Dashboard │
│ • File Imports  │    │ • ML Pipeline   │    │ • Mobile App    │
│ • Manual Entry  │    │ • Insight Gen   │    │ • API Endpoints │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Data Storage   │    │   Security &    │    │   Integration   │
│                 │    │   Privacy       │    │                 │
│ • Local SQLite  │    │ • Encryption    │    │ • Open Banking  │
│ • Encrypted     │    │ • Access Ctrl   │    │ • Plaid/Yodlee  │
│ • Backup Sync   │    │ • Audit Logs    │    │ • CSV/OFX       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Component Architecture

#### 1. Data Ingestion Layer
- **Account Connectors**: Secure integrations with financial institutions
- **File Processors**: CSV, OFX, QIF, and other format parsers
- **Data Validators**: Ensure data integrity and completeness
- **Normalization Engine**: Standardize data formats across sources

#### 2. Data Storage Layer
- **Local Database**: Encrypted SQLite for primary data storage
- **Cache Layer**: Redis for temporary analysis results
- **Backup System**: Encrypted cloud sync (optional)
- **Archive Manager**: Historical data compression and retrieval

#### 3. Analysis Engine
- **Transaction Processor**: Categorization and pattern recognition
- **Cashflow Analyzer**: Income/expense flow analysis
- **Subscription Detector**: Recurring payment identification
- **Savings Calculator**: Savings rate and opportunity analysis
- **Investment Analyzer**: Portfolio performance and allocation
- **Trend Engine**: Historical pattern and projection analysis

#### 4. Intelligence Layer
- **Insight Generator**: Converts analysis into actionable insights
- **Recommendation Engine**: Generates gentle, personalized suggestions
- **Goal Tracker**: Monitors progress toward financial objectives
- **Alert System**: Intelligent notifications and reminders
- **Educational Context**: Provides learning opportunities

#### 5. Presentation Layer
- **Web Dashboard**: Primary user interface
- **Mobile Application**: iOS/Android companion apps
- **API Gateway**: RESTful API for third-party integrations
- **Report Generator**: PDF and export functionality

## Data Models

### Core Entities

#### Account
```sql
CREATE TABLE accounts (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    institution_name VARCHAR(255) NOT NULL,
    account_type ENUM('checking', 'savings', 'credit', 'investment', 'loan') NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_number_hash VARCHAR(64), -- Hashed for privacy
    currency_code CHAR(3) DEFAULT 'USD',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_sync_at TIMESTAMP,
    balance_current DECIMAL(15,2),
    balance_available DECIMAL(15,2)
);
```

#### Transaction
```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL REFERENCES accounts(id),
    transaction_date DATE NOT NULL,
    posted_date DATE,
    amount DECIMAL(15,2) NOT NULL,
    description TEXT NOT NULL,
    merchant_name VARCHAR(255),
    category_id UUID REFERENCES categories(id),
    subcategory_id UUID REFERENCES subcategories(id),
    transaction_type ENUM('debit', 'credit') NOT NULL,
    is_recurring BOOLEAN DEFAULT false,
    recurring_group_id UUID,
    confidence_score DECIMAL(3,2), -- ML categorization confidence
    user_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Category
```sql
CREATE TABLE categories (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,
    parent_category_id UUID REFERENCES categories(id),
    color_code VARCHAR(7), -- Hex color
    icon_name VARCHAR(50),
    is_system_category BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Subscription
```sql
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    merchant_name VARCHAR(255) NOT NULL,
    service_name VARCHAR(255),
    amount DECIMAL(10,2) NOT NULL,
    currency_code CHAR(3) DEFAULT 'USD',
    billing_cycle ENUM('weekly', 'monthly', 'quarterly', 'annually') NOT NULL,
    next_billing_date DATE,
    category_id UUID REFERENCES categories(id),
    is_active BOOLEAN DEFAULT true,
    confidence_score DECIMAL(3,2),
    first_detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_transaction_id UUID REFERENCES transactions(id),
    annual_cost DECIMAL(10,2) GENERATED ALWAYS AS (
        CASE billing_cycle
            WHEN 'weekly' THEN amount * 52
            WHEN 'monthly' THEN amount * 12
            WHEN 'quarterly' THEN amount * 4
            WHEN 'annually' THEN amount
        END
    ) STORED
);
```

#### Goal
```sql
CREATE TABLE goals (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    goal_type ENUM('savings', 'debt_payoff', 'investment', 'expense_reduction') NOT NULL,
    target_amount DECIMAL(15,2),
    current_amount DECIMAL(15,2) DEFAULT 0,
    target_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Insight
```sql
CREATE TABLE insights (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    insight_type ENUM('cashflow', 'expense', 'subscription', 'savings', 'investment', 'goal', 'alert') NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    importance_score INTEGER CHECK (importance_score BETWEEN 1 AND 10),
    data_source JSON, -- References to supporting data
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_read BOOLEAN DEFAULT false,
    user_feedback ENUM('helpful', 'not_helpful', 'irrelevant')
);
```

### Supporting Entities

#### User Preferences
```sql
CREATE TABLE user_preferences (
    user_id UUID PRIMARY KEY,
    default_currency CHAR(3) DEFAULT 'USD',
    insight_frequency ENUM('daily', 'weekly', 'monthly') DEFAULT 'weekly',
    max_insights_per_session INTEGER DEFAULT 5,
    max_recommendations_per_session INTEGER DEFAULT 3,
    communication_tone ENUM('formal', 'casual', 'encouraging') DEFAULT 'formal',
    categories_auto_learn BOOLEAN DEFAULT true,
    alerts_enabled BOOLEAN DEFAULT true,
    data_retention_months INTEGER DEFAULT 60,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Analysis Cache
```sql
CREATE TABLE analysis_cache (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    analysis_type VARCHAR(50) NOT NULL,
    parameters_hash VARCHAR(64) NOT NULL,
    result_data JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    UNIQUE(user_id, analysis_type, parameters_hash)
);
```

### Data Relationships

1. **User → Accounts**: One-to-many relationship with cascade delete
2. **Account → Transactions**: One-to-many with foreign key constraint
3. **Transaction → Category**: Many-to-one with optional categorization
4. **User → Goals**: One-to-many for personal financial objectives
5. **User → Subscriptions**: One-to-many for recurring payment tracking
6. **User → Insights**: One-to-many for generated intelligence
7. **Categories**: Self-referencing hierarchy for subcategories

### Data Integrity Constraints

1. **Transaction Amounts**: Must be non-zero with appropriate precision
2. **Date Consistency**: Posted date >= transaction date
3. **Currency Consistency**: All related amounts use same currency
4. **Category Hierarchy**: Prevent circular references in category tree
5. **Goal Progress**: Current amount cannot exceed target (for savings goals)
6. **Subscription Cycles**: Next billing date must align with cycle frequency
## Analysis Algorithms

### Cashflow Analysis Algorithm

#### Monthly Cashflow Calculation
```python
def calculate_monthly_cashflow(transactions, start_date, end_date):
    """
    Calculate net cashflow for specified period
    Returns: {income, expenses, net_flow, flow_by_category}
    """
    income = sum(t.amount for t in transactions 
                if t.amount > 0 and start_date <= t.date <= end_date)
    expenses = sum(abs(t.amount) for t in transactions 
                  if t.amount < 0 and start_date <= t.date <= end_date)
    
    return {
        'income': income,
        'expenses': expenses,
        'net_flow': income - expenses,
        'flow_by_category': group_by_category(transactions)
    }
```

#### Cashflow Trend Analysis
- **Moving Averages**: 3-month and 12-month rolling averages
- **Seasonality Detection**: Identify recurring patterns by month/quarter
- **Volatility Measurement**: Standard deviation of monthly flows
- **Trend Direction**: Linear regression on 6-month periods

### Expense Categorization Algorithm

#### Machine Learning Categorization
```python
class TransactionCategorizer:
    def __init__(self):
        self.vectorizer = TfidfVectorizer(max_features=1000)
        self.classifier = RandomForestClassifier(n_estimators=100)
        self.confidence_threshold = 0.7
    
    def categorize_transaction(self, transaction):
        """
        Categorize transaction using ML model
        Returns: (category_id, confidence_score)
        """
        features = self.extract_features(transaction)
        probabilities = self.classifier.predict_proba([features])[0]
        
        max_prob_idx = np.argmax(probabilities)
        confidence = probabilities[max_prob_idx]
        
        if confidence >= self.confidence_threshold:
            return self.categories[max_prob_idx], confidence
        else:
            return None, confidence  # Requires manual categorization
```

#### Feature Extraction
- **Merchant Name**: TF-IDF vectorization of merchant names
- **Transaction Amount**: Normalized amount ranges
- **Transaction Time**: Day of week, time of day patterns
- **Description Keywords**: Key terms from transaction descriptions
- **Historical Patterns**: User's past categorization for similar transactions

### Subscription Detection Algorithm

#### Recurring Pattern Detection
```python
def detect_subscriptions(transactions, min_occurrences=3):
    """
    Detect recurring payments using pattern matching
    Returns: List of detected subscription patterns
    """
    # Group by merchant and amount
    grouped = defaultdict(list)
    for t in transactions:
        key = (t.merchant_name, round(t.amount, 2))
        grouped[key].append(t)
    
    subscriptions = []
    for (merchant, amount), txns in grouped.items():
        if len(txns) >= min_occurrences:
            intervals = calculate_intervals(txns)
            if is_regular_pattern(intervals):
                subscription = {
                    'merchant': merchant,
                    'amount': amount,
                    'frequency': determine_frequency(intervals),
                    'confidence': calculate_confidence(intervals),
                    'next_expected': predict_next_payment(txns)
                }
                subscriptions.append(subscription)
    
    return subscriptions
```

#### Pattern Recognition Rules
- **Amount Consistency**: ±5% variance allowed for same subscription
- **Timing Patterns**: Weekly (7±1 days), Monthly (28-31 days), Quarterly (90-93 days)
- **Merchant Matching**: Fuzzy string matching for merchant name variations
- **Confidence Scoring**: Based on regularity, amount consistency, and occurrence count

### Savings Analysis Algorithm

#### Savings Rate Calculation
```python
def calculate_savings_metrics(transactions, period_months=12):
    """
    Calculate comprehensive savings metrics
    Returns: Savings rate, trends, and opportunities
    """
    income = calculate_total_income(transactions, period_months)
    expenses = calculate_total_expenses(transactions, period_months)
    savings_transfers = identify_savings_transfers(transactions)
    
    savings_rate = (income - expenses) / income if income > 0 else 0
    
    return {
        'savings_rate': savings_rate,
        'monthly_average_savings': (income - expenses) / period_months,
        'savings_trend': calculate_savings_trend(transactions),
        'opportunities': identify_savings_opportunities(transactions)
    }
```

#### Savings Opportunity Detection
- **Expense Anomalies**: Identify unusually high spending in categories
- **Subscription Optimization**: Find unused or duplicate subscriptions
- **Seasonal Patterns**: Highlight seasonal spending that could be reduced
- **Category Benchmarking**: Compare spending to user's historical averages

### Investment Analysis Algorithm

#### Portfolio Performance Calculation
```python
def analyze_investment_performance(investment_accounts, benchmark_data):
    """
    Analyze investment portfolio performance and allocation
    Returns: Performance metrics, allocation analysis, risk assessment
    """
    total_value = sum(account.current_balance for account in investment_accounts)
    
    allocation = calculate_asset_allocation(investment_accounts)
    performance = calculate_returns(investment_accounts)
    risk_metrics = calculate_risk_metrics(investment_accounts)
    
    return {
        'total_value': total_value,
        'allocation': allocation,
        'performance': performance,
        'risk_metrics': risk_metrics,
        'rebalancing_suggestions': suggest_rebalancing(allocation)
    }
```

#### Risk Assessment Metrics
- **Diversification Score**: Measure of portfolio spread across asset classes
- **Concentration Risk**: Identify over-weighted positions
- **Volatility Analysis**: Standard deviation of returns
- **Correlation Analysis**: Asset correlation for risk management

## Correctness Properties

Based on the requirements analysis, the following correctness properties ensure system reliability and user trust:

### Data Integrity Properties

**Property DI-1: Data Source Fidelity**
- **Specification**: ∀ insight i ∈ Insights: data_sources(i) ⊆ user_provided_data ∧ fabricated_data(i) = ∅
- **Verification**: All insights must reference only data explicitly provided by users, with no fabricated or assumed values
- **Test Strategy**: Audit trail verification ensuring all insight data points trace back to user-provided sources

**Property DI-2: Analysis Completeness**
- **Specification**: ∀ analysis a: insufficient_data(a) → explicit_limitation_stated(a) ∧ ¬assumption_made(a)
- **Verification**: When data is insufficient for analysis, system must state limitations rather than make assumptions
- **Test Strategy**: Test with incomplete datasets to verify limitation reporting

**Property DI-3: Data Citation Accuracy**
- **Specification**: ∀ insight i: cited_sources(i) = actual_sources(i) ∧ time_periods(i) = actual_periods(i)
- **Verification**: All insights must accurately cite their data sources and time periods
- **Test Strategy**: Cross-reference insight citations with actual data sources used

### Output Limitation Properties

**Property OL-1: Insight Count Constraint**
- **Specification**: ∀ session s: |insights(s)| ≤ 5 ∧ |insights(s)| ≥ 3 ∨ insufficient_data(s)
- **Verification**: Each analysis session produces 3-5 insights unless data is insufficient
- **Test Strategy**: Automated counting of insights per session across various data scenarios

**Property OL-2: Recommendation Count Constraint**
- **Specification**: ∀ session s: |recommendations(s)| ≤ 3 ∧ |recommendations(s)| ≥ 1 ∨ no_actionable_items(s)
- **Verification**: Each session produces 1-3 recommendations unless no actionable items exist
- **Test Strategy**: Validate recommendation counts across different user scenarios

**Property OL-3: Priority-Based Selection**
- **Specification**: ∀ session s: selected_insights(s) = top_k_by_importance(available_insights(s), k≤5)
- **Verification**: System selects most important insights when more than 5 are available
- **Test Strategy**: Generate scenarios with >5 potential insights and verify selection logic

### Communication Tone Properties

**Property CT-1: Calm Language Verification**
- **Specification**: ∀ message m: urgency_words(m) = ∅ ∧ alarm_words(m) = ∅ ∧ pressure_words(m) = ∅
- **Verification**: All communications avoid urgent, alarmist, or pressure-inducing language
- **Test Strategy**: Natural language processing to detect prohibited word patterns

**Property CT-2: Professional Tone Consistency**
- **Specification**: ∀ message m: tone_score(m) ∈ [professional_min, professional_max] ∧ supportive_elements(m) > 0
- **Verification**: Messages maintain professional tone while being supportive
- **Test Strategy**: Sentiment analysis and tone scoring of all generated messages

**Property CT-3: Non-Judgmental Communication**
- **Specification**: ∀ financial_challenge c, message m: discusses(m, c) → judgmental_language(m) = ∅
- **Verification**: Financial challenges discussed without judgmental language
- **Test Strategy**: Review communications about negative financial situations for judgmental content

### Privacy and Security Properties

**Property PS-1: Data Encryption Invariant**
- **Specification**: ∀ data d ∈ stored_data: encrypted(d) = true ∧ ∀ transmission t: encrypted(t) = true
- **Verification**: All stored and transmitted data must be encrypted
- **Test Strategy**: Verify encryption at rest and in transit through security audits

**Property PS-2: Local Processing Guarantee**
- **Specification**: ∀ sensitive_operation o: processing_location(o) = local ∨ explicit_user_consent(o) = true
- **Verification**: Sensitive operations process locally unless user explicitly consents to cloud processing
- **Test Strategy**: Network monitoring to ensure no unauthorized data transmission

**Property PS-3: Access Control Enforcement**
- **Specification**: ∀ user u, data d: access(u, d) → authorized(u, d) ∧ audit_logged(access(u, d))
- **Verification**: All data access requires authorization and is logged
- **Test Strategy**: Access control testing and audit log verification

### Analysis Accuracy Properties

**Property AA-1: Categorization Consistency**
- **Specification**: ∀ transaction t: user_corrected(t) → future_similar_transactions_use_correction(t)
- **Verification**: User corrections improve future categorization accuracy
- **Test Strategy**: Test learning from corrections with similar transaction patterns

**Property AA-2: Subscription Detection Accuracy**
- **Specification**: ∀ detected_subscription s: confidence(s) ≥ threshold ∧ pattern_evidence(s) ≥ min_occurrences
- **Verification**: Subscriptions detected only with sufficient confidence and evidence
- **Test Strategy**: Validate detection accuracy against known subscription patterns

**Property AA-3: Trend Analysis Validity**
- **Specification**: ∀ trend t: data_points(t) ≥ minimum_required ∧ statistical_significance(t) = true
- **Verification**: Trends reported only with sufficient data and statistical significance
- **Test Strategy**: Statistical validation of trend calculations with various data sizes

### Goal Tracking Properties

**Property GT-1: Progress Calculation Accuracy**
- **Specification**: ∀ goal g: progress_percentage(g) = (current_amount(g) / target_amount(g)) * 100
- **Verification**: Goal progress calculated accurately based on current vs target amounts
- **Test Strategy**: Mathematical verification of progress calculations

**Property GT-2: Timeline Estimation Validity**
- **Specification**: ∀ goal g: estimated_completion(g) = extrapolate_from_current_rate(g) ∧ confidence_interval_provided(g)
- **Verification**: Timeline estimates based on current progress rates with confidence intervals
- **Test Strategy**: Validate estimation algorithms against historical achievement data

## Error Handling

### Error Categories and Responses

#### Data Integration Errors
- **Connection Failures**: Graceful degradation with cached data and user notification
- **Authentication Errors**: Clear guidance for credential renewal without exposing sensitive details
- **Data Format Errors**: Robust parsing with detailed error reporting for manual correction
- **Sync Conflicts**: User-controlled conflict resolution with data preservation

#### Analysis Errors
- **Insufficient Data**: Transparent communication about data limitations and requirements
- **Calculation Errors**: Fallback to simpler analysis methods with accuracy disclaimers
- **Model Failures**: Graceful degradation to rule-based systems with reduced confidence scores
- **Performance Issues**: Progressive analysis with partial results and continuation options

#### User Interface Errors
- **Network Connectivity**: Offline mode with local data access and sync queuing
- **Browser Compatibility**: Progressive enhancement with feature detection
- **Mobile Responsiveness**: Adaptive layouts with core functionality preservation
- **Accessibility Issues**: WCAG 2.1 AA compliance with screen reader support

### Error Recovery Strategies

#### Automatic Recovery
```python
class ErrorRecoveryManager:
    def handle_analysis_error(self, error_type, context):
        if error_type == "insufficient_data":
            return self.request_additional_data(context)
        elif error_type == "calculation_failure":
            return self.fallback_to_simple_analysis(context)
        elif error_type == "model_error":
            return self.use_rule_based_backup(context)
        else:
            return self.log_and_notify_user(error_type, context)
```

#### User-Guided Recovery
- **Data Correction Workflows**: Step-by-step guidance for fixing data issues
- **Manual Categorization**: Fallback to user categorization when ML fails
- **Goal Adjustment**: Assisted goal modification when targets become unrealistic
- **Account Reconnection**: Simplified re-authentication flows

## Testing Strategy

### Unit Testing
- **Data Model Validation**: Test all database constraints and relationships
- **Algorithm Accuracy**: Verify mathematical calculations and ML model performance
- **Business Logic**: Test all requirement-based business rules
- **Error Handling**: Comprehensive error scenario coverage

### Integration Testing
- **API Integrations**: Test all external financial data connections
- **Database Operations**: Verify data consistency across complex operations
- **Security Measures**: Test encryption, authentication, and authorization
- **Performance**: Load testing with realistic data volumes

### User Acceptance Testing
- **Requirement Validation**: Verify each requirement through user scenarios
- **Usability Testing**: Ensure calm, professional user experience
- **Accessibility Testing**: WCAG 2.1 AA compliance verification
- **Privacy Testing**: Verify data handling meets privacy requirements

### Automated Testing Pipeline
```yaml
testing_pipeline:
  unit_tests:
    - data_models
    - algorithms
    - business_logic
    - error_handling
  
  integration_tests:
    - api_connections
    - database_operations
    - security_measures
    - performance_benchmarks
  
  acceptance_tests:
    - requirement_scenarios
    - user_workflows
    - accessibility_compliance
    - privacy_verification
  
  continuous_monitoring:
    - data_quality_checks
    - algorithm_performance
    - user_satisfaction_metrics
    - security_audit_logs
```

### Quality Assurance Metrics
- **Code Coverage**: Minimum 90% for critical financial calculations
- **Performance Benchmarks**: Sub-second response for standard analyses
- **Accuracy Metrics**: >95% categorization accuracy after user training
- **User Satisfaction**: Regular surveys and feedback integration
- **Security Compliance**: Regular penetration testing and vulnerability assessments

This design provides a comprehensive foundation for implementing the Nestia Personal Finance Intelligence System while ensuring all requirements are met with appropriate technical rigor and user-focused design principles.