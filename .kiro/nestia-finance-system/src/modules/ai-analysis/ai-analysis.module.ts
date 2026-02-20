import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { CacheModule } from '@nestjs/cache-manager';

import { AIAnalysisService } from './ai-analysis.service';
import { AIAnalysisController } from './ai-analysis.controller';

@Module({
  imports: [
    ConfigModule,
    CacheModule.register({
      ttl: 30 * 60 * 1000, // 30 minutes default TTL
      max: 1000, // Maximum number of items in cache
    }),
  ],
  controllers: [AIAnalysisController],
  providers: [AIAnalysisService],
  exports: [AIAnalysisService],
})
export class AIAnalysisModule {}