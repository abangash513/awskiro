import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Goal } from '../../entities/goal.entity';
import { IGoalRepository } from '../interfaces/goal-repository.interface';
import { BaseRepository } from './base.repository';

@Injectable()
export class GoalRepository extends BaseRepository<Goal> implements IGoalRepository {
  constructor(
    @InjectRepository(Goal)
    private readonly goalRepository: Repository<Goal>,
  ) {
    super(goalRepository);
  }

  async findByUserId(userId: string): Promise<Goal[]> {
    return await this.goalRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async findActiveByUserId(userId: string): Promise<Goal[]> {
    return await this.goalRepository.find({
      where: { 
        userId,
        status: 'active',
      },
      order: { targetDate: 'ASC' },
    });
  }

  async findByType(userId: string, goalType: string): Promise<Goal[]> {
    return await this.goalRepository.find({
      where: { 
        userId,
        goalType,
      },
      order: { createdAt: 'DESC' },
    });
  }

  async findByStatus(userId: string, status: string): Promise<Goal[]> {
    return await this.goalRepository.find({
      where: { 
        userId,
        status,
      },
      order: { createdAt: 'DESC' },
    });
  }

  async findDueSoon(userId: string, daysAhead: number): Promise<Goal[]> {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + daysAhead);

    return await this.goalRepository
      .createQueryBuilder('goal')
      .where('goal.userId = :userId', { userId })
      .andWhere('goal.status = :status', { status: 'active' })
      .andWhere('goal.targetDate <= :futureDate', { futureDate })
      .andWhere('goal.targetDate >= :now', { now: new Date() })
      .orderBy('goal.targetDate', 'ASC')
      .getMany();
  }

  async updateProgress(goalId: string, currentAmount: number): Promise<void> {
    await this.goalRepository.update(goalId, {
      currentAmount,
      updatedAt: new Date(),
    });
  }

  async markAsAchieved(goalId: string): Promise<void> {
    const goal = await this.findById(goalId);
    if (!goal) {
      throw new Error(`Goal with id ${goalId} not found`);
    }

    await this.goalRepository.update(goalId, {
      status: 'achieved',
      currentAmount: goal.targetAmount,
      achievedAt: new Date(),
      updatedAt: new Date(),
    });
  }

  async getProgressStatistics(userId: string): Promise<{
    totalGoals: number;
    activeGoals: number;
    achievedGoals: number;
    averageProgress: number;
  }> {
    const totalGoals = await this.goalRepository.count({
      where: { userId },
    });

    const activeGoals = await this.goalRepository.count({
      where: { userId, status: 'active' },
    });

    const achievedGoals = await this.goalRepository.count({
      where: { userId, status: 'achieved' },
    });

    // Calculate average progress for active goals
    const activeGoalsList = await this.goalRepository.find({
      where: { userId, status: 'active' },
      select: ['currentAmount', 'targetAmount'],
    });

    let averageProgress = 0;
    if (activeGoalsList.length > 0) {
      const totalProgress = activeGoalsList.reduce((sum, goal) => {
        const progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) * 100 : 0;
        return sum + Math.min(progress, 100); // Cap at 100%
      }, 0);
      averageProgress = totalProgress / activeGoalsList.length;
    }

    return {
      totalGoals,
      activeGoals,
      achievedGoals,
      averageProgress: Math.round(averageProgress * 100) / 100, // Round to 2 decimal places
    };
  }
}