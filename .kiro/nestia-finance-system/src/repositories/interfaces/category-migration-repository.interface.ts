import { CategoryMigration } from '../../entities/category-migration.entity';
import { IBaseRepository } from './base-repository.interface';

export interface ICategoryMigrationRepository extends IBaseRepository<CategoryMigration> {
  findByUserId(userId: string): Promise<CategoryMigration[]>;
  findByStatus(status: string): Promise<CategoryMigration[]>;
  findByFromCategory(fromCategoryId: string): Promise<CategoryMigration[]>;
  findByToCategory(toCategoryId: string): Promise<CategoryMigration[]>;
  findPendingMigrations(userId: string): Promise<CategoryMigration[]>;
  updateStatus(migrationId: string, status: string, errorMessage?: string): Promise<void>;
  markCompleted(migrationId: string, affectedTransactions: number): Promise<void>;
}