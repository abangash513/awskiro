/**
 * Transaction-related type definitions
 */

import { UUID, Timestamp, CurrencyCode, Decimal } from './index';

export type TransactionType = 'debit' | 'credit';

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
  transactionType: TransactionType;
  isRecurring: boolean;
  recurringGroupId?: UUID;
  confidenceScore?: Decimal;
  userVerified: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface TransactionCategory {
  id: UUID;
  userId: UUID;
  name: string;
  parentCategoryId?: UUID;
  colorCode?: string;
  iconName?: string;
  isSystemCategory: boolean;
  isActive: boolean;
  createdAt: Timestamp;
}

export interface TransactionRule {
  id: UUID;
  userId: UUID;
  name: string;
  description?: string;
  conditions: TransactionRuleCondition[];
  actions: TransactionRuleAction[];
  isActive: boolean;
  priority: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface TransactionRuleCondition {
  field: 'description' | 'merchantName' | 'amount' | 'accountId';
  operator: 'equals' | 'contains' | 'startsWith' | 'endsWith' | 'greaterThan' | 'lessThan' | 'between';
  value: string | number | string[] | number[];
  caseSensitive?: boolean;
}

export interface TransactionRuleAction {
  type: 'setCategoryId' | 'setMerchantName' | 'setRecurring';
  value: string | boolean;
}

export interface TransactionImport {
  id: UUID;
  userId: UUID;
  accountId: UUID;
  fileName: string;
  fileFormat: 'csv' | 'ofx' | 'qif' | 'json';
  status: 'pending' | 'processing' | 'completed' | 'failed';
  totalRows: number;
  processedRows: number;
  successfulRows: number;
  failedRows: number;
  errorMessages: string[];
  createdAt: Timestamp;
  completedAt?: Timestamp;
}

export interface TransactionDuplicate {
  id: UUID;
  originalTransactionId: UUID;
  duplicateTransactionId: UUID;
  similarityScore: Decimal;
  matchingFields: string[];
  status: 'pending' | 'confirmed_duplicate' | 'not_duplicate';
  resolvedAt?: Timestamp;
  resolvedBy?: UUID;
}

export interface CreateTransactionInput {
  accountId: UUID;
  transactionDate: Date;
  postedDate?: Date;
  amount: Decimal;
  description: string;
  merchantName?: string;
  categoryId?: UUID;
  subcategoryId?: UUID;
  transactionType: TransactionType;
}

export interface UpdateTransactionInput {
  description?: string;
  merchantName?: string;
  categoryId?: UUID;
  subcategoryId?: UUID;
  userVerified?: boolean;
}

export interface TransactionFilter {
  accountIds?: UUID[];
  categoryIds?: UUID[];
  dateFrom?: Date;
  dateTo?: Date;
  amountMin?: Decimal;
  amountMax?: Decimal;
  transactionType?: TransactionType;
  merchantName?: string;
  description?: string;
  isRecurring?: boolean;
  userVerified?: boolean;
}

export interface TransactionSummary {
  totalTransactions: number;
  totalAmount: Decimal;
  averageAmount: Decimal;
  transactionsByType: Record<TransactionType, number>;
  transactionsByCategory: Record<string, number>;
  dateRange: {
    earliest: Date;
    latest: Date;
  };
}

export interface TransactionEnrichment {
  transactionId: UUID;
  originalMerchantName?: string;
  cleanedMerchantName?: string;
  suggestedCategoryId?: UUID;
  confidenceScore?: Decimal;
  enrichmentSource: 'ml_model' | 'rule_engine' | 'user_correction' | 'external_api';
  enrichedAt: Timestamp;
}