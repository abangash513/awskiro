import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReportsController } from './reports.controller';
import { ReportsService } from './reports.service';

// Entities
import { Transaction } from '../../entities/transaction.entity';
import { Account } from '../../entities/account.entity';
import { Category } from '../../entities/category.entity';
import { Goal } from '../../entities/goal.entity';
import { User } from '../../entities/user.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Transaction,
      Account,
      Category,
      Goal,
      User,
    ]),
  ],
  controllers: [ReportsController],
  providers: [ReportsService],
  exports: [ReportsService],
})
export class ReportsModule {}