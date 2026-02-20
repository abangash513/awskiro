import { Router, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { AuthService, MFAService } from '../services';
import { authMiddleware, AuthenticatedRequest, invalidateSession, authRateLimit } from '../middleware';
import { UserModel } from '../models';

const router = Router();

// Validation middleware
const validateEmail = body('email').isEmail().normalizeEmail();
const validatePassword = body('password')
  .isLength({ min: 12 })
  .withMessage('Password must be at least 12 characters')
  .matches(/[A-Z]/)
  .withMessage('Password must contain uppercase letter')
  .matches(/[a-z]/)
  .withMessage('Password must contain lowercase letter')
  .matches(/[0-9]/)
  .withMessage('Password must contain number')
  .matches(/[!@#$%^&*]/)
  .withMessage('Password must contain special character');

const validateName = [body('firstName').trim().notEmpty(), body('lastName').trim().notEmpty()];

// Register endpoint
router.post(
  '/register',
  authRateLimit,
  validateEmail,
  validatePassword,
  ...validateName,
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        res.status(400).json({ error: { code: 'VALIDATION_ERROR', details: errors.array() } });
        return;
      }

      const { email, password, firstName, lastName } = req.body;
      const authResponse = await AuthService.register(email, password, firstName, lastName);

      res.status(201).json(authResponse);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Registration failed';
      res.status(400).json({
        error: {
          code: 'REGISTRATION_ERROR',
          message,
        },
      });
    }
  },
);

// Login endpoint
router.post(
  '/login',
  authRateLimit,
  validateEmail,
  body('password').notEmpty(),
  async (req: AuthenticatedRequest, res: Response) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', details: errors.array() } });
      return;
    }

    const { email, password } = req.body;
    const authResponse = await AuthService.login(email, password);

    res.json(authResponse);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Login failed';
    res.status(401).json({
      error: {
        code: 'LOGIN_ERROR',
        message,
      },
    });
  }
  },
);

// Logout endpoint
router.post('/logout', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      await invalidateSession(token);
    }

    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    res.status(500).json({
      error: {
        code: 'LOGOUT_ERROR',
        message: 'Logout failed',
      },
    });
  }
});

// Refresh token endpoint
router.post('/refresh-token', body('refreshToken').notEmpty(), async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { refreshToken } = req.body;
    const tokens = await AuthService.refreshToken(refreshToken);

    res.json(tokens);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Token refresh failed';
    res.status(401).json({
      error: {
        code: 'REFRESH_ERROR',
        message,
      },
    });
  }
});

// MFA setup endpoint
router.post('/mfa-setup', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    if (!req.userId) {
      res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'User not authenticated' } });
      return;
    }

    const user = await UserModel.findById(req.userId);
    if (!user) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'User not found' } });
      return;
    }

    const { secret, qrCode } = await MFAService.generateSecret(user.email);

    res.json({
      secret,
      qrCode,
      message: 'Scan the QR code with your authenticator app',
    });
  } catch (error) {
    res.status(500).json({
      error: {
        code: 'MFA_SETUP_ERROR',
        message: 'MFA setup failed',
      },
    });
  }
});

// MFA verify endpoint
router.post(
  '/verify-mfa',
  authMiddleware,
  body('secret').notEmpty(),
  body('token').isLength({ min: 6, max: 6 }).isNumeric(),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        res.status(400).json({ error: { code: 'VALIDATION_ERROR', details: errors.array() } });
        return;
      }

      if (!req.userId) {
        res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'User not authenticated' } });
        return;
      }

      const { secret, token } = req.body;

      const isValid = MFAService.verifyToken(secret, token);
      if (!isValid) {
        res.status(400).json({
          error: {
            code: 'INVALID_MFA_TOKEN',
            message: 'Invalid MFA token',
          },
        });
        return;
      }

      await MFAService.enableMFA(req.userId, secret);

      res.json({
        message: 'MFA enabled successfully',
      });
    } catch (error) {
      res.status(500).json({
        error: {
          code: 'MFA_VERIFY_ERROR',
          message: 'MFA verification failed',
        },
      });
    }
  },
);

export default router;
