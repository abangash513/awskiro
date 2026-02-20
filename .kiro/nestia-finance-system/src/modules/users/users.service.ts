import { Injectable, NotFoundException } from '@nestjs/common';
import { UserRepository } from '../../repositories/implementations';
import { User, UserPreferences } from '../../entities';
import { CreateInput, UpdateInput } from '../../types';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(
    private readonly userRepository: UserRepository,
  ) {}

  async create(userData: CreateInput<User>): Promise<User> {
    // Hash password before saving
    const hashedPassword = await bcrypt.hash(userData.passwordHash, 10);
    
    const user = await this.userRepository.create({
      ...userData,
      passwordHash: hashedPassword,
    });

    // Create default preferences
    await this.createDefaultPreferences(user.id);

    return user;
  }

  async findById(id: string): Promise<User> {
    const user = await this.userRepository.findById(id);
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return user;
  }

  async findByEmail(email: string): Promise<User | null> {
    return await this.userRepository.findByEmail(email);
  }

  async update(id: string, updateData: UpdateInput<User>): Promise<User> {
    const user = await this.findById(id);
    
    // Hash password if it's being updated
    if (updateData.passwordHash) {
      updateData.passwordHash = await bcrypt.hash(updateData.passwordHash, 10);
    }

    return await this.userRepository.update(id, updateData);
  }

  async delete(id: string): Promise<void> {
    const user = await this.findById(id);
    await this.userRepository.delete(id);
  }

  async updateLastLogin(id: string): Promise<void> {
    await this.userRepository.update(id, {
      lastLoginAt: new Date(),
    });
  }

  async validatePassword(user: User, password: string): Promise<boolean> {
    return await bcrypt.compare(password, user.passwordHash);
  }

  private async createDefaultPreferences(userId: string): Promise<UserPreferences> {
    // This would typically use a UserPreferencesRepository
    // For now, we'll create a basic implementation
    const defaultPreferences: CreateInput<UserPreferences> = {
      userId,
      defaultCurrency: 'USD',
      insightFrequency: 'weekly',
      maxInsightsPerSession: 5,
      maxRecommendationsPerSession: 3,
      communicationTone: 'encouraging',
      categoriesAutoLearn: true,
      alertsEnabled: true,
      dataRetentionMonths: 24,
    };

    // TODO: Implement UserPreferencesRepository and use it here
    return defaultPreferences as UserPreferences;
  }
}