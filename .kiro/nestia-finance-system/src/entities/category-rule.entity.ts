import { Entity, Column, ManyToOne, JoinColumn, Index } from 'typeorm';
import { BaseEntity } from './base.entity';
import { User } from './user.entity';
import { Category } from './category.entity';
import { UUID } from '../types';

@Entity('category_rules')
@Index(['userId', 'isActive'])
@Index(['priority'])
export class CategoryRule extends BaseEntity {
  @Column({ type: 'uuid' })
  userId: UUID;

  @Column({ type: 'uuid' })
  categoryId: UUID;

  @Column({ length: 100 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description?: string;

  @Column({ type: 'json' })
  conditions: {
    merchantName?: {
      contains?: string[];
      equals?: string[];
      startsWith?: string[];
      endsWith?: string[];
    };
    description?: {
      contains?: string[];
      equals?: string[];
      startsWith?: string[];
      endsWith?: string[];
    };
    amount?: {
      min?: number;
      max?: number;
      equals?: number;
    };
    transactionType?: 'debit' | 'credit';
  };

  @Column({ type: 'int', default: 100 })
  priority: number;

  @Column({ type: 'decimal', precision: 3, scale: 2, default: 0.8 })
  confidenceScore: number;

  @Column({ default: true })
  isActive: boolean;

  @Column({ type: 'int', default: 0 })
  matchCount: number;

  @Column({ type: 'int', default: 0 })
  correctCount: number;

  // Relationships
  @ManyToOne(() => User, (user) => user.categoryRules)
  @JoinColumn({ name: 'userId' })
  user: User;

  @ManyToOne(() => Category, (category) => category.categoryRules)
  @JoinColumn({ name: 'categoryId' })
  category: Category;
}