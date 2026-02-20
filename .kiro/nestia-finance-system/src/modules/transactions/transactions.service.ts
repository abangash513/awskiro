import { Injectable } from '@nestjs/common';
import { TransactionRepository } from '../../repositories/implementations/transaction.repository';
import { AccountsService } from '../accounts/accounts.service';
import { Transaction } from '../../entities/transaction.entity';
import { CreateInput, UpdateInput, UUID, NotFoundError, ValidationError } from '../../types';

export interface CreateTransactionDto {
  accountId: UUID;
  transactionDate: Date;
  postedDate?: Date;
  amount: number;
  description: string;
  merchantName?: string;
  categoryId?: UUID;
  subcategoryId?: UUID;
  transactionType: 'debit' | 'credit';
  isRecurring?: boolean;
  recurringGroupId?: UUID;
}

export interface UpdateTransactionDto {
  description?: string;
  merchantName?: string;
  categoryId?: UUID;
  subcategoryId?: UUID;
  isRecurring?: boolean;
  userVerified?: boolean;
}

export interface TransactionFilters {
  accountId?: UUID;
  categoryId?: UUID;
  transactionType?: 'debit' | 'credit';
  startDate?: Date;
  endDate?: Date;
  minAmount?: number;
  maxAmount?: number;
  isRecurring?: boolean;
  userVerified?: boolean;
}

@Injectable()
export class TransactionsService {
  constructor(
    private readonly transactionRepository: TransactionRepository,
    private readonly accountsService: AccountsService,
  ) {}

  async create(userId: UUID, createTransactionDto: CreateTransactionDto): Promise<Transaction> {
    // Verify account ownership
    await this.accountsService.findById(createTransactionDto.accountId, userId);

    // Validate transaction data
    if (createTransactionDto.amount === 0) {
      throw new ValidationError('Transaction amount cannot be zero');
    }

    const transactionData: CreateInput<Transaction> = {
      ...createTransactionDto,
      isRecurring: createTransactionDto.isRecurring || false,
      userVerified: false,
      confidenceScore: 1.0, // Default confidence for manual entries
    };

    return this.transactionRepository.create(transactionData);
  }

  async findAllByUserId(
    userId: UUID,
    filters?: TransactionFilters,
    page: number = 1,
    limit: number = 50,
  ): Promise<{ transactions: Transaction[]; total: number }> {
    // Get user's account IDs to filter transactions
    const userAccounts = await this.accountsService.findAllByUserId(userId);
    const accountIds = userAccounts.map(account => account.id);

    if (accountIds.length === 0) {
      return { transactions: [], total: 0 };
    }

    return this.transactionRepository.findByFilters({
      ...filters,
      accountIds,
    }, page, limit);
  }

  async findById(id: UUID, userId: UUID): Promise<Transaction> {
    const transaction = await this.transactionRepository.findById(id);
    if (!transaction) {
      throw new NotFoundError('Transaction');
    }

    // Verify user owns the account this transaction belongs to
    await this.accountsService.findById(transaction.accountId, userId);

    return transaction;
  }

  async update(id: UUID, userId: UUID, updateTransactionDto: UpdateTransactionDto): Promise<Transaction> {
    const transaction = await this.findById(id, userId);
    
    const updatedTransaction = await this.transactionRepository.update(id, updateTransactionDto);
    if (!updatedTransaction) {
      throw new NotFoundError('Transaction');
    }
    
    return updatedTransaction;
  }

  async delete(id: UUID, userId: UUID): Promise<void> {
    const transaction = await this.findById(id, userId);
    await this.transactionRepository.delete(id);
  }

  async findByAccountId(accountId: UUID, userId: UUID): Promise<Transaction[]> {
    // Verify account ownership
    await this.accountsService.findById(accountId, userId);
    
    return this.transactionRepository.findByAccountId(accountId);
  }

  async findRecurringTransactions(userId: UUID): Promise<Transaction[]> {
    const userAccounts = await this.accountsService.findAllByUserId(userId);
    const accountIds = userAccounts.map(account => account.id);

    if (accountIds.length === 0) {
      return [];
    }

    return this.transactionRepository.findRecurringByAccountIds(accountIds);
  }

  async markAsVerified(id: UUID, userId: UUID): Promise<Transaction> {
    const transaction = await this.findById(id, userId);
    
    const updatedTransaction = await this.transactionRepository.update(id, {
      userVerified: true,
    });
    
    if (!updatedTransaction) {
      throw new NotFoundError('Transaction');
    }
    
    return updatedTransaction;
  }

  async bulkCreate(userId: UUID, transactions: CreateTransactionDto[]): Promise<Transaction[]> {
    const createdTransactions: Transaction[] = [];
    
    for (const transactionDto of transactions) {
      try {
        const transaction = await this.create(userId, transactionDto);
        createdTransactions.push(transaction);
      } catch (error) {
        // Log error but continue with other transactions
        console.error(`Failed to create transaction: ${error.message}`);
      }
    }
    
    return createdTransactions;
  }
}