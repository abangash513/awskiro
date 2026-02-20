import { Router, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { authMiddleware, AuthenticatedRequest } from '../middleware';
import { MessageModel } from '../models';
import { EncryptionService, NotificationService } from '../services';

const router = Router();

// Send message
router.post(
  '/',
  authMiddleware,
  body('recipientId').notEmpty(),
  body('body').notEmpty(),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        res.status(400).json({ error: { code: 'VALIDATION_ERROR', details: errors.array() } });
        return;
      }

      const { recipientId, subject, body, attachments } = req.body;

      // Encrypt message body
      const encryptedBody = EncryptionService.encrypt(body);

      const message = await MessageModel.create(req.userId!, recipientId, encryptedBody, subject, attachments);

      res.status(201).json(message);
    } catch (error) {
      res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to send message' } });
    }
  },
);

// Get message history
router.get('/', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const messages = await MessageModel.findByRecipient(req.userId!);

    // Decrypt messages
    const decryptedMessages = messages.map((msg) => ({
      ...msg,
      body: EncryptionService.decrypt(msg.body),
    }));

    res.json(decryptedMessages);
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to fetch messages' } });
  }
});

// Get conversation with specific user
router.get('/conversation/:userId', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const messages = await MessageModel.findConversation(req.userId!, req.params.userId);

    // Decrypt messages
    const decryptedMessages = messages.map((msg) => ({
      ...msg,
      body: EncryptionService.decrypt(msg.body),
    }));

    res.json(decryptedMessages);
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to fetch conversation' } });
  }
});

// Mark message as read
router.put('/:id/read', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const message = await MessageModel.findById(req.params.id);

    if (!message) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Message not found' } });
      return;
    }

    // Check authorization
    if (req.userId !== message.recipientId) {
      res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
      return;
    }

    const updated = await MessageModel.markAsRead(req.params.id);
    res.json(updated);
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to mark message as read' } });
  }
});

// Delete message
router.delete('/:id', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const message = await MessageModel.findById(req.params.id);

    if (!message) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Message not found' } });
      return;
    }

    // Check authorization
    if (req.userId !== message.senderId && req.userId !== message.recipientId) {
      res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
      return;
    }

    await MessageModel.delete(req.params.id);
    res.json({ message: 'Message deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Failed to delete message' } });
  }
});

export default router;
