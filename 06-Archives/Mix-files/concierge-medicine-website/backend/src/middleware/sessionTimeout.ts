import { Request, Response, NextFunction } from 'express';
import redis from 'redis';
import dotenv from 'dotenv';

dotenv.config();

const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
});

redisClient.on('error', (err) => console.error('Redis error:', err));
redisClient.connect();

const SESSION_TIMEOUT = 30 * 60 * 1000; // 30 minutes in milliseconds

export interface SessionRequest extends Request {
  sessionId?: string;
}

export async function sessionTimeoutMiddleware(
  req: SessionRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      next();
      return;
    }

    const token = authHeader.substring(7);
    const sessionId = `session:${token}`;

    // Check if session exists in Redis
    const sessionExists = await redisClient.exists(sessionId);

    if (!sessionExists) {
      // Create new session
      await redisClient.setEx(sessionId, SESSION_TIMEOUT / 1000, JSON.stringify({ createdAt: Date.now() }));
    } else {
      // Refresh session timeout
      await redisClient.expire(sessionId, SESSION_TIMEOUT / 1000);
    }

    req.sessionId = sessionId;
    next();
  } catch (error) {
    console.error('Session timeout middleware error:', error);
    next();
  }
}

export async function invalidateSession(token: string): Promise<void> {
  const sessionId = `session:${token}`;
  await redisClient.del(sessionId);
}

export async function closeRedisConnection(): Promise<void> {
  await redisClient.quit();
}
