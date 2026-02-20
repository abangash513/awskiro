import { Router } from 'express';
import authRoutes from './auth';
import patientRoutes from './patients';
import appointmentRoutes from './appointments';
import medicalRecordsRoutes from './medical-records';
import messagesRoutes from './messages';
import billingRoutes from './billing';

const router = Router();

router.use('/auth', authRoutes);
router.use('/patients', patientRoutes);
router.use('/appointments', appointmentRoutes);
router.use('/medical-records', medicalRecordsRoutes);
router.use('/messages', messagesRoutes);
router.use('/billing', billingRoutes);

export default router;
