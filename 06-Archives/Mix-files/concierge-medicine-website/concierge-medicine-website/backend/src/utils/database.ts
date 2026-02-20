import fs from 'fs';
import path from 'path';
import { query } from '../database/connection';

export async function initializeDatabase(): Promise<void> {
  try {
    console.log('Initializing database...');

    // Check if tables exist
    const result = await query(
      `SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'users'
      )`,
    );

    if (result.rows[0].exists) {
      console.log('✓ Database already initialized');
      return;
    }

    console.log('Creating database schema...');

    // Read and execute initial schema
    const schemaPath = path.join(__dirname, '../database/migrations/001_initial_schema.sql');
    const schemaSql = fs.readFileSync(schemaPath, 'utf-8');

    // Split by semicolon and execute each statement
    const statements = schemaSql.split(';').filter((stmt) => stmt.trim());
    for (const statement of statements) {
      if (statement.trim()) {
        await query(statement);
      }
    }

    console.log('✓ Schema created');

    // Seed initial data
    console.log('Seeding initial data...');
    const seedPath = path.join(__dirname, '../database/migrations/002_seed_data.sql');
    const seedSql = fs.readFileSync(seedPath, 'utf-8');

    const seedStatements = seedSql.split(';').filter((stmt) => stmt.trim());
    for (const statement of seedStatements) {
      if (statement.trim()) {
        await query(statement);
      }
    }

    console.log('✓ Seed data inserted');
    console.log('✓ Database initialization complete');
  } catch (error) {
    console.error('Database initialization error:', error);
    throw error;
  }
}
