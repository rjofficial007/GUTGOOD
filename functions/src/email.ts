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
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="x-apple-disable-message-reformatting">
  <title>Welcome to GutGood</title>
</head>
<body style="margin:0; padding:0; background-color:#ffffff; font-family:Inter,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif; color:#17231e;">
  <div style="display:none; max-height:0; overflow:hidden; opacity:0; color:transparent; mso-hide:all;">
    Welcome to GutGood — understand what you eat, understand your body.
  </div>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%; max-width:600px;">
          <!-- Brand -->
          <tr>
            <td style="padding:52px 32px 32px;">
              <div style="font-family:Inter,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif; font-size:24px; line-height:30px; font-weight:700; letter-spacing:-0.7px; color:#17231e;">
                GutGood
              </div>
            </td>
          </tr>
          <!-- Welcome -->
          <tr>
            <td style="padding:0 32px;">
              <p style="margin:0 0 26px; font-size:16px; line-height:26px; font-weight:500; color:#69756f;">
                Welcome to GutGood, ${displayName || 'friend'}.
              </p>
              <!-- Hero Typography -->
              <h1 style="margin:0 0 34px; font-size:38px; line-height:46px; font-weight:600; letter-spacing:-1.5px; color:#17231e;">
                Food is more than calories.<br>
                It’s information.
              </h1>
              <!-- Body -->
              <p style="margin:0 0 34px; max-width:540px; font-size:17px; line-height:30px; font-weight:400; color:#596660;">
                GutGood helps you understand what you eat, notice your patterns, and learn how your everyday choices connect to how you feel.
              </p>
              <!-- Section Label -->
              <p style="margin:0 0 18px; font-size:12px; line-height:18px; font-weight:600; letter-spacing:1.2px; text-transform:uppercase; color:#89948f;">
                Start simple
              </p>
              <!-- Steps -->
              <p style="margin:0 0 36px; font-size:20px; line-height:34px; font-weight:500; letter-spacing:-0.2px; color:#35423c;">
                Scan your food.<br>
                Check in with your body.<br>
                Build your patterns.
              </p>
              <!-- Personalization -->
              <p style="margin:0 0 38px; max-width:540px; font-size:17px; line-height:30px; font-weight:400; color:#596660;">
                The more you use GutGood, the more personal your experience becomes.
              </p>
              <!-- Brand Statement -->
              <p style="margin:0 0 48px; font-size:22px; line-height:32px; font-weight:600; letter-spacing:-0.5px; color:#17231e;">
                Your food.<br>
                Your body.<br>
                Your patterns.
              </p>
              <!-- Closing -->
              <p style="margin:0 0 70px; font-size:16px; line-height:26px; font-weight:500; color:#52605a;">
                Welcome aboard.
              </p>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="padding:28px 32px 42px; border-top:1px solid #eeeeeb;">
              <p style="margin:0 0 6px; font-size:13px; line-height:20px; font-weight:600; color:#68756f;">
                — The GutGood Team
              </p>
              <p style="margin:0; font-size:12px; line-height:19px; font-weight:400; color:#9aa49f;">
                © GutGood — Understand what you eat. Understand your body.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
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
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="x-apple-disable-message-reformatting">
  <title>Welcome to GutGood</title>
</head>
<body style="margin:0; padding:0; background-color:#ffffff; font-family:Inter,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif; color:#17231e;">
  <div style="display:none; max-height:0; overflow:hidden; opacity:0; color:transparent; mso-hide:all;">
    Confirm your email to start your GutGood journey.
  </div>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%; max-width:600px;">
          <!-- Brand -->
          <tr>
            <td style="padding:52px 32px 32px;">
              <div style="font-family:Inter,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif; font-size:24px; line-height:30px; font-weight:700; letter-spacing:-0.7px; color:#17231e;">
                GutGood
              </div>
            </td>
          </tr>
          <!-- Content -->
          <tr>
            <td style="padding:0 32px;">
              <p style="margin:0 0 26px; font-size:16px; line-height:26px; font-weight:500; color:#69756f;">
                Welcome to GutGood.
              </p>
              <!-- Hero Typography -->
              <h1 style="margin:0 0 34px; font-size:38px; line-height:46px; font-weight:600; letter-spacing:-1.5px; color:#17231e;">
                You’re almost in.
              </h1>
              <!-- Body -->
              <p style="margin:0 0 42px; max-width:540px; font-size:17px; line-height:30px; font-weight:400; color:#596660;">
                Confirm your email to start understanding your food, your body, and your patterns.
              </p>
              <!-- Button -->
              <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 54px;">
                <tr>
                  <td align="center" bgcolor="#17231e" style="border-radius:12px;">
                    <a href="${link}" target="_blank" style="padding:16px 32px; font-size:16px; font-weight:600; color:#ffffff; text-decoration:none; display:inline-block;">
                      Confirm My Email
                    </a>
                  </td>
                </tr>
              </table>
              <!-- Closing -->
              <p style="margin:0 0 70px; font-size:16px; line-height:26px; font-weight:500; color:#52605a;">
                Food is information.
              </p>
              <p style="margin:0 0 70px; font-size:12px; line-height:20px; font-weight:400; color:#9aa49f;">
                If you didn’t create a GutGood account, you can safely ignore this email.
              </p>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="padding:28px 32px 42px; border-top:1px solid #eeeeeb;">
              <p style="margin:0 0 6px; font-size:13px; line-height:20px; font-weight:600; color:#68756f;">
                — The GutGood Team
              </p>
              <p style="margin:0; font-size:12px; line-height:19px; font-weight:400; color:#9aa49f;">
                © GutGood — Understand what you eat. Understand your body.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
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
