import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { CategoryMigration } from '../../../entities/category-migration.entity';
import { Transaction } from '../../../entities/transaction.entity';
import { Category } from '../../../entities/category.entity';
import { ICategoryMigrationRepository } from '../../../repositories/interfaces/category-migration-repository.interface';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateInput, UpdateInput, UUID } from '../../../types';

export interface MigrationRequest {
  fromCategoryId: UUID;
  toCategoryId: UUID;
  reason: string;
  preserveHistory?: boolean;
  migrateSubcategories?: boolean;
}

export interface MigrationProgress {
  migrationId: UUID;
  status: 'pending' | 'in_progress' | 'completed' | 'failed';
  totalTransactions: number;
  processedTransactions: number;
  errorMessage?: string;
  startedAt?: Date;
  completedAt?: Date;
}

@Injectable()
export class CategoryMigrationService {
  constructor(
    private readonly categoryMigrationRepository: ICategoryMigrationRepository,
    @InjectRepository(Transaction)
    private readonly transactionRepository: Repository<Transaction>,
    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
  ) {}

  async createMigration(
    userId: UUID,
    migrationRequest: MigrationRequest
  ): Promise<CategoryMigration> {
    // Validate categories exist and belong to user
    await this.validateCategories(userId, migrationRequest.fromCategoryId, migrationRequest.toCategoryId);

    // Check if migration already exists
    const existingMigrations = await this.categoryMigrationRepository.findByFromCategory(
      migrationRequest.fromCategoryId
    );
    
    const pendingMigration = existingMigrations.find(m => 
      m.status === 'pending' || m.status === 'in_progress'
    );
    
    if (pendingMigration) {
      throw new BadRequestException('A migration for this category is already in progress');
    }

    // Count affected transactions
    const affectedTransactions = await this.countAffectedTransactions(
      migrationRequest.fromCategoryId,
      migrationRequest.migrateSubcategories
    );

    const migrationData: CreateInput<CategoryMigration> = {
      userId,
      fromCategoryId: migrationRequest.fromCategoryId,
      toCategoryId: migrationRequest.toCategoryId,
      reason: migrationRequest.reason,
      status: 'pending',
      preserveHistory: migrationRequest.preserveHistory ?? true,
      migrateSubcategories: migrationRequest.migrateSubcategories ?? false,
      totalTransactions: affectedTransactions,
      processedTransactions: 0,
    };

    return await this.categoryMigrationRepository.create(migrationData);
  }

  async executeMigration(migrationId: UUID): Promise<void> {
    const migration = await this.categoryMigrationRepository.findById(migrationId);
    if (!migration) {
      throw new NotFoundException(`Migration with ID ${migrationId} not found`);
    }

    if (migration.status !== 'pending') {
      throw new BadRequestException(`Migration is not in pending status: ${migration.status}`);
    }

    try {
      // Update status to in_progress
      await this.categoryMigrationRepository.updateStatus(migrationId, 'in_progress');

      let processedCount = 0;

      // Migrate transactions from the main category
      const mainCategoryTransactions = await this.transactionRepository.find({
        where: { categoryId: migration.fromCategoryId }
      });

      for (const transaction of mainCategoryTransactions) {
        await this.transactionRepository.update(transaction.id, {
          categoryId: migration.toCategoryId,
          updatedAt: new Date(),
        });
        processedCount++;
      }

      // Migrate subcategories if requested
      if (migration.migrateSubcategories) {
        const subcategories = await this.categoryRepository.find({
          where: { parentCategoryId: migration.fromCategoryId }
        });

        for (const subcategory of subcategories) {
          // Update subcategory parent
          await this.categoryRepository.update(subcategory.id, {
            parentCategoryId: migration.toCategoryId,
          });

          // Migrate transactions from subcategory
          const subcategoryTransactions = await this.transactionRepository.find({
            where: { categoryId: subcategory.id }
          });

          for (const transaction of subcategoryTransactions) {
            await this.transactionRepository.update(transaction.id, {
              categoryId: migration.toCategoryId,
              updatedAt: new Date(),
            });
            processedCount++;
          }
        }
      }

      // Mark migration as completed
      await this.categoryMigrationRepository.markCompleted(migrationId, processedCount);

      // Optionally deactivate the old category if not preserving history
      if (!migration.preserveHistory) {
        await this.categoryRepository.update(migration.fromCategoryId, {
          isActive: false,
        });
      }

    } catch (error) {
      await this.categoryMigrationRepository.updateStatus(
        migrationId,
        'failed',
        error.message
      );
      throw error;
    }
  }

  async getMigrationProgress(migrationId: UUID): Promise<MigrationProgress> {
    const migration = await this.categoryMigrationRepository.findById(migrationId);
    if (!migration) {
      throw new NotFoundException(`Migration with ID ${migrationId} not found`);
    }

    return {
      migrationId: migration.id,
      status: migration.status as any,
      totalTransactions: migration.totalTransactions,
      processedTransactions: migration.processedTransactions,
      errorMessage: migration.errorMessage,
      startedAt: migration.startedAt,
      completedAt: migration.completedAt,
    };
  }

  async getUserMigrations(userId: UUID): Promise<CategoryMigration[]> {
    return await this.categoryMigrationRepository.findByUserId(userId);
  }

  async getPendingMigrations(userId: UUID): Promise<CategoryMigration[]> {
    return await this.categoryMigrationRepository.findPendingMigrations(userId);
  }

  async cancelMigration(migrationId: UUID): Promise<void> {
    const migration = await this.categoryMigrationRepository.findById(migrationId);
    if (!migration) {
      throw new NotFoundException(`Migration with ID ${migrationId} not found`);
    }

    if (migration.status === 'completed') {
      throw new BadRequestException('Cannot cancel a completed migration');
    }

    if (migration.status === 'in_progress') {
      throw new BadRequestException('Cannot cancel a migration that is currently in progress');
    }

    await this.categoryMigrationRepository.updateStatus(migrationId, 'cancelled');
  }

  async rollbackMigration(migrationId: UUID): Promise<void> {
    const migration = await this.categoryMigrationRepository.findById(migrationId);
    if (!migration) {
      throw new NotFoundException(`Migration with ID ${migrationId} not found`);
    }

    if (migration.status !== 'completed') {
      throw new BadRequestException('Can only rollback completed migrations');
    }

    if (!migration.preserveHistory) {
      throw new BadRequestException('Cannot rollback migration that did not preserve history');
    }

    try {
      // Update status to indicate rollback in progress
      await this.categoryMigrationRepository.updateStatus(migrationId, 'rolling_back');

      // Revert transactions back to original category
      const migratedTransactions = await this.transactionRepository.find({
        where: { categoryId: migration.toCategoryId }
      });

      // Filter transactions that were migrated after the migration started
      const transactionsToRevert = migratedTransactions.filter(t => 
        t.updatedAt >= migration.startedAt!
      );

      for (const transaction of transactionsToRevert) {
        await this.transactionRepository.update(transaction.id, {
          categoryId: migration.fromCategoryId,
          updatedAt: new Date(),
        });
      }

      // Reactivate the original category if it was deactivated
      await this.categoryRepository.update(migration.fromCategoryId, {
        isActive: true,
      });

      // Mark migration as rolled back
      await this.categoryMigrationRepository.updateStatus(migrationId, 'rolled_back');

    } catch (error) {
      await this.categoryMigrationRepository.updateStatus(
        migrationId,
        'rollback_failed',
        error.message
      );
      throw error;
    }
  }

  private async validateCategories(
    userId: UUID,
    fromCategoryId: UUID,
    toCategoryId: UUID
  ): Promise<void> {
    if (fromCategoryId === toCategoryId) {
      throw new BadRequestException('Source and destination categories cannot be the same');
    }

    const fromCategory = await this.categoryRepository.findOne({
      where: { id: fromCategoryId, userId }
    });

    if (!fromCategory) {
      throw new NotFoundException(`Source category with ID ${fromCategoryId} not found`);
    }

    const toCategory = await this.categoryRepository.findOne({
      where: { id: toCategoryId, userId }
    });

    if (!toCategory) {
      throw new NotFoundException(`Destination category with ID ${toCategoryId} not found`);
    }

    // Check for circular reference (destination cannot be a child of source)
    if (await this.isChildCategory(fromCategoryId, toCategoryId)) {
      throw new BadRequestException('Cannot migrate to a subcategory of the source category');
    }
  }

  private async isChildCategory(parentId: UUID, childId: UUID): Promise<boolean> {
    const category = await this.categoryRepository.findOne({
      where: { id: childId }
    });

    if (!category || !category.parentCategoryId) {
      return false;
    }

    if (category.parentCategoryId === parentId) {
      return true;
    }

    return await this.isChildCategory(parentId, category.parentCategoryId);
  }

  private async countAffectedTransactions(
    categoryId: UUID,
    includeSubcategories: boolean = false
  ): Promise<number> {
    let count = await this.transactionRepository.count({
      where: { categoryId }
    });

    if (includeSubcategories) {
      const subcategories = await this.categoryRepository.find({
        where: { parentCategoryId: categoryId }
      });

      for (const subcategory of subcategories) {
        const subcategoryCount = await this.transactionRepository.count({
          where: { categoryId: subcategory.id }
        });
        count += subcategoryCount;
      }
    }

    return count;
  }
}