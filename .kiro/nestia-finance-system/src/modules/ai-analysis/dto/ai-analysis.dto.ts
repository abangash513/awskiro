import { IsString, IsObject, IsOptional, IsEnum, IsNumber, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AnalysisOptionsDto {
  @ApiPropertyOptional({ description: 'Whether to use cached results if available' })
  @IsOptional()
  useCache?: boolean;

  @ApiPropertyOptional({ 
    enum: ['low', 'normal', 'high'], 
    description: 'Processing priority level' 
  })
  @IsOptional()
  @IsEnum(['low', 'normal', 'high'])
  priority?: 'low' | 'normal' | 'high';

  @ApiPropertyOptional({ description: 'Request timeout in milliseconds' })
  @IsOptional()
  @IsNumber()
  timeout?: number;
}

export class AIAnalysisRequestDto {
  @ApiProperty({ 
    enum: ['cashflow', 'categorization', 'subscription', 'savings', 'investment'],
    description: 'Type of AI analysis to perform'
  })
  @IsEnum(['cashflow', 'categorization', 'subscription', 'savings', 'investment'])
  type: 'cashflow' | 'categorization' | 'subscription' | 'savings' | 'investment';

  @ApiProperty({ description: 'Data to analyze (structure varies by analysis type)' })
  @IsObject()
  data: any;

  @ApiProperty({ description: 'User ID for the analysis request' })
  @IsString()
  userId: string;

  @ApiPropertyOptional({ description: 'Additional options for the analysis' })
  @IsOptional()
  @ValidateNested()
  @Type(() => AnalysisOptionsDto)
  options?: AnalysisOptionsDto;
}

export class BatchAnalysisRequestDto {
  @ApiProperty({ description: 'Unique identifier for the batch request' })
  @IsString()
  batchId: string;

  @ApiProperty({ 
    type: [AIAnalysisRequestDto],
    description: 'Array of analysis requests to process in batch' 
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AIAnalysisRequestDto)
  requests: AIAnalysisRequestDto[];

  @ApiProperty({ 
    enum: ['low', 'normal', 'high'],
    description: 'Priority level for the entire batch' 
  })
  @IsEnum(['low', 'normal', 'high'])
  priority: 'low' | 'normal' | 'high';
}

// Specific analysis request DTOs
export class CashflowAnalysisDto {
  @ApiProperty({ description: 'Array of transactions for cashflow analysis' })
  @IsArray()
  transactions: any[];

  @ApiPropertyOptional({ description: 'Time period for analysis (e.g., "6 months", "1 year")' })
  @IsOptional()
  @IsString()
  timeframe?: string;
}

export class CategorizationAnalysisDto {
  @ApiProperty({ description: 'Transaction to categorize' })
  @IsObject()
  transaction: {
    description: string;
    merchant?: string;
    amount: number;
    date: string;
  };
}

export class SubscriptionAnalysisDto {
  @ApiProperty({ description: 'Array of transactions to analyze for subscription patterns' })
  @IsArray()
  transactions: any[];

  @ApiPropertyOptional({ description: 'Merchant name to focus analysis on' })
  @IsOptional()
  @IsString()
  merchantName?: string;
}

export class SavingsAnalysisDto {
  @ApiProperty({ description: 'Array of transactions for savings opportunity analysis' })
  @IsArray()
  transactions: any[];

  @ApiProperty({ description: 'Current monthly income' })
  @IsNumber()
  monthlyIncome: number;

  @ApiPropertyOptional({ description: 'Savings goals and preferences' })
  @IsOptional()
  @IsObject()
  preferences?: {
    riskTolerance?: 'low' | 'medium' | 'high';
    savingsGoals?: string[];
    timeHorizon?: string;
  };
}

export class InvestmentAnalysisDto {
  @ApiProperty({ description: 'Current financial portfolio information' })
  @IsObject()
  portfolio: {
    totalValue: number;
    assets: Array<{
      type: string;
      value: number;
      allocation: number;
    }>;
  };

  @ApiProperty({ description: 'Investment preferences and constraints' })
  @IsObject()
  preferences: {
    riskTolerance: 'conservative' | 'moderate' | 'aggressive';
    timeHorizon: string;
    investmentGoals: string[];
  };

  @ApiProperty({ description: 'Available cash for investment' })
  @IsNumber()
  availableCash: number;
}