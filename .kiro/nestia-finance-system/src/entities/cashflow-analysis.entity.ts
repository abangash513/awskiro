import { Entity, Column, Index } from 'typeorm';
import { BaseEntity } from './base.entity';
import { Decimal, UUID } from '../types';

@Entity('cashflow_analyses')
@Index(['userId', 'periodStart', 'periodEnd'])
export class CashflowAnalysisEntity extends BaseEntity {
  @Column({ type: 'uuid' })
  userId: UUID;

  @Column({ type: 'date' })
  periodStart: Date;

  @Column({ type: 'date' })
  periodEnd: Date;

  @Column({ type: 'decimal', precision: 15, scale: 2 })
  totalIncome: Decimal;

  @Column({ type: 'decimal', precision: 15, scale: 2 })
  totalExpenses: Decimal;

  @Column({ type: 'decimal', precision: 15, scale: 2 })
  netCashflow: Decimal;

  @Column({ type: 'text' })
  incomeByCategory: string; // JSON string

  @Column({ type: 'text' })
  expensesByCategory: string; // JSON string

  @Column({ type: 'text' })
  monthlyTrend: string; // JSON string

  @Column({ type: 'datetime' })
  generatedAt: Date;

  // Helper methods for JSON serialization
  getIncomeByCategory(): Record<string, Decimal> {
    return JSON.parse(this.incomeByCategory);
  }

  setIncomeByCategory(data: Record<string, Decimal>): void {
    this.incomeByCategory = JSON.stringify(data);
  }

  getExpensesByCategory(): Record<string, Decimal> {
    return JSON.parse(this.expensesByCategory);
  }

  setExpensesByCategory(data: Record<string, Decimal>): void {
    this.expensesByCategory = JSON.stringify(data);
  }

  getMonthlyTrend(): Array<{
    month: string;
    income: Decimal;
    expenses: Decimal;
    netFlow: Decimal;
  }> {
    return JSON.parse(this.monthlyTrend);
  }

  setMonthlyTrend(data: Array<{
    month: string;
    income: Decimal;
    expenses: Decimal;
    netFlow: Decimal;
  }>): void {
    this.monthlyTrend = JSON.stringify(data);
  }
}