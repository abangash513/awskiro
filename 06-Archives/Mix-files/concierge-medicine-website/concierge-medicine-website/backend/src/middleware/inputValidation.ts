import { Request, Response, NextFunction } from 'express';

// SQL injection prevention - check for common SQL keywords
const SQL_KEYWORDS = [
  'SELECT',
  'INSERT',
  'UPDATE',
  'DELETE',
  'DROP',
  'CREATE',
  'ALTER',
  'EXEC',
  'EXECUTE',
  'UNION',
  'SCRIPT',
];

// XSS prevention - check for common XSS patterns
const XSS_PATTERNS = [/<script[^>]*>.*?<\/script>/gi, /javascript:/gi, /on\w+\s*=/gi];

export function validateInput(req: Request, res: Response, next: NextFunction): void {
  try {
    // Check request body
    if (req.body && typeof req.body === 'object') {
      validateObject(req.body);
    }

    // Check query parameters
    if (req.query && typeof req.query === 'object') {
      validateObject(req.query);
    }

    // Check URL parameters
    if (req.params && typeof req.params === 'object') {
      validateObject(req.params);
    }

    next();
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Invalid input detected';
    res.status(400).json({
      error: {
        code: 'INVALID_INPUT',
        message,
      },
    });
  }
}

function validateObject(obj: Record<string, any>): void {
  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === 'string') {
      // Check for SQL injection
      const upperValue = value.toUpperCase();
      for (const keyword of SQL_KEYWORDS) {
        if (upperValue.includes(keyword)) {
          throw new Error(`Potential SQL injection detected in field: ${key}`);
        }
      }

      // Check for XSS
      for (const pattern of XSS_PATTERNS) {
        if (pattern.test(value)) {
          throw new Error(`Potential XSS attack detected in field: ${key}`);
        }
      }
    } else if (typeof value === 'object' && value !== null) {
      validateObject(value);
    }
  }
}
