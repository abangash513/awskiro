import { Entity, Column, OneToOne, JoinColumn } from 'typeorm';
import { BaseEntity } from './base.entity';
import { User } from './user.entity';
import { CurrencyCode, UUID } from '../types';

@Entity('user_preferences')
export class UserPreferences extends BaseEntity {
  @Column({ type: 'uuid' })
  userId: UUID;

  @Column({ length: 3, default: 'USD' })
  defaultCurrency: CurrencyCode;

  @Column({ 
    type: 'text',
    default: 'weekly',
    check: "insightFrequency IN ('daily', 'weekly', 'monthly')"
  })
  insightFrequency: 'daily' | 'weekly' | 'monthly';

  @Column({ type: 'integer', default: 5 })
  maxInsightsPerSession: number;

  @Column({ type: 'integer', default: 3 })
  maxRecommendationsPerSession: number;

  @Column({ 
    type: 'text',
    default: 'encouraging',
    check: "communicationTone IN ('formal', 'casual', 'encouraging')"
  })
  communicationTone: 'formal' | 'casual' | 'encouraging';

  @Column({ default: true })
  categoriesAutoLearn: boolean;

  @Column({ default: true })
  alertsEnabled: boolean;

  @Column({ type: 'integer', default: 24 })
  dataRetentionMonths: number;

  // Relationships
  @OneToOne(() => User, (user) => user.preferences)
  @JoinColumn({ name: 'userId' })
  user: User;
}