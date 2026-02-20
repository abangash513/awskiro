import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, Like, IsNull } from 'typeorm';
import { Transaction } from '../../entities/transaction.entity';
import { ITransactionRepository } from '../interfaces/transaction-repository.interface';
import { BaseRepository } from './base.repository';

@Injectable()
export class TransactionRepository
  extends BaseRepository<Transaction>
  implements ITransactionRepository
{
  constructor(
    @InjectRepository(Transaction)
    private readonly transactionRepository: Repository<Transaction>,
  ) {
    super(transactionRepository);
  }

  async findByAccountId(
    accountId: string,
    limit: number = 100,
    offset: number = 0,
  ): Promise<Transaction[]> {
    return await this.transactionRepository.find({
      where: { accountId },
      order: { transactionDate: 'DESC' },
      take: limit,
      skip: offset,
      relations: ['category'],
    });
  }

  async findByUserId(
    userId: string,
    limit: number = 100,
    offset: number = 0,
  ): Promise<Transaction[]> {
    return await this.transactionRepository
      .createQueryBuilder('transaction')
      .leftJoinAndSelect('transaction.account', 'account')
      .leftJoinAndSelect('transaction.category', 'category')
      .where('account.userId = :userId', { userId })
      .orderBy('transaction.transactionDate', 'DESC')
      .take(limit)
      .skip(offset)
      .getMany();
  }

  async findByDateRange(
    accountId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<Transaction[]> {
    return await this.transactionRepository.find({
      where: {
        accountId,
        transactionDate: Between(startDate, endDate),
      },
      order: { transactionDate: 'DESC' },
      relations: ['category'],
    });
  }

  async findByCategory(
    categoryId: string,
    limit: number = 100,
    offset: number = 0,
  ): Promise<Transaction[]> {
    return await this.transactionRepository.find({
      where: { categoryId },
      order: { transactionDate: 'DESC' },
      take: limit,
      skip: offset,
      relations: ['account', 'category'],
    });
  }

  async findRecurringTransactions(accountId?: string): Promise<Transaction[]> {
    const whereCondition: any = { isRecurring: true };
    if (accountId) {
      whereCondition.accountId = accountId;
    }

    return await this.transactionRepository.find({
      where: whereCondition,
      order: { transactionDate: 'DESC' },
      relations: ['account', 'category'],
    });
  }

  async findByAmountRange(
    accountId: string,
    minAmount: number,
    maxAmount: number,
  ): Promise<Transaction[]> {
    return await this.transactionRepository
      .createQueryBuilder('transaction')
      .where('transaction.accountId = :accountId', { accountId })
      .andWhere('transaction.amount BETWEEN :minAmount AND :maxAmount', {
        minAmount,
        maxAmount,
      })
      .orderBy('transaction.transactionDate', 'DESC')
      .getMany();
  }

  async searchByDescription(
    userId: string,
    searchTerm: string,
    limit: number = 50,
  ): Promise<Transaction[]> {
    return await this.transactionRepository
      .createQueryBuilder('transaction')
      .leftJoinAndSelect('transaction.account', 'account')
      .leftJoinAndSelect('transaction.category', 'category')
      .where('account.userId = :userId', { userId })
      .andWhere(
        '(transaction.description LIKE :searchTerm OR transaction.merchantName LIKE :searchTerm)',
        { searchTerm: `%${searchTerm}%` },
      )
      .orderBy('transaction.transactionDate', 'DESC')
      .take(limit)
      .getMany();
  }

  async findUnverified(userId: string): Promise<Transaction[]> {
    return await this.transactionRepository
      .createQueryBuilder('transaction')
      .leftJoinAndSelect('transaction.account', 'account')
      .leftJoinAndSelect('transaction.category', 'category')
      .where('account.userId = :userId', { userId })
      .andWhere('transaction.userVerified = :verified', { verified: false })
      .orderBy('transaction.transactionDate', 'DESC')
      .getMany();
  }

  async findUncategorized(userId: string): Promise<Transaction[]> {
    return await this.transactionRepository
      .createQueryBuilder('transaction')
      .leftJoinAndSelect('transaction.account', 'account')
      .where('account.userId = :userId', { userId })
      .andWhere('transaction.categoryId IS NULL')
      .orderBy('transaction.transactionDate', 'DESC')
      .getMany();
  }

  async getStatistics(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<{
    totalTransactions: number;
    totalIncome: number;
    totalExpenses: number;
    averageTransaction: number;
  }> {
    const result = await this.transactionRepository
      .createQueryBuilder('transaction')
      .leftJoin('transaction.account', 'account')
      .select([
        'COUNT(transaction.id) as totalTransactions',
        'SUM(CASE WHEN transaction.transactionType = "credit" THEN transaction.amount ELSE 0 END) as totalIncome',
        'SUM(CASE WHEN transaction.transactionType = "debit" THEN transaction.amount ELSE 0 END) as totalExpenses',
        'AVG(transaction.amount) as averageTransaction',
      ])
      .where('account.userId = :userId', { userId })
      .andWhere('transaction.transactionDate BETWEEN :startDate AND :endDate', {
        startDate,
        endDate,
      })
      .getRawOne();

    return {
      totalTransactions: parseInt(result.totalTransactions) || 0,
      totalIncome: parseFloat(result.totalIncome) || 0,
      totalExpenses: parseFloat(result.totalExpenses) || 0,
      averageTransaction: parseFloat(result.averageTransaction) || 0,
    };
  }
}