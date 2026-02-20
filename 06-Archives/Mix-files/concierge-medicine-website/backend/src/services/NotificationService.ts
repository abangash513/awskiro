import sgMail from '@sendgrid/mail';
import twilio from 'twilio';
import dotenv from 'dotenv';

dotenv.config();

// SendGrid setup
sgMail.setApiKey(process.env.SENDGRID_API_KEY || '');

// Twilio setup
const twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

export class NotificationService {
  // Email notifications
  static async sendEmail(
    to: string,
    subject: string,
    htmlContent: string,
    from: string = process.env.ADMIN_EMAIL || 'noreply@concierge-medicine.com',
  ): Promise<void> {
    try {
      await sgMail.send({
        to,
        from,
        subject,
        html: htmlContent,
      });

      console.log(`Email sent to ${to}`);
    } catch (error) {
      console.error('Email sending error:', error);
      throw new Error('Failed to send email');
    }
  }

  static async sendAppointmentConfirmation(
    email: string,
    appointmentDate: Date,
    appointmentType: string,
    physicianName: string,
  ): Promise<void> {
    const htmlContent = `
      <h2>Appointment Confirmation</h2>
      <p>Your appointment has been confirmed.</p>
      <p><strong>Date & Time:</strong> ${appointmentDate.toLocaleString()}</p>
      <p><strong>Type:</strong> ${appointmentType}</p>
      <p><strong>Physician:</strong> ${physicianName}</p>
      <p>Please arrive 10 minutes early for in-person appointments.</p>
    `;

    await this.sendEmail(email, 'Appointment Confirmation', htmlContent);
  }

  static async sendAppointmentReminder(
    email: string,
    appointmentDate: Date,
    hoursUntil: number,
  ): Promise<void> {
    const htmlContent = `
      <h2>Appointment Reminder</h2>
      <p>This is a reminder that you have an appointment in ${hoursUntil} hours.</p>
      <p><strong>Date & Time:</strong> ${appointmentDate.toLocaleString()}</p>
      <p>If you need to reschedule, please contact us as soon as possible.</p>
    `;

    await this.sendEmail(email, 'Appointment Reminder', htmlContent);
  }

  static async sendFollowUpEmail(
    email: string,
    visitSummary: string,
    medications: string[],
    nextSteps: string,
  ): Promise<void> {
    const medicationsList = medications.map((med) => `<li>${med}</li>`).join('');

    const htmlContent = `
      <h2>Visit Follow-Up</h2>
      <p><strong>Visit Summary:</strong></p>
      <p>${visitSummary}</p>
      <p><strong>Prescribed Medications:</strong></p>
      <ul>${medicationsList}</ul>
      <p><strong>Next Steps:</strong></p>
      <p>${nextSteps}</p>
    `;

    await this.sendEmail(email, 'Visit Follow-Up', htmlContent);
  }

  // SMS notifications
  static async sendSMS(phoneNumber: string, message: string): Promise<void> {
    try {
      await twilioClient.messages.create({
        body: message,
        from: process.env.TWILIO_PHONE_NUMBER,
        to: phoneNumber,
      });

      console.log(`SMS sent to ${phoneNumber}`);
    } catch (error) {
      console.error('SMS sending error:', error);
      throw new Error('Failed to send SMS');
    }
  }

  static async sendAppointmentReminderSMS(phoneNumber: string, appointmentDate: Date): Promise<void> {
    const message = `Reminder: You have an appointment on ${appointmentDate.toLocaleString()}. Reply CONFIRM to confirm or CANCEL to cancel.`;
    await this.sendSMS(phoneNumber, message);
  }

  static async sendVerificationCodeSMS(phoneNumber: string, code: string): Promise<void> {
    const message = `Your Concierge Medicine verification code is: ${code}. Do not share this code with anyone.`;
    await this.sendSMS(phoneNumber, message);
  }

  // In-app notifications (stored in database)
  static async createInAppNotification(
    userId: string,
    title: string,
    message: string,
    type: 'APPOINTMENT' | 'MESSAGE' | 'BILLING' | 'SYSTEM',
  ): Promise<void> {
    // This would be implemented with a notifications table
    console.log(`In-app notification created for user ${userId}: ${title}`);
  }
}
