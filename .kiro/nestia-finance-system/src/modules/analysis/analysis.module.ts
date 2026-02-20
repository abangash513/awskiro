import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AnalysisController } from './analysis.controller';
import { AnalysisService } from './analysis.service';
import { Transaction } from '../../entities/transaction.entity';
import { Account } from '../../entities/account.entity';
import { Category } from '../../entities/category.entity';
import { CashflowAnalysisEntity } from '../../entities/cashflow-analysis.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Transaction,
      Account,
      Category,
      CashflowAnalysisEntity,
    ]),
  ],
  controllers: [AnalysisController],
  providers: [AnalysisService],
  exports: [AnalysisService],
})
export class AnalysisModule {}