import { Account } from '../../entities/account.entity';
import { IBaseRepository } from './base-repository.interface';

/**
 * Account repository interface
 */
export interface IAccountRepository extends IBaseRepository<Account> {
  /**
   * Find accounts by user ID
   */
  findByUserId(userId: string): Promise<Account[]>;

  /**
   * Find active accounts by user ID
   */
  findActiveByUserId(userId: string): Promise<Account[]>;

  /**
   * Find account by user ID and account ID
   */
  findByUserIdAndAccountId(userId: string, accountId: string): Promise<Account | null>;

  /**
   * Update account balance
   */
  updateBalance(accountId: string, currentBalance: number, availableBalance?: number): Promise<void>;

  /**
   * Update last sync timestamp
   */
  updateLastSync(accountId: string): Promise<void>;

  /**
   * Find accounts by institution
   */
  findByInstitution(institutionName: string): Promise<Account[]>;

  /**
   * Find accounts by type
   */
  findByType(accountType: string): Promise<Account[]>;
}