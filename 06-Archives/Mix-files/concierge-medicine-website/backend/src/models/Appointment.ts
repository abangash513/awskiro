import { query } from '../database/connection';
import { Appointment, AppointmentStatus, AppointmentType } from '../types';

export class AppointmentModel {
  static async create(
    patientId: string,
    physicianId: string,
    appointmentType: AppointmentType,
    scheduledStartTime: Date,
    scheduledEndTime: Date,
    reasonForVisit?: string,
  ): Promise<Appointment> {
    const result = await query(
      `INSERT INTO appointments (patient_id, physician_id, appointment_type, reason_for_visit, scheduled_start_time, scheduled_end_time, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, patient_id, physician_id, appointment_type, reason_for_visit, scheduled_start_time, scheduled_end_time, status, notes, reminders_sent, created_at, updated_at`,
      [patientId, physicianId, appointmentType, reasonForVisit, scheduledStartTime, scheduledEndTime, 'SCHEDULED'],
    );

    return this.mapRow(result.rows[0]);
  }

  static async findById(id: string): Promise<Appointment | null> {
    const result = await query(
      `SELECT id, patient_id, physician_id, appointment_type, reason_for_visit, scheduled_start_time, scheduled_end_time, status, notes, reminders_sent, created_at, updated_at
       FROM appointments WHERE id = $1`,
      [id],
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  static async findByPatientId(patientId: string): Promise<Appointment[]> {
    const result = await query(
      `SELECT id, patient_id, physician_id, appointment_type, reason_for_visit, scheduled_start_time, scheduled_end_time, status, notes, reminders_sent, created_at, updated_at
       FROM appointments WHERE patient_id = $1 ORDER BY scheduled_start_time DESC`,
      [patientId],
    );

    return result.rows.map((row) => this.mapRow(row));
  }

  static async findByPhysicianId(physicianId: string): Promise<Appointment[]> {
    const result = await query(
      `SELECT id, patient_id, physician_id, appointment_type, reason_for_visit, scheduled_start_time, scheduled_end_time, status, notes, reminders_sent, created_at, updated_at
       FROM appointments WHERE physician_id = $1 ORDER BY scheduled_start_time DESC`,
      [physicianId],
    );

    return result.rows.map((row) => this.mapRow(row));
  }

  static async findAvailableSlots(physicianId: string, startDate: Date, endDate: Date): Promise<Appointment[]> {
    const result = await query(
      `SELECT id, patient_id, physician_id, appointment_type, reason_for_visit, scheduled_start_time, scheduled_end_time, status, notes, reminders_sent, created_at, updated_at
       FROM appointments WHERE physician_id = $1 AND scheduled_start_time >= $2 AND scheduled_end_time <= $3 AND status = 'SCHEDULED'
       ORDER BY scheduled_start_time ASC`,
      [physicianId, startDate, endDate],
    );

    return result.rows.map((row) => this.mapRow(row));
  }

  static async update(id: string, updates: Partial<Appointment>): Promise<Appointment | null> {
    const fields: string[] = [];
    const values: unknown[] = [];
    let paramCount = 1;

    if (updates.status !== undefined) {
      fields.push(`status = $${paramCount++}`);
      values.push(updates.status);
    }
    if (updates.notes !== undefined) {
      fields.push(`notes = $${paramCount++}`);
      values.push(updates.notes);
    }
    if (updates.remindersSent !== undefined) {
      fields.push(`reminders_sent = $${paramCount++}`);
      values.push(updates.remindersSent);
    }

    if (fields.length === 0) {
      return this.findById(id);
    }

    values.push(id);
    const result = await query(
      `UPDATE appointments SET ${fields.join(', ')} WHERE id = $${paramCount}
       RETURNING id, patient_id, physician_id, appointment_type, reason_for_visit, scheduled_start_time, scheduled_end_time, status, notes, reminders_sent, created_at, updated_at`,
      values,
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  static async delete(id: string): Promise<boolean> {
    const result = await query(`DELETE FROM appointments WHERE id = $1`, [id]);
    return result.rowCount > 0;
  }

  static async findByStatus(status: AppointmentStatus): Promise<Appointment[]> {
    const result = await query(
      `SELECT id, patient_id, physician_id, appointment_type, reason_for_visit, scheduled_start_time, scheduled_end_time, status, notes, reminders_sent, created_at, updated_at
       FROM appointments WHERE status = $1 ORDER BY scheduled_start_time DESC`,
      [status],
    );

    return result.rows.map((row) => this.mapRow(row));
  }

  private static mapRow(row: Record<string, unknown>): Appointment {
    return {
      id: row.id as string,
      patientId: row.patient_id as string,
      physicianId: row.physician_id as string,
      appointmentType: row.appointment_type as string,
      reasonForVisit: row.reason_for_visit as string | undefined,
      scheduledStartTime: new Date(row.scheduled_start_time as string),
      scheduledEndTime: new Date(row.scheduled_end_time as string),
      status: row.status as string,
      notes: row.notes as string | undefined,
      remindersSent: (row.reminders_sent as boolean[]) || [false, false, false],
      createdAt: new Date(row.created_at as string),
      updatedAt: new Date(row.updated_at as string),
    };
  }
}
