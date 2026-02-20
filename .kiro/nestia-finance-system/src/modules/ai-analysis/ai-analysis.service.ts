import { Injectable, Logger, Inject } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Cache } from 'cache-manager';
import axios, { AxiosInstance } from 'axios';
import * as crypto from 'crypto';

import {
  AIAnalysisRequest,
  AIAnalysisResponse,
  BatchAnalysisRequest,
  BatchAnalysisResponse,
  CashflowAnalysisResult,
  CategorizationResult,
  SubscriptionResult,
  SavingsResult,
  InvestmentResult,
} from './interfaces/ai-analysis.interface';

@Injectable()
export class AIAnalysisService {
  private readonly logger = new Logger(AIAnalysisService.name);
  private readonly httpClient: AxiosInstance;
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(
    private readonly configService: ConfigService,
    @Inject(CACHE_MANAGER) private readonly cacheManager: Cache,
  ) {
    this.apiKey = this.configService.get<string>('AI_API_KEY');
    this.baseUrl = this.configService.get<string>('AI_API_BASE_URL');
    
    this.httpClient = axios.create({
      baseURL: this.baseUrl,
      timeout: 30000,
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
    });
  }

  async analyzeData<T = any>(request: AIAnalysisRequest): Promise<AIAnalysisResponse<T>> {
    const startTime = Date.now();
    
    try {
      // Check cache first if enabled
      if (request.options?.useCache !== false) {
        const cacheKey = this.generateCacheKey(request);
        const cachedResult = await this.cacheManager.get<AIAnalysisResponse<T>>(cacheKey);
        
        if (cachedResult) {
          this.logger.debug(`Cache hit for analysis type: ${request.type}`);
          return {
            ...cachedResult,
            cached: true,
            processingTime: Date.now() - startTime,
          };
        }
      }

      // Perform analysis
      const prompt = this.buildPrompt(request);
      const response = await this.callFoundationModel(prompt, request.options?.timeout);
      const parsedResult = this.parseResponse(request.type, response);
      
      const result: AIAnalysisResponse<T> = {
        success: true,
        data: parsedResult.data,
        confidence: parsedResult.confidence,
        cached: false,
        processingTime: Date.now() - startTime,
        timestamp: new Date(),
      };

      // Cache the result
      if (request.options?.useCache !== false) {
        const cacheKey = this.generateCacheKey(request);
        const cacheTTL = this.getCacheTTL(request.type);
        await this.cacheManager.set(cacheKey, result, cacheTTL);
      }

      return result;
    } catch (error) {
      this.logger.error(`Analysis failed for type ${request.type}:`, error.message);
      
      return {
        success: false,
        error: error.message,
        confidence: 0,
        cached: false,
        processingTime: Date.now() - startTime,
        timestamp: new Date(),
      };
    }
  }

  async processBatch(batchRequest: BatchAnalysisRequest): Promise<BatchAnalysisResponse> {
    const startTime = Date.now();
    const results: AIAnalysisResponse[] = [];
    
    this.logger.log(`Processing batch ${batchRequest.batchId} with ${batchRequest.requests.length} requests`);

    // Process requests concurrently with rate limiting
    const concurrencyLimit = 5;
    const chunks = this.chunkArray(batchRequest.requests, concurrencyLimit);
    
    for (const chunk of chunks) {
      const chunkPromises = chunk.map(request => this.analyzeData(request));
      const chunkResults = await Promise.all(chunkPromises);
      results.push(...chunkResults);
    }

    const successCount = results.filter(r => r.success).length;
    const failureCount = results.length - successCount;

    return {
      batchId: batchRequest.batchId,
      results,
      successCount,
      failureCount,
      totalProcessingTime: Date.now() - startTime,
      timestamp: new Date(),
    };
  }

  private buildPrompt(request: AIAnalysisRequest): string {
    switch (request.type) {
      case 'cashflow':
        return this.buildCashflowPrompt(request.data);
      case 'categorization':
        return this.buildCategorizationPrompt(request.data);
      case 'subscription':
        return this.buildSubscriptionPrompt(request.data);
      case 'savings':
        return this.buildSavingsPrompt(request.data);
      case 'investment':
        return this.buildInvestmentPrompt(request.data);
      default:
        throw new Error(`Unsupported analysis type: ${request.type}`);
    }
  }

  private buildCashflowPrompt(data: any): string {
    const { transactions, timeframe = '6 months' } = data;
    
    return `
Analyze the following financial transactions for cashflow patterns over ${timeframe}.

Transactions:
${JSON.stringify(transactions, null, 2)}

Please provide a comprehensive cashflow analysis in JSON format with the following structure:
{
  "monthlyIncome": number,
  "monthlyExpenses": number,
  "netCashflow": number,
  "trends": {
    "direction": "increasing" | "decreasing" | "stable",
    "percentage": number
  },
  "seasonality": {
    "detected": boolean,
    "pattern": string,
    "confidence": number
  },
  "projections": {
    "nextMonth": number,
    "nextQuarter": number,
    "nextYear": number
  }
}

Focus on identifying income patterns, expense categories, and seasonal variations.
    `.trim();
  }

  private buildCategorizationPrompt(data: any): string {
    const { transaction } = data;
    
    return `
Categorize the following financial transaction:

Transaction Details:
- Description: ${transaction.description}
- Merchant: ${transaction.merchant || 'Unknown'}
- Amount: ${transaction.amount}
- Date: ${transaction.date}

Please provide categorization in JSON format:
{
  "category": string,
  "subcategory": string,
  "confidence": number (0-1),
  "reasoning": string,
  "suggestedBudgetCategory": string
}

Use standard financial categories like "Food & Dining", "Transportation", "Shopping", etc.
    `.trim();
  }

  private buildSubscriptionPrompt(data: any): string {
    const { transactions, merchantName } = data;
    
    return `
Analyze the following transactions to identify subscription patterns:

Transactions:
${JSON.stringify(transactions, null, 2)}

${merchantName ? `Focus on transactions from: ${merchantName}` : ''}

Please provide subscription analysis in JSON format:
{
  "isSubscription": boolean,
  "confidence": number (0-1),
  "subscriptionDetails": {
    "frequency": "weekly" | "monthly" | "quarterly" | "yearly",
    "estimatedAmount": number,
    "nextPaymentDate": string,
    "merchantName": string
  },
  "reasoning": string
}

Look for recurring patterns, consistent amounts, and regular intervals.
    `.trim();
  }

  private buildSavingsPrompt(data: any): string {
    const { transactions, monthlyIncome, preferences = {} } = data;
    
    return `
Analyze spending patterns to identify savings opportunities:

Monthly Income: ${monthlyIncome}
Transactions:
${JSON.stringify(transactions, null, 2)}

Preferences:
${JSON.stringify(preferences, null, 2)}

Please provide savings analysis in JSON format:
{
  "opportunities": [
    {
      "category": string,
      "potentialSavings": number,
      "confidence": number,
      "recommendation": string
    }
  ],
  "totalPotentialSavings": number,
  "priorityRecommendations": [string]
}

Focus on identifying overspending, unnecessary subscriptions, and optimization opportunities.
    `.trim();
  }

  private buildInvestmentPrompt(data: any): string {
    const { portfolio, preferences, availableCash } = data;
    
    return `
Provide investment recommendations based on the following information:

Current Portfolio:
${JSON.stringify(portfolio, null, 2)}

Investment Preferences:
${JSON.stringify(preferences, null, 2)}

Available Cash: ${availableCash}

Please provide investment analysis in JSON format:
{
  "riskProfile": "conservative" | "moderate" | "aggressive",
  "recommendations": [
    {
      "type": string,
      "allocation": number,
      "reasoning": string,
      "expectedReturn": number
    }
  ],
  "diversificationScore": number (0-1),
  "suggestions": [string]
}

Consider risk tolerance, time horizon, and diversification principles.
    `.trim();
  }

  private async callFoundationModel(prompt: string, timeout?: number): Promise<string> {
    try {
      const response = await this.httpClient.post('/chat/completions', {
        model: 'gpt-4',
        messages: [
          {
            role: 'system',
            content: 'You are a financial analysis expert. Provide accurate, detailed analysis in the requested JSON format only. Do not include any additional text or explanations outside the JSON structure.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        temperature: 0.1,
        max_tokens: 2000,
      }, {
        timeout: timeout || 30000,
      });

      return response.data.choices[0].message.content;
    } catch (error) {
      this.logger.error('Foundation model API call failed:', error.message);
      throw new Error(`AI API Error: ${error.message}`);
    }
  }

  private parseResponse(type: string, response: string): { data: any; confidence: number } {
    try {
      switch (type) {
        case 'cashflow':
          return { data: this.parseCashflowResponse(response), confidence: 0.9 };
        case 'categorization':
          return { data: this.parseCategorizationResponse(response), confidence: 0.85 };
        case 'subscription':
          return { data: this.parseSubscriptionResponse(response), confidence: 0.8 };
        case 'savings':
          return { data: this.parseSavingsResponse(response), confidence: 0.85 };
        case 'investment':
          return { data: this.parseInvestmentResponse(response), confidence: 0.8 };
        default:
          throw new Error(`Unsupported response type: ${type}`);
      }
    } catch (error) {
      this.logger.error(`Failed to parse ${type} response:`, error.message);
      throw new Error(`Response parsing failed: ${error.message}`);
    }
  }

  private parseCashflowResponse(response: string): CashflowAnalysisResult {
    try {
      const parsed = JSON.parse(response);
      
      if (!parsed.monthlyIncome || !parsed.monthlyExpenses || !parsed.netCashflow) {
        throw new Error('Missing required cashflow fields');
      }
      
      return parsed as CashflowAnalysisResult;
    } catch (error) {
      throw new Error('Invalid cashflow analysis response format');
    }
  }

  private parseCategorizationResponse(response: string): CategorizationResult {
    try {
      const parsed = JSON.parse(response);
      
      if (!parsed.category || !parsed.confidence) {
        throw new Error('Missing required categorization fields');
      }
      
      return parsed as CategorizationResult;
    } catch (error) {
      throw new Error('Invalid categorization response format');
    }
  }

  private parseSubscriptionResponse(response: string): SubscriptionResult {
    try {
      const parsed = JSON.parse(response);
      
      if (typeof parsed.isSubscription !== 'boolean' || !parsed.confidence) {
        throw new Error('Missing required subscription fields');
      }
      
      return parsed as SubscriptionResult;
    } catch (error) {
      throw new Error('Invalid subscription analysis response format');
    }
  }

  private parseSavingsResponse(response: string): SavingsResult {
    try {
      const parsed = JSON.parse(response);
      
      if (!Array.isArray(parsed.opportunities) || typeof parsed.totalPotentialSavings !== 'number') {
        throw new Error('Missing required savings fields');
      }
      
      return parsed as SavingsResult;
    } catch (error) {
      throw new Error('Invalid savings analysis response format');
    }
  }

  private parseInvestmentResponse(response: string): InvestmentResult {
    try {
      const parsed = JSON.parse(response);
      
      if (!parsed.riskProfile || !Array.isArray(parsed.recommendations)) {
        throw new Error('Missing required investment fields');
      }
      
      return parsed as InvestmentResult;
    } catch (error) {
      throw new Error('Invalid investment analysis response format');
    }
  }

  private generateCacheKey(request: AIAnalysisRequest): string {
    const dataHash = crypto
      .createHash('md5')
      .update(JSON.stringify(request.data))
      .digest('hex');
    
    return `ai_analysis:${request.type}:${request.userId}:${dataHash}`;
  }

  private getCacheTTL(analysisType: string): number {
    // Cache TTL in milliseconds
    const ttlMap = {
      cashflow: 30 * 60 * 1000, // 30 minutes
      categorization: 24 * 60 * 60 * 1000, // 24 hours
      subscription: 60 * 60 * 1000, // 1 hour
      savings: 30 * 60 * 1000, // 30 minutes
      investment: 15 * 60 * 1000, // 15 minutes
    };
    
    return ttlMap[analysisType] || 30 * 60 * 1000;
  }

  private chunkArray<T>(array: T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }
}