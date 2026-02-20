import { registerAs } from '@nestjs/config';
import { AppConfig } from '../types';

export const appConfig = registerAs('app', (): AppConfig => ({
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: (process.env.NODE_ENV as 'development' | 'production' | 'test') || 'development',
  
  database: {
    type: 'sqlite',
    database: process.env.DB_DATABASE || './data/nestia-finance.db',
    synchronize: process.env.DB_SYNCHRONIZE === 'true' || process.env.NODE_ENV === 'development',
    logging: process.env.DB_LOGGING === 'true',
    entities: ['dist/**/*.entity{.ts,.js}'],
    migrations: ['dist/migrations/*{.ts,.js}'],
  },

  security: {
    jwtSecret: process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-this-in-production',
    jwtExpiresIn: process.env.JWT_EXPIRES_IN || '24h',
    bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS || '12', 10),
    encryptionKey: process.env.ENCRYPTION_KEY || 'your-32-character-encryption-key-here',
  },

  features: {
    openBankingEnabled: process.env.OPEN_BANKING_ENABLED === 'true',
    plaidEnabled: process.env.PLAID_ENABLED === 'true',
    mlCategorization: process.env.ML_CATEGORIZATION_ENABLED !== 'false',
    investmentAnalysis: process.env.INVESTMENT_ANALYSIS_ENABLED !== 'false',
  },
}));