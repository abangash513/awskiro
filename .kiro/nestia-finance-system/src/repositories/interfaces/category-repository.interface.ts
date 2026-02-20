import { Category } from '../../entities/category.entity';
import { IBaseRepository } from './base-repository.interface';

/**
 * Category repository interface
 */
export interface ICategoryRepository extends IBaseRepository<Category> {
  /**
   * Find categories by user ID
   */
  findByUserId(userId: string): Promise<Category[]>;

  /**
   * Find active categories by user ID
   */
  findActiveByUserId(userId: string): Promise<Category[]>;

  /**
   * Find system categories
   */
  findSystemCategories(): Promise<Category[]>;

  /**
   * Find root categories (no parent)
   */
  findRootCategories(userId: string): Promise<Category[]>;

  /**
   * Find subcategories by parent ID
   */
  findSubcategories(parentCategoryId: string): Promise<Category[]>;

  /**
   * Find category hierarchy for user
   */
  findCategoryHierarchy(userId: string): Promise<Category[]>;

  /**
   * Find category by name
   */
  findByName(userId: string, name: string): Promise<Category | null>;

  /**
   * Check if category has transactions
   */
  hasTransactions(categoryId: string): Promise<boolean>;

  /**
   * Get category usage statistics
   */
  getCategoryUsage(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<Array<{
    categoryId: string;
    categoryName: string;
    transactionCount: number;
    totalAmount: number;
  }>>;
}