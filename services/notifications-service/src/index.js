const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3005;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'notifications-service',
    timestamp: new Date().toISOString()
  });
});

// API endpoints
app.post('/api/notifications/email', async (req, res) => {
  try {
    const { to, subject, body, template } = req.body;

    // Mock email sending - replace with actual email service (SES, SendGrid, etc.)
    const notification = {
      id: `notif_${Date.now()}`,
      type: 'email',
      to,
      subject,
      status: 'sent',
      sentAt: new Date()
    };

    console.log(`Email notification sent to ${to}: ${subject}`);
    res.json({ success: true, data: notification });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/notifications/sms', async (req, res) => {
  try {
    const { to, message } = req.body;

    // Mock SMS sending - replace with actual SMS service (SNS, Twilio, etc.)
    const notification = {
      id: `notif_${Date.now()}`,
      type: 'sms',
      to,
      status: 'sent',
      sentAt: new Date()
    };

    console.log(`SMS notification sent to ${to}`);
    res.json({ success: true, data: notification });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/notifications/:id', async (req, res) => {
  try {
    const { id } = req.params;
    // Mock data - replace with actual notification lookup
    const notification = {
      id,
      type: 'email',
      status: 'sent',
      sentAt: new Date()
    };
    res.json({ success: true, data: notification });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Notifications service running on port ${PORT}`);
});
