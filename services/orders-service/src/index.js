const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3003;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'orders-service',
    timestamp: new Date().toISOString()
  });
});

// API endpoints
app.get('/api/orders', async (req, res) => {
  try {
    // Mock data - replace with actual database queries
    const orders = [
      { id: 1, userId: 1, total: 99.99, status: 'completed', createdAt: new Date() },
      { id: 2, userId: 2, total: 149.99, status: 'pending', createdAt: new Date() }
    ];
    res.json({ success: true, data: orders });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/orders/:id', async (req, res) => {
  try {
    const { id } = req.params;
    // Mock data - replace with actual database query
    const order = {
      id: parseInt(id),
      userId: 1,
      items: [{ productId: 1, quantity: 2, price: 29.99 }],
      total: 59.98,
      status: 'completed',
      createdAt: new Date()
    };
    res.json({ success: true, data: order });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/orders', async (req, res) => {
  try {
    const { userId, items } = req.body;
    // Mock response - replace with actual order creation logic
    const newOrder = {
      id: Date.now(),
      userId,
      items,
      total: items.reduce((sum, item) => sum + (item.price * item.quantity), 0),
      status: 'pending',
      createdAt: new Date()
    };
    res.status(201).json({ success: true, data: newOrder });
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
  console.log(`Orders service running on port ${PORT}`);
});
