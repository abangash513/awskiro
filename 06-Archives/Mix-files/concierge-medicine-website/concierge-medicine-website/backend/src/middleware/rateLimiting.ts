import { Request, Response, NextFunction } from 'express';
import redis from 'redis';
import dotenv from 'dotenv';

dotenv.config();

const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
});

redisClient.on('error', (err) => console.error('Redis error:', err));
redisClient.connect();

interface RateLimitConfig {
  windowMs: number; // Time window in milliseconds
  maxRequests: number; // Max requests per window
}

const defaultConfig: RateLimitConfig = {
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 100,
};

export function rateLimitMiddleware(config: RateLimitConfig = defaultConfig) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const key = `rate-limit:${req.ip}`;
      const current = await redisClient.incr(key);

      if (current === 1) {
        await redisClient.expire(key, Math.ceil(config.windowMs / 1000));
      }

      res.setHeader('X-RateLimit-Limit', config.maxRequests);
      res.setHeader('X-RateLimit-Remaining', Math.max(0, config.maxRequests - current));

      if (current > config.maxRequests) {
        res.status(429).json({
          error: {
            code: 'TOO_MANY_REQUESTS',
            message: 'Too many requests, please try again later',
            retryAfter: Math.ceil(config.windowMs / 1000),
          },
        });
        return;
      }

      next();
    } catch (error) {
      console.error('Rate limiting error:', error);
      next();
    }
  };
}

// Stricter rate limit for auth endpoints
export const authRateLimit = rateLimitMiddleware({
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 5, // 5 requests per 15 minutes
});

// Standard rate limit for API endpoints
export const apiRateLimit = rateLimitMiddleware({
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 100, // 100 requests per 15 minutes
});

export async function closeRedisConnection(): Promise<void> {
  await redisClient.quit();
}
