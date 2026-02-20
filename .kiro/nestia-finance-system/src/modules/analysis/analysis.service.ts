import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Transaction } from '../../entities/transaction.entity';
import { Account } from '../../entities/account.entity';
import { Category } from '../../entities/category.entity';
import { CashflowAnalysisEntity } from '../../entities/cashflow-analysis.entity';
import { UUID, CashflowAnalysis, ExpenseAnalysis, Decimal } from '../../types';

@Injectable()
export class AnalysisService {
  constructor(
    @InjectRepository(Transaction)
    private readonly transactionRepository: Repository<Transaction>,
    @InjectRepository(Account)
    private readonly accountRepository: Repository<Account>,
    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
    @InjectRepository(CashflowAnalysisEntity)
    private readonly cashflowAnalysisRepository: Repository<CashflowAnalysisEntity>,
  ) {}

  async generateCashflowAnalysis(
    userId: UUID,
    startDate: Date,
    endDate: Date,
  ): Promise<CashflowAnalysis> {
    // Get user's accounts
    const accounts = await this.accountRepository.find({
      where: { userId },
    });
    const accountIds = accounts.map(account => account.id);

    // Get transactions for the period
    const transactions = await this.transactionRepository.find({
      where: {
        accountId: { $in: accountIds } as any,
        transactionDate: Between(startDate, endDate),
      },
      relations: ['category'],
    });

    // Calculate totals
    let totalIncome = 0;
    let totalExpenses = 0;
    const incomeByCategory: Record<string, Decimal> = {};
    const expensesByCategory: Record<string, Decimal> = {};

    transactions.forEach(transaction => {
      const amount = Math.abs(transaction.amount);
      const categoryName = transaction.category?.name || 'Uncategorized';

      if (transaction.transactionType === 'credit') {
        totalIncome += amount;
        incomeByCategory[categoryName] = (incomeByCategory[categoryName] || 0) + amount;
      } else {
        totalExpenses += amount;
        expensesByCategory[categoryName] = (expensesByCategory[categoryName] || 0) + amount;
      }
    });

    // Generate monthly trend
    const monthlyTrend = this.generateMonthlyTrend(transactions, startDate, endDate);

    const analysis: CashflowAnalysis = {
      userId,
      periodStart: startDate,
      periodEnd: endDate,
      totalIncome,
      totalExpenses,
      netCashflow: totalIncome - totalExpenses,
      incomeByCategory,
      expensesByCategory,
      monthlyTrend,
      generatedAt: new Date(),
    };

    // Save analysis to database
    const analysisEntity = this.cashflowAnalysisRepository.create({
      userId,
      periodStart: startDate,
      periodEnd: endDate,
      totalIncome,
      totalExpenses,
      netCashflow: analysis.netCashflow,
      analysisData: JSON.stringify({
        incomeByCategory,
        expensesByCategory,
        monthlyTrend,
      }),
    });

    await this.cashflowAnalysisRepository.save(analysisEntity);

    return analysis;
  }

  async generateExpenseAnalysis(
    userId: UUID,
    startDate: Date,
    endDate: Date,
  ): Promise<ExpenseAnalysis> {
    // Get user's accounts
    const accounts = await this.accountRepository.find({
      where: { userId },
    });
    const accountIds = accounts.map(account => account.id);

    // Get expense transactions for the period
    const transactions = await this.transactionRepository.find({
      where: {
        accountId: { $in: accountIds } as any,
        transactionDate: Between(startDate, endDate),
        transactionType: 'debit',
      },
      relations: ['category'],
    });

    let totalExpenses = 0;
    const expensesByCategory: Record<string, Decimal> = {};

    transactions.forEach(transaction => {
      const amount = Math.abs(transaction.amount);
      const categoryName = transaction.category?.name || 'Uncategorized';
      
      totalExpenses += amount;
      expensesByCategory[categoryName] = (expensesByCategory[categoryName] || 0) + amount;
    });

    // Calculate top expense categories
    const topExpenseCategories = Object.entries(expensesByCategory)
      .map(([categoryName, amount]) => ({
        categoryName,
        amount,
        percentage: (amount / totalExpenses) * 100,
      }))
      .sort((a, b) => b.amount - a.amount)
      .slice(0, 10);

    // Detect unusual expenses (transactions > 2 standard deviations from mean)
    const amounts = transactions.map(t => Math.abs(t.amount));
    const mean = amounts.reduce((sum, amount) => sum + amount, 0) / amounts.length;
    const variance = amounts.reduce((sum, amount) => sum + Math.pow(amount - mean, 2), 0) / amounts.length;
    const stdDev = Math.sqrt(variance);
    const threshold = mean + (2 * stdDev);

    const unusualExpenses = transactions
      .filter(transaction => Math.abs(transaction.amount) > threshold)
      .map(transaction => ({
        transactionId: transaction.id,
        amount: Math.abs(transaction.amount),
        description: transaction.description,
        reason: 'Amount significantly higher than average',
      }));

    return {
      userId,
      periodStart: startDate,
      periodEnd: endDate,
      totalExpenses,
      expensesByCategory,
      topExpenseCategories,
      unusualExpenses,
      generatedAt: new Date(),
    };
  }

  async detectSubscriptions(userId: UUID): Promise<Array<{
    merchantName: string;
    frequency: 'weekly' | 'monthly' | 'quarterly' | 'annual';
    averageAmount: Decimal;
    nextPaymentDate: Date;
    annualCost: Decimal;
    confidence: Decimal;
  }>> {
    // Get user's accounts
    const accounts = await this.accountRepository.find({
      where: { userId },
    });
    const accountIds = accounts.map(account => account.id);

    // Get transactions from last 2 years for pattern detection
    const twoYearsAgo = new Date();
    twoYearsAgo.setFullYear(twoYearsAgo.getFullYear() - 2);

    const transactions = await this.transactionRepository.find({
      where: {
        accountId: { $in: accountIds } as any,
        transactionDate: Between(twoYearsAgo, new Date()),
        transactionType: 'debit',
      },
      order: { transactionDate: 'ASC' },
    });

    // Group transactions by merchant name (fuzzy matching)
    const merchantGroups = this.groupTransactionsByMerchant(transactions);

    const subscriptions = [];

    for (const [merchantName, merchantTransactions] of merchantGroups.entries()) {
      if (merchantTransactions.length < 3) continue; // Need at least 3 transactions

      const subscription = this.analyzeSubscriptionPattern(merchantName, merchantTransactions);
      if (subscription && subscription.confidence > 0.7) {
        subscriptions.push(subscription);
      }
    }

    return subscriptions.sort((a, b) => b.annualCost - a.annualCost);
  }

  private generateMonthlyTrend(
    transactions: Transaction[],
    startDate: Date,
    endDate: Date,
  ): Array<{ month: string; income: Decimal; expenses: Decimal; netFlow: Decimal }> {
    const monthlyData = new Map<string, { income: number; expenses: number }>();

    // Initialize months
    const current = new Date(startDate);
    while (current <= endDate) {
      const monthKey = `${current.getFullYear()}-${String(current.getMonth() + 1).padStart(2, '0')}`;
      monthlyData.set(monthKey, { income: 0, expenses: 0 });
      current.setMonth(current.getMonth() + 1);
    }

    // Aggregate transactions by month
    transactions.forEach(transaction => {
      const monthKey = `${transaction.transactionDate.getFullYear()}-${String(transaction.transactionDate.getMonth() + 1).padStart(2, '0')}`;
      const data = monthlyData.get(monthKey);
      
      if (data) {
        const amount = Math.abs(transaction.amount);
        if (transaction.transactionType === 'credit') {
          data.income += amount;
        } else {
          data.expenses += amount;
        }
      }
    });

    return Array.from(monthlyData.entries()).map(([month, data]) => ({
      month,
      income: data.income,
      expenses: data.expenses,
      netFlow: data.income - data.expenses,
    }));
  }

  private groupTransactionsByMerchant(transactions: Transaction[]): Map<string, Transaction[]> {
    const groups = new Map<string, Transaction[]>();

    transactions.forEach(transaction => {
      const merchantName = this.normalizeMerchantName(transaction.merchantName || transaction.description);
      
      if (!groups.has(merchantName)) {
        groups.set(merchantName, []);
      }
      groups.get(merchantName)!.push(transaction);
    });

    return groups;
  }

  private normalizeMerchantName(name: string): string {
    // Remove common suffixes and normalize merchant names
    return name
      .toLowerCase()
      .replace(/\s+/g, ' ')
      .replace(/\b(inc|llc|corp|ltd|co)\b/g, '')
      .replace(/[^a-z0-9\s]/g, '')
      .trim();
  }

  private analyzeSubscriptionPattern(
    merchantName: string,
    transactions: Transaction[],
  ): {
    merchantName: string;
    frequency: 'weekly' | 'monthly' | 'quarterly' | 'annual';
    averageAmount: Decimal;
    nextPaymentDate: Date;
    annualCost: Decimal;
    confidence: Decimal;
  } | null {
    if (transactions.length < 3) return null;

    // Sort transactions by date
    transactions.sort((a, b) => a.transactionDate.getTime() - b.transactionDate.getTime());

    // Calculate intervals between transactions
    const intervals = [];
    for (let i = 1; i < transactions.length; i++) {
      const daysDiff = Math.round(
        (transactions[i].transactionDate.getTime() - transactions[i - 1].transactionDate.getTime()) / 
        (1000 * 60 * 60 * 24)
      );
      intervals.push(daysDiff);
    }

    // Determine frequency based on average interval
    const avgInterval = intervals.reduce((sum, interval) => sum + interval, 0) / intervals.length;
    const intervalVariance = intervals.reduce((sum, interval) => sum + Math.pow(interval - avgInterval, 2), 0) / intervals.length;
    const intervalStdDev = Math.sqrt(intervalVariance);

    // Low variance indicates regular pattern
    const regularityScore = Math.max(0, 1 - (intervalStdDev / avgInterval));

    let frequency: 'weekly' | 'monthly' | 'quarterly' | 'annual';
    if (avgInterval >= 6 && avgInterval <= 8) frequency = 'weekly';
    else if (avgInterval >= 28 && avgInterval <= 32) frequency = 'monthly';
    else if (avgInterval >= 88 && avgInterval <= 95) frequency = 'quarterly';
    else if (avgInterval >= 360 && avgInterval <= 370) frequency = 'annual';
    else return null; // Not a recognized subscription pattern

    // Calculate average amount
    const amounts = transactions.map(t => Math.abs(t.amount));
    const averageAmount = amounts.reduce((sum, amount) => sum + amount, 0) / amounts.length;
    const amountVariance = amounts.reduce((sum, amount) => sum + Math.pow(amount - averageAmount, 2), 0) / amounts.length;
    const amountConsistency = Math.max(0, 1 - (Math.sqrt(amountVariance) / averageAmount));

    // Overall confidence score
    const confidence = (regularityScore + amountConsistency) / 2;

    // Predict next payment date
    const lastTransaction = transactions[transactions.length - 1];
    const nextPaymentDate = new Date(lastTransaction.transactionDate);
    nextPaymentDate.setDate(nextPaymentDate.getDate() + avgInterval);

    // Calculate annual cost
    let paymentsPerYear: number;
    switch (frequency) {
      case 'weekly': paymentsPerYear = 52; break;
      case 'monthly': paymentsPerYear = 12; break;
      case 'quarterly': paymentsPerYear = 4; break;
      case 'annual': paymentsPerYear = 1; break;
    }

    const annualCost = averageAmount * paymentsPerYear;

    return {
      merchantName,
      frequency,
      averageAmount,
      nextPaymentDate,
      annualCost,
      confidence,
    };
  }
}