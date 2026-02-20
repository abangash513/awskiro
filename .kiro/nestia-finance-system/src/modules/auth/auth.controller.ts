import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  Get,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ThrottlerGuard } from '@nestjs/throttler';
import { AuthService, LoginDto, RegisterDto, AuthResult } from './auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { ApiResponse } from '../../types';
import { User } from '../../entities/user.entity';

@Controller('auth')
@UseGuards(ThrottlerGuard)
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @UseGuards(AuthGuard('local'))
  async login(@Body() loginDto: LoginDto): Promise<ApiResponse<AuthResult>> {
    const result = await this.authService.login(loginDto);
    
    return {
      success: true,
      data: result,
      timestamp: new Date(),
    };
  }

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  async register(@Body() registerDto: RegisterDto): Promise<ApiResponse<AuthResult>> {
    const result = await this.authService.register(registerDto);
    
    return {
      success: true,
      data: result,
      timestamp: new Date(),
    };
  }

  @Get('profile')
  @UseGuards(JwtAuthGuard)
  async getProfile(@Request() req): Promise<ApiResponse<Omit<User, 'passwordHash'>>> {
    const { passwordHash, ...userWithoutPassword } = req.user;
    
    return {
      success: true,
      data: userWithoutPassword,
      timestamp: new Date(),
    };
  }

  @Post('refresh')
  @UseGuards(JwtAuthGuard)
  async refreshToken(@Request() req): Promise<ApiResponse<{ accessToken: string }>> {
    const result = await this.authService.refreshToken(req.user);
    
    return {
      success: true,
      data: result,
      timestamp: new Date(),
    };
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async logout(): Promise<ApiResponse<{ message: string }>> {
    // In a stateless JWT system, logout is handled client-side
    // In a more sophisticated system, you might maintain a blacklist
    return {
      success: true,
      data: { message: 'Logged out successfully' },
      timestamp: new Date(),
    };
  }
}