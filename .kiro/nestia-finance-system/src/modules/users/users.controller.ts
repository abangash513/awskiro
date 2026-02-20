import { 
  Controller, 
  Get, 
  Post, 
  Put, 
  Delete, 
  Body, 
  Param, 
  UseGuards,
  HttpStatus,
} from '@nestjs/common';
import { 
  ApiTags, 
  ApiOperation, 
  ApiResponse, 
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { UsersService } from './users.service';
import { User } from '../../entities';
import { CreateInput, UpdateInput, ApiResponse as ApiResponseType } from '../../types';

@ApiTags('Users')
@Controller('users')
// @UseGuards(JwtAuthGuard) // TODO: Implement when AuthModule is ready
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new user' })
  @ApiResponse({ 
    status: HttpStatus.CREATED, 
    description: 'User created successfully',
    type: User,
  })
  @ApiResponse({ 
    status: HttpStatus.BAD_REQUEST, 
    description: 'Invalid user data' 
  })
  async create(@Body() userData: CreateInput<User>): Promise<ApiResponseType<User>> {
    try {
      const user = await this.usersService.create(userData);
      return {
        success: true,
        data: user,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'USER_CREATION_FAILED',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Get(':id')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user by ID' })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiResponse({ 
    status: HttpStatus.OK, 
    description: 'User found',
    type: User,
  })
  @ApiResponse({ 
    status: HttpStatus.NOT_FOUND, 
    description: 'User not found' 
  })
  async findById(@Param('id') id: string): Promise<ApiResponseType<User>> {
    try {
      const user = await this.usersService.findById(id);
      return {
        success: true,
        data: user,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'USER_NOT_FOUND',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Put(':id')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update user' })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiResponse({ 
    status: HttpStatus.OK, 
    description: 'User updated successfully',
    type: User,
  })
  @ApiResponse({ 
    status: HttpStatus.NOT_FOUND, 
    description: 'User not found' 
  })
  async update(
    @Param('id') id: string,
    @Body() updateData: UpdateInput<User>,
  ): Promise<ApiResponseType<User>> {
    try {
      const user = await this.usersService.update(id, updateData);
      return {
        success: true,
        data: user,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'USER_UPDATE_FAILED',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }

  @Delete(':id')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete user' })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiResponse({ 
    status: HttpStatus.OK, 
    description: 'User deleted successfully' 
  })
  @ApiResponse({ 
    status: HttpStatus.NOT_FOUND, 
    description: 'User not found' 
  })
  async delete(@Param('id') id: string): Promise<ApiResponseType<void>> {
    try {
      await this.usersService.delete(id);
      return {
        success: true,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'USER_DELETION_FAILED',
          message: error.message,
        },
        timestamp: new Date(),
      };
    }
  }
}