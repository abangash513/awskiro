import { CategoryRule } from '../../entities/category-rule.entity';
import { IBaseRepository } from './base-repository.interface';

export interface ICategoryRuleRepository extends IBaseRepository<CategoryRule> {
  findByUserId(userId: string): Promise<CategoryRule[]>;
  findActiveByUserId(userId: string): Promise<CategoryRule[]>;
  findByCategoryId(categoryId: string): Promise<CategoryRule[]>;
  findByPriority(userId: string, minPriority?: number): Promise<CategoryRule[]>;
  updateMatchCount(ruleId: string, increment: number): Promise<void>;
  updateCorrectCount(ruleId: string, increment: number): Promise<void>;
  findMatchingRules(
    userId: string,
    transactionData: {
      merchantName?: string;
      description: string;
      amount: number;
      transactionType: 'debit' | 'credit';
    }
  ): Promise<CategoryRule[]>;
}