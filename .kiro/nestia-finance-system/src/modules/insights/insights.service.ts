import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../entities/user.entity';
import { Transaction } from '../../entities/transaction.entity';
import { Account } from '../../entities/account.entity';
import { 
  CashflowAnalysis, 
  ExpenseAnalysis, 
  ApiResponse,
  UUID 
} from '../../types';

export interface Insight {
  id: string;
  type: 'spending' | 'saving' | 'cashflow' | 'subscription' | 'goal';
  title: string;
  description: string;
  priority: 'high' | 'medium' | 'low';
  actionable: boolean;
  generatedAt: Date;
  expiresAt?: Date;
}

@Injectable()
export class InsightsService {
  private readonly logger = new Logger(InsightsService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Transaction)
    private readonly transactionRepository: Repository<Transaction>,
    @InjectRepository(Account)
    private readonly accountRepository: Repository<Account>,
  ) {}

  async generateInsights(userId: UUID): Promise<ApiResponse<Insight[]>> {
    try {
      this.logger.log(`Generating insights for user ${userId}`);

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

      // Get recent transactions for analysis
      const recentTransactions = await this.transactionRepository.find({
        where: { 
          account: { userId },
        },
        relations: ['account'],
        order: { transactionDate: 'DESC' },
        take: 1000, // Last 1000 transactions
      });

      const insights: Insight[] = [];

      // Generate spending insights
      const spendingInsights = await this.generateSpendingInsights(recentTransactions);
      insights.push(...spendingInsights);

      // Generate cashflow insights
      const cashflowInsights = await this.generateCashflowInsights(recentTransactions);
      insights.push(...cashflowInsights);

      // Generate subscription insights
      const subscriptionInsights = await this.generateSubscriptionInsights(recentTransactions);
      insights.push(...subscriptionInsights);

      // Prioritize and limit insights (max 5 per session)
      const prioritizedInsights = this.prioritizeInsights(insights).slice(0, 5);

      return {
        success: true,
        data: prioritizedInsights,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to generate insights for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'INSIGHT_GENERATION_FAILED',
          message: 'Failed to generate insights',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  private async generateSpendingInsights(transactions: Transaction[]): Promise<Insight[]> {
    const insights: Insight[] = [];
    
    // Analyze spending patterns
    const currentMonth = new Date();
    const lastMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1);
    
    const currentMonthSpending = transactions
      .filter(t => t.transactionType === 'debit' && t.transactionDate >= lastMonth)
      .reduce((sum, t) => sum + Math.abs(t.amount), 0);

    const previousMonthSpending = transactions
      .filter(t => {
        const twoMonthsAgo = new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 2);
        return t.transactionType === 'debit' && 
               t.transactionDate >= twoMonthsAgo && 
               t.transactionDate < lastMonth;
      })
      .reduce((sum, t) => sum + Math.abs(t.amount), 0);

    if (previousMonthSpending > 0) {
      const spendingChange = ((currentMonthSpending - previousMonthSpending) / previousMonthSpending) * 100;
      
      if (spendingChange > 20) {
        insights.push({
          id: `spending-increase-${Date.now()}`,
          type: 'spending',
          title: 'Spending Increase Detected',
          description: `Your spending has increased by ${spendingChange.toFixed(1)}% compared to last month. Consider reviewing your recent purchases to identify any unusual expenses.`,
          priority: 'high',
          actionable: true,
          generatedAt: new Date(),
          expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
        });
      } else if (spendingChange < -10) {
        insights.push({
          id: `spending-decrease-${Date.now()}`,
          type: 'spending',
          title: 'Great Job on Spending Control',
          description: `You've reduced your spending by ${Math.abs(spendingChange).toFixed(1)}% this month. This positive trend could help you reach your financial goals faster.`,
          priority: 'medium',
          actionable: false,
          generatedAt: new Date(),
          expiresAt: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // 14 days
        });
      }
    }

    return insights;
  }

  private async generateCashflowInsights(transactions: Transaction[]): Promise<Insight[]> {
    const insights: Insight[] = [];
    
    // Calculate monthly cashflow
    const currentMonth = new Date();
    const monthStart = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), 1);
    
    const monthlyTransactions = transactions.filter(t => t.transactionDate >= monthStart);
    
    const income = monthlyTransactions
      .filter(t => t.transactionType === 'credit')
      .reduce((sum, t) => sum + t.amount, 0);
    
    const expenses = monthlyTransactions
      .filter(t => t.transactionType === 'debit')
      .reduce((sum, t) => sum + Math.abs(t.amount), 0);
    
    const netCashflow = income - expenses;
    
    if (netCashflow < 0) {
      insights.push({
        id: `negative-cashflow-${Date.now()}`,
        type: 'cashflow',
        title: 'Negative Cashflow This Month',
        description: `Your expenses exceed your income by $${Math.abs(netCashflow).toFixed(2)} this month. Consider reviewing your spending or exploring ways to increase income.`,
        priority: 'high',
        actionable: true,
        generatedAt: new Date(),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      });
    } else if (netCashflow > income * 0.2) {
      insights.push({
        id: `positive-cashflow-${Date.now()}`,
        type: 'cashflow',
        title: 'Strong Positive Cashflow',
        description: `You have a healthy surplus of $${netCashflow.toFixed(2)} this month. This could be a good opportunity to boost your savings or investments.`,
        priority: 'medium',
        actionable: true,
        generatedAt: new Date(),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      });
    }

    return insights;
  }

  private async generateSubscriptionInsights(transactions: Transaction[]): Promise<Insight[]> {
    const insights: Insight[] = [];
    
    // Simple subscription detection based on recurring patterns
    const recurringTransactions = transactions.filter(t => t.isRecurring);
    
    if (recurringTransactions.length > 0) {
      const monthlySubscriptionCost = recurringTransactions
        .filter(t => t.transactionType === 'debit')
        .reduce((sum, t) => sum + Math.abs(t.amount), 0);
      
      const annualCost = monthlySubscriptionCost * 12;
      
      if (annualCost > 1000) {
        insights.push({
          id: `subscription-review-${Date.now()}`,
          type: 'subscription',
          title: 'Review Your Subscriptions',
          description: `You're spending approximately $${monthlySubscriptionCost.toFixed(2)} monthly on subscriptions (${annualCost.toFixed(2)} annually). Consider reviewing which services you actively use.`,
          priority: 'medium',
          actionable: true,
          generatedAt: new Date(),
          expiresAt: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000), // 60 days
        });
      }
    }

    return insights;
  }

  private prioritizeInsights(insights: Insight[]): Insight[] {
    // Sort by priority (high > medium > low) and then by actionable status
    return insights.sort((a, b) => {
      const priorityOrder = { high: 3, medium: 2, low: 1 };
      const priorityDiff = priorityOrder[b.priority] - priorityOrder[a.priority];
      
      if (priorityDiff !== 0) return priorityDiff;
      
      // If same priority, prioritize actionable insights
      if (a.actionable && !b.actionable) return -1;
      if (!a.actionable && b.actionable) return 1;
      
      return 0;
    });
  }

  async getInsightHistory(userId: UUID, limit: number = 50): Promise<ApiResponse<Insight[]>> {
    try {
      // In a real implementation, this would fetch from a database
      // For now, return empty array as this is a foundational implementation
      return {
        success: true,
        data: [],
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to get insight history for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'INSIGHT_HISTORY_FAILED',
          message: 'Failed to retrieve insight history',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }
}