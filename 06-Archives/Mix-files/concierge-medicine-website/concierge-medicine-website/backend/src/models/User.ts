import { query } from '../database/connection';
import { User, UserRole } from '../types';

export class UserModel {
  static async create(
    email: string,
    passwordHash: string,
    firstName: string,
    lastName: string,
    role: UserRole = 'PATIENT',
  ): Promise<User> {
    const result = await query(
      `INSERT INTO users (email, password_hash, first_name, last_name, role)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, email, password_hash, first_name, last_name, phone_number, date_of_birth, address, role, mfa_enabled, mfa_secret, last_login, created_at, updated_at, deleted_at`,
      [email, passwordHash, firstName, lastName, role],
    );

    return this.mapRow(result.rows[0]);
  }

  static async findById(id: string): Promise<User | null> {
    const result = await query(
      `SELECT id, email, password_hash, first_name, last_name, phone_number, date_of_birth, address, role, mfa_enabled, mfa_secret, last_login, created_at, updated_at, deleted_at
       FROM users WHERE id = $1 AND deleted_at IS NULL`,
      [id],
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  static async findByEmail(email: string): Promise<User | null> {
    const result = await query(
      `SELECT id, email, password_hash, first_name, last_name, phone_number, date_of_birth, address, role, mfa_enabled, mfa_secret, last_login, created_at, updated_at, deleted_at
       FROM users WHERE email = $1 AND deleted_at IS NULL`,
      [email],
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  static async update(id: string, updates: Partial<User>): Promise<User | null> {
    const fields: string[] = [];
    const values: unknown[] = [];
    let paramCount = 1;

    if (updates.firstName !== undefined) {
      fields.push(`first_name = $${paramCount++}`);
      values.push(updates.firstName);
    }
    if (updates.lastName !== undefined) {
      fields.push(`last_name = $${paramCount++}`);
      values.push(updates.lastName);
    }
    if (updates.phoneNumber !== undefined) {
      fields.push(`phone_number = $${paramCount++}`);
      values.push(updates.phoneNumber);
    }
    if (updates.address !== undefined) {
      fields.push(`address = $${paramCount++}`);
      values.push(updates.address);
    }
    if (updates.mfaEnabled !== undefined) {
      fields.push(`mfa_enabled = $${paramCount++}`);
      values.push(updates.mfaEnabled);
    }
    if (updates.mfaSecret !== undefined) {
      fields.push(`mfa_secret = $${paramCount++}`);
      values.push(updates.mfaSecret);
    }
    if (updates.lastLogin !== undefined) {
      fields.push(`last_login = $${paramCount++}`);
      values.push(updates.lastLogin);
    }

    if (fields.length === 0) {
      return this.findById(id);
    }

    values.push(id);
    const result = await query(
      `UPDATE users SET ${fields.join(', ')} WHERE id = $${paramCount} AND deleted_at IS NULL
       RETURNING id, email, password_hash, first_name, last_name, phone_number, date_of_birth, address, role, mfa_enabled, mfa_secret, last_login, created_at, updated_at, deleted_at`,
      values,
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  static async delete(id: string): Promise<boolean> {
    const result = await query(
      `UPDATE users SET deleted_at = CURRENT_TIMESTAMP WHERE id = $1 AND deleted_at IS NULL`,
      [id],
    );

    return result.rowCount > 0;
  }

  static async findByRole(role: UserRole): Promise<User[]> {
    const result = await query(
      `SELECT id, email, password_hash, first_name, last_name, phone_number, date_of_birth, address, role, mfa_enabled, mfa_secret, last_login, created_at, updated_at, deleted_at
       FROM users WHERE role = $1 AND deleted_at IS NULL`,
      [role],
    );

    return result.rows.map((row) => this.mapRow(row));
  }

  private static mapRow(row: Record<string, unknown>): User {
    return {
      id: row.id as string,
      email: row.email as string,
      passwordHash: row.password_hash as string,
      firstName: row.first_name as string,
      lastName: row.last_name as string,
      phoneNumber: row.phone_number as string | undefined,
      dateOfBirth: row.date_of_birth ? new Date(row.date_of_birth as string) : undefined,
      address: row.address as string | undefined,
      role: row.role as string,
      mfaEnabled: row.mfa_enabled as boolean,
      mfaSecret: row.mfa_secret as string | undefined,
      lastLogin: row.last_login ? new Date(row.last_login as string) : undefined,
      createdAt: new Date(row.created_at as string),
      updatedAt: new Date(row.updated_at as string),
      deletedAt: row.deleted_at ? new Date(row.deleted_at as string) : undefined,
    };
  }
}
