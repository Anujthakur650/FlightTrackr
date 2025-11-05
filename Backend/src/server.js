const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const dotenv = require('dotenv');
const apn = require('apn');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// In-memory storage (use a database in production)
const devices = new Map();
const subscriptions = new Map();

// APNs Provider setup
let apnProvider = null;

if (process.env.APNS_KEY_PATH && process.env.APNS_KEY_ID && process.env.APNS_TEAM_ID) {
  const options = {
    token: {
      key: process.env.APNS_KEY_PATH,
      keyId: process.env.APNS_KEY_ID,
      teamId: process.env.APNS_TEAM_ID
    },
    production: process.env.APNS_ENVIRONMENT === 'production'
  };
  
  apnProvider = new apn.Provider(options);
  console.log('✅ APNs provider initialized');
} else {
  console.warn('⚠️  APNs not configured. Push notifications will not work.');
}

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    apnsConfigured: apnProvider !== null,
    devices: devices.size,
    subscriptions: subscriptions.size
  });
});

// Register device for push notifications
app.post('/api/register-device', (req, res) => {
  const { deviceToken, userId, platform } = req.body;
  
  if (!deviceToken) {
    return res.status(400).json({ error: 'Device token is required' });
  }
  
  devices.set(deviceToken, {
    deviceToken,
    userId: userId || null,
    platform: platform || 'iOS',
    registeredAt: new Date().toISOString()
  });
  
  console.log(`✅ Registered device: ${deviceToken.substring(0, 8)}...`);
  
  res.json({
    success: true,
    message: 'Device registered successfully'
  });
});

// Subscribe to flight updates
app.post('/api/subscribe', (req, res) => {
  const { deviceToken, flightId, icao24, callsign, notificationTypes } = req.body;
  
  if (!deviceToken || !flightId) {
    return res.status(400).json({ error: 'Device token and flight ID are required' });
  }
  
  const subscriptionKey = `${deviceToken}_${flightId}`;
  
  subscriptions.set(subscriptionKey, {
    deviceToken,
    flightId,
    icao24: icao24 || null,
    callsign: callsign || null,
    notificationTypes: notificationTypes || ['departure', 'arrival', 'delay'],
    subscribedAt: new Date().toISOString()
  });
  
  console.log(`✅ Subscribed ${deviceToken.substring(0, 8)}... to flight ${flightId}`);
  
  res.json({
    success: true,
    message: 'Subscribed to flight updates'
  });
});

// Unsubscribe from flight updates
app.post('/api/unsubscribe', (req, res) => {
  const { deviceToken, flightId } = req.body;
  
  if (!deviceToken || !flightId) {
    return res.status(400).json({ error: 'Device token and flight ID are required' });
  }
  
  const subscriptionKey = `${deviceToken}_${flightId}`;
  const deleted = subscriptions.delete(subscriptionKey);
  
  if (deleted) {
    console.log(`✅ Unsubscribed ${deviceToken.substring(0, 8)}... from flight ${flightId}`);
    res.json({
      success: true,
      message: 'Unsubscribed from flight updates'
    });
  } else {
    res.status(404).json({
      success: false,
      error: 'Subscription not found'
    });
  }
});

// Send push notification (internal API)
app.post('/api/internal/send-notification', async (req, res) => {
  const { deviceToken, title, body, data } = req.body;
  
  if (!deviceToken || !title || !body) {
    return res.status(400).json({ error: 'Device token, title, and body are required' });
  }
  
  if (!apnProvider) {
    return res.status(503).json({ error: 'APNs not configured' });
  }
  
  const notification = new apn.Notification({
    alert: {
      title,
      body
    },
    sound: 'default',
    badge: 1,
    topic: process.env.APNS_BUNDLE_ID,
    payload: data || {}
  });
  
  try {
    const result = await apnProvider.send(notification, deviceToken);
    
    if (result.failed.length > 0) {
      console.error('❌ Failed to send notification:', result.failed);
      return res.status(500).json({
        success: false,
        error: 'Failed to send notification',
        details: result.failed
      });
    }
    
    console.log('✅ Notification sent successfully');
    res.json({
      success: true,
      message: 'Notification sent',
      result: result.sent
    });
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Update Live Activity (internal API)
app.post('/api/internal/update-live-activity', async (req, res) => {
  const { activityToken, state } = req.body;
  
  if (!activityToken || !state) {
    return res.status(400).json({ error: 'Activity token and state are required' });
  }
  
  if (!apnProvider) {
    return res.status(503).json({ error: 'APNs not configured' });
  }
  
  const notification = new apn.Notification({
    topic: `${process.env.APNS_BUNDLE_ID}.push-type.liveactivity`,
    pushType: 'liveactivity',
    payload: {
      aps: {
        timestamp: Math.floor(Date.now() / 1000),
        event: 'update',
        'content-state': state
      }
    }
  });
  
  try {
    const result = await apnProvider.send(notification, activityToken);
    
    if (result.failed.length > 0) {
      console.error('❌ Failed to update Live Activity:', result.failed);
      return res.status(500).json({
        success: false,
        error: 'Failed to update Live Activity',
        details: result.failed
      });
    }
    
    console.log('✅ Live Activity updated successfully');
    res.json({
      success: true,
      message: 'Live Activity updated'
    });
  } catch (error) {
    console.error('❌ Error updating Live Activity:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Get active subscriptions (for debugging)
app.get('/api/subscriptions', (req, res) => {
  const { deviceToken } = req.query;
  
  if (deviceToken) {
    const deviceSubscriptions = Array.from(subscriptions.values())
      .filter(sub => sub.deviceToken === deviceToken);
    
    res.json({
      count: deviceSubscriptions.length,
      subscriptions: deviceSubscriptions
    });
  } else {
    res.json({
      count: subscriptions.size,
      subscriptions: Array.from(subscriptions.values())
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 FlightyClone backend running on port ${PORT}`);
  console.log(`📱 Device registrations: ${devices.size}`);
  console.log(`📡 Active subscriptions: ${subscriptions.size}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server...');
  if (apnProvider) {
    apnProvider.shutdown();
  }
  process.exit(0);
});

module.exports = app;
