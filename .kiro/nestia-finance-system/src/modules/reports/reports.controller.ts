import { 
  Controller, 
  Get, 
  Query, 
  UseGuards, 
  Request,
  ParseIntPipe,
  BadRequestException,
  Logger 
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ReportsService, MonthlyReport, YearlyReport, CashflowReport } from './reports.service';
import { ApiResponse as CustomApiResponse } from '../../types';

@ApiTags('reports')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('reports')
export class ReportsController {
  private readonly logger = new Logger(ReportsController.name);

  constructor(private readonly reportsService: ReportsService) {}

  @Get('monthly')
  @ApiOperation({ 
    summary: 'Generate monthly financial report',
    description: 'Generate a comprehensive monthly report including income, expenses, goal progress, and account balances'
  })
  @ApiQuery({ name: 'year', type: Number, description: 'Year for the report' })
  @ApiQuery({ name: 'month', type: Number, description: 'Month for the report (1-12)' })
  @ApiResponse({ status: 200, description: 'Monthly report generated successfully' })
  @ApiResponse({ status: 400, description: 'Invalid month or year provided' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getMonthlyReport(
    @Request() req: any,
    @Query('year', ParseIntPipe) year: number,
    @Query('month', ParseIntPipe) month: number,
  ): Promise<CustomApiResponse<MonthlyReport>> {
    this.logger.log(`Generating monthly report for user ${req.user.userId}, ${year}-${month}`);

    // Validate month
    if (month < 1 || month > 12) {
      throw new BadRequestException('Month must be between 1 and 12');
    }

    // Validate year (reasonable range)
    const currentYear = new Date().getFullYear();
    if (year < 2000 || year > currentYear + 1) {
      throw new BadRequestException(`Year must be between 2000 and ${currentYear + 1}`);
    }

    return await this.reportsService.generateMonthlyReport(req.user.userId, year, month);
  }

  @Get('yearly')
  @ApiOperation({ 
    summary: 'Generate yearly financial report',
    description: 'Generate a comprehensive yearly report with monthly breakdown, category trends, and goal achievements'
  })
  @ApiQuery({ name: 'year', type: Number, description: 'Year for the report' })
  @ApiResponse({ status: 200, description: 'Yearly report generated successfully' })
  @ApiResponse({ status: 400, description: 'Invalid year provided' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getYearlyReport(
    @Request() req: any,
    @Query('year', ParseIntPipe) year: number,
  ): Promise<CustomApiResponse<YearlyReport>> {
    this.logger.log(`Generating yearly report for user ${req.user.userId}, ${year}`);

    // Validate year (reasonable range)
    const currentYear = new Date().getFullYear();
    if (year < 2000 || year > currentYear + 1) {
      throw new BadRequestException(`Year must be between 2000 and ${currentYear + 1}`);
    }

    return await this.reportsService.generateYearlyReport(req.user.userId, year);
  }

  @Get('cashflow')
  @ApiOperation({ 
    summary: 'Generate cashflow report',
    description: 'Generate a detailed cashflow report for a specified date range with daily breakdown'
  })
  @ApiQuery({ name: 'startDate', type: String, description: 'Start date (YYYY-MM-DD)' })
  @ApiQuery({ name: 'endDate', type: String, description: 'End date (YYYY-MM-DD)' })
  @ApiResponse({ status: 200, description: 'Cashflow report generated successfully' })
  @ApiResponse({ status: 400, description: 'Invalid date range provided' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getCashflowReport(
    @Request() req: any,
    @Query('startDate') startDateStr: string,
    @Query('endDate') endDateStr: string,
  ): Promise<CustomApiResponse<CashflowReport>> {
    this.logger.log(`Generating cashflow report for user ${req.user.userId}, ${startDateStr} to ${endDateStr}`);

    // Validate and parse dates
    const startDate = new Date(startDateStr);
    const endDate = new Date(endDateStr);

    if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
      throw new BadRequestException('Invalid date format. Use YYYY-MM-DD format.');
    }

    if (startDate >= endDate) {
      throw new BadRequestException('Start date must be before end date');
    }

    // Limit date range to prevent excessive data processing
    const daysDiff = Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));
    if (daysDiff > 365) {
      throw new BadRequestException('Date range cannot exceed 365 days');
    }

    // Ensure dates are not in the future beyond today
    const today = new Date();
    today.setHours(23, 59, 59, 999);
    if (startDate > today) {
      throw new BadRequestException('Start date cannot be in the future');
    }

    return await this.reportsService.generateCashflowReport(req.user.userId, startDate, endDate);
  }

  @Get('current-month')
  @ApiOperation({ 
    summary: 'Generate current month report',
    description: 'Generate a monthly report for the current month'
  })
  @ApiResponse({ status: 200, description: 'Current month report generated successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getCurrentMonthReport(@Request() req: any): Promise<CustomApiResponse<MonthlyReport>> {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1;

    this.logger.log(`Generating current month report for user ${req.user.userId}, ${year}-${month}`);

    return await this.reportsService.generateMonthlyReport(req.user.userId, year, month);
  }

  @Get('current-year')
  @ApiOperation({ 
    summary: 'Generate current year report',
    description: 'Generate a yearly report for the current year'
  })
  @ApiResponse({ status: 200, description: 'Current year report generated successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getCurrentYearReport(@Request() req: any): Promise<CustomApiResponse<YearlyReport>> {
    const year = new Date().getFullYear();

    this.logger.log(`Generating current year report for user ${req.user.userId}, ${year}`);

    return await this.reportsService.generateYearlyReport(req.user.userId, year);
  }

  @Get('last-30-days')
  @ApiOperation({ 
    summary: 'Generate last 30 days cashflow report',
    description: 'Generate a cashflow report for the last 30 days'
  })
  @ApiResponse({ status: 200, description: 'Last 30 days report generated successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getLast30DaysReport(@Request() req: any): Promise<CustomApiResponse<CashflowReport>> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 30);

    this.logger.log(`Generating last 30 days report for user ${req.user.userId}`);

    return await this.reportsService.generateCashflowReport(req.user.userId, startDate, endDate);
  }
}