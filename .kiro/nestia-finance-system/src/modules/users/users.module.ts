import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User, UserPreferences } from '../../entities';
import { UserRepository } from '../../repositories/implementations';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, UserPreferences]),
  ],
  controllers: [UsersController],
  providers: [
    UsersService,
    UserRepository,
  ],
  exports: [UsersService, UserRepository],
})
export class UsersModule {}