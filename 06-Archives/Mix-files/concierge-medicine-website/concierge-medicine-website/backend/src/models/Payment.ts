import { query } from '../database/connection';
import { Payment, PaymentStatus, PaymentMethod } from '../types';

export class PaymentModel {
  static async create(
    patientId: string,
    amount: number,
    currency: string,
    paymentMethod: PaymentMethod,
    stripePaymentIntentId?: string,
  ): Promise<Payment> {
    const result = await query(
      `INSERT INTO payments (patient_id, amount, currency, payment_method, stripe_payment_intent_id, status)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, patient_id, amount, currency, payment_method, stripe_payment_intent_id, status, invoice_id, processed_at, created_at, updated_at`,
      [patientId, amount, currency, paymentMethod, stripePaymentIntentId, 'PENDING'],
    );

    return this.mapRow(result.rows[0]);
  }

  static async findById(id: string): Promise<Payment | null> {
    const result = await query(
      `SELECT id, patient_id, amount, currency, payment_method, stripe_payment_intent_id, status, invoice_id, processed_at, created_at, updated_at
       FROM payments WHERE id = $1`,
      [id],
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  static async findByPatientId(patientId: string): Promise<Payment[]> {
    const result = await query(
      `SELECT id, patient_id, amount, currency, payment_method, stripe_payment_intent_id, status, invoice_id, processed_at, created_at, updated_at
       FROM payments WHERE patient_id = $1 ORDER BY created_at DESC`,
      [patientId],
    );

    return result.rows.map((row) => this.mapRow(row));
  }

  static async update(id: string, updates: Partial<Payment>): Promise<Payment | null> {
    const fields: string[] = [];
    const values: unknown[] = [];
    let paramCount = 1;

    if (updates.status !== undefined) {
      fields.push(`status = $${paramCount++}`);
      values.push(updates.status);
    }
    if (updates.processedAt !== undefined) {
      fields.push(`processed_at = $${paramCount++}`);
      values.push(updates.processedAt);
    }
    if (updates.invoiceId !== undefined) {
      fields.push(`invoice_id = $${paramCount++}`);
      values.push(updates.invoiceId);
    }

    if (fields.length === 0) {
      return this.findById(id);
    }

    values.push(id);
    const result = await query(
      `UPDATE payments SET ${fields.join(', ')} WHERE id = $${paramCount}
       RETURNING id, patient_id, amount, currency, payment_method, stripe_payment_intent_id, status, invoice_id, processed_at, created_at, updated_at`,
      values,
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  private static mapRow(row: Record<string, unknown>): Payment {
    return {
      id: row.id as string,
      patientId: row.patient_id as string,
      amount: parseFloat(row.amount as string),
      currency: row.currency as string,
      paymentMethod: row.payment_method as string,
      stripePaymentIntentId: row.stripe_payment_intent_id as string | undefined,
      status: row.status as string,
      invoiceId: row.invoice_id as string | undefined,
      processedAt: row.processed_at ? new Date(row.processed_at as string) : undefined,
      createdAt: new Date(row.created_at as string),
      updatedAt: new Date(row.updated_at as string),
    };
  }
}
