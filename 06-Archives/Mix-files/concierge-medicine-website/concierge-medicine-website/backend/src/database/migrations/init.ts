import fs from 'fs';
import path from 'path';
import { query } from '../connection';

async function runMigrations(): Promise<void> {
  try {
    console.log('Starting database migrations...');

    // Read and execute initial schema
    const schemaPath = path.join(__dirname, '001_initial_schema.sql');
    const schemaSql = fs.readFileSync(schemaPath, 'utf-8');
    console.log('Executing initial schema...');
    await query(schemaSql);
    console.log('✓ Initial schema created');

    // Read and execute seed data
    const seedPath = path.join(__dirname, '002_seed_data.sql');
    const seedSql = fs.readFileSync(seedPath, 'utf-8');
    console.log('Executing seed data...');
    await query(seedSql);
    console.log('✓ Seed data inserted');

    console.log('✓ All migrations completed successfully');
  } catch (error) {
    console.error('Migration error:', error);
    throw error;
  }
}

export default runMigrations;
