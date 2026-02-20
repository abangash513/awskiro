/**
 * Core type definitions for the Nestia Personal Finance Intelligence System
 */

// Base types
export type UUID = string;
export type Timestamp = Date;
export type CurrencyCode = 'USD' | 'EUR' | 'GBP' | 'CAD' | 'AUD' | 'JPY' | string;
export type Decimal = number;

// User and authentication types
export interface User {
  id: UUID;
  email: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  isActive: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastLoginAt?: Timestamp;
}

export interface UserPreferences {
  userId: UUID;
  defaultCurrency: CurrencyCode;
  insightFrequency: 'daily' | 'weekly' | 'monthly';
  maxInsightsPerSession: number;
  maxRecommendationsPerSession: number;
  communicationTone: 'formal' | 'casual' | 'encouraging';
  categoriesAutoLearn: boolean;
  alertsEnabled: boolean;
  dataRetentionMonths: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Financial data types
export interface Account {
  id: UUID;
  userId: UUID;
  institutionName: string;
  accountType: 'checking' | 'savings' | 'credit' | 'investment' | 'loan';
  accountName: string;
  accountNumberHash?: string;
  currencyCode: CurrencyCode;
  isActive: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastSyncAt?: Timestamp;
  balanceCurrent?: Decimal;
  balanceAvailable?: Decimal;
}

export interface Transaction {
  id: UUID;
  accountId: UUID;
  transactionDate: Date;
  postedDate?: Date;
  amount: Decimal;
  description: string;
  merchantName?: string;
  categoryId?: UUID;
  subcategoryId?: UUID;
  transactionType: 'debit' | 'credit';
  isRecurring: boolean;
  recurringGroupId?: UUID;
  confidenceScore?: Decimal;
  userVerified: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface Category {
  id: UUID;
  userId: UUID;
  name: string;
  parentCategoryId?: UUID;
  colorCode?: string;
  iconName?: string;
  isSystemCategory: boolean;
  isActive: boolean;
  createdAt: Timestamp;
  children?: Category[]; // For hierarchy building
}

// Analysis result types
export interface CashflowAnalysis {
  userId: UUID;
  periodStart: Date;
  periodEnd: Date;
  totalIncome: Decimal;
  totalExpenses: Decimal;
  netCashflow: Decimal;
  incomeByCategory: Record<string, Decimal>;
  expensesByCategory: Record<string, Decimal>;
  monthlyTrend: Array<{
    month: string;
    income: Decimal;
    expenses: Decimal;
    netFlow: Decimal;
  }>;
  generatedAt: Timestamp;
}

export interface ExpenseAnalysis {
  userId: UUID;
  periodStart: Date;
  periodEnd: Date;
  totalExpenses: Decimal;
  expensesByCategory: Record<string, Decimal>;
  topExpenseCategories: Array<{
    categoryName: string;
    amount: Decimal;
    percentage: Decimal;
  }>;
  unusualExpenses: Array<{
    transactionId: UUID;
    amount: Decimal;
    description: string;
    reason: string;
  }>;
  generatedAt: Timestamp;
}

// API response types
export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: unknown;
  };
  timestamp: Timestamp;
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

// Configuration types
export interface DatabaseConfig {
  type: 'sqlite';
  database: string;
  synchronize: boolean;
  logging: boolean;
  entities: string[];
  migrations: string[];
}

export interface SecurityConfig {
  jwtSecret: string;
  jwtExpiresIn: string;
  bcryptRounds: number;
  encryptionKey: string;
}

export interface AppConfig {
  port: number;
  nodeEnv: 'development' | 'production' | 'test';
  database: DatabaseConfig;
  security: SecurityConfig;
  features: {
    openBankingEnabled: boolean;
    plaidEnabled: boolean;
    mlCategorization: boolean;
    investmentAnalysis: boolean;
  };
}

// Error types
export class NestiaError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 500,
    public details?: unknown
  ) {
    super(message);
    this.name = 'NestiaError';
  }
}

export class ValidationError extends NestiaError {
  constructor(message: string, details?: unknown) {
    super(message, 'VALIDATION_ERROR', 400, details);
    this.name = 'ValidationError';
  }
}

export class AuthenticationError extends NestiaError {
  constructor(message: string = 'Authentication failed') {
    super(message, 'AUTHENTICATION_ERROR', 401);
    this.name = 'AuthenticationError';
  }
}

export class AuthorizationError extends NestiaError {
  constructor(message: string = 'Access denied') {
    super(message, 'AUTHORIZATION_ERROR', 403);
    this.name = 'AuthorizationError';
  }
}

export class NotFoundError extends NestiaError {
  constructor(resource: string) {
    super(`${resource} not found`, 'NOT_FOUND_ERROR', 404);
    this.name = 'NotFoundError';
  }
}

// Utility types
export type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

export type CreateInput<T> = Omit<T, 'id' | 'createdAt' | 'updatedAt'>;
export type UpdateInput<T> = DeepPartial<Omit<T, 'id' | 'createdAt' | 'updatedAt'>>;