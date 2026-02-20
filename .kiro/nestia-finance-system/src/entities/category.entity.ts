import { Entity, Column, ManyToOne, OneToMany, JoinColumn, Index } from 'typeorm';
import { BaseEntity } from './base.entity';
import { User } from './user.entity';
import { Transaction } from './transaction.entity';
import { CategoryRule } from './category-rule.entity';
import { UUID } from '../types';

@Entity('categories')
@Index(['userId', 'isActive'])
@Index(['parentCategoryId'])
export class Category extends BaseEntity {
  @Column({ type: 'uuid' })
  userId: UUID;

  @Column({ length: 100 })
  name: string;

  @Column({ type: 'uuid', nullable: true })
  parentCategoryId?: UUID;

  @Column({ length: 7, nullable: true })
  colorCode?: string;

  @Column({ length: 50, nullable: true })
  iconName?: string;

  @Column({ default: false })
  isSystemCategory: boolean;

  @Column({ default: true })
  isActive: boolean;

  // Relationships
  @ManyToOne(() => User, (user) => user.categories)
  @JoinColumn({ name: 'userId' })
  user: User;

  @ManyToOne(() => Category, (category) => category.subcategories, { nullable: true })
  @JoinColumn({ name: 'parentCategoryId' })
  parentCategory?: Category;

  @OneToMany(() => Category, (category) => category.parentCategory)
  subcategories: Category[];

  @OneToMany(() => Transaction, (transaction) => transaction.category)
  transactions: Transaction[];

  @OneToMany(() => Transaction, (transaction) => transaction.subcategory)
  subcategoryTransactions: Transaction[];

  @OneToMany(() => CategoryRule, (rule) => rule.category)
  categoryRules: CategoryRule[];
}