import { Entity, Column, ManyToOne, JoinColumn, Index } from 'typeorm';
import { BaseEntity } from './base.entity';
import { User } from './user.entity';
import { Category } from './category.entity';
import { UUID } from '../types';

@Entity('category_migrations')
@Index(['userId'])
@Index(['fromCategoryId'])
@Index(['toCategoryId'])
export class CategoryMigration extends BaseEntity {
  @Column({ type: 'uuid' })
  userId: UUID;

  @Column({ type: 'uuid' })
  fromCategoryId: UUID;

  @Column({ type: 'uuid' })
  toCategoryId: UUID;

  @Column({ type: 'text', nullable: true })
  reason?: string;

  @Column({ type: 'int', default: 0 })
  affectedTransactions: number;

  @Column({ type: 'json', nullable: true })
  migrationData?: {
    preserveHistory: boolean;
    updateRules: boolean;
    notifyUser: boolean;
    rollbackData?: any;
  };

  @Column({ 
    type: 'varchar', 
    length: 20, 
    default: 'pending' 
  })
  status: 'pending' | 'in_progress' | 'completed' | 'failed' | 'rolled_back';

  @Column({ type: 'timestamp', nullable: true })
  completedAt?: Date;

  @Column({ type: 'text', nullable: true })
  errorMessage?: string;

  // Relationships
  @ManyToOne(() => User, (user) => user.categoryMigrations)
  @JoinColumn({ name: 'userId' })
  user: User;

  @ManyToOne(() => Category, { nullable: true })
  @JoinColumn({ name: 'fromCategoryId' })
  fromCategory?: Category;

  @ManyToOne(() => Category)
  @JoinColumn({ name: 'toCategoryId' })
  toCategory: Category;
}