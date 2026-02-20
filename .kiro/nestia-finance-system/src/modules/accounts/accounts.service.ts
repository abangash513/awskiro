import { Injectable } from '@nestjs/common';
import { AccountRepository } from '../../repositories/implementations/account.repository';
import { Account } from '../../entities/account.entity';
import { CreateInput, UpdateInput, UUID, NotFoundError } from '../../types';

export interface CreateAccountDto {
  institutionName: string;
  accountType: 'checking' | 'savings' | 'credit' | 'investment' | 'loan';
  accountName: string;
  accountNumberHash?: string;
  currencyCode: string;
  balanceCurrent?: number;
  balanceAvailable?: number;
}

export interface UpdateAccountDto {
  accountName?: string;
  balanceCurrent?: number;
  balanceAvailable?: number;
  isActive?: boolean;
}

@Injectable()
export class AccountsService {
  constructor(private readonly accountRepository: AccountRepository) {}

  async create(userId: UUID, createAccountDto: CreateAccountDto): Promise<Account> {
    const accountData: CreateInput<Account> = {
      userId,
      ...createAccountDto,
      isActive: true,
    };

    return this.accountRepository.create(accountData);
  }

  async findAllByUserId(userId: UUID): Promise<Account[]> {
    return this.accountRepository.findByUserId(userId);
  }

  async findById(id: UUID, userId: UUID): Promise<Account> {
    const account = await this.accountRepository.findById(id);
    if (!account || account.userId !== userId) {
      throw new NotFoundError('Account');
    }
    return account;
  }

  async update(id: UUID, userId: UUID, updateAccountDto: UpdateAccountDto): Promise<Account> {
    const account = await this.findById(id, userId);
    
    const updatedAccount = await this.accountRepository.update(id, updateAccountDto);
    if (!updatedAccount) {
      throw new NotFoundError('Account');
    }
    
    return updatedAccount;
  }

  async delete(id: UUID, userId: UUID): Promise<void> {
    const account = await this.findById(id, userId);
    await this.accountRepository.delete(id);
  }

  async updateBalance(id: UUID, balanceCurrent: number, balanceAvailable?: number): Promise<Account> {
    const updateData: UpdateAccountDto = {
      balanceCurrent,
      balanceAvailable,
    };

    const updatedAccount = await this.accountRepository.update(id, updateData);
    if (!updatedAccount) {
      throw new NotFoundError('Account');
    }

    return updatedAccount;
  }

  async updateLastSync(id: UUID): Promise<Account> {
    const updateData = {
      lastSyncAt: new Date(),
    };

    const updatedAccount = await this.accountRepository.update(id, updateData);
    if (!updatedAccount) {
      throw new NotFoundError('Account');
    }

    return updatedAccount;
  }
}