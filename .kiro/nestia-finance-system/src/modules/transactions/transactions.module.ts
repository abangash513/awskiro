import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Transaction } from '../../entities/transaction.entity';
import { Account } from '../../entities/account.entity';
import { TransactionRepository } from '../../repositories/implementations/transaction.repository';
import { CategoryRepository } from '../../repositories/implementations/category.repository';
import { AccountsModule } from '../accounts/accounts.module';
import { CategoriesModule } from '../categories/categories.module';
import { TransactionsService } from './transactions.service';
import { TransactionsController } from './transactions.controller';
import { TransactionProcessorService } from './services/transaction-processor.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Transaction, Account]),
    AccountsModule,
    CategoriesModule,
  ],
  controllers: [TransactionsController],
  providers: [
    TransactionsService, 
    TransactionRepository, 
    CategoryRepository,
    TransactionProcessorService,
  ],
  exports: [
    TransactionsService, 
    TransactionRepository, 
    TransactionProcessorService,
  ],
})
export class TransactionsModule {}