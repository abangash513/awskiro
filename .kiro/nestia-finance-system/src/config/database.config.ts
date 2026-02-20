import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { entities } from '../entities';

export const databaseConfig = (configService: ConfigService): TypeOrmModuleOptions => {
  const config = configService.get('app');
  
  return {
    type: 'sqlite',
    database: config.database.database,
    entities: entities,
    synchronize: config.database.synchronize,
    logging: config.database.logging,
    migrations: ['dist/migrations/*{.ts,.js}'],
    migrationsTableName: 'nestia_migrations',
    migrationsRun: false,
    cli: {
      migrationsDir: 'src/migrations',
    },
  };
};