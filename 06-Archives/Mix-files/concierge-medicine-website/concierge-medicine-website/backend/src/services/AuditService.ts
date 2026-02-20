import { query } from '../database/connection';
import { AuditLog } from '../types';

export class AuditService {
  static async logAccess(
    userId: string | undefined,
    action: string,
    resourceType: string,
    resourceId: string,
    details?: Record<string, unknown>,
    ipAddress?: string,
    userAgent?: string,
  ): Promise<void> {
    try {
      await query(
        `INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, ip_address, user_agent)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [userId || null, action, resourceType, resourceId, JSON.stringify(details || {}), ipAddress, userAgent],
      );
    } catch (error) {
      console.error('Audit logging error:', error);
      // Don't throw - audit logging should not break the application
    }
  }

  static async getAuditLogs(
    resourceType?: string,
    resourceId?: string,
    limit: number = 100,
    offset: number = 0,
  ): Promise<AuditLog[]> {
    try {
      let queryStr = 'SELECT * FROM audit_logs WHERE 1=1';
      const params: unknown[] = [];
      let paramCount = 1;

      if (resourceType) {
        queryStr += ` AND resource_type = $${paramCount++}`;
        params.push(resourceType);
      }

      if (resourceId) {
        queryStr += ` AND resource_id = $${paramCount++}`;
        params.push(resourceId);
      }

      queryStr += ` ORDER BY created_at DESC LIMIT $${paramCount++} OFFSET $${paramCount++}`;
      params.push(limit, offset);

      const result = await query(queryStr, params);

      return result.rows.map((row: Record<string, unknown>) => ({
        id: row.id as string,
        userId: row.user_id as string | undefined,
        action: row.action as string,
        resourceType: row.resource_type as string | undefined,
        resourceId: row.resource_id as string | undefined,
        details: row.details as Record<string, unknown> | undefined,
        ipAddress: row.ip_address as string | undefined,
        userAgent: row.user_agent as string | undefined,
        createdAt: new Date(row.created_at as string),
      }));
    } catch (error) {
      console.error('Error retrieving audit logs:', error);
      return [];
    }
  }

  static async getUserAuditLogs(userId: string, limit: number = 100, offset: number = 0): Promise<AuditLog[]> {
    try {
      const result = await query(
        `SELECT * FROM audit_logs WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`,
        [userId, limit, offset],
      );

      return result.rows.map((row: Record<string, unknown>) => ({
        id: row.id as string,
        userId: row.user_id as string | undefined,
        action: row.action as string,
        resourceType: row.resource_type as string | undefined,
        resourceId: row.resource_id as string | undefined,
        details: row.details as Record<string, unknown> | undefined,
        ipAddress: row.ip_address as string | undefined,
        userAgent: row.user_agent as string | undefined,
        createdAt: new Date(row.created_at as string),
      }));
    } catch (error) {
      console.error('Error retrieving user audit logs:', error);
      return [];
    }
  }
}
