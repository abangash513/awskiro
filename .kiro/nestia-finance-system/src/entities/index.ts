// Base entity
export { BaseEntity } from './base.entity';

// Core entities
export { User } from './user.entity';
export { UserPreferences } from './user-preferences.entity';
export { Account } from './account.entity';
export { Transaction } from './transaction.entity';
export { Category } from './category.entity';
export { Goal } from './goal.entity';
export { Notification } from './notification.entity';

// Analysis entities
export { CashflowAnalysisEntity } from './cashflow-analysis.entity';

// Re-export all entities as an array for TypeORM configuration
export const entities = [
  User,
  UserPreferences,
  Account,
  Transaction,
  Category,
  Goal,
  Notification,
  CashflowAnalysisEntity,
];