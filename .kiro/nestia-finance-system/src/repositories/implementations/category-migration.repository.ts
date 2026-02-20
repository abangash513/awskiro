import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CategoryMigration } from '../../entities/category-migration.entity';
import { ICategoryMigrationRepository } from '../interfaces/category-migration-repository.interface';
import { BaseRepository } from './base.repository';

@Injectable()
export class CategoryMigrationRepository
  extends BaseRepository<CategoryMigration>
  implements ICategoryMigrationRepository
{
  constructor(
    @InjectRepository(CategoryMigration)
    private readonly categoryMigrationRepository: Repository<CategoryMigration>,
  ) {
    super(categoryMigrationRepository);
  }

  async findByUserId(userId: string): Promise<CategoryMigration[]> {
    return await this.categoryMigrationRepository.find({
      where: { userId },
      relations: ['fromCategory', 'toCategory'],
      order: { createdAt: 'DESC' },
    });
  }

  async findByStatus(status: string): Promise<CategoryMigration[]> {
    return await this.categoryMigrationRepository.find({
      where: { status: status as any },
      relations: ['fromCategory', 'toCategory', 'user'],
      order: { createdAt: 'ASC' },
    });
  }

  async findByFromCategory(fromCategoryId: string): Promise<CategoryMigration[]> {
    return await this.categoryMigrationRepository.find({
      where: { fromCategoryId },
      relations: ['toCategory', 'user'],
      order: { createdAt: 'DESC' },
    });
  }

  async findByToCategory(toCategoryId: string): Promise<CategoryMigration[]> {
    return await this.categoryMigrationRepository.find({
      where: { toCategoryId },
      relations: ['fromCategory', 'user'],
      order: { createdAt: 'DESC' },
    });
  }

  async findPendingMigrations(userId: string): Promise<CategoryMigration[]> {
    return await this.categoryMigrationRepository.find({
      where: { 
        userId, 
        status: 'pending' as any 
      },
      relations: ['fromCategory', 'toCategory'],
      order: { createdAt: 'ASC' },
    });
  }

  async updateStatus(
    migrationId: string, 
    status: string, 
    errorMessage?: string
  ): Promise<void> {
    const updateData: any = { 
      status: status as any,
      updatedAt: new Date()
    };
    
    if (errorMessage) {
      updateData.errorMessage = errorMessage;
    }

    await this.categoryMigrationRepository.update(migrationId, updateData);
  }

  async markCompleted(
    migrationId: string, 
    affectedTransactions: number
  ): Promise<void> {
    await this.categoryMigrationRepository.update(migrationId, {
      status: 'completed' as any,
      affectedTransactions,
      completedAt: new Date(),
      updatedAt: new Date(),
    });
  }
}