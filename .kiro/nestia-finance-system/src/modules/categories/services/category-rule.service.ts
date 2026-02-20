import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { CategoryRule } from '../../../entities/category-rule.entity';
import { Transaction } from '../../../entities/transaction.entity';
import { ICategoryRuleRepository } from '../../../repositories/interfaces/category-rule-repository.interface';
import { CreateInput, UpdateInput, UUID } from '../../../types';

export interface CategorySuggestion {
  categoryId: UUID;
  categoryName: string;
  confidence: number;
  ruleId?: UUID;
  ruleName?: string;
  matchedConditions: string[];
}

export interface RulePerformanceMetrics {
  ruleId: UUID;
  ruleName: string;
  matchCount: number;
  correctCount: number;
  accuracy: number;
  confidenceScore: number;
  isActive: boolean;
}

@Injectable()
export class CategoryRuleService {
  constructor(
    private readonly categoryRuleRepository: ICategoryRuleRepository,
  ) {}

  async create(ruleData: CreateInput<CategoryRule>): Promise<CategoryRule> {
    // Validate rule conditions
    this.validateRuleConditions(ruleData.conditions);
    
    return await this.categoryRuleRepository.create(ruleData);
  }

  async findByUserId(userId: UUID): Promise<CategoryRule[]> {
    return await this.categoryRuleRepository.findByUserId(userId);
  }

  async findActiveByUserId(userId: UUID): Promise<CategoryRule[]> {
    return await this.categoryRuleRepository.findActiveByUserId(userId);
  }

  async findById(id: UUID): Promise<CategoryRule> {
    const rule = await this.categoryRuleRepository.findById(id);
    if (!rule) {
      throw new NotFoundException(`Category rule with ID ${id} not found`);
    }
    return rule;
  }

  async update(id: UUID, updateData: UpdateInput<CategoryRule>): Promise<CategoryRule> {
    const rule = await this.findById(id);
    
    if (updateData.conditions) {
      this.validateRuleConditions(updateData.conditions);
    }
    
    return await this.categoryRuleRepository.update(id, updateData);
  }

  async delete(id: UUID): Promise<void> {
    const rule = await this.findById(id);
    await this.categoryRuleRepository.delete(id);
  }

  async suggestCategory(
    userId: UUID,
    transactionData: {
      merchantName?: string;
      description: string;
      amount: number;
      transactionType: 'debit' | 'credit';
    }
  ): Promise<CategorySuggestion[]> {
    const matchingRules = await this.categoryRuleRepository.findMatchingRules(
      userId,
      transactionData
    );

    const suggestions: CategorySuggestion[] = [];

    for (const rule of matchingRules) {
      const matchedConditions = this.getMatchedConditions(rule, transactionData);
      
      suggestions.push({
        categoryId: rule.categoryId,
        categoryName: rule.category?.name || 'Unknown',
        confidence: rule.confidenceScore,
        ruleId: rule.id,
        ruleName: rule.name,
        matchedConditions,
      });

      // Update match count
      await this.categoryRuleRepository.updateMatchCount(rule.id, 1);
    }

    // Sort by confidence score (highest first) and priority (lowest first)
    return suggestions.sort((a, b) => {
      if (a.confidence !== b.confidence) {
        return b.confidence - a.confidence;
      }
      // If confidence is equal, prefer rules with higher priority (lower number)
      const ruleA = matchingRules.find(r => r.id === a.ruleId);
      const ruleB = matchingRules.find(r => r.id === b.ruleId);
      return (ruleA?.priority || 100) - (ruleB?.priority || 100);
    });
  }

  async recordCorrectPrediction(ruleId: UUID): Promise<void> {
    await this.categoryRuleRepository.updateCorrectCount(ruleId, 1);
  }

  async recordIncorrectPrediction(ruleId: UUID): Promise<void> {
    // For incorrect predictions, we don't increment correctCount
    // The accuracy will naturally decrease as matchCount increases
    // without correctCount increasing
  }

  async getPerformanceMetrics(userId: UUID): Promise<RulePerformanceMetrics[]> {
    const rules = await this.categoryRuleRepository.findByUserId(userId);
    
    return rules.map(rule => ({
      ruleId: rule.id,
      ruleName: rule.name,
      matchCount: rule.matchCount,
      correctCount: rule.correctCount,
      accuracy: rule.matchCount > 0 ? rule.correctCount / rule.matchCount : 0,
      confidenceScore: rule.confidenceScore,
      isActive: rule.isActive,
    }));
  }

  async optimizeRules(userId: UUID): Promise<void> {
    const metrics = await this.getPerformanceMetrics(userId);
    
    for (const metric of metrics) {
      // Disable rules with very low accuracy (< 30%) and sufficient data points
      if (metric.accuracy < 0.3 && metric.matchCount >= 10) {
        await this.categoryRuleRepository.update(metric.ruleId, {
          isActive: false,
        });
      }
      
      // Adjust confidence scores based on performance
      if (metric.matchCount >= 5) {
        const newConfidence = Math.max(0.1, Math.min(0.99, metric.accuracy));
        await this.categoryRuleRepository.update(metric.ruleId, {
          confidenceScore: newConfidence,
        });
      }
    }
  }

  async createDefaultRules(userId: UUID, categoryMap: Map<string, UUID>): Promise<CategoryRule[]> {
    const defaultRules: CreateInput<CategoryRule>[] = [
      // Income rules
      {
        userId,
        categoryId: categoryMap.get('Salary') || categoryMap.get('Income')!,
        name: 'Salary Deposits',
        description: 'Automatic detection of salary deposits',
        conditions: {
          transactionType: 'credit',
          description: {
            contains: ['salary', 'payroll', 'direct deposit', 'wages']
          },
          amount: { min: 1000 }
        },
        priority: 10,
        confidenceScore: 0.9,
        isActive: true,
      },
      
      // Housing rules
      {
        userId,
        categoryId: categoryMap.get('Rent') || categoryMap.get('Housing')!,
        name: 'Rent Payments',
        description: 'Monthly rent payments',
        conditions: {
          transactionType: 'debit',
          description: {
            contains: ['rent', 'rental', 'apartment', 'lease']
          },
          amount: { min: 500 }
        },
        priority: 20,
        confidenceScore: 0.85,
        isActive: true,
      },
      
      // Utilities
      {
        userId,
        categoryId: categoryMap.get('Utilities') || categoryMap.get('Bills & Utilities')!,
        name: 'Electric Bill',
        description: 'Electric utility payments',
        conditions: {
          transactionType: 'debit',
          merchantName: {
            contains: ['electric', 'power', 'energy', 'pge', 'edison']
          }
        },
        priority: 30,
        confidenceScore: 0.9,
        isActive: true,
      },
      
      // Transportation
      {
        userId,
        categoryId: categoryMap.get('Gas & Fuel') || categoryMap.get('Transportation')!,
        name: 'Gas Stations',
        description: 'Fuel purchases at gas stations',
        conditions: {
          transactionType: 'debit',
          merchantName: {
            contains: ['shell', 'exxon', 'chevron', 'bp', 'mobil', 'gas', 'fuel']
          }
        },
        priority: 40,
        confidenceScore: 0.8,
        isActive: true,
      },
      
      // Food & Dining
      {
        userId,
        categoryId: categoryMap.get('Restaurants') || categoryMap.get('Food & Dining')!,
        name: 'Restaurant Purchases',
        description: 'Restaurant and fast food purchases',
        conditions: {
          transactionType: 'debit',
          merchantName: {
            contains: ['restaurant', 'mcdonald', 'burger', 'pizza', 'starbucks', 'cafe']
          }
        },
        priority: 50,
        confidenceScore: 0.75,
        isActive: true,
      },
      
      // Groceries
      {
        userId,
        categoryId: categoryMap.get('Groceries') || categoryMap.get('Food & Dining')!,
        name: 'Grocery Stores',
        description: 'Grocery store purchases',
        conditions: {
          transactionType: 'debit',
          merchantName: {
            contains: ['grocery', 'market', 'safeway', 'kroger', 'walmart', 'target', 'costco']
          }
        },
        priority: 45,
        confidenceScore: 0.8,
        isActive: true,
      },
    ];

    const rules: CategoryRule[] = [];
    for (const ruleData of defaultRules) {
      try {
        const rule = await this.create(ruleData);
        rules.push(rule);
      } catch (error) {
        // Continue creating other rules even if one fails
        console.warn(`Failed to create default rule: ${ruleData.name}`, error);
      }
    }

    return rules;
  }

  private validateRuleConditions(conditions: any): void {
    if (!conditions || typeof conditions !== 'object') {
      throw new BadRequestException('Rule conditions must be a valid object');
    }

    // Validate that at least one condition is provided
    const hasConditions = 
      conditions.merchantName ||
      conditions.description ||
      conditions.amount ||
      conditions.transactionType;

    if (!hasConditions) {
      throw new BadRequestException('At least one rule condition must be specified');
    }

    // Validate amount conditions
    if (conditions.amount) {
      const { min, max, equals } = conditions.amount;
      if (min !== undefined && (typeof min !== 'number' || min < 0)) {
        throw new BadRequestException('Amount min must be a non-negative number');
      }
      if (max !== undefined && (typeof max !== 'number' || max < 0)) {
        throw new BadRequestException('Amount max must be a non-negative number');
      }
      if (equals !== undefined && (typeof equals !== 'number' || equals < 0)) {
        throw new BadRequestException('Amount equals must be a non-negative number');
      }
      if (min !== undefined && max !== undefined && min > max) {
        throw new BadRequestException('Amount min cannot be greater than max');
      }
    }

    // Validate string conditions
    const stringConditions = ['merchantName', 'description'];
    for (const field of stringConditions) {
      if (conditions[field]) {
        this.validateStringCondition(conditions[field], field);
      }
    }
  }

  private validateStringCondition(condition: any, fieldName: string): void {
    const validKeys = ['contains', 'equals', 'startsWith', 'endsWith'];
    const providedKeys = Object.keys(condition);
    
    if (providedKeys.length === 0) {
      throw new BadRequestException(`${fieldName} condition cannot be empty`);
    }

    for (const key of providedKeys) {
      if (!validKeys.includes(key)) {
        throw new BadRequestException(`Invalid ${fieldName} condition key: ${key}`);
      }
      
      if (!Array.isArray(condition[key]) || condition[key].length === 0) {
        throw new BadRequestException(`${fieldName}.${key} must be a non-empty array`);
      }
      
      for (const value of condition[key]) {
        if (typeof value !== 'string' || value.trim().length === 0) {
          throw new BadRequestException(`${fieldName}.${key} values must be non-empty strings`);
        }
      }
    }
  }

  private getMatchedConditions(
    rule: CategoryRule,
    transactionData: {
      merchantName?: string;
      description: string;
      amount: number;
      transactionType: 'debit' | 'credit';
    }
  ): string[] {
    const matched: string[] = [];
    const { conditions } = rule;

    if (conditions.transactionType && conditions.transactionType === transactionData.transactionType) {
      matched.push(`Transaction type: ${transactionData.transactionType}`);
    }

    if (conditions.amount) {
      const { min, max, equals } = conditions.amount;
      if (equals !== undefined && transactionData.amount === equals) {
        matched.push(`Amount equals $${equals}`);
      }
      if (min !== undefined && transactionData.amount >= min) {
        matched.push(`Amount >= $${min}`);
      }
      if (max !== undefined && transactionData.amount <= max) {
        matched.push(`Amount <= $${max}`);
      }
    }

    if (conditions.merchantName && transactionData.merchantName) {
      const merchantMatches = this.getStringMatches(conditions.merchantName, transactionData.merchantName);
      matched.push(...merchantMatches.map(m => `Merchant: ${m}`));
    }

    if (conditions.description) {
      const descriptionMatches = this.getStringMatches(conditions.description, transactionData.description);
      matched.push(...descriptionMatches.map(m => `Description: ${m}`));
    }

    return matched;
  }

  private getStringMatches(
    conditions: {
      contains?: string[];
      equals?: string[];
      startsWith?: string[];
      endsWith?: string[];
    },
    value: string
  ): string[] {
    const matches: string[] = [];
    const lowerValue = value.toLowerCase();

    if (conditions.equals) {
      for (const eq of conditions.equals) {
        if (lowerValue === eq.toLowerCase()) {
          matches.push(`equals "${eq}"`);
        }
      }
    }

    if (conditions.contains) {
      for (const contains of conditions.contains) {
        if (lowerValue.includes(contains.toLowerCase())) {
          matches.push(`contains "${contains}"`);
        }
      }
    }

    if (conditions.startsWith) {
      for (const starts of conditions.startsWith) {
        if (lowerValue.startsWith(starts.toLowerCase())) {
          matches.push(`starts with "${starts}"`);
        }
      }
    }

    if (conditions.endsWith) {
      for (const ends of conditions.endsWith) {
        if (lowerValue.endsWith(ends.toLowerCase())) {
          matches.push(`ends with "${ends}"`);
        }
      }
    }

    return matches;
  }
}