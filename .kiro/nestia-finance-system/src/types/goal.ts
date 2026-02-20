/**
 * Goal-related type definitions
 */

import { UUID, Timestamp, CurrencyCode, Decimal } from './index';

export type GoalType = 'savings' | 'debt_payoff' | 'investment' | 'expense_reduction';
export type GoalStatus = 'active' | 'completed' | 'paused' | 'cancelled';
export type GoalFrequency = 'weekly' | 'monthly' | 'quarterly' | 'annually';

export interface Goal {
  id: UUID;
  userId: UUID;
  name: string;
  description?: string;
  goalType: GoalType;
  targetAmount?: Decimal;
  currentAmount: Decimal;
  targetDate?: Date;
  status: GoalStatus;
  currencyCode: CurrencyCode;
  isActive: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface GoalProgress {
  goalId: UUID;
  progressPercentage: Decimal;
  amountRemaining: Decimal;
  projectedCompletionDate?: Date;
  isOnTrack: boolean;
  monthlyProgressRate: Decimal;
  lastCalculatedAt: Timestamp;
}

export interface GoalMilestone {
  id: UUID;
  goalId: UUID;
  name: string;
  description?: string;
  targetAmount: Decimal;
  targetDate?: Date;
  isCompleted: boolean;
  completedAt?: Timestamp;
  order: number;
  createdAt: Timestamp;
}

export interface GoalContribution {
  id: UUID;
  goalId: UUID;
  transactionId?: UUID;
  amount: Decimal;
  contributionDate: Date;
  contributionType: 'automatic' | 'manual' | 'transfer';
  description?: string;
  createdAt: Timestamp;
}

export interface GoalInsight {
  goalId: UUID;
  insightType: 'on_track' | 'behind_schedule' | 'ahead_of_schedule' | 'target_unrealistic' | 'milestone_achieved';
  title: string;
  description: string;
  recommendedAction?: string;
  severity: 'low' | 'medium' | 'high';
  generatedAt: Timestamp;
}

export interface CreateGoalInput {
  name: string;
  description?: string;
  goalType: GoalType;
  targetAmount?: Decimal;
  targetDate?: Date;
  currencyCode?: CurrencyCode;
}

export interface UpdateGoalInput {
  name?: string;
  description?: string;
  targetAmount?: Decimal;
  targetDate?: Date;
  status?: GoalStatus;
  isActive?: boolean;
}

export interface GoalSummary {
  totalGoals: number;
  activeGoals: number;
  completedGoals: number;
  goalsByType: Record<GoalType, number>;
  totalTargetAmount: Decimal;
  totalCurrentAmount: Decimal;
  overallProgressPercentage: Decimal;
  goalsOnTrack: number;
  goalsBehindSchedule: number;
}

export interface GoalRecommendation {
  goalId: UUID;
  recommendationType: 'increase_contribution' | 'extend_deadline' | 'reduce_target' | 'create_milestone';
  title: string;
  description: string;
  suggestedAmount?: Decimal;
  suggestedDate?: Date;
  potentialImpact: string;
  confidenceScore: Decimal;
  generatedAt: Timestamp;
}

export interface GoalTemplate {
  id: UUID;
  name: string;
  description: string;
  goalType: GoalType;
  suggestedTargetAmount?: Decimal;
  suggestedTimeframe?: number; // months
  milestones: Array<{
    name: string;
    percentage: Decimal;
    description?: string;
  }>;
  isSystemTemplate: boolean;
  createdAt: Timestamp;
}