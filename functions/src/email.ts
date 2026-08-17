import * as nodemailer from 'nodemailer';
import * as functions from 'firebase-functions/v1';
import { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM } from './config';

/**
 * Creates a Nodemailer transporter using secrets.
 */
function getTransporter() {
  return nodemailer.createTransport({
    host: SMTP_HOST.value(),
    port: parseInt(SMTP_PORT.value()),
    secure: SMTP_PORT.value() === '465', // true for 465, false for other ports
    auth: {
      user: SMTP_USER.value(),
      pass: SMTP_PASS.value(),
    },
  });
}

/**
 * Sends a polished welcome email with a verification link.
 */
export async function sendWelcomeEmail(email: string, displayName: string) {
  const transporter = getTransporter();

  const mailOptions = {
    from: SMTP_FROM.value(),
    to: email,
    subject: 'Welcome to GutGood',
    text: `
Welcome to GutGood, ${displayName}.

Food is more than calories. It’s information.

GutGood helps you understand what you eat, notice your patterns, and learn how your everyday choices connect to how you feel.

Start simple.
Scan your food.
Check in with your body.
Build your patterns.

The more you use GutGood, the more personal your experience becomes.

Your food. Your body. Your patterns.

Welcome aboard.

— The GutGood Team
Understand what you eat. Understand your body.
    `.trim(),
    html: `
<div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; color: #333; line-height: 1.6;">
  <p>Welcome to GutGood.</p>

  <p>Food is more than calories. It’s information.</p>

  <p>
    GutGood helps you understand what you eat, notice your patterns, and learn how your everyday choices connect to how you feel.
  </p>

  <p>
    Start simple.<br>
    Scan your food.<br>
    Check in with your body.<br>
    Build your patterns.
  </p>

  <p>
    The more you use GutGood, the more personal your experience becomes.
  </p>

  <p><b>Your food. Your body. Your patterns.</b></p>

  <p>Welcome aboard.</p>

  <p style="color: #888; font-size: 0.9em; margin-top: 40px;">
    — The GutGood Team<br>
    Understand what you eat. Understand your body.
  </p>
</div>
    `.trim(),
  };

  try {
    await transporter.sendMail(mailOptions);
    functions.logger.info(`Welcome email sent to ${email}`);
  } catch (error) {
    functions.logger.error(`Failed to send welcome email to ${email}`, error);
    throw error;
  }
}

/**
 * Sends a polished magic link login email.
 */
export async function sendMagicLinkEmail(email: string, link: string, name?: string) {
  const transporter = getTransporter();

  const mailOptions = {
    from: SMTP_FROM.value(),
    to: email,
    subject: 'Welcome to GutGood — confirm your email',
    text: `
Welcome to GutGood.

You’re almost in.

Confirm your email to start understanding your food, your body, and your patterns: ${link}

Food is information.

If you didn’t create a GutGood account, you can ignore this email.

— GutGood
    `.trim(),
    html: `
<div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; color: #333; line-height: 1.6;">
  <p>Welcome to GutGood.</p>
  <p>You’re almost in.</p>
  <p>Confirm your email to start understanding your food, your body, and your patterns.</p>
  <p style="margin: 30px 0;">
    <a href="${link}" style="background-color: #000; color: #fff; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold; display: inline-block;">Confirm my email</a>
  </p>
  <p>Food is information.</p>
  <p style="color: #888; font-size: 0.9em; margin-top: 40px;">
    If you didn’t create a GutGood account, you can ignore this email.
  </p>
  <p>— GutGood</p>
</div>
    `.trim(),
  };

  try {
    await transporter.sendMail(mailOptions);
    functions.logger.info(`Magic link email sent to ${email}`);
  } catch (error) {
    functions.logger.error(`Failed to send magic link email to ${email}`, error);
    throw error;
  }
}
