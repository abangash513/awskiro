import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AccountsService, CreateAccountDto, UpdateAccountDto } from './accounts.service';
import { Account } from '../../entities/account.entity';
import { ApiResponse, UUID } from '../../types';

@Controller('accounts')
@UseGuards(JwtAuthGuard)
export class AccountsController {
  constructor(private readonly accountsService: AccountsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Request() req,
    @Body() createAccountDto: CreateAccountDto,
  ): Promise<ApiResponse<Account>> {
    const account = await this.accountsService.create(req.user.id, createAccountDto);
    
    return {
      success: true,
      data: account,
      timestamp: new Date(),
    };
  }

  @Get()
  async findAll(@Request() req): Promise<ApiResponse<Account[]>> {
    const accounts = await this.accountsService.findAllByUserId(req.user.id);
    
    return {
      success: true,
      data: accounts,
      timestamp: new Date(),
    };
  }

  @Get(':id')
  async findOne(
    @Request() req,
    @Param('id') id: UUID,
  ): Promise<ApiResponse<Account>> {
    const account = await this.accountsService.findById(id, req.user.id);
    
    return {
      success: true,
      data: account,
      timestamp: new Date(),
    };
  }

  @Put(':id')
  async update(
    @Request() req,
    @Param('id') id: UUID,
    @Body() updateAccountDto: UpdateAccountDto,
  ): Promise<ApiResponse<Account>> {
    const account = await this.accountsService.update(id, req.user.id, updateAccountDto);
    
    return {
      success: true,
      data: account,
      timestamp: new Date(),
    };
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @Request() req,
    @Param('id') id: UUID,
  ): Promise<void> {
    await this.accountsService.delete(id, req.user.id);
  }

  @Put(':id/balance')
  async updateBalance(
    @Request() req,
    @Param('id') id: UUID,
    @Body() balanceData: { balanceCurrent: number; balanceAvailable?: number },
  ): Promise<ApiResponse<Account>> {
    // Verify account ownership
    await this.accountsService.findById(id, req.user.id);
    
    const account = await this.accountsService.updateBalance(
      id,
      balanceData.balanceCurrent,
      balanceData.balanceAvailable,
    );
    
    return {
      success: true,
      data: account,
      timestamp: new Date(),
    };
  }
}