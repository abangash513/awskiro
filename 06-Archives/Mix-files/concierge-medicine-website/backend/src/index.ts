import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { createServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';
import { initializeDatabase } from './utils';
import {
  authMiddleware,
  sessionTimeoutMiddleware,
  auditLoggingMiddleware,
  securityHeadersMiddleware,
  apiRateLimit,
  validateInput,
} from './middleware';
import apiRoutes from './routes';

dotenv.config();

const app: Express = express();
const httpServer = createServer(app);
const io = new SocketIOServer(httpServer, {
  cors: {
    origin: process.env.FRONTEND_URL || 'http://localhost:3000',
    methods: ['GET', 'POST'],
  },
});

const PORT = process.env.PORT || 3001;
const NODE_ENV = process.env.NODE_ENV || 'development';

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Security middleware
app.use(securityHeadersMiddleware);
app.use(validateInput);
app.use(apiRateLimit);

// Request logging middleware
app.use((req: Request, _res: Response, next: NextFunction) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Session timeout middleware
app.use(sessionTimeoutMiddleware);

// Audit logging middleware
app.use(auditLoggingMiddleware);

// Health check endpoint
app.get('/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    environment: NODE_ENV,
  });
});

// API routes placeholder
app.get('/api', (_req: Request, res: Response) => {
  res.json({
    message: 'Concierge Medicine API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      auth: '/api/auth',
      patients: '/api/patients',
      appointments: '/api/appointments',
      messages: '/api/messages',
      billing: '/api/billing',
    },
  });
});

// API routes
app.use('/api', apiRoutes);

// 404 handler
app.use((_req: Request, res: Response) => {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: 'Endpoint not found',
    },
  });
});

// Error handling middleware
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  console.error('Error:', err);
  res.status(500).json({
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: NODE_ENV === 'production' ? 'Internal server error' : err.message,
    },
  });
});

// WebSocket connection handler
io.on('connection', (socket) => {
  console.log(`User connected: ${socket.id}`);

  socket.on('disconnect', () => {
    console.log(`User disconnected: ${socket.id}`);
  });
});

// Initialize database and start server
async function startServer(): Promise<void> {
  try {
    await initializeDatabase();

    httpServer.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════════════════════════╗
║   Concierge Medicine Website - Backend Server              ║
║   Environment: ${NODE_ENV.padEnd(45)}║
║   Port: ${String(PORT).padEnd(51)}║
║   Status: Running ✓                                        ║
╚════════════════════════════════════════════════════════════╝
    `);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

export { app, io };
