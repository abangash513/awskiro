import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CategoriesService } from './categories.service';
import { CategoryRuleService, CategorySuggestion, RulePerformanceMetrics } from './services/category-rule.service';
import { CategoryMigrationService, MigrationRequest, MigrationProgress } from './services/category-migration.service';
import { Category } from '../../entities/category.entity';
import { CategoryRule } from '../../entities/category-rule.entity';
import { CategoryMigration } from '../../entities/category-migration.entity';
import { CreateInput, UpdateInput, UUID, ApiResponse } from '../../types';

@Controller('categories')
@UseGuards(JwtAuthGuard)
export class CategoriesController {
  constructor(
    private readonly categoriesService: CategoriesService,
    private readonly categoryRuleService: CategoryRuleService,
    private readonly categoryMigrationService: CategoryMigrationService,
  ) {}

  @Post()
  async create(
    @Body() categoryData: CreateInput<Category>,
    @Request() req: any,
  ): Promise<ApiResponse<Category>> {
    try {
      const category = await this.categoriesService.create({
        ...categoryData,
        userId: req.user.id,
      });

      return {
        success: true,
        data: category,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CATEGORY_CREATE_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get()
  async findAll(@Request() req: any): Promise<ApiResponse<Category[]>> {
    try {
      const categories = await this.categoriesService.findAll(req.user.id);

      return {
        success: true,
        data: categories,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CATEGORIES_FETCH_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get('system')
  async findSystemCategories(): Promise<ApiResponse<Category[]>> {
    try {
      const categories = await this.categoriesService.findSystemCategories();

      return {
        success: true,
        data: categories,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'SYSTEM_CATEGORIES_FETCH_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get(':id')
  async findById(
    @Param('id') id: UUID,
    @Request() req: any,
  ): Promise<ApiResponse<Category>> {
    try {
      const category = await this.categoriesService.findById(id, req.user.id);

      return {
        success: true,
        data: category,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CATEGORY_FETCH_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get('parent/:parentId')
  async findByParent(
    @Param('parentId') parentId: UUID,
    @Request() req: any,
  ): Promise<ApiResponse<Category[]>> {
    try {
      const categories = await this.categoriesService.findByParent(
        parentId,
        req.user.id,
      );

      return {
        success: true,
        data: categories,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'SUBCATEGORIES_FETCH_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Put(':id')
  async update(
    @Param('id') id: UUID,
    @Body() updateData: UpdateInput<Category>,
    @Request() req: any,
  ): Promise<ApiResponse<Category>> {
    try {
      const category = await this.categoriesService.update(
        id,
        req.user.id,
        updateData,
      );

      return {
        success: true,
        data: category,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CATEGORY_UPDATE_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Delete(':id')
  async delete(
    @Param('id') id: UUID,
    @Request() req: any,
  ): Promise<ApiResponse<void>> {
    try {
      await this.categoriesService.delete(id, req.user.id);

      return {
        success: true,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CATEGORY_DELETE_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Post('defaults')
  async createDefaults(@Request() req: any): Promise<ApiResponse<Category[]>> {
    try {
      const categories = await this.categoriesService.createDefaultCategories(
        req.user.id,
      );

      return {
        success: true,
        data: categories,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'DEFAULT_CATEGORIES_CREATE_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  // Category Rules endpoints
  @Post('rules')
  async createRule(
    @Body() ruleData: CreateInput<CategoryRule>,
    @Request() req: any,
  ): Promise<ApiResponse<CategoryRule>> {
    try {
      const rule = await this.categoryRuleService.create({
        ...ruleData,
        userId: req.user.id,
      });

      return {
        success: true,
        data: rule,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CATEGORY_RULE_CREATE_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get('rules')
  async getRules(@Request() req: any): Promise<ApiResponse<CategoryRule[]>> {
    try {
      const rules = await this.categoryRuleService.findByUserId(req.user.id);

      return {
        success: true,
        data: rules,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CATEGORY_RULES_FETCH_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get('rules/active')
  async getActiveRules(@Request() req: any): Promise<ApiResponse<CategoryRule[]>> {
    try {
      const rules = await this.categoryRuleService.findActiveByUserId(req.user.id);

      return {
        success: true,
        data: rules,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'ACTIVE_RULES_FETCH_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get('rules/performance')
  async getRulePerformance(@Request() req: any): Promise<ApiResponse<RulePerformanceMetrics[]>> {
    try {
      const metrics = await this.categoryRuleService.getPerformanceMetrics(req.user.id);

      return {
        success: true,
        data: metrics,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'RULE_PERFORMANCE_FETCH_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Post('rules/suggest')
  async suggestCategory(
    @Body() transactionData: {
      merchantName?: string;
      description: string;
      amount: number;
      transactionType: 'debit' | 'credit';
    },
    @Request() req: any,
  ): Promise<ApiResponse<CategorySuggestion[]>> {
    try {
      const suggestions = await this.categoryRuleService.suggestCategory(
        req.user.id,
        transactionData,
      );

      return {
        success: true,
        data: suggestions,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CATEGORY_SUGGESTION_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Post('rules/optimize')
  async optimizeRules(@Request() req: any): Promise<ApiResponse<void>> {
    try {
      await this.categoryRuleService.optimizeRules(req.user.id);

      return {
        success: true,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'RULE_OPTIMIZATION_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Put('rules/:id')
  async updateRule(
    @Param('id') id: UUID,
    @Body() updateData: UpdateInput<CategoryRule>,
  ): Promise<ApiResponse<CategoryRule>> {
    try {
      const rule = await this.categoryRuleService.update(id, updateData);

      return {
        success: true,
        data: rule,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CATEGORY_RULE_UPDATE_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Delete('rules/:id')
  async deleteRule(@Param('id') id: UUID): Promise<ApiResponse<void>> {
    try {
      await this.categoryRuleService.delete(id);

      return {
        success: true,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CATEGORY_RULE_DELETE_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  // Category Migration endpoints
  @Post('migrations')
  async createMigration(
    @Body() migrationRequest: MigrationRequest,
    @Request() req: any,
  ): Promise<ApiResponse<CategoryMigration>> {
    try {
      const migration = await this.categoryMigrationService.createMigration(
        req.user.id,
        migrationRequest,
      );

      return {
        success: true,
        data: migration,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'MIGRATION_CREATE_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Post('migrations/:id/execute')
  async executeMigration(@Param('id') id: UUID): Promise<ApiResponse<void>> {
    try {
      await this.categoryMigrationService.executeMigration(id);

      return {
        success: true,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'MIGRATION_EXECUTION_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get('migrations')
  async getMigrations(@Request() req: any): Promise<ApiResponse<CategoryMigration[]>> {
    try {
      const migrations = await this.categoryMigrationService.getUserMigrations(req.user.id);

      return {
        success: true,
        data: migrations,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'MIGRATIONS_FETCH_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get('migrations/pending')
  async getPendingMigrations(@Request() req: any): Promise<ApiResponse<CategoryMigration[]>> {
    try {
      const migrations = await this.categoryMigrationService.getPendingMigrations(req.user.id);

      return {
        success: true,
        data: migrations,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'PENDING_MIGRATIONS_FETCH_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get('migrations/:id/progress')
  async getMigrationProgress(@Param('id') id: UUID): Promise<ApiResponse<MigrationProgress>> {
    try {
      const progress = await this.categoryMigrationService.getMigrationProgress(id);

      return {
        success: true,
        data: progress,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'MIGRATION_PROGRESS_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Post('migrations/:id/cancel')
  async cancelMigration(@Param('id') id: UUID): Promise<ApiResponse<void>> {
    try {
      await this.categoryMigrationService.cancelMigration(id);

      return {
        success: true,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'MIGRATION_CANCEL_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Post('migrations/:id/rollback')
  async rollbackMigration(@Param('id') id: UUID): Promise<ApiResponse<void>> {
    try {
      await this.categoryMigrationService.rollbackMigration(id);

      return {
        success: true,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'MIGRATION_ROLLBACK_ERROR',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }
}