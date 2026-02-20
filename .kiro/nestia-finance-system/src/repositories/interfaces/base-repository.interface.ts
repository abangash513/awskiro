import { DeepPartial, FindManyOptions, FindOneOptions } from 'typeorm';

/**
 * Base repository interface defining common CRUD operations
 */
export interface IBaseRepository<T> {
  /**
   * Create a new entity
   */
  create(entity: DeepPartial<T>): Promise<T>;

  /**
   * Find entity by ID
   */
  findById(id: string): Promise<T | null>;

  /**
   * Find one entity by criteria
   */
  findOne(options: FindOneOptions<T>): Promise<T | null>;

  /**
   * Find multiple entities
   */
  findMany(options?: FindManyOptions<T>): Promise<T[]>;

  /**
   * Find entities with pagination
   */
  findWithPagination(
    options: FindManyOptions<T>,
    page: number,
    limit: number,
  ): Promise<{
    data: T[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }>;

  /**
   * Update entity by ID
   */
  update(id: string, updates: DeepPartial<T>): Promise<T>;

  /**
   * Delete entity by ID
   */
  delete(id: string): Promise<boolean>;

  /**
   * Count entities matching criteria
   */
  count(options?: FindManyOptions<T>): Promise<number>;

  /**
   * Check if entity exists
   */
  exists(id: string): Promise<boolean>;
}