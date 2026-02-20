import { query } from '../database/connection';
import { MedicalRecord, MedicalRecordType } from '../types';

export class MedicalRecordModel {
  static async create(
    patientId: string,
    recordType: MedicalRecordType,
    title: string,
    uploadedBy: string,
    description?: string,
    fileUrl?: string,
    fileSize?: number,
    mimeType?: string,
  ): Promise<MedicalRecord> {
    const result = await query(
      `INSERT INTO medical_records (patient_id, record_type, title, description, file_url, file_size, mime_type, uploaded_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, patient_id, record_type, title, description, file_url, file_size, mime_type, uploaded_by, uploaded_at, expires_at, is_shared, created_at, updated_at`,
      [patientId, recordType, title, description, fileUrl, fileSize, mimeType, uploadedBy],
    );

    return this.mapRow(result.rows[0]);
  }

  static async findById(id: string): Promise<MedicalRecord | null> {
    const result = await query(
      `SELECT id, patient_id, record_type, title, description, file_url, file_size, mime_type, uploaded_by, uploaded_at, expires_at, is_shared, created_at, updated_at
       FROM medical_records WHERE id = $1`,
      [id],
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  static async findByPatientId(patientId: string): Promise<MedicalRecord[]> {
    const result = await query(
      `SELECT id, patient_id, record_type, title, description, file_url, file_size, mime_type, uploaded_by, uploaded_at, expires_at, is_shared, created_at, updated_at
       FROM medical_records WHERE patient_id = $1 ORDER BY uploaded_at DESC`,
      [patientId],
    );

    return result.rows.map((row) => this.mapRow(row));
  }

  static async delete(id: string): Promise<boolean> {
    const result = await query(`DELETE FROM medical_records WHERE id = $1`, [id]);
    return result.rowCount > 0;
  }

  static async update(id: string, updates: Partial<MedicalRecord>): Promise<MedicalRecord | null> {
    const fields: string[] = [];
    const values: unknown[] = [];
    let paramCount = 1;

    if (updates.isShared !== undefined) {
      fields.push(`is_shared = $${paramCount++}`);
      values.push(updates.isShared);
    }
    if (updates.expiresAt !== undefined) {
      fields.push(`expires_at = $${paramCount++}`);
      values.push(updates.expiresAt);
    }

    if (fields.length === 0) {
      return this.findById(id);
    }

    values.push(id);
    const result = await query(
      `UPDATE medical_records SET ${fields.join(', ')} WHERE id = $${paramCount}
       RETURNING id, patient_id, record_type, title, description, file_url, file_size, mime_type, uploaded_by, uploaded_at, expires_at, is_shared, created_at, updated_at`,
      values,
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  private static mapRow(row: Record<string, unknown>): MedicalRecord {
    return {
      id: row.id as string,
      patientId: row.patient_id as string,
      recordType: row.record_type as string,
      title: row.title as string,
      description: row.description as string | undefined,
      fileUrl: row.file_url as string | undefined,
      fileSize: row.file_size as number | undefined,
      mimeType: row.mime_type as string | undefined,
      uploadedBy: row.uploaded_by as string,
      uploadedAt: new Date(row.uploaded_at as string),
      expiresAt: row.expires_at ? new Date(row.expires_at as string) : undefined,
      isShared: row.is_shared as boolean,
      createdAt: new Date(row.created_at as string),
      updatedAt: new Date(row.updated_at as string),
    };
  }
}
