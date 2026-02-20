import { Controller, Post, Body, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { ThrottlerGuard } from '@nestjs/throttler';

import { AIAnalysisService } from './ai-analysis.service';
import {
  AIAnalysisRequestDto,
  BatchAnalysisRequestDto,
  CashflowAnalysisDto,
  CategorizationAnalysisDto,
  SubscriptionAnalysisDto,
  SavingsAnalysisDto,
  InvestmentAnalysisDto,
} from './dto/ai-analysis.dto';
import {
  AIAnalysisResponse,
  BatchAnalysisResponse,
  CashflowAnalysisResult,
  CategorizationResult,
  SubscriptionResult,
  SavingsResult,
  InvestmentResult,
} from './interfaces/ai-analysis.interface';

@ApiTags('AI Analysis')
@Controller('ai-analysis')
@UseGuards(ThrottlerGuard)
@ApiBearerAuth()
export class AIAnalysisController {
  constructor(private readonly aiAnalysisService: AIAnalysisService) {}

  @Post('analyze')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ 
    summary: 'Perform AI analysis on financial data',
    description: 'Analyze financial data using foundation models for various analysis types'
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Analysis completed successfully',
    type: Object
  })
  @ApiResponse({ 
    status: 400, 
    description: 'Invalid request data' 
  })
  @ApiResponse({ 
    status: 429, 
    description: 'Rate limit exceeded' 
  })
  async analyzeData(@Body() request: AIAnalysisRequestDto): Promise<AIAnalysisResponse> {
    return this.aiAnalysisService.analyzeData(request);
  }

  @Post('batch')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ 
    summary: 'Process multiple AI analysis requests in batch',
    description: 'Submit multiple analysis requests to be processed concurrently'
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Batch processing completed',
    type: Object
  })
  @ApiResponse({ 
    status: 400, 
    description: 'Invalid batch request data' 
  })
  async processBatch(@Body() batchRequest: BatchAnalysisRequestDto): Promise<BatchAnalysisResponse> {
    return this.aiAnalysisService.processBatch(batchRequest);
  }

  @Post('cashflow')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ 
    summary: 'Analyze cashflow patterns',
    description: 'Perform detailed cashflow analysis on transaction data'
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Cashflow analysis completed',
    type: Object
  })
  async analyzeCashflow(@Body() data: CashflowAnalysisDto): Promise<AIAnalysisResponse<CashflowAnalysisResult>> {
    const request = {
      type: 'cashflow' as const,
      data,
      userId: 'current-user', // This should come from authentication context
    };
    
    return this.aiAnalysisService.analyzeData<CashflowAnalysisResult>(request);
  }

  @Post('categorization')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ 
    summary: 'Categorize financial transactions',
    description: 'Automatically categorize transactions using AI'
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Transaction categorization completed',
    type: Object
  })
  async categorizeTransaction(@Body() data: CategorizationAnalysisDto): Promise<AIAnalysisResponse<CategorizationResult>> {
    const request = {
      type: 'categorization' as const,
      data,
      userId: 'current-user', // This should come from authentication context
    };
    
    return this.aiAnalysisService.analyzeData<CategorizationResult>(request);
  }

  @Post('subscription')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ 
    summary: 'Detect subscription patterns',
    description: 'Identify recurring subscription payments in transaction data'
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Subscription analysis completed',
    type: Object
  })
  async analyzeSubscriptions(@Body() data: SubscriptionAnalysisDto): Promise<AIAnalysisResponse<SubscriptionResult>> {
    const request = {
      type: 'subscription' as const,
      data,
      userId: 'current-user', // This should come from authentication context
    };
    
    return this.aiAnalysisService.analyzeData<SubscriptionResult>(request);
  }

  @Post('savings')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ 
    summary: 'Identify savings opportunities',
    description: 'Analyze spending patterns to find potential savings'
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Savings analysis completed',
    type: Object
  })
  async analyzeSavings(@Body() data: SavingsAnalysisDto): Promise<AIAnalysisResponse<SavingsResult>> {
    const request = {
      type: 'savings' as const,
      data,
      userId: 'current-user', // This should come from authentication context
    };
    
    return this.aiAnalysisService.analyzeData<SavingsResult>(request);
  }

  @Post('investment')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ 
    summary: 'Generate investment recommendations',
    description: 'Provide personalized investment advice based on portfolio and preferences'
  })
  @ApiResponse({ 
    status: 200, 
    description: 'Investment analysis completed',
    type: Object
  })
  async analyzeInvestment(@Body() data: InvestmentAnalysisDto): Promise<AIAnalysisResponse<InvestmentResult>> {
    const request = {
      type: 'investment' as const,
      data,
      userId: 'current-user', // This should come from authentication context
    };
    
    return this.aiAnalysisService.analyzeData<InvestmentResult>(request);
  }
}