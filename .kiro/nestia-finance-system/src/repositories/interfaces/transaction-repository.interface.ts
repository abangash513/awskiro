import { Transaction } from '../../entities/transaction.entity';
import { IBaseRepository } from './base-repository.interface';

/**
 * Transaction repository interface
 */
export interface ITransactionRepository extends IBaseRepository<Transaction> {
  /**
   * Find transactions by account ID
   */
  findByAccountId(accountId: string, limit?: number, offset?: number): Promise<Transaction[]>;

  /**
   * Find transactions by user ID (across all accounts)
   */
  findByUserId(userId: string, limit?: number, offset?: number): Promise<Transaction[]>;

  /**
   * Find transactions by date range
   */
  findByDateRange(
    accountId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<Transaction[]>;

  /**
   * Find transactions by category
   */
  findByCategory(categoryId: string, limit?: number, offset?: number): Promise<Transaction[]>;

  /**
   * Find recurring transactions
   */
  findRecurringTransactions(accountId?: string): Promise<Transaction[]>;

  /**
   * Find transactions by amount range
   */
  findByAmountRange(
    accountId: string,
    minAmount: number,
    maxAmount: number,
  ): Promise<Transaction[]>;

  /**
   * Search transactions by description or merchant
   */
  searchByDescription(
    userId: string,
    searchTerm: string,
    limit?: number,
  ): Promise<Transaction[]>;

  /**
   * Find unverified transactions
   */
  findUnverified(userId: string): Promise<Transaction[]>;

  /**
   * Find transactions needing categorization
   */
  findUncategorized(userId: string): Promise<Transaction[]>;

  /**
   * Get transaction statistics for a period
   */
  getStatistics(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<{
    totalTransactions: number;
    totalIncome: number;
    totalExpenses: number;
    averageTransaction: number;
  }>;
}