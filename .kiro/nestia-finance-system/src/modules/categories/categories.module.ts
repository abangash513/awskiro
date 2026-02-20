import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CategoriesController } from './categories.controller';
import { CategoriesService } from './categories.service';
import { CategoryRuleService } from './services/category-rule.service';
import { CategoryMigrationService } from './services/category-migration.service';
import { Category } from '../../entities/category.entity';
import { CategoryRule } from '../../entities/category-rule.entity';
import { CategoryMigration } from '../../entities/category-migration.entity';
import { Transaction } from '../../entities/transaction.entity';
import { CategoryRuleRepository } from '../../repositories/category-rule.repository';
import { CategoryMigrationRepository } from '../../repositories/category-migration.repository';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Category,
      CategoryRule,
      CategoryMigration,
      Transaction,
    ]),
  ],
  controllers: [CategoriesController],
  providers: [
    CategoriesService,
    CategoryRuleService,
    CategoryMigrationService,
    CategoryRuleRepository,
    CategoryMigrationRepository,
  ],
  exports: [
    CategoriesService,
    CategoryRuleService,
    CategoryMigrationService,
  ],
})
export class CategoriesModule {}