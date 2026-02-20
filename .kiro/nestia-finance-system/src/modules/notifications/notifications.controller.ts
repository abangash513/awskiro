import { 
  Controller, 
  Get, 
  Post, 
  Put, 
  Delete, 
  Body, 
  Param, 
  Query,
  UseGuards, 
  Request,
  Logger,
  ParseUUIDPipe,
  ParseBoolPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { NotificationsService } from './notifications.service';
import { Notification } from '../../entities/notification.entity';
import { 
  ApiResponse, 
  CreateInput, 
  UUID,
  NotificationType,
  NotificationPriority 
} from '../../types';

export class CreateNotificationDto implements CreateInput<Notification> {
  type: NotificationType;
  priority: NotificationPriority;
  title: string;
  message: string;
  metadata?: Record<string, any>;
}

export class CreateBudgetAlertDto {
  categoryName: string;
  currentAmount: number;
  budgetLimit: number;
}

export class CreateGoalReminderDto {
  goalName: string;
  targetDate: Date;
  currentProgress: number;
}

export class CreateUnusualActivityAlertDto {
  transactionAmount: number;
  merchantName: string;
}

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  private readonly logger = new Logger(NotificationsController.name);

  constructor(private readonly notificationsService: NotificationsService) {}

  @Post()
  async createNotification(
    @Request() req,
    @Body() createNotificationDto: CreateNotificationDto,
  ): Promise<ApiResponse<Notification>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Creating notification for user ${userId}`);
    
    return this.notificationsService.createNotification(userId, createNotificationDto);
  }

  @Get()
  async getUserNotifications(
    @Request() req,
    @Query('unreadOnly', new ParseBoolPipe({ optional: true })) unreadOnly?: boolean,
  ): Promise<ApiResponse<Notification[]>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Getting notifications for user ${userId}, unreadOnly: ${unreadOnly}`);
    
    return this.notificationsService.getUserNotifications(userId, unreadOnly);
  }

  @Get('unread-count')
  async getUnreadCount(@Request() req): Promise<ApiResponse<number>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Getting unread count for user ${userId}`);
    
    return this.notificationsService.getUnreadCount(userId);
  }

  @Put(':notificationId/read')
  async markAsRead(
    @Request() req,
    @Param('notificationId', ParseUUIDPipe) notificationId: UUID,
  ): Promise<ApiResponse<Notification>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Marking notification ${notificationId} as read for user ${userId}`);
    
    return this.notificationsService.markAsRead(userId, notificationId);
  }

  @Put('mark-all-read')
  async markAllAsRead(@Request() req): Promise<ApiResponse<void>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Marking all notifications as read for user ${userId}`);
    
    return this.notificationsService.markAllAsRead(userId);
  }

  @Delete(':notificationId')
  async deleteNotification(
    @Request() req,
    @Param('notificationId', ParseUUIDPipe) notificationId: UUID,
  ): Promise<ApiResponse<void>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Deleting notification ${notificationId} for user ${userId}`);
    
    return this.notificationsService.deleteNotification(userId, notificationId);
  }

  @Post('budget-alert')
  async createBudgetAlert(
    @Request() req,
    @Body() createBudgetAlertDto: CreateBudgetAlertDto,
  ): Promise<ApiResponse<Notification>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Creating budget alert for user ${userId}`);
    
    return this.notificationsService.createBudgetAlert(
      userId,
      createBudgetAlertDto.categoryName,
      createBudgetAlertDto.currentAmount,
      createBudgetAlertDto.budgetLimit,
    );
  }

  @Post('goal-reminder')
  async createGoalReminder(
    @Request() req,
    @Body() createGoalReminderDto: CreateGoalReminderDto,
  ): Promise<ApiResponse<Notification>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Creating goal reminder for user ${userId}`);
    
    return this.notificationsService.createGoalReminder(
      userId,
      createGoalReminderDto.goalName,
      createGoalReminderDto.targetDate,
      createGoalReminderDto.currentProgress,
    );
  }

  @Post('unusual-activity-alert')
  async createUnusualActivityAlert(
    @Request() req,
    @Body() createUnusualActivityAlertDto: CreateUnusualActivityAlertDto,
  ): Promise<ApiResponse<Notification>> {
    const userId: UUID = req.user.userId;
    this.logger.log(`Creating unusual activity alert for user ${userId}`);
    
    return this.notificationsService.createUnusualActivityAlert(
      userId,
      createUnusualActivityAlertDto.transactionAmount,
      createUnusualActivityAlertDto.merchantName,
    );
  }
}