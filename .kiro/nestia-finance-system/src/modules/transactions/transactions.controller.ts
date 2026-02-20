import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Express } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { 
  TransactionsService, 
  CreateTransactionDto, 
  UpdateTransactionDto,
  TransactionFilters 
} from './transactions.service';
import { 
  TransactionProcessorService, 
  TransactionImportData, 
  ProcessingResult,
  DuplicateDetectionConfig 
} from './services/transaction-processor.service';
import { Transaction } from '../../entities/transaction.entity';
import { ApiResponse, PaginatedResponse, UUID, ValidationError } from '../../types';

@Controller('transactions')
@UseGuards(JwtAuthGuard)
export class TransactionsController {
  constructor(
    private readonly transactionsService: TransactionsService,
    private readonly transactionProcessorService: TransactionProcessorService,
  ) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Request() req,
    @Body() createTransactionDto: CreateTransactionDto,
  ): Promise<ApiResponse<Transaction>> {
    const transaction = await this.transactionsService.create(req.user.id, createTransactionDto);
    
    return {
      success: true,
      data: transaction,
      timestamp: new Date(),
    };
  }

  @Post('bulk')
  @HttpCode(HttpStatus.CREATED)
  async bulkCreate(
    @Request() req,
    @Body() transactions: CreateTransactionDto[],
  ): Promise<ApiResponse<Transaction[]>> {
    const createdTransactions = await this.transactionsService.bulkCreate(req.user.id, transactions);
    
    return {
      success: true,
      data: createdTransactions,
      timestamp: new Date(),
    };
  }

  @Get()
  async findAll(
    @Request() req,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 50,
    @Query('accountId') accountId?: UUID,
    @Query('categoryId') categoryId?: UUID,
    @Query('transactionType') transactionType?: 'debit' | 'credit',
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('minAmount') minAmount?: number,
    @Query('maxAmount') maxAmount?: number,
    @Query('isRecurring') isRecurring?: boolean,
    @Query('userVerified') userVerified?: boolean,
  ): Promise<PaginatedResponse<Transaction>> {
    const filters: TransactionFilters = {
      accountId,
      categoryId,
      transactionType,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      minAmount,
      maxAmount,
      isRecurring,
      userVerified,
    };

    const { transactions, total } = await this.transactionsService.findAllByUserId(
      req.user.id,
      filters,
      page,
      limit,
    );

    const totalPages = Math.ceil(total / limit);
    
    return {
      success: true,
      data: transactions,
      pagination: {
        page,
        limit,
        total,
        totalPages,
      },
      timestamp: new Date(),
    };
  }

  @Get('recurring')
  async findRecurring(@Request() req): Promise<ApiResponse<Transaction[]>> {
    const transactions = await this.transactionsService.findRecurringTransactions(req.user.id);
    
    return {
      success: true,
      data: transactions,
      timestamp: new Date(),
    };
  }

  @Get(':id')
  async findOne(
    @Request() req,
    @Param('id') id: UUID,
  ): Promise<ApiResponse<Transaction>> {
    const transaction = await this.transactionsService.findById(id, req.user.id);
    
    return {
      success: true,
      data: transaction,
      timestamp: new Date(),
    };
  }

  @Put(':id')
  async update(
    @Request() req,
    @Param('id') id: UUID,
    @Body() updateTransactionDto: UpdateTransactionDto,
  ): Promise<ApiResponse<Transaction>> {
    const transaction = await this.transactionsService.update(id, req.user.id, updateTransactionDto);
    
    return {
      success: true,
      data: transaction,
      timestamp: new Date(),
    };
  }

  @Put(':id/verify')
  async markAsVerified(
    @Request() req,
    @Param('id') id: UUID,
  ): Promise<ApiResponse<Transaction>> {
    const transaction = await this.transactionsService.markAsVerified(id, req.user.id);
    
    return {
      success: true,
      data: transaction,
      timestamp: new Date(),
    };
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @Request() req,
    @Param('id') id: UUID,
  ): Promise<void> {
    await this.transactionsService.delete(id, req.user.id);
  }

  @Post('import/csv')
  @UseInterceptors(FileInterceptor('file', {
    limits: {
      fileSize: 10 * 1024 * 1024, // 10MB limit
    },
    fileFilter: (req, file, callback) => {
      if (file.mimetype !== 'text/csv' && !file.originalname.endsWith('.csv')) {
        return callback(new BadRequestException('Only CSV files are allowed'), false);
      }
      callback(null, true);
    },
  }))
  async importCSV(
    @Request() req,
    @UploadedFile() file: Express.Multer.File,
    @Body('fieldMapping') fieldMappingStr?: string,
    @Body('duplicateConfig') duplicateConfigStr?: string,
  ): Promise<ApiResponse<ProcessingResult>> {
    if (!file) {
      throw new BadRequestException('CSV file is required');
    }

    try {
      // Parse field mapping if provided
      const fieldMapping = fieldMappingStr ? JSON.parse(fieldMappingStr) : {};
      
      // Parse duplicate detection config if provided
      const duplicateConfig: Partial<DuplicateDetectionConfig> = duplicateConfigStr 
        ? JSON.parse(duplicateConfigStr) 
        : {};

      // Convert buffer to string
      const csvData = file.buffer.toString('utf-8');

      // Parse CSV data
      const transactions = await this.transactionProcessorService.parseCSV(csvData, fieldMapping);

      // Process the batch
      const result = await this.transactionProcessorService.processBatch(
        transactions,
        req.user.id,
        duplicateConfig
      );

      return {
        success: true,
        data: result,
        timestamp: new Date(),
      };
    } catch (error) {
      if (error instanceof ValidationError) {
        throw new BadRequestException(error.message);
      }
      throw error;
    }
  }

  @Post('batch')
  @HttpCode(HttpStatus.CREATED)
  async processBatch(
    @Request() req,
    @Body('transactions') transactions: TransactionImportData[],
    @Body('duplicateConfig') duplicateConfig?: Partial<DuplicateDetectionConfig>,
  ): Promise<ApiResponse<ProcessingResult>> {
    if (!transactions || !Array.isArray(transactions) || transactions.length === 0) {
      throw new BadRequestException('Transactions array is required and cannot be empty');
    }

    if (transactions.length > 1000) {
      throw new BadRequestException('Batch size cannot exceed 1000 transactions');
    }

    try {
      const result = await this.transactionProcessorService.processBatch(
        transactions,
        req.user.id,
        duplicateConfig
      );

      return {
        success: true,
        data: result,
        timestamp: new Date(),
      };
    } catch (error) {
      if (error instanceof ValidationError) {
        throw new BadRequestException(error.message);
      }
      throw error;
    }
  }
}