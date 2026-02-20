import { Router, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { authMiddleware, AuthenticatedRequest, requireRole } from '../middleware';
import { AppointmentModel, PatientModel } from '../models';
import { NotificationService } from '../services';

const router = Router();

// Get available appointment slots
router.get('/available-slots', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { physicianId, startDate, endDate } = req.query;

    if (!physicianId || !startDate || !endDate) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Missing required parameters' } });
      return;
    }

    const slots = await AppointmentModel.findAvailableSlots(
      physicianId as string,
      new Date(startDate as string),
      new Date(endDate as string),
    );

    res.json(slots);
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to fetch available slots' } });
  }
});

// Book appointment
router.post(
  '/',
  authMiddleware,
  body('physicianId').notEmpty(),
  body('appointmentType').isIn(['IN_PERSON', 'TELEMEDICINE', 'PHONE']),
  body('scheduledStartTime').isISO8601(),
  body('scheduledEndTime').isISO8601(),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        res.status(400).json({ error: { code: 'VALIDATION_ERROR', details: errors.array() } });
        return;
      }

      const patient = await PatientModel.findByUserId(req.userId!);
      if (!patient) {
        res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Patient profile not found' } });
        return;
      }

      const { physicianId, appointmentType, scheduledStartTime, scheduledEndTime, reasonForVisit } = req.body;

      const appointment = await AppointmentModel.create(
        patient.id,
        physicianId,
        appointmentType,
        new Date(scheduledStartTime),
        new Date(scheduledEndTime),
        reasonForVisit,
      );

      // Send confirmation email
      const user = await PatientModel.findById(patient.id);
      if (user) {
        await NotificationService.sendAppointmentConfirmation(
          user.userId,
          new Date(scheduledStartTime),
          appointmentType,
          'Dr. [Physician Name]',
        );
      }

      res.status(201).json(appointment);
    } catch (error) {
      res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to book appointment' } });
    }
  },
);

// Get appointment details
router.get('/:id', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const appointment = await AppointmentModel.findById(req.params.id);

    if (!appointment) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Appointment not found' } });
      return;
    }

    // Check authorization
    const patient = await PatientModel.findById(appointment.patientId);
    if (req.userId !== patient?.userId && req.userRole !== 'ADMIN') {
      res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
      return;
    }

    res.json(appointment);
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to fetch appointment' } });
  }
});

// Cancel appointment
router.delete('/:id', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const appointment = await AppointmentModel.findById(req.params.id);

    if (!appointment) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Appointment not found' } });
      return;
    }

    // Check authorization
    const patient = await PatientModel.findById(appointment.patientId);
    if (req.userId !== patient?.userId && req.userRole !== 'ADMIN') {
      res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
      return;
    }

    // Check if cancellation is within 24 hours
    const hoursUntilAppointment = (appointment.scheduledStartTime.getTime() - Date.now()) / (1000 * 60 * 60);
    if (hoursUntilAppointment < 24) {
      res.status(400).json({
        error: { code: 'CANCELLATION_ERROR', message: 'Cannot cancel within 24 hours of appointment' },
      });
      return;
    }

    await AppointmentModel.delete(req.params.id);
    res.json({ message: 'Appointment cancelled successfully' });
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to cancel appointment' } });
  }
});

// List patient appointments
router.get('/patient/:patientId', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const patient = await PatientModel.findById(req.params.patientId);

    if (!patient) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Patient not found' } });
      return;
    }

    // Check authorization
    if (req.userId !== patient.userId && req.userRole !== 'ADMIN') {
      res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
      return;
    }

    const appointments = await AppointmentModel.findByPatientId(req.params.patientId);
    res.json(appointments);
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to fetch appointments' } });
  }
});

export default router;
