const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3004;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'payments-service',
    timestamp: new Date().toISOString()
  });
});

// API endpoints
app.post('/api/payments/charge', async (req, res) => {
  try {
    const { amount, currency, source, orderId } = req.body;

    // Mock payment processing - replace with actual Stripe integration
    const payment = {
      id: `pay_${Date.now()}`,
      amount,
      currency: currency || 'usd',
      status: 'succeeded',
      orderId,
      createdAt: new Date()
    };

    res.json({ success: true, data: payment });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/payments/:id', async (req, res) => {
  try {
    const { id } = req.params;
    // Mock data - replace with actual payment lookup
    const payment = {
      id,
      amount: 5999,
      currency: 'usd',
      status: 'succeeded',
      createdAt: new Date()
    };
    res.json({ success: true, data: payment });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/payments/refund', async (req, res) => {
  try {
    const { paymentId, amount } = req.body;

    // Mock refund - replace with actual Stripe refund
    const refund = {
      id: `ref_${Date.now()}`,
      paymentId,
      amount,
      status: 'succeeded',
      createdAt: new Date()
    };

    res.json({ success: true, data: refund });
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
  console.log(`Payments service running on port ${PORT}`);
});
