import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { AIAnalysisService } from './ai-analysis.service';
import {
  AIAnalysisRequest,
  CashflowAnalysisResult,
  CategorizationResult,
  SubscriptionResult,
} from './interfaces/ai-analysis.interface';

describe('AIAnalysisService', () => {
  let service: AIAnalysisService;
  let configService: ConfigService;
  let cacheManager: any;

  const mockCacheManager = {
    get: jest.fn(),
    set: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      const config = {
        AI_API_KEY: 'test-api-key',
        AI_API_BASE_URL: 'https://api.openai.com/v1',
      };
      return config[key];
    }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AIAnalysisService,
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
        {
          provide: CACHE_MANAGER,
          useValue: mockCacheManager,
        },
      ],
    }).compile();

    service = module.get<AIAnalysisService>(AIAnalysisService);
    configService = module.get<ConfigService>(ConfigService);
    cacheManager = module.get(CACHE_MANAGER);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('analyzeData', () => {
    it('should return cached result when available', async () => {
      const request: AIAnalysisRequest = {
        type: 'cashflow',
        data: { transactions: [] },
        userId: 'user123',
        options: { useCache: true },
      };

      const cachedResult = {
        success: true,
        data: { monthlyIncome: 5000 } as CashflowAnalysisResult,
        confidence: 0.9,
        cached: true,
        processingTime: 50,
      };

      mockCacheManager.get.mockResolvedValue(cachedResult);

      const result = await service.analyzeData(request);

      expect(result.cached).toBe(true);
      expect(result.data).toEqual(cachedResult.data);
      expect(mockCacheManager.get).toHaveBeenCalled();
    });

    it('should handle analysis errors gracefully', async () => {
      const request: AIAnalysisRequest = {
        type: 'categorization',
        data: { transaction: { description: 'Test' } },
        userId: 'user123',
      };

      mockCacheManager.get.mockResolvedValue(null);
      
      // Mock the HTTP client to throw an error
      jest.spyOn(service as any, 'callFoundationModel').mockRejectedValue(
        new Error('API Error')
      );

      const result = await service.analyzeData(request);

      expect(result.success).toBe(false);
      expect(result.error).toBe('API Error');
      expect(result.confidence).toBe(0);
    });
  });

  describe('processBatch', () => {
    it('should process multiple requests in batch', async () => {
      const batchRequest = {
        batchId: 'batch123',
        requests: [
          {
            type: 'cashflow' as const,
            data: { transactions: [] },
            userId: 'user123',
          },
          {
            type: 'categorization' as const,
            data: { transaction: { description: 'Test' } },
            userId: 'user123',
          },
        ],
        priority: 'normal' as const,
      };

      mockCacheManager.get.mockResolvedValue(null);
      
      // Mock successful responses
      jest.spyOn(service as any, 'callFoundationModel').mockResolvedValue(
        JSON.stringify({ monthlyIncome: 5000, confidence: 0.9 })
      );

      const result = await service.processBatch(batchRequest);

      expect(result.batchId).toBe('batch123');
      expect(result.results).toHaveLength(2);
      expect(result.successCount).toBeGreaterThan(0);
    });
  });

  describe('prompt building', () => {
    it('should build cashflow prompt correctly', () => {
      const data = {
        transactions: [
          { amount: 1000, description: 'Salary', date: '2023-01-01' },
          { amount: -500, description: 'Rent', date: '2023-01-01' },
        ],
        timeframe: '6 months',
      };

      const prompt = (service as any).buildCashflowPrompt(data);

      expect(prompt).toContain('6 months');
      expect(prompt).toContain('Salary');
      expect(prompt).toContain('monthlyIncome');
      expect(prompt).toContain('JSON format');
    });

    it('should build categorization prompt correctly', () => {
      const data = {
        transaction: {
          description: 'STARBUCKS COFFEE',
          merchant: 'Starbucks',
          amount: -4.50,
          date: '2023-01-01',
        },
      };

      const prompt = (service as any).buildCategorizationPrompt(data);

      expect(prompt).toContain('STARBUCKS COFFEE');
      expect(prompt).toContain('Starbucks');
      expect(prompt).toContain('-4.50');
      expect(prompt).toContain('category');
    });
  });

  describe('response parsing', () => {
    it('should parse cashflow response correctly', () => {
      const response = JSON.stringify({
        monthlyIncome: 5000,
        monthlyExpenses: 3000,
        netCashflow: 2000,
        trends: { direction: 'increasing', percentage: 10 },
        seasonality: { detected: true, pattern: 'holiday spending', confidence: 0.8 },
        projections: { nextMonth: 2100, nextQuarter: 6300, nextYear: 25200 },
      });

      const result = (service as any).parseCashflowResponse(response);

      expect(result.monthlyIncome).toBe(5000);
      expect(result.netCashflow).toBe(2000);
      expect(result.trends.direction).toBe('increasing');
      expect(result.seasonality.detected).toBe(true);
    });

    it('should handle invalid JSON in response parsing', () => {
      const invalidResponse = 'invalid json';

      expect(() => {
        (service as any).parseCashflowResponse(invalidResponse);
      }).toThrow('Invalid cashflow analysis response format');
    });

    it('should parse categorization response correctly', () => {
      const response = JSON.stringify({
        category: 'Food & Dining',
        subcategory: 'Coffee Shops',
        confidence: 0.95,
        reasoning: 'Starbucks is a well-known coffee chain',
        suggestedBudgetCategory: 'Dining Out',
      });

      const result = (service as any).parseCategorizationResponse(response);

      expect(result.category).toBe('Food & Dining');
      expect(result.subcategory).toBe('Coffee Shops');
      expect(result.confidence).toBe(0.95);
      expect(result.reasoning).toContain('Starbucks');
    });
  });

  describe('caching', () => {
    it('should generate consistent cache keys', () => {
      const request1: AIAnalysisRequest = {
        type: 'cashflow',
        data: { transactions: [{ id: 1 }] },
        userId: 'user123',
      };

      const request2: AIAnalysisRequest = {
        type: 'cashflow',
        data: { transactions: [{ id: 1 }] },
        userId: 'user123',
      };

      const key1 = (service as any).generateCacheKey(request1);
      const key2 = (service as any).generateCacheKey(request2);

      expect(key1).toBe(key2);
      expect(key1).toContain('ai_analysis:cashflow:user123');
    });

    it('should generate different cache keys for different data', () => {
      const request1: AIAnalysisRequest = {
        type: 'cashflow',
        data: { transactions: [{ id: 1 }] },
        userId: 'user123',
      };

      const request2: AIAnalysisRequest = {
        type: 'cashflow',
        data: { transactions: [{ id: 2 }] },
        userId: 'user123',
      };

      const key1 = (service as any).generateCacheKey(request1);
      const key2 = (service as any).generateCacheKey(request2);

      expect(key1).not.toBe(key2);
    });
  });
});