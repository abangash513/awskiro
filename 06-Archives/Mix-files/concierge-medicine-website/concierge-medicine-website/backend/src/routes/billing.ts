import { Router, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { authMiddleware, AuthenticatedRequest } from '../middleware';
import { PatientModel, PaymentModel } from '../models';
import { PaymentService, NotificationService } from '../services';

const router = Router();

// Get invoices
router.get('/invoices', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const patient = await PatientModel.findByUserId(req.userId!);

    if (!patient) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Patient not found' } });
      return;
    }

    // In a real implementation, this would query the invoices table
    res.json({ invoices: [] });
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to fetch invoices' } });
  }
});

// Process payment
router.post(
  '/payments',
  authMiddleware,
  body('amount').isFloat({ min: 0.01 }),
  body('paymentMethod').isIn(['CREDIT_CARD', 'DEBIT_CARD', 'ACH']),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        res.status(400).json({ error: { code: 'VALIDATION_ERROR', details: errors.array() } });
        return;
      }

      const patient = await PatientModel.findByUserId(req.userId!);

      if (!patient) {
        res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Patient not found' } });
        return;
      }

      const { amount, paymentMethod } = req.body;

      // Create payment intent with Stripe
      const paymentIntent = await PaymentService.createPaymentIntent(amount, 'usd');

      // Create payment record
      const payment = await PaymentModel.create(
        patient.id,
        amount,
        'USD',
        paymentMethod,
        paymentIntent.id,
      );

      res.status(201).json({
        payment,
        clientSecret: paymentIntent.client_secret,
      });
    } catch (error) {
      res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to process payment' } });
    }
  },
);

// Get subscription
router.get('/subscription', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const patient = await PatientModel.findByUserId(req.userId!);

    if (!patient) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Patient not found' } });
      return;
    }

    res.json({
      membershipTierId: patient.membershipTierId,
      membershipStatus: patient.membershipStatus,
      membershipStartDate: patient.membershipStartDate,
      membershipEndDate: patient.membershipEndDate,
    });
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to fetch subscription' } });
  }
});

// Update subscription
router.put(
  '/subscription',
  authMiddleware,
  body('membershipTierId').notEmpty(),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        res.status(400).json({ error: { code: 'VALIDATION_ERROR', details: errors.array() } });
        return;
      }

      const patient = await PatientModel.findByUserId(req.userId!);

      if (!patient) {
        res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Patient not found' } });
        return;
      }

      const { membershipTierId } = req.body;

      const updated = await PatientModel.update(patient.id, {
        membershipTierId,
      });

      res.json(updated);
    } catch (error) {
      res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to update subscription' } });
    }
  },
);

export default router;
