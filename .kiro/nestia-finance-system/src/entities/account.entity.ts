import { Entity, Column, ManyToOne, OneToMany, JoinColumn, Index } from 'typeorm';
import { BaseEntity } from './base.entity';
import { User } from './user.entity';
import { Transaction } from './transaction.entity';
import { CurrencyCode, Decimal, Timestamp, UUID } from '../types';

@Entity('accounts')
@Index(['userId', 'isActive'])
export class Account extends BaseEntity {
  @Column({ type: 'uuid' })
  userId: UUID;

  @Column({ length: 255 })
  institutionName: string;

  @Column({ 
    type: 'text',
    check: "accountType IN ('checking', 'savings', 'credit', 'investment', 'loan')"
  })
  accountType: 'checking' | 'savings' | 'credit' | 'investment' | 'loan';

  @Column({ length: 255 })
  accountName: string;

  @Column({ length: 255, nullable: true })
  accountNumberHash?: string;

  @Column({ length: 3, default: 'USD' })
  currencyCode: CurrencyCode;

  @Column({ default: true })
  isActive: boolean;

  @Column({ type: 'datetime', nullable: true })
  lastSyncAt?: Timestamp;

  @Column({ type: 'decimal', precision: 15, scale: 2, nullable: true })
  balanceCurrent?: Decimal;

  @Column({ type: 'decimal', precision: 15, scale: 2, nullable: true })
  balanceAvailable?: Decimal;

  // Relationships
  @ManyToOne(() => User, (user) => user.accounts)
  @JoinColumn({ name: 'userId' })
  user: User;

  @OneToMany(() => Transaction, (transaction) => transaction.account)
  transactions: Transaction[];
}