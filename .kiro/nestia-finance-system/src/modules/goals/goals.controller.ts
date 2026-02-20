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
  Logger,
  ParseUUIDPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { GoalsService, GoalProgress } from './goals.service';
import { Goal } from '../../entities/goal.entity';
import { 
  ApiResponse, 
  CreateInput, 
  UpdateInput, 
  UUID,
  Decimal 
} from '../../types';

export class CreateGoalDto implements CreateInput<Goal> {
  name: string;
  description?: string;
  targetAmount: Decimal;
  targetDate: Date;
  category?: string;
}

export class UpdateGoalDto implements UpdateInput<Goal> {
  name?: string;
  description?: string;
  targetAmount?: Decimal;
  targetDate?: Date;
  category?: string;
}

export class UpdateProgressDto {
  contributionAmount: Decimal;
}

@Controller('goals')
@UseGuards(JwtAuthGuard)
export class GoalsController {
  private readonly logger = new Logger(GoalsController.name);

  constructor(private readonly goalsService: GoalsService) {}

  @Post()
  async createGoal(
    @Request() req,
    @Body() createGoalDto: CreateGoalDto,
  ): Promise<ApiResponse<Goal>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Creating goal for user ${userId}`);
    
    return this.goalsService.createGoal(userId, createGoalDto);
  }

  @Get()
  async getUserGoals(@Request() req): Promise<ApiResponse<Goal[]>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Getting goals for user ${userId}`);
    
    return this.goalsService.getUserGoals(userId);
  }

  @Get(':goalId')
  async getGoalById(
    @Request() req,
    @Param('goalId', ParseUUIDPipe) goalId: UUID,
  ): Promise<ApiResponse<Goal>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Getting goal ${goalId} for user ${userId}`);
    
    return this.goalsService.getGoalById(userId, goalId);
  }

  @Put(':goalId')
  async updateGoal(
    @Request() req,
    @Param('goalId', ParseUUIDPipe) goalId: UUID,
    @Body() updateGoalDto: UpdateGoalDto,
  ): Promise<ApiResponse<Goal>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Updating goal ${goalId} for user ${userId}`);
    
    return this.goalsService.updateGoal(userId, goalId, updateGoalDto);
  }

  @Delete(':goalId')
  async deleteGoal(
    @Request() req,
    @Param('goalId', ParseUUIDPipe) goalId: UUID,
  ): Promise<ApiResponse<void>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Deleting goal ${goalId} for user ${userId}`);
    
    return this.goalsService.deleteGoal(userId, goalId);
  }

  @Get(':goalId/progress')
  async getGoalProgress(
    @Request() req,
    @Param('goalId', ParseUUIDPipe) goalId: UUID,
  ): Promise<ApiResponse<GoalProgress>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Getting progress for goal ${goalId}, user ${userId}`);
    
    return this.goalsService.getGoalProgress(userId, goalId);
  }

  @Put(':goalId/progress')
  async updateGoalProgress(
    @Request() req,
    @Param('goalId', ParseUUIDPipe) goalId: UUID,
    @Body() updateProgressDto: UpdateProgressDto,
  ): Promise<ApiResponse<Goal>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Updating progress for goal ${goalId} with contribution ${updateProgressDto.contributionAmount}`);
    
    return this.goalsService.updateGoalProgress(userId, goalId, updateProgressDto.contributionAmount);
  }
}