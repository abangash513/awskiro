/**
 * Account-related type definitions
 */

import { UUID, Timestamp, CurrencyCode, Decimal } from './index';

export type AccountType = 'checking' | 'savings' | 'credit' | 'investment' | 'loan';

export interface Account {
  id: UUID;
  userId: UUID;
  institutionName: string;
  accountType: AccountType;
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

export interface AccountBalance {
  accountId: UUID;
  current: Decimal;
  available?: Decimal;
  currencyCode: CurrencyCode;
  asOfDate: Timestamp;
}

export interface AccountConnection {
  id: UUID;
  userId: UUID;
  accountId: UUID;
  connectionType: 'open_banking' | 'plaid' | 'manual';
  institutionId?: string;
  accessToken?: string; // Encrypted
  refreshToken?: string; // Encrypted
  connectionStatus: 'active' | 'inactive' | 'error' | 'requires_reauth';
  lastSyncAt?: Timestamp;
  lastErrorAt?: Timestamp;
  lastErrorMessage?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface AccountSyncResult {
  accountId: UUID;
  success: boolean;
  transactionsAdded: number;
  transactionsUpdated: number;
  balanceUpdated: boolean;
  errorMessage?: string;
  syncedAt: Timestamp;
}

export interface CreateAccountInput {
  institutionName: string;
  accountType: AccountType;
  accountName: string;
  accountNumberHash?: string;
  currencyCode?: CurrencyCode;
  balanceCurrent?: Decimal;
  balanceAvailable?: Decimal;
}

export interface UpdateAccountInput {
  institutionName?: string;
  accountName?: string;
  isActive?: boolean;
  balanceCurrent?: Decimal;
  balanceAvailable?: Decimal;
}

export interface AccountSummary {
  totalAccounts: number;
  accountsByType: Record<AccountType, number>;
  totalBalance: Decimal;
  balanceByType: Record<AccountType, Decimal>;
  balanceByCurrency: Record<CurrencyCode, Decimal>;
  lastSyncAt?: Timestamp;
}

export interface AccountInsight {
  accountId: UUID;
  insightType: 'low_balance' | 'unusual_activity' | 'sync_issue' | 'dormant_account';
  title: string;
  description: string;
  severity: 'low' | 'medium' | 'high';
  actionRequired: boolean;
  generatedAt: Timestamp;
}