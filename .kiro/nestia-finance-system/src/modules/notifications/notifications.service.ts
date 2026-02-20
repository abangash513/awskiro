import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from '../../entities/notification.entity';
import { User } from '../../entities/user.entity';
import { 
  ApiResponse, 
  CreateInput, 
  UpdateInput, 
  UUID,
  NotificationType,
  NotificationPriority 
} from '../../types';

export interface NotificationPreferences {
  emailEnabled: boolean;
  pushEnabled: boolean;
  smsEnabled: boolean;
  budgetAlerts: boolean;
  goalReminders: boolean;
  unusualActivity: boolean;
  weeklyReports: boolean;
  monthlyReports: boolean;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    @InjectRepository(Notification)
    private readonly notificationRepository: Repository<Notification>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async createNotification(
    userId: UUID, 
    notificationData: CreateInput<Notification>
  ): Promise<ApiResponse<Notification>> {
    try {
      this.logger.log(`Creating notification for user ${userId}`);

      const user = await this.userRepository.findOne({ where: { id: userId } });
      if (!user) {
        return {
          success: false,
          error: {
            code: 'USER_NOT_FOUND',
            message: 'User not found',
          },
          timestamp: new Date(),
        };
      }

      const notification = this.notificationRepository.create({
        ...notificationData,
        userId,
        isRead: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const savedNotification = await this.notificationRepository.save(notification);

      return {
        success: true,
        data: savedNotification,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to create notification for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'NOTIFICATION_CREATION_FAILED',
          message: 'Failed to create notification',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async getUserNotifications(
    userId: UUID, 
    unreadOnly: boolean = false
  ): Promise<ApiResponse<Notification[]>> {
    try {
      this.logger.log(`Getting notifications for user ${userId}, unreadOnly: ${unreadOnly}`);

      const whereCondition: any = { userId };
      if (unreadOnly) {
        whereCondition.isRead = false;
      }

      const notifications = await this.notificationRepository.find({
        where: whereCondition,
        order: { createdAt: 'DESC' },
        take: 50, // Limit to recent 50 notifications
      });

      return {
        success: true,
        data: notifications,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to get notifications for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'NOTIFICATIONS_FETCH_FAILED',
          message: 'Failed to retrieve notifications',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async markAsRead(userId: UUID, notificationId: UUID): Promise<ApiResponse<Notification>> {
    try {
      this.logger.log(`Marking notification ${notificationId} as read for user ${userId}`);

      const notification = await this.notificationRepository.findOne({
        where: { id: notificationId, userId },
      });

      if (!notification) {
        return {
          success: false,
          error: {
            code: 'NOTIFICATION_NOT_FOUND',
            message: 'Notification not found',
          },
          timestamp: new Date(),
        };
      }

      notification.isRead = true;
      notification.readAt = new Date();
      notification.updatedAt = new Date();

      const updatedNotification = await this.notificationRepository.save(notification);

      return {
        success: true,
        data: updatedNotification,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to mark notification ${notificationId} as read:`, error);
      return {
        success: false,
        error: {
          code: 'NOTIFICATION_UPDATE_FAILED',
          message: 'Failed to update notification',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async markAllAsRead(userId: UUID): Promise<ApiResponse<void>> {
    try {
      this.logger.log(`Marking all notifications as read for user ${userId}`);

      await this.notificationRepository.update(
        { userId, isRead: false },
        { 
          isRead: true, 
          readAt: new Date(),
          updatedAt: new Date(),
        }
      );

      return {
        success: true,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to mark all notifications as read for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'NOTIFICATIONS_UPDATE_FAILED',
          message: 'Failed to update notifications',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async deleteNotification(userId: UUID, notificationId: UUID): Promise<ApiResponse<void>> {
    try {
      this.logger.log(`Deleting notification ${notificationId} for user ${userId}`);

      const result = await this.notificationRepository.delete({
        id: notificationId,
        userId,
      });

      if (result.affected === 0) {
        return {
          success: false,
          error: {
            code: 'NOTIFICATION_NOT_FOUND',
            message: 'Notification not found',
          },
          timestamp: new Date(),
        };
      }

      return {
        success: true,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to delete notification ${notificationId}:`, error);
      return {
        success: false,
        error: {
          code: 'NOTIFICATION_DELETE_FAILED',
          message: 'Failed to delete notification',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async getUnreadCount(userId: UUID): Promise<ApiResponse<number>> {
    try {
      this.logger.log(`Getting unread count for user ${userId}`);

      const count = await this.notificationRepository.count({
        where: { userId, isRead: false },
      });

      return {
        success: true,
        data: count,
        timestamp: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to get unread count for user ${userId}:`, error);
      return {
        success: false,
        error: {
          code: 'UNREAD_COUNT_FAILED',
          message: 'Failed to get unread count',
          details: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  async createBudgetAlert(
    userId: UUID, 
    categoryName: string, 
    currentAmount: number, 
    budgetLimit: number
  ): Promise<ApiResponse<Notification>> {
    const percentageUsed = (currentAmount / budgetLimit) * 100;
    
    let priority: NotificationPriority = 'medium';
    let title = 'Budget Alert';
    let message = `You've used ${percentageUsed.toFixed(1)}% of your ${categoryName} budget.`;

    if (percentageUsed >= 100) {
      priority = 'high';
      title = 'Budget Exceeded';
      message = `You've exceeded your ${categoryName} budget by ${(percentageUsed - 100).toFixed(1)}%.`;
    } else if (percentageUsed >= 80) {
      priority = 'high';
      title = 'Budget Warning';
      message = `You're approaching your ${categoryName} budget limit (${percentageUsed.toFixed(1)}% used).`;
    }

    return this.createNotification(userId, {
      type: 'budget_alert' as NotificationType,
      priority,
      title,
      message,
      metadata: {
        categoryName,
        currentAmount,
        budgetLimit,
        percentageUsed: Math.round(percentageUsed * 100) / 100,
      },
    });
  }

  async createGoalReminder(
    userId: UUID, 
    goalName: string, 
    targetDate: Date, 
    currentProgress: number
  ): Promise<ApiResponse<Notification>> {
    const daysUntilTarget = Math.ceil((targetDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
    
    let priority: NotificationPriority = 'low';
    let message = `Your goal "${goalName}" is ${currentProgress.toFixed(1)}% complete.`;

    if (daysUntilTarget <= 7) {
      priority = 'high';
      message += ` Only ${daysUntilTarget} days remaining!`;
    } else if (daysUntilTarget <= 30) {
      priority = 'medium';
      message += ` ${daysUntilTarget} days remaining.`;
    }

    return this.createNotification(userId, {
      type: 'goal_reminder' as NotificationType,
      priority,
      title: 'Goal Progress Update',
      message,
      metadata: {
        goalName,
        targetDate: targetDate.toISOString(),
        currentProgress: Math.round(currentProgress * 100) / 100,
        daysRemaining: daysUntilTarget,
      },
    });
  }

  async createUnusualActivityAlert(
    userId: UUID, 
    transactionAmount: number, 
    merchantName: string
  ): Promise<ApiResponse<Notification>> {
    return this.createNotification(userId, {
      type: 'unusual_activity' as NotificationType,
      priority: 'high',
      title: 'Unusual Transaction Detected',
      message: `Large transaction of $${transactionAmount.toFixed(2)} at ${merchantName} detected.`,
      metadata: {
        transactionAmount,
        merchantName,
        detectedAt: new Date().toISOString(),
      },
    });
  }
}