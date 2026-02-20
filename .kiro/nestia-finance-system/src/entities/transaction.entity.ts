import { Entity, Column, ManyToOne, JoinColumn, Index } from 'typeorm';
import { BaseEntity } from './base.entity';
import { Account } from './account.entity';
import { Category } from './category.entity';
import { Decimal, UUID } from '../types';

@Entity('transactions')
@Index(['accountId', 'transactionDate'])
@Index(['categoryId'])
@Index(['isRecurring', 'recurringGroupId'])
@Index(['transactionDate'])
export class Transaction extends BaseEntity {
  @Column({ type: 'uuid' })
  accountId: UUID;

  @Column({ type: 'date' })
  transactionDate: Date;

  @Column({ type: 'date', nullable: true })
  postedDate?: Date;

  @Column({ type: 'decimal', precision: 15, scale: 2 })
  amount: Decimal;

  @Column({ length: 500 })
  description: string;

  @Column({ length: 255, nullable: true })
  merchantName?: string;

  @Column({ type: 'uuid', nullable: true })
  categoryId?: UUID;

  @Column({ type: 'uuid', nullable: true })
  subcategoryId?: UUID;

  @Column({ 
    type: 'text',
    check: "transactionType IN ('debit', 'credit')"
  })
  transactionType: 'debit' | 'credit';

  @Column({ default: false })
  isRecurring: boolean;

  @Column({ type: 'uuid', nullable: true })
  recurringGroupId?: UUID;

  @Column({ type: 'decimal', precision: 5, scale: 4, nullable: true })
  confidenceScore?: Decimal;

  @Column({ default: false })
  userVerified: boolean;

  // Relationships
  @ManyToOne(() => Account, (account) => account.transactions)
  @JoinColumn({ name: 'accountId' })
  account: Account;

  @ManyToOne(() => Category, (category) => category.transactions, { nullable: true })
  @JoinColumn({ name: 'categoryId' })
  category?: Category;

  @ManyToOne(() => Category, (category) => category.subcategoryTransactions, { nullable: true })
  @JoinColumn({ name: 'subcategoryId' })
  subcategory?: Category;
}