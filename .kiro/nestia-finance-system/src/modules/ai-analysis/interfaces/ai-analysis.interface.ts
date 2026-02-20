export interface AIAnalysisRequest {
  type: 'cashflow' | 'categorization' | 'subscription' | 'savings' | 'investment';
  data: any;
  userId: string;
  options?: {
    useCache?: boolean;
    priority?: 'low' | 'normal' | 'high';
    timeout?: number;
  };
}

export interface AIAnalysisResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  confidence: number;
  cached?: boolean;
  processingTime: number;
  timestamp: Date;
}

export interface BatchAnalysisRequest {
  batchId: string;
  requests: AIAnalysisRequest[];
  priority: 'low' | 'normal' | 'high';
}

export interface BatchAnalysisResponse {
  batchId: string;
  results: AIAnalysisResponse[];
  successCount: number;
  failureCount: number;
  totalProcessingTime: number;
  timestamp: Date;
}

// Specific analysis result interfaces
export interface CashflowAnalysisResult {
  monthlyIncome: number;
  monthlyExpenses: number;
  netCashflow: number;
  trends: {
    direction: 'increasing' | 'decreasing' | 'stable';
    percentage: number;
  };
  seasonality: {
    detected: boolean;
    pattern?: string;
    confidence: number;
  };
  projections: {
    nextMonth: number;
    nextQuarter: number;
    nextYear: number;
  };
}

export interface CategorizationResult {
  category: string;
  subcategory: string;
  confidence: number;
  reasoning: string;
  suggestedBudgetCategory: string;
}

export interface SubscriptionResult {
  isSubscription: boolean;
  confidence: number;
  subscriptionDetails?: {
    frequency: 'weekly' | 'monthly' | 'quarterly' | 'yearly';
    estimatedAmount: number;
    nextPaymentDate?: string;
    merchantName: string;
  };
  reasoning: string;
}

export interface SavingsResult {
  opportunities: Array<{
    category: string;
    potentialSavings: number;
    confidence: number;
    recommendation: string;
  }>;
  totalPotentialSavings: number;
  priorityRecommendations: string[];
}

export interface InvestmentResult {
  riskProfile: 'conservative' | 'moderate' | 'aggressive';
  recommendations: Array<{
    type: string;
    allocation: number;
    reasoning: string;
    expectedReturn: number;
  }>;
  diversificationScore: number;
  suggestions: string[];
}