import { Pool, PoolClient, QueryResult } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  user: process.env.DB_USER || 'concierge_user',
  password: process.env.DB_PASSWORD || 'concierge_password',
  database: process.env.DB_NAME || 'concierge_medicine',
});

pool.on('error', (err: Error) => {
  console.error('Unexpected error on idle client', err);
});

export async function getConnection(): Promise<PoolClient> {
  return pool.connect();
}

export async function query(
  text: string,
  params?: unknown[],
): Promise<QueryResult<Record<string, unknown>>> {
  const start = Date.now();
  try {
    const result = await pool.query<Record<string, unknown>>(text, params);
    const duration = Date.now() - start;
    console.log('Executed query', { text, duration, rows: result.rowCount });
    return result;
  } catch (error) {
    console.error('Database query error', { text, error });
    throw error;
  }
}

export async function closePool(): Promise<void> {
  await pool.end();
}

export default pool;
