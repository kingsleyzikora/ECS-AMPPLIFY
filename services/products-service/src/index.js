const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'products-service',
    timestamp: new Date().toISOString()
  });
});

// API endpoints
app.get('/api/products', async (req, res) => {
  try {
    // Mock data - replace with actual database queries
    const products = [
      { id: 1, name: 'Product A', price: 29.99, stock: 100 },
      { id: 2, name: 'Product B', price: 49.99, stock: 50 }
    ];
    res.json({ success: true, data: products });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/products/:id', async (req, res) => {
  try {
    const { id } = req.params;
    // Mock data - replace with actual database query
    const product = { id: parseInt(id), name: 'Product A', price: 29.99, stock: 100 };
    res.json({ success: true, data: product });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/products', async (req, res) => {
  try {
    const { name, price, stock } = req.body;
    // Mock response - replace with actual database insert
    const newProduct = { id: Date.now(), name, price, stock };
    res.status(201).json({ success: true, data: newProduct });
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
  console.log(`Products service running on port ${PORT}`);
});
