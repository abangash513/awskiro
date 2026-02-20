import { query } from '../database/connection';
import { MembershipTier } from '../types';

export class MembershipTierModel {
  static async findAll(): Promise<MembershipTier[]> {
    const result = await query(
      `SELECT id, name, monthly_price, annual_price, appointments_per_year, telemedicine_included, response_time_hours, includes_preventive_care, includes_chronic_disease_management, description, created_at, updated_at
       FROM membership_tiers ORDER BY monthly_price ASC`,
    );

    return result.rows.map((row) => this.mapRow(row));
  }

  static async findById(id: string): Promise<MembershipTier | null> {
    const result = await query(
      `SELECT id, name, monthly_price, annual_price, appointments_per_year, telemedicine_included, response_time_hours, includes_preventive_care, includes_chronic_disease_management, description, created_at, updated_at
       FROM membership_tiers WHERE id = $1`,
      [id],
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  static async findByName(name: string): Promise<MembershipTier | null> {
    const result = await query(
      `SELECT id, name, monthly_price, annual_price, appointments_per_year, telemedicine_included, response_time_hours, includes_preventive_care, includes_chronic_disease_management, description, created_at, updated_at
       FROM membership_tiers WHERE name = $1`,
      [name],
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  private static mapRow(row: Record<string, unknown>): MembershipTier {
    return {
      id: row.id as string,
      name: row.name as string,
      monthlyPrice: parseFloat(row.monthly_price as string),
      annualPrice: parseFloat(row.annual_price as string),
      appointmentsPerYear: row.appointments_per_year as number,
      telemedicineIncluded: row.telemedicine_included as boolean,
      responseTimeHours: row.response_time_hours as number,
      includesPreventiveCare: row.includes_preventive_care as boolean,
      includesChronicDiseaseManagement: row.includes_chronic_disease_management as boolean,
      description: row.description as string | undefined,
      createdAt: new Date(row.created_at as string),
      updatedAt: new Date(row.updated_at as string),
    };
  }
}
