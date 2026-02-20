import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull, Between } from 'typeorm';
import { Category } from '../../entities/category.entity';
import { ICategoryRepository } from '../interfaces/category-repository.interface';
import { BaseRepository } from './base.repository';

@Injectable()
export class CategoryRepository
  extends BaseRepository<Category>
  implements ICategoryRepository
{
  constructor(
    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
  ) {
    super(categoryRepository);
  }

  async findByUserId(userId: string): Promise<Category[]> {
    return await this.categoryRepository.find({
      where: { userId },
      order: { name: 'ASC' },
    });
  }

  async findActiveByUserId(userId: string): Promise<Category[]> {
    return await this.categoryRepository.find({
      where: { userId, isActive: true },
      order: { name: 'ASC' },
    });
  }

  async findSystemCategories(): Promise<Category[]> {
    return await this.categoryRepository.find({
      where: { isSystemCategory: true, isActive: true },
      order: { name: 'ASC' },
    });
  }

  async findRootCategories(userId: string): Promise<Category[]> {
    return await this.categoryRepository.find({
      where: {
        userId,
        parentCategoryId: IsNull(),
        isActive: true,
      },
      order: { name: 'ASC' },
    });
  }

  async findSubcategories(parentCategoryId: string): Promise<Category[]> {
    return await this.categoryRepository.find({
      where: {
        parentCategoryId,
        isActive: true,
      },
      order: { name: 'ASC' },
    });
  }

  async findCategoryHierarchy(userId: string): Promise<Category[]> {
    return await this.categoryRepository
      .createQueryBuilder('category')
      .leftJoinAndSelect('category.subcategories', 'subcategories')
      .where('category.userId = :userId', { userId })
      .andWhere('category.parentCategoryId IS NULL')
      .andWhere('category.isActive = :isActive', { isActive: true })
      .orderBy('category.name', 'ASC')
      .addOrderBy('subcategories.name', 'ASC')
      .getMany();
  }

  async findByName(userId: string, name: string): Promise<Category | null> {
    return await this.categoryRepository.findOne({
      where: { userId, name },
    });
  }

  async hasTransactions(categoryId: string): Promise<boolean> {
    const count = await this.categoryRepository
      .createQueryBuilder('category')
      .leftJoin('category.transactions', 'transaction')
      .where('category.id = :categoryId', { categoryId })
      .andWhere('transaction.id IS NOT NULL')
      .getCount();

    return count > 0;
  }

  async getCategoryUsage(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<Array<{
    categoryId: string;
    categoryName: string;
    transactionCount: number;
    totalAmount: number;
  }>> {
    const result = await this.categoryRepository
      .createQueryBuilder('category')
      .leftJoin('category.transactions', 'transaction')
      .select([
        'category.id as categoryId',
        'category.name as categoryName',
        'COUNT(transaction.id) as transactionCount',
        'SUM(transaction.amount) as totalAmount',
      ])
      .where('category.userId = :userId', { userId })
      .andWhere('transaction.transactionDate BETWEEN :startDate AND :endDate', {
        startDate,
        endDate,
      })
      .groupBy('category.id')
      .orderBy('totalAmount', 'DESC')
      .getRawMany();

    return result.map((row) => ({
      categoryId: row.categoryId,
      categoryName: row.categoryName,
      transactionCount: parseInt(row.transactionCount) || 0,
      totalAmount: parseFloat(row.totalAmount) || 0,
    }));
  }
}