import { Goal } from '../../entities/goal.entity';
import { IBaseRepository } from './base-repository.interface';

/**
 * Goal repository interface
 */
export interface IGoalRepository extends IBaseRepository<Goal> {
  /**
   * Find goals by user ID
   */
  findByUserId(userId: string): Promise<Goal[]>;

  /**
   * Find active goals by user ID
   */
  findActiveByUserId(userId: string): Promise<Goal[]>;

  /**
   * Find goals by type
   */
  findByType(userId: string, goalType: string): Promise<Goal[]>;

  /**
   * Find goals by status
   */
  findByStatus(userId: string, status: string): Promise<Goal[]>;

  /**
   * Find goals due soon
   */
  findDueSoon(userId: string, daysAhead: number): Promise<Goal[]>;

  /**
   * Update goal progress
   */
  updateProgress(goalId: string, currentAmount: number): Promise<void>;

  /**
   * Mark goal as achieved
   */
  markAsAchieved(goalId: string): Promise<void>;

  /**
   * Get goal progress statistics
   */
  getProgressStatistics(userId: string): Promise<{
    totalGoals: number;
    activeGoals: number;
    achievedGoals: number;
    averageProgress: number;
  }>;
}