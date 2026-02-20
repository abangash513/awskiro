import crypto from 'crypto';
import dotenv from 'dotenv';

dotenv.config();

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || crypto.randomBytes(32).toString('hex');
const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 16;
const AUTH_TAG_LENGTH = 16;

export class EncryptionService {
  static encrypt(plaintext: string): string {
    try {
      const key = Buffer.from(ENCRYPTION_KEY, 'hex');
      const iv = crypto.randomBytes(IV_LENGTH);

      const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
      let encrypted = cipher.update(plaintext, 'utf8', 'hex');
      encrypted += cipher.final('hex');

      const authTag = cipher.getAuthTag();

      // Combine IV + authTag + encrypted data
      const combined = iv.toString('hex') + authTag.toString('hex') + encrypted;
      return combined;
    } catch (error) {
      console.error('Encryption error:', error);
      throw new Error('Encryption failed');
    }
  }

  static decrypt(ciphertext: string): string {
    try {
      const key = Buffer.from(ENCRYPTION_KEY, 'hex');

      // Extract IV, authTag, and encrypted data
      const iv = Buffer.from(ciphertext.substring(0, IV_LENGTH * 2), 'hex');
      const authTag = Buffer.from(ciphertext.substring(IV_LENGTH * 2, IV_LENGTH * 2 + AUTH_TAG_LENGTH * 2), 'hex');
      const encrypted = ciphertext.substring(IV_LENGTH * 2 + AUTH_TAG_LENGTH * 2);

      const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
      decipher.setAuthTag(authTag);

      let decrypted = decipher.update(encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');

      return decrypted;
    } catch (error) {
      console.error('Decryption error:', error);
      throw new Error('Decryption failed');
    }
  }

  static hashData(data: string): string {
    return crypto.createHash('sha256').update(data).digest('hex');
  }

  static generateRandomToken(length: number = 32): string {
    return crypto.randomBytes(length).toString('hex');
  }
}
