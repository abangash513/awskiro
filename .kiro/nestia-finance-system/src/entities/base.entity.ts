import {
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  BaseEntity as TypeOrmBaseEntity,
} from 'typeorm';
import { UUID, Timestamp } from '../types';

export abstract class BaseEntity extends TypeOrmBaseEntity {
  @PrimaryGeneratedColumn('uuid')
  id: UUID;

  @CreateDateColumn({ type: 'datetime' })
  createdAt: Timestamp;

  @UpdateDateColumn({ type: 'datetime' })
  updatedAt: Timestamp;
}