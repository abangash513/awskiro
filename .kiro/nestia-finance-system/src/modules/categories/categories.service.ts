import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Category } from '../../entities/category.entity';
import { CreateInput, UpdateInput, UUID } from '../../types';
import { CategoryRuleService, CategorySuggestion } from './services/category-rule.service';
import { CategoryMigrationService, MigrationRequest, MigrationProgress } from './services/category-migration.service';

@Injectable()
export class CategoriesService {
  constructor(
    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
    private readonly categoryRuleService: CategoryRuleService,
    private readonly categoryMigrationService: CategoryMigrationService,
  ) {}

  async create(categoryData: CreateInput<Category>): Promise<Category> {
    const category = this.categoryRepository.create(categoryData);
    return await this.categoryRepository.save(category);
  }

  async findAll(userId: UUID): Promise<Category[]> {
    return await this.categoryRepository.find({
      where: { userId },
      order: { name: 'ASC' },
    });
  }

  async findById(id: UUID, userId: UUID): Promise<Category> {
    const category = await this.categoryRepository.findOne({
      where: { id, userId },
    });

    if (!category) {
      throw new NotFoundException(`Category with ID ${id} not found`);
    }

    return category;
  }

  async findByParent(parentCategoryId: UUID, userId: UUID): Promise<Category[]> {
    return await this.categoryRepository.find({
      where: { parentCategoryId, userId },
      order: { name: 'ASC' },
    });
  }

  async findSystemCategories(): Promise<Category[]> {
    return await this.categoryRepository.find({
      where: { isSystemCategory: true },
      order: { name: 'ASC' },
    });
  }

  async update(id: UUID, userId: UUID, updateData: UpdateInput<Category>): Promise<Category> {
    const category = await this.findById(id, userId);
    
    Object.assign(category, updateData);
    return await this.categoryRepository.save(category);
  }

  async delete(id: UUID, userId: UUID): Promise<void> {
    const category = await this.findById(id, userId);
    
    // Check if category has subcategories
    const subcategories = await this.findByParent(id, userId);
    if (subcategories.length > 0) {
      throw new Error('Cannot delete category with subcategories');
    }

    await this.categoryRepository.remove(category);
  }

  async createDefaultCategories(userId: UUID): Promise<Category[]> {
    const defaultCategories = [
      { name: 'Income', userId, isSystemCategory: false, isActive: true },
      { name: 'Salary', userId, isSystemCategory: false, isActive: true, parentCategoryId: null },
      { name: 'Housing', userId, isSystemCategory: false, isActive: true },
      { name: 'Rent', userId, isSystemCategory: false, isActive: true, parentCategoryId: null },
      { name: 'Utilities', userId, isSystemCategory: false, isActive: true, parentCategoryId: null },
      { name: 'Transportation', userId, isSystemCategory: false, isActive: true },
      { name: 'Gas & Fuel', userId, isSystemCategory: false, isActive: true, parentCategoryId: null },
      { name: 'Food & Dining', userId, isSystemCategory: false, isActive: true },
      { name: 'Groceries', userId, isSystemCategory: false, isActive: true, parentCategoryId: null },
      { name: 'Restaurants', userId, isSystemCategory: false, isActive: true, parentCategoryId: null },
      { name: 'Shopping', userId, isSystemCategory: false, isActive: true },
      { name: 'Entertainment', userId, isSystemCategory: false, isActive: true },
      { name: 'Bills & Utilities', userId, isSystemCategory: false, isActive: true },
      { name: 'Healthcare', userId, isSystemCategory: false, isActive: true },
      { name: 'Education', userId, isSystemCategory: false, isActive: true },
      { name: 'Personal Care', userId, isSystemCategory: false, isActive: true },
      { name: 'Investments', userId, isSystemCategory: false, isActive: true },
      { name: 'Savings', userId, isSystemCategory: false, isActive: true },
    ];

    const categories = this.categoryRepository.create(defaultCategories);
    const savedCategories = await this.categoryRepository.save(categories);

    // Create category name to ID mapping for rule creation
    const categoryMap = new Map<string, UUID>();
    savedCategories.forEach(cat => categoryMap.set(cat.name, cat.id));

    // Create default category rules
    await this.categoryRuleService.createDefaultRules(userId, categoryMap);

    return savedCategories;
  }

  // Category Rule Integration Methods
  async suggestCategoryForTransaction(
    userId: UUID,
    transactionData: {
      merchantName?: string;
      description: string;
      amount: number;
      transactionType: 'debit' | 'credit';
    }
  ): Promise<CategorySuggestion[]> {
    return await this.categoryRuleService.suggestCategory(userId, transactionData);
  }

  async recordCategoryPredictionFeedback(
    ruleId: UUID,
    wasCorrect: boolean
  ): Promise<void> {
    if (wasCorrect) {
      await this.categoryRuleService.recordCorrectPrediction(ruleId);
    } else {
      await this.categoryRuleService.recordIncorrectPrediction(ruleId);
    }
  }

  async getCategoryRulePerformance(userId: UUID) {
    return await this.categoryRuleService.getPerformanceMetrics(userId);
  }

  async optimizeCategoryRules(userId: UUID): Promise<void> {
    await this.categoryRuleService.optimizeRules(userId);
  }

  // Category Migration Methods
  async requestCategoryMigration(
    userId: UUID,
    migrationRequest: MigrationRequest
  ) {
    return await this.categoryMigrationService.createMigration(userId, migrationRequest);
  }

  async executeCategoryMigration(migrationId: UUID): Promise<void> {
    await this.categoryMigrationService.executeMigration(migrationId);
  }

  async getMigrationProgress(migrationId: UUID): Promise<MigrationProgress> {
    return await this.categoryMigrationService.getMigrationProgress(migrationId);
  }

  async getUserMigrations(userId: UUID) {
    return await this.categoryMigrationService.getUserMigrations(userId);
  }

  async getPendingMigrations(userId: UUID) {
    return await this.categoryMigrationService.getPendingMigrations(userId);
  }

  async cancelMigration(migrationId: UUID): Promise<void> {
    await this.categoryMigrationService.cancelMigration(migrationId);
  }

  async rollbackMigration(migrationId: UUID): Promise<void> {
    await this.categoryMigrationService.rollbackMigration(migrationId);
  }

  // Enhanced hierarchy methods
  async getCategoryHierarchy(userId: UUID): Promise<Category[]> {
    const categories = await this.findAll(userId);
    return this.buildCategoryTree(categories);
  }

  private buildCategoryTree(categories: Category[]): Category[] {
    const categoryMap = new Map<UUID, Category>();
    const rootCategories: Category[] = [];

    // First pass: create map and identify root categories
    categories.forEach(category => {
      categoryMap.set(category.id, { ...category, children: [] });
      if (!category.parentCategoryId) {
        rootCategories.push(categoryMap.get(category.id)!);
      }
    });

    // Second pass: build parent-child relationships
    categories.forEach(category => {
      if (category.parentCategoryId) {
        const parent = categoryMap.get(category.parentCategoryId);
        const child = categoryMap.get(category.id);
        if (parent && child) {
          if (!parent.children) parent.children = [];
          parent.children.push(child);
        }
      }
    });

    return rootCategories;
  }

  async validateCategoryHierarchy(userId: UUID): Promise<boolean> {
    const categories = await this.findAll(userId);
    
    // Check for circular references
    for (const category of categories) {
      if (await this.hasCircularReference(category.id, category.parentCategoryId, categories)) {
        return false;
      }
    }
    
    return true;
  }

  private async hasCircularReference(
    categoryId: UUID,
    parentId: UUID | null,
    allCategories: Category[]
  ): Promise<boolean> {
    if (!parentId) return false;
    if (parentId === categoryId) return true;

    const parent = allCategories.find(c => c.id === parentId);
    if (!parent) return false;

    return await this.hasCircularReference(categoryId, parent.parentCategoryId, allCategories);
  }
}