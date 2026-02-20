import { RtcTokenBuilder, RtcRole } from 'agora-access-token';
import dotenv from 'dotenv';

dotenv.config();

const APP_ID = process.env.AGORA_APP_ID || '';
const APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || '';

export class VideoService {
  static generateToken(
    channelName: string,
    uid: number,
    role: 'publisher' | 'subscriber' = 'publisher',
    expirationTimeInSeconds: number = 3600,
  ): string {
    try {
      const rtcRole = role === 'publisher' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

      const token = RtcTokenBuilder.buildTokenWithUid(
        APP_ID,
        APP_CERTIFICATE,
        channelName,
        uid,
        rtcRole,
        expirationTimeInSeconds,
      );

      return token;
    } catch (error) {
      console.error('Token generation error:', error);
      throw new Error('Failed to generate video token');
    }
  }

  static generateChannelName(appointmentId: string): string {
    return `appointment_${appointmentId}`;
  }

  static generateUid(userId: string): number {
    // Convert UUID to a numeric UID for Agora
    const hash = userId
      .split('')
      .reduce((acc, char) => {
        return (acc << 5) - acc + char.charCodeAt(0);
      }, 0);

    return Math.abs(hash) % 2147483647; // Ensure it's within valid range
  }

  static async createSession(appointmentId: string, physicianId: string, patientId: string): Promise<{
    channelName: string;
    physicianToken: string;
    patientToken: string;
    appId: string;
  }> {
    try {
      const channelName = this.generateChannelName(appointmentId);
      const physicianUid = this.generateUid(physicianId);
      const patientUid = this.generateUid(patientId);

      const physicianToken = this.generateToken(channelName, physicianUid, 'publisher');
      const patientToken = this.generateToken(channelName, patientUid, 'publisher');

      return {
        channelName,
        physicianToken,
        patientToken,
        appId: APP_ID,
      };
    } catch (error) {
      console.error('Session creation error:', error);
      throw new Error('Failed to create video session');
    }
  }

  static validateChannelName(channelName: string): boolean {
    // Channel name should match pattern: appointment_<uuid>
    const pattern = /^appointment_[a-f0-9-]{36}$/;
    return pattern.test(channelName);
  }
}
