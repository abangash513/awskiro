import { Router, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { authMiddleware, AuthenticatedRequest } from '../middleware';
import { MedicalRecordModel, PatientModel } from '../models';
import { StorageService, EncryptionService } from '../services';

const router = Router();

// List patient medical records
router.get('/', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const patient = await PatientModel.findByUserId(req.userId!);

    if (!patient) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Patient not found' } });
      return;
    }

    const records = await MedicalRecordModel.findByPatientId(patient.id);
    res.json(records);
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to fetch medical records' } });
  }
});

// Upload medical record
router.post(
  '/',
  authMiddleware,
  body('recordType').isIn(['VISIT_NOTE', 'TEST_RESULT', 'PRESCRIPTION', 'LAB_REPORT', 'IMAGING']),
  body('title').notEmpty(),
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

      const { recordType, title, description, fileContent, fileName } = req.body;

      let fileUrl: string | undefined;
      let fileSize: number | undefined;

      if (fileContent && fileName) {
        const fileKey = StorageService.generateFileKey(patient.id, recordType, fileName);
        const buffer = Buffer.from(fileContent, 'base64');
        fileUrl = await StorageService.uploadFile(fileKey, buffer, 'application/octet-stream', true);
        fileSize = buffer.length;
      }

      const record = await MedicalRecordModel.create(
        patient.id,
        recordType,
        title,
        req.userId!,
        description,
        fileUrl,
        fileSize,
        'application/octet-stream',
      );

      res.status(201).json(record);
    } catch (error) {
      res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to upload medical record' } });
    }
  },
);

// Get specific medical record
router.get('/:id', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const record = await MedicalRecordModel.findById(req.params.id);

    if (!record) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Record not found' } });
      return;
    }

    // Check authorization
    const patient = await PatientModel.findById(record.patientId);
    if (req.userId !== patient?.userId && req.userRole !== 'ADMIN') {
      res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
      return;
    }

    res.json(record);
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to fetch record' } });
  }
});

// Delete medical record
router.delete('/:id', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const record = await MedicalRecordModel.findById(req.params.id);

    if (!record) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Record not found' } });
      return;
    }

    // Check authorization
    const patient = await PatientModel.findById(record.patientId);
    if (req.userId !== patient?.userId && req.userRole !== 'ADMIN') {
      res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
      return;
    }

    if (record.fileUrl) {
      const fileKey = record.fileUrl.split('/').pop();
      if (fileKey) {
        await StorageService.deleteFile(fileKey);
      }
    }

    await MedicalRecordModel.delete(req.params.id);
    res.json({ message: 'Record deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to delete record' } });
  }
});

// Share medical record
router.post('/:id/share', authMiddleware, body('expirationDays').optional().isInt({ min: 1, max: 365 }), async (req: AuthenticatedRequest, res: Response) => {
  try {
    const record = await MedicalRecordModel.findById(req.params.id);

    if (!record) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Record not found' } });
      return;
    }

    // Check authorization
    const patient = await PatientModel.findById(record.patientId);
    if (req.userId !== patient?.userId && req.userRole !== 'ADMIN') {
      res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
      return;
    }

    const expirationDays = req.body.expirationDays || 30;
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + expirationDays);

    const updated = await MedicalRecordModel.update(req.params.id, {
      isShared: true,
      expiresAt,
    });

    // Generate presigned URL
    if (record.fileUrl) {
      const fileKey = record.fileUrl.split('/').pop();
      if (fileKey) {
        const shareLink = await StorageService.generatePresignedUrl(fileKey, expirationDays * 24 * 60 * 60);
        res.json({ record: updated, shareLink });
        return;
      }
    }

    res.json({ record: updated });
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to share record' } });
  }
});

export default router;
