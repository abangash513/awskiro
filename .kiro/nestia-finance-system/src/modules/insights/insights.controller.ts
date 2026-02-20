import { 
  Controller, 
  Get, 
  Query, 
  UseGuards, 
  Request,
  Logger,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { InsightsService, Insight } from './insights.service';
import { ApiResponse, UUID } from '../../types';

@Controller('insights')
@UseGuards(JwtAuthGuard)
export class InsightsController {
  private readonly logger = new Logger(InsightsController.name);

  constructor(private readonly insightsService: InsightsService) {}

  @Get()
  async generateInsights(@Request() req): Promise<ApiResponse<Insight[]>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Generating insights for user ${userId}`);
    
    return this.insightsService.generateInsights(userId);
  }

  @Get('history')
  async getInsightHistory(
    @Request() req,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
  ): Promise<ApiResponse<Insight[]>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Getting insight history for user ${userId}, limit: ${limit}`);
    
    return this.insightsService.getInsightHistory(userId, limit);
  }
}