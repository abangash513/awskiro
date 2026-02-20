import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Transaction } from '../../../entities/transaction.entity';
import { Account } from '../../../entities/account.entity';
import { Category } from '../../../entities/category.entity';
import { ValidationError, NestiaError } from '../../../types';
import { TransactionRepository } from '../../../repositories/implementations/transaction.repository';
import { CategoryRepository } from '../../../repositories/implementations/category.repository';

export interface TransactionImportData {
  accountId: string;
  date: string;
  amount: number;
  description: string;
  merchantName?: string;
  transactionType?: 'debit' | 'credit';
  category?: string;
  reference?: string;
}

export interface ProcessingResult {
  processed: number;
  duplicates: number;
  errors: number;
  errorDetails: Array<{
    row: number;
    error: string;
    data: Partial<TransactionImportData>;
  }>;
}

export interface DuplicateDetectionConfig {
  dateToleranceDays: number;
  amountToleranceCents: number;
  descriptionSimilarityThreshold: number;
}

@Injectable()
export class TransactionProcessorService {
  private readonly logger = new Logger(TransactionProcessorService.name);
  
  private readonly defaultDuplicateConfig: DuplicateDetectionConfig = {
    dateToleranceDays: 1,
    amountToleranceCents: 0,
    descriptionSimilarityThreshold: 0.85,
  };

  constructor(
    private readonly transactionRepository: TransactionRepository,
    private readonly categoryRepository: CategoryRepository,
    @InjectRepository(Account)
    private readonly accountRepository: Repository<Account>,
  ) {}

  /**
   * Process a batch of transaction data with validation, deduplication, and enrichment
   */
  async processBatch(
    transactions: TransactionImportData[],
    userId: string,
    config?: Partial<DuplicateDetectionConfig>
  ): Promise<ProcessingResult> {
    const processingConfig = { ...this.defaultDuplicateConfig, ...config };
    const result: ProcessingResult = {
      processed: 0,
      duplicates: 0,
      errors: 0,
      errorDetails: [],
    };

    this.logger.log(`Processing batch of ${transactions.length} transactions for user ${userId}`);

    for (let i = 0; i < transactions.length; i++) {
      try {
        const transactionData = transactions[i];
        
        // Validate transaction data
        const validationResult = await this.validateTransaction(transactionData, userId);
        if (!validationResult.isValid) {
          result.errors++;
          result.errorDetails.push({
            row: i + 1,
            error: validationResult.error!,
            data: transactionData,
          });
          continue;
        }

        // Check for duplicates
        const isDuplicate = await this.checkForDuplicate(
          transactionData,
          userId,
          processingConfig
        );
        
        if (isDuplicate) {
          result.duplicates++;
          this.logger.debug(`Duplicate transaction detected at row ${i + 1}`);
          continue;
        }

        // Normalize and enrich transaction data
        const normalizedTransaction = await this.normalizeTransaction(
          transactionData,
          userId
        );

        // Save transaction
        await this.transactionRepository.create(normalizedTransaction);
        result.processed++;

      } catch (error) {
        result.errors++;
        result.errorDetails.push({
          row: i + 1,
          error: error instanceof Error ? error.message : 'Unknown error',
          data: transactions[i],
        });
        this.logger.error(`Error processing transaction at row ${i + 1}:`, error);
      }
    }

    this.logger.log(`Batch processing complete: ${result.processed} processed, ${result.duplicates} duplicates, ${result.errors} errors`);
    return result;
  }

  /**
   * Validate transaction data for completeness and correctness
   */
  private async validateTransaction(
    data: TransactionImportData,
    userId: string
  ): Promise<{ isValid: boolean; error?: string }> {
    // Required fields validation
    if (!data.accountId) {
      return { isValid: false, error: 'Account ID is required' };
    }

    if (!data.date) {
      return { isValid: false, error: 'Transaction date is required' };
    }

    if (data.amount === undefined || data.amount === null) {
      return { isValid: false, error: 'Transaction amount is required' };
    }

    if (!data.description || data.description.trim().length === 0) {
      return { isValid: false, error: 'Transaction description is required' };
    }

    // Date validation
    const transactionDate = new Date(data.date);
    if (isNaN(transactionDate.getTime())) {
      return { isValid: false, error: 'Invalid transaction date format' };
    }

    // Future date validation (allow up to 1 day in future for timezone differences)
    const maxFutureDate = new Date();
    maxFutureDate.setDate(maxFutureDate.getDate() + 1);
    if (transactionDate > maxFutureDate) {
      return { isValid: false, error: 'Transaction date cannot be in the future' };
    }

    // Amount validation
    if (typeof data.amount !== 'number' || !isFinite(data.amount)) {
      return { isValid: false, error: 'Transaction amount must be a valid number' };
    }

    if (Math.abs(data.amount) > 1000000) {
      return { isValid: false, error: 'Transaction amount exceeds maximum allowed value' };
    }

    // Account ownership validation
    const account = await this.accountRepository.findOne({
      where: { id: data.accountId, userId },
    });

    if (!account) {
      return { isValid: false, error: 'Account not found or access denied' };
    }

    if (!account.isActive) {
      return { isValid: false, error: 'Cannot add transactions to inactive account' };
    }

    return { isValid: true };
  }

  /**
   * Check if a transaction is a duplicate based on configurable criteria
   */
  private async checkForDuplicate(
    data: TransactionImportData,
    userId: string,
    config: DuplicateDetectionConfig
  ): Promise<boolean> {
    const transactionDate = new Date(data.date);
    const startDate = new Date(transactionDate);
    startDate.setDate(startDate.getDate() - config.dateToleranceDays);
    const endDate = new Date(transactionDate);
    endDate.setDate(endDate.getDate() + config.dateToleranceDays);

    // Find potentially duplicate transactions
    const potentialDuplicates = await this.transactionRepository.findByDateRange(
      data.accountId,
      startDate,
      endDate
    );

    for (const existing of potentialDuplicates) {
      // Check amount similarity
      const amountDiff = Math.abs(existing.amount - data.amount);
      if (amountDiff <= config.amountToleranceCents / 100) {
        // Check description similarity
        const similarity = this.calculateStringSimilarity(
          existing.description.toLowerCase(),
          data.description.toLowerCase()
        );
        
        if (similarity >= config.descriptionSimilarityThreshold) {
          return true;
        }
      }
    }

    return false;
  }

  /**
   * Normalize and enrich transaction data
   */
  private async normalizeTransaction(
    data: TransactionImportData,
    userId: string
  ): Promise<Partial<Transaction>> {
    const transactionDate = new Date(data.date);
    
    // Determine transaction type if not provided
    let transactionType = data.transactionType;
    if (!transactionType) {
      transactionType = data.amount < 0 ? 'debit' : 'credit';
    }

    // Normalize amount to always be positive
    const amount = Math.abs(data.amount);

    // Clean up merchant name
    const merchantName = data.merchantName 
      ? this.normalizeMerchantName(data.merchantName)
      : this.extractMerchantFromDescription(data.description);

    // Clean up description
    const description = this.normalizeDescription(data.description);

    // Auto-categorize if category not provided
    let categoryId = undefined;
    if (data.category) {
      const category = await this.categoryRepository.findByName(userId, data.category);
      categoryId = category?.id;
    }

    return {
      accountId: data.accountId,
      transactionDate,
      amount,
      description,
      merchantName,
      transactionType,
      categoryId,
      isRecurring: false, // Will be determined by subscription detection
      userVerified: false,
      confidenceScore: 1.0, // High confidence for manually imported data
    };
  }

  /**
   * Normalize merchant name by removing common suffixes and cleaning up formatting
   */
  private normalizeMerchantName(merchantName: string): string {
    let normalized = merchantName.trim().toUpperCase();
    
    // Remove common suffixes
    const suffixesToRemove = [
      /\s+INC\.?$/,
      /\s+LLC\.?$/,
      /\s+LTD\.?$/,
      /\s+CORP\.?$/,
      /\s+CO\.?$/,
      /\s+#\d+$/,
      /\s+\d{10,}$/,
    ];

    for (const suffix of suffixesToRemove) {
      normalized = normalized.replace(suffix, '');
    }

    // Remove extra whitespace
    normalized = normalized.replace(/\s+/g, ' ').trim();

    return normalized;
  }

  /**
   * Extract merchant name from transaction description
   */
  private extractMerchantFromDescription(description: string): string | undefined {
    // Common patterns for merchant extraction
    const patterns = [
      /^([A-Z\s&]+)\s+\d+/,  // "MERCHANT NAME 123456"
      /^([A-Z\s&]+)\s+[A-Z]{2}$/,  // "MERCHANT NAME CA"
      /^([A-Z\s&]+)\s+\*\d+/,  // "MERCHANT NAME *1234"
    ];

    for (const pattern of patterns) {
      const match = description.toUpperCase().match(pattern);
      if (match && match[1]) {
        return this.normalizeMerchantName(match[1]);
      }
    }

    return undefined;
  }

  /**
   * Normalize transaction description
   */
  private normalizeDescription(description: string): string {
    return description
      .trim()
      .replace(/\s+/g, ' ')  // Normalize whitespace
      .replace(/[^\w\s\-\.\,\&\*\#]/g, '')  // Remove special characters except common ones
      .substring(0, 255);  // Limit length
  }

  /**
   * Calculate string similarity using Levenshtein distance
   */
  private calculateStringSimilarity(str1: string, str2: string): number {
    const matrix = Array(str2.length + 1).fill(null).map(() => Array(str1.length + 1).fill(null));

    for (let i = 0; i <= str1.length; i++) {
      matrix[0][i] = i;
    }

    for (let j = 0; j <= str2.length; j++) {
      matrix[j][0] = j;
    }

    for (let j = 1; j <= str2.length; j++) {
      for (let i = 1; i <= str1.length; i++) {
        const indicator = str1[i - 1] === str2[j - 1] ? 0 : 1;
        matrix[j][i] = Math.min(
          matrix[j][i - 1] + 1,     // deletion
          matrix[j - 1][i] + 1,     // insertion
          matrix[j - 1][i - 1] + indicator  // substitution
        );
      }
    }

    const maxLength = Math.max(str1.length, str2.length);
    return maxLength === 0 ? 1 : 1 - (matrix[str2.length][str1.length] / maxLength);
  }

  /**
   * Parse CSV data into transaction import format
   */
  async parseCSV(csvData: string, fieldMapping: Record<string, string>): Promise<TransactionImportData[]> {
    const lines = csvData.split('\n').filter(line => line.trim());
    if (lines.length === 0) {
      throw new ValidationError('CSV file is empty');
    }

    const headers = lines[0].split(',').map(h => h.trim().replace(/"/g, ''));
    const transactions: TransactionImportData[] = [];

    for (let i = 1; i < lines.length; i++) {
      const values = this.parseCSVLine(lines[i]);
      if (values.length !== headers.length) {
        throw new ValidationError(`Row ${i + 1}: Column count mismatch`);
      }

      const rowData: Record<string, string> = {};
      headers.forEach((header, index) => {
        rowData[header] = values[index];
      });

      try {
        const transaction = this.mapCSVRowToTransaction(rowData, fieldMapping);
        transactions.push(transaction);
      } catch (error) {
        throw new ValidationError(`Row ${i + 1}: ${error instanceof Error ? error.message : 'Invalid data'}`);
      }
    }

    return transactions;
  }

  /**
   * Parse a single CSV line handling quoted values
   */
  private parseCSVLine(line: string): string[] {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
      const char = line[i];
      
      if (char === '"') {
        inQuotes = !inQuotes;
      } else if (char === ',' && !inQuotes) {
        result.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    
    result.push(current.trim());
    return result;
  }

  /**
   * Map CSV row data to transaction import format
   */
  private mapCSVRowToTransaction(
    rowData: Record<string, string>,
    fieldMapping: Record<string, string>
  ): TransactionImportData {
    const getField = (field: string): string => {
      const mappedField = fieldMapping[field] || field;
      return rowData[mappedField] || '';
    };

    const dateStr = getField('date');
    const amountStr = getField('amount');
    const description = getField('description');
    const accountId = getField('accountId');

    if (!dateStr || !amountStr || !description || !accountId) {
      throw new Error('Missing required fields: date, amount, description, accountId');
    }

    const amount = parseFloat(amountStr.replace(/[,$]/g, ''));
    if (isNaN(amount)) {
      throw new Error(`Invalid amount: ${amountStr}`);
    }

    return {
      accountId,
      date: dateStr,
      amount,
      description,
      merchantName: getField('merchantName') || undefined,
      transactionType: (getField('transactionType') as 'debit' | 'credit') || undefined,
      category: getField('category') || undefined,
      reference: getField('reference') || undefined,
    };
  }
}