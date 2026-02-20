import { query } from '../database/connection';
import { Message } from '../types';

export class MessageModel {
  static async create(
    senderId: string,
    recipientId: string,
    body: string,
    subject?: string,
    attachments?: string[],
  ): Promise<Message> {
    const result = await query(
      `INSERT INTO messages (sender_id, recipient_id, subject, body, attachments)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, sender_id, recipient_id, subject, body, attachments, is_read, read_at, created_at, updated_at`,
      [senderId, recipientId, subject, body, attachments || []],
    );

    return this.mapRow(result.rows[0]);
  }

  static async findById(id: string): Promise<Message | null> {
    const result = await query(
      `SELECT id, sender_id, recipient_id, subject, body, attachments, is_read, read_at, created_at, updated_at
       FROM messages WHERE id = $1`,
      [id],
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  static async findConversation(userId1: string, userId2: string): Promise<Message[]> {
    const result = await query(
      `SELECT id, sender_id, recipient_id, subject, body, attachments, is_read, read_at, created_at, updated_at
       FROM messages 
       WHERE (sender_id = $1 AND recipient_id = $2) OR (sender_id = $2 AND recipient_id = $1)
       ORDER BY created_at ASC`,
      [userId1, userId2],
    );

    return result.rows.map((row) => this.mapRow(row));
  }

  static async findByRecipient(recipientId: string): Promise<Message[]> {
    const result = await query(
      `SELECT id, sender_id, recipient_id, subject, body, attachments, is_read, read_at, created_at, updated_at
       FROM messages WHERE recipient_id = $1 ORDER BY created_at DESC`,
      [recipientId],
    );

    return result.rows.map((row) => this.mapRow(row));
  }

  static async markAsRead(id: string): Promise<Message | null> {
    const result = await query(
      `UPDATE messages SET is_read = true, read_at = CURRENT_TIMESTAMP WHERE id = $1
       RETURNING id, sender_id, recipient_id, subject, body, attachments, is_read, read_at, created_at, updated_at`,
      [id],
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  static async delete(id: string): Promise<boolean> {
    const result = await query(`DELETE FROM messages WHERE id = $1`, [id]);
    return result.rowCount > 0;
  }

  private static mapRow(row: Record<string, unknown>): Message {
    return {
      id: row.id as string,
      senderId: row.sender_id as string,
      recipientId: row.recipient_id as string,
      subject: row.subject as string | undefined,
      body: row.body as string,
      attachments: (row.attachments as string[]) || [],
      isRead: row.is_read as boolean,
      readAt: row.read_at ? new Date(row.read_at as string) : undefined,
      createdAt: new Date(row.created_at as string),
      updatedAt: new Date(row.updated_at as string),
    };
  }
}
