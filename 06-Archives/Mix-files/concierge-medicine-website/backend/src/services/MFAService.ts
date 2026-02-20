import speakeasy from 'speakeasy';
import QRCode from 'qrcode';
import { UserModel } from '../models';

export class MFAService {
  static async generateSecret(email: string): Promise<{ secret: string; qrCode: string }> {
    const secret = speakeasy.generateSecret({
      name: `Concierge Medicine (${email})`,
      issuer: 'Concierge Medicine',
      length: 32,
    });

    const qrCode = await QRCode.toDataURL(secret.otpauth_url || '');

    return {
      secret: secret.base32,
      qrCode,
    };
  }

  static verifyToken(secret: string, token: string): boolean {
    return speakeasy.totp.verify({
      secret,
      encoding: 'base32',
      token,
      window: 2,
    });
  }

  static async enableMFA(userId: string, secret: string): Promise<void> {
    await UserModel.update(userId, {
      mfaEnabled: true,
      mfaSecret: secret,
    });
  }

  static async disableMFA(userId: string): Promise<void> {
    await UserModel.update(userId, {
      mfaEnabled: false,
      mfaSecret: undefined,
    });
  }
}
