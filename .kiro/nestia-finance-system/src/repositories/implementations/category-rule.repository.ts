import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CategoryRule } from '../../entities/category-rule.entity';
import { ICategoryRuleRepository } from '../interfaces/category-rule-repository.interface';
import { BaseRepository } from './base.repository';

@Injectable()
export class CategoryRuleRepository
  extends BaseRepository<CategoryRule>
  implements ICategoryRuleRepository
{
  constructor(
    @InjectRepository(CategoryRule)
    private readonly categoryRuleRepository: Repository<CategoryRule>,
  ) {
    super(categoryRuleRepository);
  }

  async findByUserId(userId: string): Promise<CategoryRule[]> {
    return await this.categoryRuleRepository.find({
      where: { userId },
      relations: ['category'],
      order: { priority: 'ASC', createdAt: 'DESC' },
    });
  }

  async findActiveByUserId(userId: string): Promise<CategoryRule[]> {
    return await this.categoryRuleRepository.find({
      where: { userId, isActive: true },
      relations: ['category'],
      order: { priority: 'ASC', createdAt: 'DESC' },
    });
  }

  async findByCategoryId(categoryId: string): Promise<CategoryRule[]> {
    return await this.categoryRuleRepository.find({
      where: { categoryId, isActive: true },
      order: { priority: 'ASC' },
    });
  }

  async findByPriority(userId: string, minPriority = 0): Promise<CategoryRule[]> {
    return await this.categoryRuleRepository
      .createQueryBuilder('rule')
      .where('rule.userId = :userId', { userId })
      .andWhere('rule.isActive = :isActive', { isActive: true })
      .andWhere('rule.priority >= :minPriority', { minPriority })
      .orderBy('rule.priority', 'ASC')
      .getMany();
  }

  async updateMatchCount(ruleId: string, increment: number): Promise<void> {
    await this.categoryRuleRepository
      .createQueryBuilder()
      .update(CategoryRule)
      .set({ matchCount: () => `matchCount + ${increment}` })
      .where('id = :ruleId', { ruleId })
      .execute();
  }

  async updateCorrectCount(ruleId: string, increment: number): Promise<void> {
    await this.categoryRuleRepository
      .createQueryBuilder()
      .update(CategoryRule)
      .set({ correctCount: () => `correctCount + ${increment}` })
      .where('id = :ruleId', { ruleId })
      .execute();
  }

  async findMatchingRules(
    userId: string,
    transactionData: {
      merchantName?: string;
      description: string;
      amount: number;
      transactionType: 'debit' | 'credit';
    }
  ): Promise<CategoryRule[]> {
    const rules = await this.findActiveByUserId(userId);
    
    return rules.filter(rule => this.evaluateRule(rule, transactionData));
  }

  private evaluateRule(
    rule: CategoryRule,
    transactionData: {
      merchantName?: string;
      description: string;
      amount: number;
      transactionType: 'debit' | 'credit';
    }
  ): boolean {
    const { conditions } = rule;
    
    // Check transaction type
    if (conditions.transactionType && conditions.transactionType !== transactionData.transactionType) {
      return false;
    }

    // Check amount conditions
    if (conditions.amount) {
      const { min, max, equals } = conditions.amount;
      if (equals !== undefined && transactionData.amount !== equals) return false;
      if (min !== undefined && transactionData.amount < min) return false;
      if (max !== undefined && transactionData.amount > max) return false;
    }

    // Check merchant name conditions
    if (conditions.merchantName && transactionData.merchantName) {
      if (!this.evaluateStringConditions(conditions.merchantName, transactionData.merchantName)) {
        return false;
      }
    }

    // Check description conditions
    if (conditions.description) {
      if (!this.evaluateStringConditions(conditions.description, transactionData.description)) {
        return false;
      }
    }

    return true;
  }

  private evaluateStringConditions(
    conditions: {
      contains?: string[];
      equals?: string[];
      startsWith?: string[];
      endsWith?: string[];
    },
    value: string
  ): boolean {
    const lowerValue = value.toLowerCase();

    if (conditions.equals) {
      return conditions.equals.some(eq => lowerValue === eq.toLowerCase());
    }

    if (conditions.contains) {
      return conditions.contains.some(contains => lowerValue.includes(contains.toLowerCase()));
    }

    if (conditions.startsWith) {
      return conditions.startsWith.some(starts => lowerValue.startsWith(starts.toLowerCase()));
    }

    if (conditions.endsWith) {
      return conditions.endsWith.some(ends => lowerValue.endsWith(ends.toLowerCase()));
    }

    return false;
  }
}