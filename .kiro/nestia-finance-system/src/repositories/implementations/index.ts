// Repository implementations
export { BaseRepository } from './base.repository';
export { UserRepository } from './user.repository';
export { AccountRepository } from './account.repository';
export { TransactionRepository } from './transaction.repository';
export { CategoryRepository } from './category.repository';
export { GoalRepository } from './goal.repository';

// Export all repositories as an array for module registration
import { UserRepository } from './user.repository';
import { AccountRepository } from './account.repository';
import { TransactionRepository } from './transaction.repository';
import { CategoryRepository } from './category.repository';
import { GoalRepository } from './goal.repository';

export const repositories = [
  UserRepository,
  AccountRepository,
  TransactionRepository,
  CategoryRepository,
  GoalRepository,
];