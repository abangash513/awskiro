import { User } from '../../entities/user.entity';
import { IBaseRepository } from './base-repository.interface';

/**
 * User repository interface
 */
export interface IUserRepository extends IBaseRepository<User> {
  /**
   * Find user by email
   */
  findByEmail(email: string): Promise<User | null>;

  /**
   * Check if email exists
   */
  emailExists(email: string): Promise<boolean>;

  /**
   * Update last login timestamp
   */
  updateLastLogin(userId: string): Promise<void>;

  /**
   * Find active users
   */
  findActiveUsers(): Promise<User[]>;

  /**
   * Deactivate user account
   */
  deactivateUser(userId: string): Promise<void>;
}