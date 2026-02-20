import { Entity, Column, OneToMany, OneToOne } from 'typeorm';
import { BaseEntity } from './base.entity';
import { Account } from './account.entity';
import { Category } from './category.entity';
import { CategoryRule } from './category-rule.entity';
import { CategoryMigration } from './category-migration.entity';
import { UserPreferences } from './user-preferences.entity';
import { Goal } from './goal.entity';
import { Timestamp } from '../types';

@Entity('users')
export class User extends BaseEntity {
  @Column({ unique: true, length: 255 })
  email: string;

  @Column({ length: 255 })
  passwordHash: string;

  @Column({ length: 100 })
  firstName: string;

  @Column({ length: 100 })
  lastName: string;

  @Column({ default: true })
  isActive: boolean;

  @Column({ type: 'datetime', nullable: true })
  lastLoginAt?: Timestamp;

  // Relationships
  @OneToMany(() => Account, (account) => account.user)
  accounts: Account[];

  @OneToMany(() => Category, (category) => category.user)
  categories: Category[];

  @OneToOne(() => UserPreferences, (preferences) => preferences.user)
  preferences: UserPreferences;

  @OneToMany(() => Goal, (goal) => goal.user)
  goals: Goal[];

  @OneToMany(() => CategoryRule, (rule) => rule.user)
  categoryRules: CategoryRule[];

  @OneToMany(() => CategoryMigration, (migration) => migration.user)
  categoryMigrations: CategoryMigration[];

  // Virtual properties
  get fullName(): string {
    return `${this.firstName} ${this.lastName}`;
  }
}