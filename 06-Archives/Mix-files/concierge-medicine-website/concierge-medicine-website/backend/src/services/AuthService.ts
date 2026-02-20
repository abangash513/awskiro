import jwt from 'jsonwebtoken';
import bcryptjs from 'bcryptjs';
import { UserModel } from '../models';
import { User, AuthRequest, AuthResponse } from '../types';

const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key_here_change_in_production';
const JWT_EXPIRY = process.env.JWT_EXPIRY || '24h';
const REFRESH_TOKEN_EXPIRY = '7d';

export class AuthService {
  static async hashPassword(password: string): Promise<string> {
    const salt = await bcryptjs.genSalt(10);
    return bcryptjs.hash(password, salt);
  }

  static async comparePassword(password: string, hash: string): Promise<boolean> {
    return bcryptjs.compare(password, hash);
  }

  static generateToken(userId: string, role: string): string {
    return jwt.sign({ userId, role }, JWT_SECRET, { expiresIn: JWT_EXPIRY });
  }

  static generateRefreshToken(userId: string): string {
    return jwt.sign({ userId }, JWT_SECRET, { expiresIn: REFRESH_TOKEN_EXPIRY });
  }

  static verifyToken(token: string): { userId: string; role: string } | null {
    try {
      const decoded = jwt.verify(token, JWT_SECRET) as { userId: string; role: string };
      return decoded;
    } catch (error) {
      console.error('Token verification error:', error);
      return null;
    }
  }

  static async register(
    email: string,
    password: string,
    firstName: string,
    lastName: string,
  ): Promise<AuthResponse> {
    // Check if user already exists
    const existingUser = await UserModel.findByEmail(email);
    if (existingUser) {
      throw new Error('User with this email already exists');
    }

    // Hash password
    const passwordHash = await this.hashPassword(password);

    // Create user
    const user = await UserModel.create(email, passwordHash, firstName, lastName, 'PATIENT');

    // Generate tokens
    const token = this.generateToken(user.id, user.role);
    const refreshToken = this.generateRefreshToken(user.id);

    // Update last login
    await UserModel.update(user.id, { lastLogin: new Date() });

    return {
      token,
      refreshToken,
      user: this.sanitizeUser(user),
    };
  }

  static async login(email: string, password: string): Promise<AuthResponse> {
    // Find user
    const user = await UserModel.findByEmail(email);
    if (!user) {
      throw new Error('Invalid email or password');
    }

    // Verify password
    const isPasswordValid = await this.comparePassword(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new Error('Invalid email or password');
    }

    // Generate tokens
    const token = this.generateToken(user.id, user.role);
    const refreshToken = this.generateRefreshToken(user.id);

    // Update last login
    await UserModel.update(user.id, { lastLogin: new Date() });

    return {
      token,
      refreshToken,
      user: this.sanitizeUser(user),
    };
  }

  static async refreshToken(refreshToken: string): Promise<{ token: string; refreshToken: string }> {
    try {
      const decoded = jwt.verify(refreshToken, JWT_SECRET) as { userId: string };
      const user = await UserModel.findById(decoded.userId);

      if (!user) {
        throw new Error('User not found');
      }

      const newToken = this.generateToken(user.id, user.role);
      const newRefreshToken = this.generateRefreshToken(user.id);

      return {
        token: newToken,
        refreshToken: newRefreshToken,
      };
    } catch (error) {
      throw new Error('Invalid refresh token');
    }
  }

  private static sanitizeUser(user: User): Omit<User, 'passwordHash' | 'mfaSecret'> {
    const { passwordHash, mfaSecret, ...sanitized } = user;
    return sanitized;
  }
}
