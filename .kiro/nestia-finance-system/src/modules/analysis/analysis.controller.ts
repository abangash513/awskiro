import {
  Controller,
  Get,
  Query,
  UseGuards,
  Request,
  BadRequestException,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AnalysisService } from './analysis.service';
import { CashflowAnalysis, ExpenseAnalysis, ApiResponse } from '../../types';

@Controller('analysis')
@UseGuards(JwtAuthGuard)
export class AnalysisController {
  constructor(private readonly analysisService: AnalysisService) {}

  @Get('cashflow')
  async getCashflowAnalysis(
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
    @Request() req: any,
  ): Promise<ApiResponse<CashflowAnalysis>> {
    try {
      if (!startDate || !endDate) {
        throw new BadRequestException('startDate and endDate are required');
      }

      const start = new Date(startDate);
      const end = new Date(endDate);

      if (isNaN(start.getTime()) || isNaN(end.getTime())) {
        throw new BadRequestException('Invalid date format');
      }

      if (start >= end) {
        throw new BadRequestException('startDate must be before endDate');
      }

      const analysis = await this.analysisService.generateCashflowAnalysis(
        req.user.id,
        start,
        end,
      );

      return {
        success: true,
        data: analysis,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CASHFLOW_ANALYSIS_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get('expenses')
  async getExpenseAnalysis(
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
    @Request() req: any,
  ): Promise<ApiResponse<ExpenseAnalysis>> {
    try {
      if (!startDate || !endDate) {
        throw new BadRequestException('startDate and endDate are required');
      }

      const start = new Date(startDate);
      const end = new Date(endDate);

      if (isNaN(start.getTime()) || isNaN(end.getTime())) {
        throw new BadRequestException('Invalid date format');
      }

      if (start >= end) {
        throw new BadRequestException('startDate must be before endDate');
      }

      const analysis = await this.analysisService.generateExpenseAnalysis(
        req.user.id,
        start,
        end,
      );

      return {
        success: true,
        data: analysis,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'EXPENSE_ANALYSIS_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get('subscriptions')
  async getSubscriptions(@Request() req: any): Promise<ApiResponse<Array<{
    merchantName: string;
    frequency: 'weekly' | 'monthly' | 'quarterly' | 'annual';
    averageAmount: number;
    nextPaymentDate: Date;
    annualCost: number;
    confidence: number;
  }>>> {
    try {
      const subscriptions = await this.analysisService.detectSubscriptions(
        req.user.id,
      );

      return {
        success: true,
        data: subscriptions,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'SUBSCRIPTION_ANALYSIS_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get('cashflow/monthly')
  async getMonthlyCashflow(
    @Query('months') months: string = '12',
    @Request() req: any,
  ): Promise<ApiResponse<CashflowAnalysis>> {
    try {
      const monthsBack = parseInt(months, 10);
      if (isNaN(monthsBack) || monthsBack < 1 || monthsBack > 24) {
        throw new BadRequestException('months must be between 1 and 24');
      }

      const endDate = new Date();
      const startDate = new Date();
      startDate.setMonth(startDate.getMonth() - monthsBack);

      const analysis = await this.analysisService.generateCashflowAnalysis(
        req.user.id,
        startDate,
        endDate,
      );

      return {
        success: true,
        data: analysis,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'MONTHLY_CASHFLOW_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }
}