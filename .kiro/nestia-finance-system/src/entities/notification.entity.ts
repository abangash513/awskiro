import { Entity, Column, ManyToOne, JoinColumn, Index } from 'typeorm';
import { BaseEntity } from './base.entity';
import { User } from './user.entity';
import { UUID } from '../types';

export type NotificationType = 
  | 'insight' 
  | 'recommendation' 
  | 'goal_progress' 
  | 'bill_reminder' 
  | 'unusual_spending' 
  | 'subscription_detected'
  | 'goal_achieved'
  | 'budget_exceeded'
  | 'account_sync_error'
  | 'security_alert';

export type NotificationPriority = 'low' | 'medium' | 'high' | 'urgent';

@Entity('notifications')
@Index(['userId', 'isRead'])
@Index(['userId', 'createdAt'])
@Index(['type', 'createdAt'])
export class Notification extends BaseEntity {
  @Column('uuid')
  userId: UUID;

  @Column({
    type: 'enum',
    enum: ['insight', 'recommendation', 'goal_progress', 'bill_reminder', 'unusual_spending', 'subscription_detected', 'goal_achieved', 'budget_exceeded', 'account_sync_error', 'security_alert'],
  })
  type: NotificationType;

  @Column({ length: 200 })
  title: string;

  @Column('text')
  message: string;

  @Column({
    type: 'enum',
    enum: ['low', 'medium', 'high', 'urgent'],
    default: 'medium',
  })
  priority: NotificationPriority;

  @Column({ default: false })
  isRead: boolean;

  @Column({ type: 'jsonb', nullable: true })
  metadata?: Record<string, any>;

  @Column({ type: 'timestamp', nullable: true })
  readAt?: Date;

  @Column({ type: 'timestamp', nullable: true })
  expiresAt?: Date;

  // Relationships
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  // Helper methods
  markAsRead(): void {
    this.isRead = true;
    this.readAt = new Date();
    this.updatedAt = new Date();
  }

  isExpired(): boolean {
    return this.expiresAt ? new Date() > this.expiresAt : false;
  }

  isUrgent(): boolean {
    return this.priority === 'urgent';
  }

  getDisplayPriority(): number {
    const priorityMap = {
      urgent: 4,
      high: 3,
      medium: 2,
      low: 1,
    };
    return priorityMap[this.priority];
  }
}