import Stripe from 'stripe';
import dotenv from 'dotenv';

dotenv.config();

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2023-10-16',
});

export class PaymentService {
  static async createPaymentIntent(
    amount: number,
    currency: string = 'usd',
    customerId?: string,
    metadata?: Record<string, string>,
  ): Promise<Stripe.PaymentIntent> {
    try {
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Convert to cents
        currency,
        customer: customerId,
        metadata: metadata || {},
        automatic_payment_methods: {
          enabled: true,
        },
      });

      return paymentIntent;
    } catch (error) {
      console.error('Payment intent creation error:', error);
      throw new Error('Failed to create payment intent');
    }
  }

  static async confirmPaymentIntent(paymentIntentId: string): Promise<Stripe.PaymentIntent> {
    try {
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
      return paymentIntent;
    } catch (error) {
      console.error('Payment intent retrieval error:', error);
      throw new Error('Failed to retrieve payment intent');
    }
  }

  static async createCustomer(email: string, name: string): Promise<Stripe.Customer> {
    try {
      const customer = await stripe.customers.create({
        email,
        name,
      });

      return customer;
    } catch (error) {
      console.error('Customer creation error:', error);
      throw new Error('Failed to create customer');
    }
  }

  static async createSubscription(
    customerId: string,
    priceId: string,
    metadata?: Record<string, string>,
  ): Promise<Stripe.Subscription> {
    try {
      const subscription = await stripe.subscriptions.create({
        customer: customerId,
        items: [{ price: priceId }],
        metadata: metadata || {},
      });

      return subscription;
    } catch (error) {
      console.error('Subscription creation error:', error);
      throw new Error('Failed to create subscription');
    }
  }

  static async cancelSubscription(subscriptionId: string): Promise<Stripe.Subscription> {
    try {
      const subscription = await stripe.subscriptions.del(subscriptionId);
      return subscription;
    } catch (error) {
      console.error('Subscription cancellation error:', error);
      throw new Error('Failed to cancel subscription');
    }
  }

  static async refundPayment(paymentIntentId: string, amount?: number): Promise<Stripe.Refund> {
    try {
      const refund = await stripe.refunds.create({
        payment_intent: paymentIntentId,
        amount: amount ? Math.round(amount * 100) : undefined,
      });

      return refund;
    } catch (error) {
      console.error('Refund error:', error);
      throw new Error('Failed to process refund');
    }
  }

  static async verifyWebhookSignature(body: string, signature: string): Promise<Stripe.Event> {
    try {
      const event = stripe.webhooks.constructEvent(
        body,
        signature,
        process.env.STRIPE_WEBHOOK_SECRET || '',
      );

      return event;
    } catch (error) {
      console.error('Webhook verification error:', error);
      throw new Error('Invalid webhook signature');
    }
  }
}
