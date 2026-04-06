const nodemailer = require('nodemailer');

// Create reusable transporter
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT) || 587,
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

/**
 * Send welcome email with credentials to new user
 */
const sendWelcomeEmail = async ({ email, fullName, workId, temporaryPassword }) => {
  const mailOptions = {
    from: process.env.SMTP_FROM || 'RCFMS <noreply@rcfms.com>',
    to: email,
    subject: 'Welcome to RCFMS - Your Account Credentials',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #2A9D8F, #1E7268); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .credentials { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #2A9D8F; }
          .credential-row { margin: 10px 0; }
          .label { color: #666; font-size: 12px; text-transform: uppercase; }
          .value { font-size: 16px; font-weight: bold; color: #2A9D8F; }
          .warning { background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 8px; margin-top: 20px; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Welcome to RCFMS</h1>
            <p>Resident Care & Facility Management System</p>
          </div>
          <div class="content">
            <p>Hello <strong>${fullName}</strong>,</p>
            <p>Your RCFMS account has been created. You can now access the system using the credentials below:</p>
            
            <div class="credentials">
              <div class="credential-row">
                <div class="label">Email</div>
                <div class="value">${email}</div>
              </div>
              <div class="credential-row">
                <div class="label">Work ID</div>
                <div class="value">${workId}</div>
              </div>
              <div class="credential-row">
                <div class="label">Temporary Password</div>
                <div class="value">${temporaryPassword}</div>
              </div>
            </div>
            
            <div class="warning">
              <strong>⚠️ Important:</strong> Please change your password after your first login. You will also need to set up your digital signature.
            </div>
            
            <p>If you have any questions, please contact your system administrator.</p>
          </div>
          <div class="footer">
            <p>This is an automated message from RCFMS. Please do not reply to this email.</p>
            <p>&copy; ${new Date().getFullYear()} RCFMS - All rights reserved</p>
          </div>
        </div>
      </body>
      </html>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`Welcome email sent to ${email}`);
    return true;
  } catch (error) {
    console.error('Failed to send welcome email:', error);
    throw error;
  }
};

/**
 * Send notification email
 */
const sendNotificationEmail = async ({ email, subject, message }) => {
  const mailOptions = {
    from: process.env.SMTP_FROM || 'RCFMS <noreply@rcfms.com>',
    to: email,
    subject: `RCFMS - ${subject}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: #2A9D8F; color: white; padding: 20px; text-align: center;">
          <h2>RCFMS Notification</h2>
        </div>
        <div style="padding: 20px; background: #f9f9f9;">
          <p>${message}</p>
        </div>
        <div style="text-align: center; padding: 20px; color: #666; font-size: 12px;">
          <p>This is an automated notification from RCFMS.</p>
        </div>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    return true;
  } catch (error) {
    console.error('Failed to send notification email:', error);
    throw error;
  }
};

module.exports = {
  sendWelcomeEmail,
  sendNotificationEmail,
};
