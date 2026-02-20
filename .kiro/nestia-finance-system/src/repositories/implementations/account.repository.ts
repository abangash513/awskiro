import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Account } from '../../entities/account.entity';
import { IAccountRepository } from '../interfaces/account-repository.interface';
import { BaseRepository } from './base.repository';

@Injectable()
export class AccountRepository extends BaseRepository<Account> implements IAccountRepository {
  constructor(
    @InjectRepository(Account)
    private readonly accountRepository: Repository<Account>,
  ) {
    super(accountRepository);
  }

  async findByUserId(userId: string): Promise<Account[]> {
    return await this.accountRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async findActiveByUserId(userId: string): Promise<Account[]> {
    return await this.accountRepository.find({
      where: { userId, isActive: true },
      order: { accountName: 'ASC' },
    });
  }

  async findByUserIdAndAccountId(userId: string, accountId: string): Promise<Account | null> {
    return await this.accountRepository.findOne({
      where: { id: accountId, userId },
    });
  }

  async updateBalance(
    accountId: string,
    currentBalance: number,
    availableBalance?: number,
  ): Promise<void> {
    const updateData: any = {
      balanceCurrent: currentBalance,
      updatedAt: new Date(),
    };

    if (availableBalance !== undefined) {
      updateData.balanceAvailable = availableBalance;
    }

    await this.accountRepository.update(accountId, updateData);
  }

  async updateLastSync(accountId: string): Promise<void> {
    await this.accountRepository.update(accountId, {
      lastSyncAt: new Date(),
    });
  }

  async findByInstitution(institutionName: string): Promise<Account[]> {
    return await this.accountRepository.find({
      where: { institutionName },
      order: { accountName: 'ASC' },
    });
  }

  async findByType(accountType: string): Promise<Account[]> {
    return await this.accountRepository.find({
      where: { accountType },
      order: { accountName: 'ASC' },
    });
  }
}