import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import * as helmet from 'helmet';
import * as cors from 'cors';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  
  try {
    const app = await NestFactory.create(AppModule, {
      logger: ['error', 'warn', 'log', 'debug', 'verbose'],
    });

    const configService = app.get(ConfigService);
    const port = configService.get<number>('PORT', 3000);
    const nodeEnv = configService.get<string>('NODE_ENV', 'development');
    const apiPrefix = configService.get<string>('API_PREFIX', 'api/v1');

    // Security middleware
    app.use(helmet({
      contentSecurityPolicy: nodeEnv === 'production',
      crossOriginEmbedderPolicy: nodeEnv === 'production',
    }));

    // CORS configuration
    if (configService.get<boolean>('CORS_ENABLED', true)) {
      app.use(cors({
        origin: configService.get<string>('CORS_ORIGIN', 'http://localhost:3001'),
        credentials: true,
      }));
    }

    // Global API prefix
    app.setGlobalPrefix(apiPrefix);

    // Global validation pipe
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: {
          enableImplicitConversion: true,
        },
      }),
    );

    // Swagger documentation (development only)
    if (nodeEnv === 'development' && configService.get<boolean>('SWAGGER_ENABLED', true)) {
      const config = new DocumentBuilder()
        .setTitle('Nestia Personal Finance Intelligence API')
        .setDescription('Privacy-first personal finance intelligence system with comprehensive financial analysis and insights')
        .setVersion('1.0.0')
        .addBearerAuth(
          {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
            name: 'JWT',
            description: 'Enter JWT token',
            in: 'header',
          },
          'JWT-auth',
        )
        .addTag('Authentication', 'User authentication and authorization endpoints')
        .addTag('Users', 'User management and profile operations')
        .addTag('Accounts', 'Financial account management')
        .addTag('Transactions', 'Transaction processing and management')
        .addTag('Categories', 'Transaction categorization and management')
        .addTag('Analysis', 'Financial analysis and insights generation')
        .addTag('Goals', 'Financial goal tracking and management')
        .addTag('Reports', 'Financial reporting and data visualization')
        .addTag('Notifications', 'Alert and notification management')
        .build();

      const document = SwaggerModule.createDocument(app, config);
      SwaggerModule.setup(`${apiPrefix}/docs`, app, document, {
        swaggerOptions: {
          persistAuthorization: true,
        },
      });

      logger.log(`Swagger documentation available at http://localhost:${port}/${apiPrefix}/docs`);
    }

    // Graceful shutdown
    process.on('SIGTERM', async () => {
      logger.log('SIGTERM received, shutting down gracefully');
      await app.close();
      process.exit(0);
    });

    process.on('SIGINT', async () => {
      logger.log('SIGINT received, shutting down gracefully');
      await app.close();
      process.exit(0);
    });

    await app.listen(port);
    
    logger.log(`🚀 Nestia Finance System is running on: http://localhost:${port}/${apiPrefix}`);
    logger.log(`📊 Environment: ${nodeEnv}`);
    logger.log(`🔒 Security: Helmet enabled, CORS ${configService.get<boolean>('CORS_ENABLED', true) ? 'enabled' : 'disabled'}`);
    
  } catch (error) {
    logger.error('Failed to start application', error);
    process.exit(1);
  }
}

bootstrap();