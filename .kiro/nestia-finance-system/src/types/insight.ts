/**
 * Insight and recommendation type definitions
 */

import { UUID, Timestamp, Decimal } from './index';

export type InsightType = 'cashflow' | 'expense' | 'subscription' | 'savings' | 'investment' | 'goal' | 'alert';
export type InsightSeverity = 'low' | 'medium' | 'high';
export type InsightStatus = 'new' | 'read' | 'dismissed' | 'acted_upon';
export type UserFeedback = 'helpful' | 'not_helpful' | 'irrelevant';

export interface Insight {
  id: UUID;
  userId: UUID;
  insightType: InsightType;
  title: string;
  description: string;
  importanceScore: number; // 1-10
  dataSource: Record<string, unknown>; // JSON references to supporting data
  status: InsightStatus;
  generatedAt: Timestamp;
  expiresAt?: Timestamp;
  isRead: boolean;
  userFeedback?: UserFeedback;
  feedbackAt?: Timestamp;
}

export interface Recommendation {
  id: UUID;
  userId: UUID;
  insightId?: UUID;
  recommendationType: 'savings_opportunity' | 'expense_reduction' | 'goal_adjustment' | 'subscription_review' | 'investment_rebalance';
  title: string;
  description: string;
  suggestedAction: string;
  potentialImpact?: string;
  estimatedSavings?: Decimal;
  confidenceScore: Decimal;
  priority: number; // 1-3, where 1 is highest priority
  status: InsightStatus;
  generatedAt: Timestamp;
  expiresAt?: Timestamp;
  userFeedback?: UserFeedback;
  feedbackAt?: Timestamp;
}

export interface InsightGeneration {
  id: UUID;
  userId: UUID;
  sessionId: UUID;
  analysisType: string;
  analysisParameters: Record<string, unknown>;
  insightsGenerated: number;
  recommendationsGenerated: number;
  processingTimeMs: number;
  generatedAt: Timestamp;
}

export interface InsightTemplate {
  id: UUID;
  insightType: InsightType;
  templateName: string;
  titleTemplate: string;
  descriptionTemplate: string;
  conditions: InsightCondition[];
  isActive: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface InsightCondition {
  field: string;
  operator: 'equals' | 'greaterThan' | 'lessThan' | 'between' | 'contains' | 'exists';
  value: string | number | boolean | Array<string | number>;
  weight: Decimal; // Contribution to importance score
}

export interface CashflowInsight {
  userId: UUID;
  periodStart: Date;
  periodEnd: Date;
  totalIncome: Decimal;
  totalExpenses: Decimal;
  netCashflow: Decimal;
  incomeGrowth?: Decimal;
  expenseGrowth?: Decimal;
  cashflowTrend: 'improving' | 'stable' | 'declining';
  seasonalPatterns: Array<{
    month: number;
    averageIncome: Decimal;
    averageExpenses: Decimal;
  }>;
  generatedAt: Timestamp;
}

export interface ExpenseInsight {
  userId: UUID;
  periodStart: Date;
  periodEnd: Date;
  totalExpenses: Decimal;
  topCategories: Array<{
    categoryName: string;
    amount: Decimal;
    percentage: Decimal;
    trend: 'increasing' | 'stable' | 'decreasing';
  }>;
  unusualExpenses: Array<{
    transactionId: UUID;
    amount: Decimal;
    description: string;
    deviationFromAverage: Decimal;
  }>;
  savingsOpportunities: Array<{
    categoryName: string;
    potentialSavings: Decimal;
    suggestion: string;
  }>;
  generatedAt: Timestamp;
}

export interface SubscriptionInsight {
  userId: UUID;
  totalSubscriptions: number;
  totalMonthlyCost: Decimal;
  totalAnnualCost: Decimal;
  subscriptionsByCategory: Record<string, number>;
  costByCategory: Record<string, Decimal>;
  unusedSubscriptions: Array<{
    subscriptionId: UUID;
    merchantName: string;
    monthlyCost: Decimal;
    lastUsageDate?: Date;
    suggestion: string;
  }>;
  duplicateServices: Array<{
    category: string;
    services: string[];
    totalCost: Decimal;
    suggestion: string;
  }>;
  generatedAt: Timestamp;
}

export interface SavingsInsight {
  userId: UUID;
  periodStart: Date;
  periodEnd: Date;
  savingsRate: Decimal;
  monthlySavingsAverage: Decimal;
  savingsTrend: 'improving' | 'stable' | 'declining';
  goalProgress: Array<{
    goalId: UUID;
    goalName: string;
    progressPercentage: Decimal;
    projectedCompletion?: Date;
  }>;
  opportunities: Array<{
    type: 'expense_reduction' | 'income_increase' | 'goal_adjustment';
    description: string;
    potentialImpact: Decimal;
  }>;
  generatedAt: Timestamp;
}

export interface InvestmentInsight {
  userId: UUID;
  portfolioValue: Decimal;
  assetAllocation: Record<string, Decimal>;
  performanceMetrics: {
    totalReturn: Decimal;
    annualizedReturn: Decimal;
    volatility: Decimal;
  };
  diversificationScore: Decimal;
  riskAssessment: 'conservative' | 'moderate' | 'aggressive';
  rebalancingNeeded: boolean;
  recommendations: Array<{
    type: 'rebalance' | 'diversify' | 'reduce_risk' | 'increase_allocation';
    description: string;
    suggestedAction: string;
  }>;
  generatedAt: Timestamp;
}

export interface CreateInsightInput {
  insightType: InsightType;
  title: string;
  description: string;
  importanceScore: number;
  dataSource: Record<string, unknown>;
  expiresAt?: Timestamp;
}

export interface UpdateInsightInput {
  status?: InsightStatus;
  isRead?: boolean;
  userFeedback?: UserFeedback;
}

export interface InsightFilter {
  insightTypes?: InsightType[];
  severities?: InsightSeverity[];
  statuses?: InsightStatus[];
  dateFrom?: Date;
  dateTo?: Date;
  isRead?: boolean;
  hasUserFeedback?: boolean;
}

export interface InsightSummary {
  totalInsights: number;
  newInsights: number;
  readInsights: number;
  dismissedInsights: number;
  insightsByType: Record<InsightType, number>;
  insightsBySeverity: Record<InsightSeverity, number>;
  averageImportanceScore: Decimal;
  lastGeneratedAt?: Timestamp;
}