import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GoalsController } from './goals.controller';
import { GoalsService } from './goals.service';
import { Goal } from '../../entities/goal.entity';
import { User } from '../../entities/user.entity';
import { Transaction } from '../../entities/transaction.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Goal, User, Transaction]),
  ],
  controllers: [GoalsController],
  providers: [GoalsService],
  exports: [GoalsService],
})
export class GoalsModule {}