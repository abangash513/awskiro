import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InsightsController } from './insights.controller';
import { InsightsService } from './insights.service';
import { User } from '../../entities/user.entity';
import { Transaction } from '../../entities/transaction.entity';
import { Account } from '../../entities/account.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Transaction, Account]),
  ],
  controllers: [InsightsController],
  providers: [InsightsService],
  exports: [InsightsService],
})
export class InsightsModule {}