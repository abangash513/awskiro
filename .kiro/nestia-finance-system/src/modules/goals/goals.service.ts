import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Goal } from '../../entities/goal.entity';
import { User } from '../../entities/user.entity';
import { Transaction } from '../../entities/transaction.entity';
import { 
  ApiResponse, 
  CreateInput, 
  UpdateInput, 
  UUID,
  Decimal 
} from '../../types';

export interface GoalProgress {
  goalId: UUID;
  currentAmount: Decimal;
  targetAmount: Decimal;
  progressPercentage: number;
  estimatedCompletionDate?: Date;
  onTrack: boolean;
  monthlyContributionNeeded?: Decimal;
}

@Injectable()
export class GoalsService {
  private readonly logger = new Logger(GoalsService.name);

  constructor(
    @InjectRepository(Goal)
    private readonly goalRepository: Repository<Goal>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Transaction)
    private readonly transactionRepository: Repository<Transaction>,
  ) {}

  async createGoal(userId: UUID, goalData: CreateInput<Goal>): Promise<ApiResponse<Goal>> {
    try {
      this.logger.log(`Creating goal for user ${userId}`);

      const user = await this.userRepository.findOne({ where: { id: userId } });
      if (!user) {
        return {
          success: false,
          error: {
            code: 'USER_NOT_FOUND',
            message: 'User not found',
          },
          timestamp: new Date(),
        };
      }

      const goal = this.goalRepository.create({
        ...goalData,
        userId,
        currentAmount: 0,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const savedGoal = await this.goalRepository.save(goal);

      return {
        success: true,
        data: savedGoal,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to create goal for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'GOAL_CREATION_FAILED',
          message: 'Failed to create goal',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async getUserGoals(userId: UUID): Promise<ApiResponse<Goal[]>> {
    try {
      this.logger.log(`Getting goals for user ${userId}`);

      const goals = await this.goalRepository.find({
        where: { userId, isActive: true },
        order: { createdAt: 'DESC' },
      });

      return {
        success: true,
        data: goals,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to get goals for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'GOALS_FETCH_FAILED',
          message: 'Failed to retrieve goals',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async getGoalById(userId: UUID, goalId: UUID): Promise<ApiResponse<Goal>> {
    try {
      this.logger.log(`Getting goal ${goalId} for user ${userId}`);

      const goal = await this.goalRepository.findOne({
        where: { id: goalId, userId },
      });

      if (!goal) {
        return {
          success: false,
          error: {
            code: 'GOAL_NOT_FOUND',
            message: 'Goal not found',
          },
          timestamp: new Date(),
        };
      }

      return {
        success: true,
        data: goal,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to get goal ${goalId} for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'GOAL_FETCH_FAILED',
          message: 'Failed to retrieve goal',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async updateGoal(userId: UUID, goalId: UUID, updateData: UpdateInput<Goal>): Promise<ApiResponse<Goal>> {
    try {
      this.logger.log(`Updating goal ${goalId} for user ${userId}`);

      const goal = await this.goalRepository.findOne({
        where: { id: goalId, userId },
      });

      if (!goal) {
        return {
          success: false,
          error: {
            code: 'GOAL_NOT_FOUND',
            message: 'Goal not found',
          },
          timestamp: new Date(),
        };
      }

      Object.assign(goal, updateData, { updatedAt: new Date() });
      const updatedGoal = await this.goalRepository.save(goal);

      return {
        success: true,
        data: updatedGoal,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to update goal ${goalId} for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'GOAL_UPDATE_FAILED',
          message: 'Failed to update goal',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async deleteGoal(userId: UUID, goalId: UUID): Promise<ApiResponse<void>> {
    try {
      this.logger.log(`Deleting goal ${goalId} for user ${userId}`);

      const goal = await this.goalRepository.findOne({
        where: { id: goalId, userId },
      });

      if (!goal) {
        return {
          success: false,
          error: {
            code: 'GOAL_NOT_FOUND',
            message: 'Goal not found',
          },
          timestamp: new Date(),
        };
      }

      // Soft delete by marking as inactive
      goal.isActive = false;
      goal.updatedAt = new Date();
      await this.goalRepository.save(goal);

      return {
        success: true,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to delete goal ${goalId} for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'GOAL_DELETE_FAILED',
          message: 'Failed to delete goal',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async getGoalProgress(userId: UUID, goalId: UUID): Promise<ApiResponse<GoalProgress>> {
    try {
      this.logger.log(`Calculating progress for goal ${goalId}, user ${userId}`);

      const goal = await this.goalRepository.findOne({
        where: { id: goalId, userId },
      });

      if (!goal) {
        return {
          success: false,
          error: {
            code: 'GOAL_NOT_FOUND',
            message: 'Goal not found',
          },
          timestamp: new Date(),
        };
      }

      // Calculate progress percentage
      const progressPercentage = Math.min((goal.currentAmount / goal.targetAmount) * 100, 100);

      // Calculate if on track
      const now = new Date();
      const totalDuration = goal.targetDate.getTime() - goal.createdAt.getTime();
      const elapsed = now.getTime() - goal.createdAt.getTime();
      const expectedProgress = Math.min((elapsed / totalDuration) * 100, 100);
      const onTrack = progressPercentage >= expectedProgress * 0.9; // 10% tolerance

      // Calculate estimated completion date
      let estimatedCompletionDate: Date | undefined;
      if (goal.currentAmount > 0 && goal.currentAmount < goal.targetAmount) {
        const remainingAmount = goal.targetAmount - goal.currentAmount;
        const monthsElapsed = elapsed / (30 * 24 * 60 * 60 * 1000); // Approximate months
        const monthlyRate = goal.currentAmount / Math.max(monthsElapsed, 1);
        
        if (monthlyRate > 0) {
          const monthsToCompletion = remainingAmount / monthlyRate;
          estimatedCompletionDate = new Date(now.getTime() + monthsToCompletion * 30 * 24 * 60 * 60 * 1000);
        }
      }

      // Calculate monthly contribution needed
      let monthlyContributionNeeded: Decimal | undefined;
      const remainingTime = goal.targetDate.getTime() - now.getTime();
      const remainingMonths = remainingTime / (30 * 24 * 60 * 60 * 1000);
      
      if (remainingMonths > 0 && goal.currentAmount < goal.targetAmount) {
        const remainingAmount = goal.targetAmount - goal.currentAmount;
        monthlyContributionNeeded = remainingAmount / remainingMonths;
      }

      const progress: GoalProgress = {
        goalId: goal.id,
        currentAmount: goal.currentAmount,
        targetAmount: goal.targetAmount,
        progressPercentage: Math.round(progressPercentage * 100) / 100,
        estimatedCompletionDate,
        onTrack,
        monthlyContributionNeeded: monthlyContributionNeeded ? Math.round(monthlyContributionNeeded * 100) / 100 : undefined,
      };

      return {
        success: true,
        data: progress,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to calculate progress for goal ${goalId}:`, error);
      return {
        success: false,
        error: {
          code: 'GOAL_PROGRESS_FAILED',
          message: 'Failed to calculate goal progress',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async updateGoalProgress(userId: UUID, goalId: UUID, contributionAmount: Decimal): Promise<ApiResponse<Goal>> {
    try {
      this.logger.log(`Updating progress for goal ${goalId} with contribution ${contributionAmount}`);

      const goal = await this.goalRepository.findOne({
        where: { id: goalId, userId },
      });

      if (!goal) {
        return {
          success: false,
          error: {
            code: 'GOAL_NOT_FOUND',
            message: 'Goal not found',
          },
          timestamp: new Date(),
        };
      }

      // Update current amount
      goal.currentAmount += contributionAmount;
      goal.updatedAt = new Date();

      // Check if goal is achieved
      if (goal.currentAmount >= goal.targetAmount && !goal.isAchieved) {
        goal.isAchieved = true;
        goal.achievedAt = new Date();
      }

      const updatedGoal = await this.goalRepository.save(goal);

      return {
        success: true,
        data: updatedGoal,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to update progress for goal ${goalId}:`, error);
      return {
        success: false,
        error: {
          code: 'GOAL_PROGRESS_UPDATE_FAILED',
          message: 'Failed to update goal progress',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }
}