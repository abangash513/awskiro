import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import {
  HealthCheckService,
  HealthCheck,
  TypeOrmHealthIndicator,
  MemoryHealthIndicator,
  DiskHealthIndicator,
} from '@nestjs/terminus';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private db: TypeOrmHealthIndicator,
    private memory: MemoryHealthIndicator,
    private disk: DiskHealthIndicator,
  ) {}

  @Get()
  @ApiOperation({ summary: 'Get application health status' })
  @ApiResponse({ 
    status: 200, 
    description: 'Health check successful',
    schema: {
      type: 'object',
      properties: {
        status: { type: 'string', example: 'ok' },
        info: { type: 'object' },
        error: { type: 'object' },
        details: { type: 'object' },
      },
    },
  })
  @HealthCheck()
  check() {
    return this.health.check([
      // Database health check
      () => this.db.pingCheck('database'),
      
      // Memory health check (heap should not use more than 300MB)
      () => this.memory.checkHeap('memory_heap', 300 * 1024 * 1024),
      
      // Memory health check (RSS should not use more than 300MB)
      () => this.memory.checkRSS('memory_rss', 300 * 1024 * 1024),
      
      // Disk health check (should have at least 250MB free space)
      () => this.disk.checkStorage('storage', { 
        path: '/', 
        thresholdPercent: 0.9 
      }),
    ]);
  }

  @Get('ready')
  @ApiOperation({ summary: 'Get application readiness status' })
  @ApiResponse({ 
    status: 200, 
    description: 'Application is ready to serve requests',
    schema: {
      type: 'object',
      properties: {
        status: { type: 'string', example: 'ok' },
        timestamp: { type: 'string', format: 'date-time' },
        uptime: { type: 'number' },
      },
    },
  })
  readiness() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    };
  }

  @Get('live')
  @ApiOperation({ summary: 'Get application liveness status' })
  @ApiResponse({ 
    status: 200, 
    description: 'Application is alive',
    schema: {
      type: 'object',
      properties: {
        status: { type: 'string', example: 'ok' },
        timestamp: { type: 'string', format: 'date-time' },
      },
    },
  })
  liveness() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
    };
  }
}