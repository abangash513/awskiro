import { INestiaConfig } from '@nestia/core';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './src/app.module';

const NESTIA_CONFIG: INestiaConfig = {
  input: async () => {
    const app = await NestFactory.create(AppModule);
    return app;
  },
  output: 'src/api',
  distribute: 'packages/api',
  simulate: true,
  clone: true,
  swagger: {
    output: 'swagger.json',
    security: {
      bearer: {
        type: 'apiKey',
        name: 'Authorization',
        in: 'header',
      },
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Local development server',
      },
      {
        url: 'https://api.nestia-finance.com',
        description: 'Production server',
      },
    ],
    info: {
      title: 'Nestia Personal Finance Intelligence API',
      description: 'Privacy-first personal finance intelligence system with comprehensive financial analysis and insights',
      version: '1.0.0',
      contact: {
        name: 'Nestia Development Team',
        email: 'support@nestia-finance.com',
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT',
      },
    },
    tags: [
      {
        name: 'Authentication',
        description: 'User authentication and authorization endpoints',
      },
      {
        name: 'Users',
        description: 'User management and profile operations',
      },
      {
        name: 'Accounts',
        description: 'Financial account management',
      },
      {
        name: 'Transactions',
        description: 'Transaction processing and management',
      },
      {
        name: 'Categories',
        description: 'Transaction categorization and management',
      },
      {
        name: 'Analysis',
        description: 'Financial analysis and insights generation',
      },
      {
        name: 'Goals',
        description: 'Financial goal tracking and management',
      },
      {
        name: 'Reports',
        description: 'Financial reporting and data visualization',
      },
      {
        name: 'Notifications',
        description: 'Alert and notification management',
      },
    ],
  },
  primitive: false,
  propagate: true,
  assert: true,
  validate: true,
  json: true,
  beautify: true,
};

export default NESTIA_CONFIG;