const express = require('express');
const app = express();
const PORT = process.env.PORT || 3001;

app.get('/', (req, res) => {
  res.json({
    message: 'Concierge Medicine Platform',
    status: 'running',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.get('/api/info', (req, res) => {
  res.json({
    database: process.env.DB_HOST || 'not configured',
    s3Bucket: process.env.AWS_S3_BUCKET || 'not configured',
    environment: process.env.NODE_ENV || 'development'
  });
});

app.listen(PORT, () => {
  console.log(`Concierge Medicine API running on port ${PORT}`);
});
