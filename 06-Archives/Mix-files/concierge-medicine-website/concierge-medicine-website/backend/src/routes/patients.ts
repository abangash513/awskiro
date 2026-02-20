import { Router, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { authMiddleware, AuthenticatedRequest } from '../middleware';
import { UserModel, PatientModel, MembershipTierModel } from '../models';
import { NotificationService } from '../services';

const router = Router();

// Get patient profile
router.get('/:id', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const patient = await PatientModel.findById(req.params.id);

    if (!patient) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Patient not found' } });
      return;
    }

    // Check authorization
    if (req.userId !== patient.userId && req.userRole !== 'ADMIN') {
      res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
      return;
    }

    const user = await UserModel.findById(patient.userId);
    res.json({ patient, user: user ? { id: user.id, email: user.email, firstName: user.firstName, lastName: user.lastName } : null });
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to fetch patient' } });
  }
});

// Update patient profile
router.put(
  '/:id',
  authMiddleware,
  body('allergies').optional().isArray(),
  body('currentMedications').optional().isArray(),
  body('medicalConditions').optional().isArray(),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        res.status(400).json({ error: { code: 'VALIDATION_ERROR', details: errors.array() } });
        return;
      }

      const patient = await PatientModel.findById(req.params.id);

      if (!patient) {
        res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Patient not found' } });
        return;
      }

      // Check authorization
      if (req.userId !== patient.userId && req.userRole !== 'ADMIN') {
        res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
        return;
      }

      const updated = await PatientModel.update(req.params.id, req.body);
      res.json(updated);
    } catch (error) {
      res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to update patient' } });
    }
  },
);

// Get patient medical history
router.get('/:id/medical-history', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const patient = await PatientModel.findById(req.params.id);

    if (!patient) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Patient not found' } });
      return;
    }

    // Check authorization
    if (req.userId !== patient.userId && req.userRole !== 'ADMIN') {
      res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
      return;
    }

    res.json({
      allergies: patient.allergies,
      currentMedications: patient.currentMedications,
      medicalConditions: patient.medicalConditions,
    });
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to fetch medical history' } });
  }
});

// Add medical history entry
router.post(
  '/:id/medical-history',
  authMiddleware,
  body('type').isIn(['allergies', 'medications', 'conditions']),
  body('value').notEmpty(),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        res.status(400).json({ error: { code: 'VALIDATION_ERROR', details: errors.array() } });
        return;
      }

      const patient = await PatientModel.findById(req.params.id);

      if (!patient) {
        res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Patient not found' } });
        return;
      }

      // Check authorization
      if (req.userId !== patient.userId && req.userRole !== 'ADMIN') {
        res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
        return;
      }

      const { type, value } = req.body;
      const updates: any = {};

      if (type === 'allergies') {
        updates.allergies = [...(patient.allergies || []), value];
      } else if (type === 'medications') {
        updates.currentMedications = [...(patient.currentMedications || []), value];
      } else if (type === 'conditions') {
        updates.medicalConditions = [...(patient.medicalConditions || []), value];
      }

      const updated = await PatientModel.update(req.params.id, updates);
      res.json(updated);
    } catch (error) {
      res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to add medical history' } });
    }
  },
);

// Get membership tiers
router.get('/tiers/list', async (_req: AuthenticatedRequest, res: Response) => {
  try {
    const tiers = await MembershipTierModel.findAll();
    res.json(tiers);
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to fetch membership tiers' } });
  }
});

export default router;
