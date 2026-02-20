import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Transaction } from '../../entities/transaction.entity';
import { Account } from '../../entities/account.entity';
import { Category } from '../../entities/category.entity';
import { Goal } from '../../entities/goal.entity';
import { User } from '../../entities/user.entity';
import { 
  ApiResponse, 
  UUID,
  Decimal,
  TransactionType 
} from '../../types';

export interface MonthlyReport {
  month: string;
  year: number;
  totalIncome: Decimal;
  totalExpenses: Decimal;
  netCashflow: Decimal;
  topExpenseCategories: CategorySummary[];
  goalProgress: GoalSummary[];
  accountBalances: AccountBalance[];
  transactionCount: number;
}

export interface CategorySummary {
  categoryName: string;
  amount: Decimal;
  transactionCount: number;
  percentage: number;
}

export interface GoalSummary {
  goalName: string;
  targetAmount: Decimal;
  currentAmount: Decimal;
  progressPercentage: number;
  targetDate: Date;
  onTrack: boolean;
}

export interface AccountBalance {
  accountName: string;
  accountType: string;
  balance: Decimal;
  lastUpdated: Date;
}

export interface YearlyReport {
  year: number;
  totalIncome: Decimal;
  totalExpenses: Decimal;
  netCashflow: Decimal;
  monthlyBreakdown: MonthlyBreakdown[];
  categoryTrends: CategoryTrend[];
  savingsRate: number;
  goalAchievements: GoalAchievement[];
}

export interface MonthlyBreakdown {
  month: number;
  monthName: string;
  income: Decimal;
  expenses: Decimal;
  netCashflow: Decimal;
}

export interface CategoryTrend {
  categoryName: string;
  monthlyAmounts: Decimal[];
  averageAmount: Decimal;
  trend: 'increasing' | 'decreasing' | 'stable';
}

export interface GoalAchievement {
  goalName: string;
  targetAmount: Decimal;
  achievedAmount: Decimal;
  achievedDate?: Date;
  status: 'achieved' | 'in_progress' | 'overdue';
}

export interface CashflowReport {
  startDate: Date;
  endDate: Date;
  totalIncome: Decimal;
  totalExpenses: Decimal;
  netCashflow: Decimal;
  dailyCashflow: DailyCashflow[];
  incomeByCategory: CategorySummary[];
  expensesByCategory: CategorySummary[];
  averageDailySpending: Decimal;
}

export interface DailyCashflow {
  date: Date;
  income: Decimal;
  expenses: Decimal;
  netAmount: Decimal;
}

@Injectable()
export class ReportsService {
  private readonly logger = new Logger(ReportsService.name);

  constructor(
    @InjectRepository(Transaction)
    private readonly transactionRepository: Repository<Transaction>,
    @InjectRepository(Account)
    private readonly accountRepository: Repository<Account>,
    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
    @InjectRepository(Goal)
    private readonly goalRepository: Repository<Goal>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async generateMonthlyReport(userId: UUID, year: number, month: number): Promise<ApiResponse<MonthlyReport>> {
    try {
      this.logger.log(`Generating monthly report for user ${userId}, ${year}-${month}`);

      const startDate = new Date(year, month - 1, 1);
      const endDate = new Date(year, month, 0, 23, 59, 59);

      // Get transactions for the month
      const transactions = await this.transactionRepository.find({
        where: {
          userId,
          date: Between(startDate, endDate),
        },
        relations: ['category'],
      });

      // Calculate totals
      const totalIncome = transactions
        .filter(t => t.type === 'income')
        .reduce((sum, t) => sum + t.amount, 0);

      const totalExpenses = transactions
        .filter(t => t.type === 'expense')
        .reduce((sum, t) => sum + Math.abs(t.amount), 0);

      const netCashflow = totalIncome - totalExpenses;

      // Top expense categories
      const expensesByCategory = new Map<string, { amount: number; count: number }>();
      transactions
        .filter(t => t.type === 'expense')
        .forEach(t => {
          const categoryName = t.category?.name || 'Uncategorized';
          const existing = expensesByCategory.get(categoryName) || { amount: 0, count: 0 };
          expensesByCategory.set(categoryName, {
            amount: existing.amount + Math.abs(t.amount),
            count: existing.count + 1,
          });
        });

      const topExpenseCategories: CategorySummary[] = Array.from(expensesByCategory.entries())
        .map(([categoryName, data]) => ({
          categoryName,
          amount: Math.round(data.amount * 100) / 100,
          transactionCount: data.count,
          percentage: totalExpenses > 0 ? Math.round((data.amount / totalExpenses) * 10000) / 100 : 0,
        }))
        .sort((a, b) => b.amount - a.amount)
        .slice(0, 10);

      // Goal progress
      const goals = await this.goalRepository.find({
        where: { userId, isActive: true },
      });

      const goalProgress: GoalSummary[] = goals.map(goal => {
        const progressPercentage = (goal.currentAmount / goal.targetAmount) * 100;
        const now = new Date();
        const totalDuration = goal.targetDate.getTime() - goal.createdAt.getTime();
        const elapsed = now.getTime() - goal.createdAt.getTime();
        const expectedProgress = Math.min((elapsed / totalDuration) * 100, 100);
        const onTrack = progressPercentage >= expectedProgress * 0.9;

        return {
          goalName: goal.name,
          targetAmount: goal.targetAmount,
          currentAmount: goal.currentAmount,
          progressPercentage: Math.round(progressPercentage * 100) / 100,
          targetDate: goal.targetDate,
          onTrack,
        };
      });

      // Account balances
      const accounts = await this.accountRepository.find({
        where: { userId },
      });

      const accountBalances: AccountBalance[] = accounts.map(account => ({
        accountName: account.name,
        accountType: account.type,
        balance: account.balance,
        lastUpdated: account.updatedAt,
      }));

      const monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];

      const report: MonthlyReport = {
        month: monthNames[month - 1],
        year,
        totalIncome: Math.round(totalIncome * 100) / 100,
        totalExpenses: Math.round(totalExpenses * 100) / 100,
        netCashflow: Math.round(netCashflow * 100) / 100,
        topExpenseCategories,
        goalProgress,
        accountBalances,
        transactionCount: transactions.length,
      };

      return {
        success: true,
        data: report,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to generate monthly report for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'MONTHLY_REPORT_FAILED',
          message: 'Failed to generate monthly report',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async generateYearlyReport(userId: UUID, year: number): Promise<ApiResponse<YearlyReport>> {
    try {
      this.logger.log(`Generating yearly report for user ${userId}, ${year}`);

      const startDate = new Date(year, 0, 1);
      const endDate = new Date(year, 11, 31, 23, 59, 59);

      // Get all transactions for the year
      const transactions = await this.transactionRepository.find({
        where: {
          userId,
          date: Between(startDate, endDate),
        },
        relations: ['category'],
      });

      // Calculate yearly totals
      const totalIncome = transactions
        .filter(t => t.type === 'income')
        .reduce((sum, t) => sum + t.amount, 0);

      const totalExpenses = transactions
        .filter(t => t.type === 'expense')
        .reduce((sum, t) => sum + Math.abs(t.amount), 0);

      const netCashflow = totalIncome - totalExpenses;
      const savingsRate = totalIncome > 0 ? (netCashflow / totalIncome) * 100 : 0;

      // Monthly breakdown
      const monthlyBreakdown: MonthlyBreakdown[] = [];
      const monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];

      for (let month = 1; month <= 12; month++) {
        const monthStart = new Date(year, month - 1, 1);
        const monthEnd = new Date(year, month, 0, 23, 59, 59);
        
        const monthTransactions = transactions.filter(t => 
          t.date >= monthStart && t.date <= monthEnd
        );

        const monthIncome = monthTransactions
          .filter(t => t.type === 'income')
          .reduce((sum, t) => sum + t.amount, 0);

        const monthExpenses = monthTransactions
          .filter(t => t.type === 'expense')
          .reduce((sum, t) => sum + Math.abs(t.amount), 0);

        monthlyBreakdown.push({
          month,
          monthName: monthNames[month - 1],
          income: Math.round(monthIncome * 100) / 100,
          expenses: Math.round(monthExpenses * 100) / 100,
          netCashflow: Math.round((monthIncome - monthExpenses) * 100) / 100,
        });
      }

      // Category trends (simplified)
      const categoryTrends: CategoryTrend[] = [];
      const categories = await this.categoryRepository.find();
      
      for (const category of categories.slice(0, 10)) { // Limit to top 10 categories
        const monthlyAmounts: Decimal[] = [];
        
        for (let month = 1; month <= 12; month++) {
          const monthStart = new Date(year, month - 1, 1);
          const monthEnd = new Date(year, month, 0, 23, 59, 59);
          
          const monthAmount = transactions
            .filter(t => 
              t.categoryId === category.id && 
              t.date >= monthStart && 
              t.date <= monthEnd &&
              t.type === 'expense'
            )
            .reduce((sum, t) => sum + Math.abs(t.amount), 0);
          
          monthlyAmounts.push(Math.round(monthAmount * 100) / 100);
        }

        const averageAmount = monthlyAmounts.reduce((sum, amount) => sum + amount, 0) / 12;
        
        // Simple trend calculation
        const firstHalf = monthlyAmounts.slice(0, 6).reduce((sum, amount) => sum + amount, 0) / 6;
        const secondHalf = monthlyAmounts.slice(6).reduce((sum, amount) => sum + amount, 0) / 6;
        
        let trend: 'increasing' | 'decreasing' | 'stable' = 'stable';
        const changePercentage = firstHalf > 0 ? ((secondHalf - firstHalf) / firstHalf) * 100 : 0;
        
        if (changePercentage > 10) trend = 'increasing';
        else if (changePercentage < -10) trend = 'decreasing';

        if (averageAmount > 0) { // Only include categories with spending
          categoryTrends.push({
            categoryName: category.name,
            monthlyAmounts,
            averageAmount: Math.round(averageAmount * 100) / 100,
            trend,
          });
        }
      }

      // Goal achievements
      const goals = await this.goalRepository.find({
        where: { userId },
      });

      const goalAchievements: GoalAchievement[] = goals.map(goal => {
        let status: 'achieved' | 'in_progress' | 'overdue' = 'in_progress';
        
        if (goal.isAchieved) {
          status = 'achieved';
        } else if (goal.targetDate < new Date()) {
          status = 'overdue';
        }

        return {
          goalName: goal.name,
          targetAmount: goal.targetAmount,
          achievedAmount: goal.currentAmount,
          achievedDate: goal.achievedAt,
          status,
        };
      });

      const report: YearlyReport = {
        year,
        totalIncome: Math.round(totalIncome * 100) / 100,
        totalExpenses: Math.round(totalExpenses * 100) / 100,
        netCashflow: Math.round(netCashflow * 100) / 100,
        monthlyBreakdown,
        categoryTrends,
        savingsRate: Math.round(savingsRate * 100) / 100,
        goalAchievements,
      };

      return {
        success: true,
        data: report,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to generate yearly report for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'YEARLY_REPORT_FAILED',
          message: 'Failed to generate yearly report',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async generateCashflowReport(
    userId: UUID, 
    startDate: Date, 
    endDate: Date
  ): Promise<ApiResponse<CashflowReport>> {
    try {
      this.logger.log(`Generating cashflow report for user ${userId}, ${startDate} to ${endDate}`);

      const transactions = await this.transactionRepository.find({
        where: {
          userId,
          date: Between(startDate, endDate),
        },
        relations: ['category'],
        order: { date: 'ASC' },
      });

      // Calculate totals
      const totalIncome = transactions
        .filter(t => t.type === 'income')
        .reduce((sum, t) => sum + t.amount, 0);

      const totalExpenses = transactions
        .filter(t => t.type === 'expense')
        .reduce((sum, t) => sum + Math.abs(t.amount), 0);

      const netCashflow = totalIncome - totalExpenses;

      // Daily cashflow
      const dailyCashflowMap = new Map<string, { income: number; expenses: number }>();
      
      transactions.forEach(t => {
        const dateKey = t.date.toISOString().split('T')[0];
        const existing = dailyCashflowMap.get(dateKey) || { income: 0, expenses: 0 };
        
        if (t.type === 'income') {
          existing.income += t.amount;
        } else {
          existing.expenses += Math.abs(t.amount);
        }
        
        dailyCashflowMap.set(dateKey, existing);
      });

      const dailyCashflow: DailyCashflow[] = Array.from(dailyCashflowMap.entries())
        .map(([dateStr, data]) => ({
          date: new Date(dateStr),
          income: Math.round(data.income * 100) / 100,
          expenses: Math.round(data.expenses * 100) / 100,
          netAmount: Math.round((data.income - data.expenses) * 100) / 100,
        }))
        .sort((a, b) => a.date.getTime() - b.date.getTime());

      // Income by category
      const incomeByCategory = this.calculateCategoryBreakdown(
        transactions.filter(t => t.type === 'income'),
        totalIncome
      );

      // Expenses by category
      const expensesByCategory = this.calculateCategoryBreakdown(
        transactions.filter(t => t.type === 'expense'),
        totalExpenses
      );

      // Average daily spending
      const daysDiff = Math.max(1, Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24)));
      const averageDailySpending = totalExpenses / daysDiff;

      const report: CashflowReport = {
        startDate,
        endDate,
        totalIncome: Math.round(totalIncome * 100) / 100,
        totalExpenses: Math.round(totalExpenses * 100) / 100,
        netCashflow: Math.round(netCashflow * 100) / 100,
        dailyCashflow,
        incomeByCategory,
        expensesByCategory,
        averageDailySpending: Math.round(averageDailySpending * 100) / 100,
      };

      return {
        success: true,
        data: report,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to generate cashflow report for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'CASHFLOW_REPORT_FAILED',
          message: 'Failed to generate cashflow report',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  private calculateCategoryBreakdown(transactions: Transaction[], total: number): CategorySummary[] {
    const categoryMap = new Map<string, { amount: number; count: number }>();
    
    transactions.forEach(t => {
      const categoryName = t.category?.name || 'Uncategorized';
      const existing = categoryMap.get(categoryName) || { amount: 0, count: 0 };
      categoryMap.set(categoryName, {
        amount: existing.amount + Math.abs(t.amount),
        count: existing.count + 1,
      });
    });

    return Array.from(categoryMap.entries())
      .map(([categoryName, data]) => ({
        categoryName,
        amount: Math.round(data.amount * 100) / 100,
        transactionCount: data.count,
        percentage: total > 0 ? Math.round((data.amount / total) * 10000) / 100 : 0,
      }))
      .sort((a, b) => b.amount - a.amount);
  }
}