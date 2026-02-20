import { Entity, Column, ManyToOne, JoinColumn, Index } from 'typeorm';
import { BaseEntity } from './base.entity';
import { User } from './user.entity';
import { Decimal, UUID } from '../types';

@Entity('goals')
@Index(['userId', 'isActive'])
export class Goal extends BaseEntity {
  @Column({ type: 'uuid' })
  userId: UUID;

  @Column({ length: 255 })
  name: string;

  @Column({ length: 1000, nullable: true })
  description?: string;

  @Column({ 
    type: 'text',
    check: "goalType IN ('savings', 'debt_reduction', 'expense_reduction', 'income_increase', 'investment')"
  })
  goalType: 'savings' | 'debt_reduction' | 'expense_reduction' | 'income_increase' | 'investment';

  @Column({ type: 'decimal', precision: 15, scale: 2 })
  targetAmount: Decimal;

  @Column({ type: 'decimal', precision: 15, scale: 2, default: 0 })
  currentAmount: Decimal;

  @Column({ type: 'date' })
  targetDate: Date;

  @Column({ type: 'date', nullable: true })
  achievedDate?: Date;

  @Column({ 
    type: 'text',
    default: 'active',
    check: "status IN ('active', 'achieved', 'paused', 'cancelled')"
  })
  status: 'active' | 'achieved' | 'paused' | 'cancelled';

  @Column({ default: true })
  isActive: boolean;

  // Relationships
  @ManyToOne(() => User, (user) => user.goals)
  @JoinColumn({ name: 'userId' })
  user: User;

  // Virtual properties
  get progressPercentage(): number {
    if (this.targetAmount === 0) return 0;
    return Math.min((this.currentAmount / this.targetAmount) * 100, 100);
  }

  get isAchieved(): boolean {
    return this.currentAmount >= this.targetAmount;
  }
}