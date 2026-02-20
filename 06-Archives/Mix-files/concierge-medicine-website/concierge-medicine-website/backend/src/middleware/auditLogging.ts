import { Request, Response, NextFunction } from 'express';
import { AuditService } from '../services/AuditService';

export interface AuditRequest extends Request {
  userId?: string;
  auditDetails?: Record<string, unknown>;
}

export async function auditLoggingMiddleware(
  req: AuditRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  // Capture the original send function
  const originalSend = res.send;

  // Override the send function to log after response
  res.send = function (data: any) {
    // Log the request
    if (req.userId && req.method !== 'GET') {
      const ipAddress = req.ip || req.connection.remoteAddress;
      const userAgent = req.get('user-agent');

      AuditService.logAccess(
        req.userId,
        `${req.method} ${req.path}`,
        'API_REQUEST',
        req.path,
        {
          method: req.method,
          statusCode: res.statusCode,
          body: req.body,
          ...req.auditDetails,
        },
        ipAddress,
        userAgent,
      ).catch((error) => console.error('Audit logging error:', error));
    }

    // Call the original send function
    return originalSend.call(this, data);
  };

  next();
}

export function setAuditDetails(details: Record<string, unknown>): (req: AuditRequest, res: Response, next: NextFunction) => void {
  return (req: AuditRequest, res: Response, next: NextFunction) => {
    req.auditDetails = details;
    next();
  };
}
