# FlightyClone Backend

Minimal backend service for push notifications and Live Activity updates.

## Features

- Device registration for APNs
- Flight subscription management
- Push notification delivery
- Live Activity updates
- Health check endpoint

## Setup

### Local Development

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file:
```bash
cp .env.example .env
# Edit .env with your APNs credentials
```

3. Start the server:
```bash
npm start
# or for development with auto-reload:
npm run dev
```

### Docker

1. Build the image:
```bash
docker build -t flightyclone-backend .
```

2. Run the container:
```bash
docker run -p 3000:3000 \
  -e APNS_KEY_ID=YOUR_KEY_ID \
  -e APNS_TEAM_ID=YOUR_TEAM_ID \
  -e APNS_KEY_PATH=/app/keys/AuthKey.p8 \
  -v /path/to/AuthKey.p8:/app/keys/AuthKey.p8:ro \
  flightyclone-backend
```

## API Endpoints

### `GET /health`
Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "apnsConfigured": true,
  "devices": 10,
  "subscriptions": 25
}
```

### `POST /api/register-device`
Register a device for push notifications.

**Request:**
```json
{
  "deviceToken": "string",
  "userId": "string (optional)",
  "platform": "iOS"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Device registered successfully"
}
```

### `POST /api/subscribe`
Subscribe to flight updates.

**Request:**
```json
{
  "deviceToken": "string",
  "flightId": "string",
  "icao24": "string",
  "callsign": "string",
  "notificationTypes": ["departure", "arrival", "delay"]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Subscribed to flight updates"
}
```

### `POST /api/unsubscribe`
Unsubscribe from flight updates.

**Request:**
```json
{
  "deviceToken": "string",
  "flightId": "string"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Unsubscribed from flight updates"
}
```

### `GET /api/subscriptions`
Get active subscriptions (for debugging).

**Query Parameters:**
- `deviceToken` (optional): Filter by device token

**Response:**
```json
{
  "count": 5,
  "subscriptions": [...]
}
```

## Internal API (for monitoring/automation)

### `POST /api/internal/send-notification`
Send a push notification to a device.

### `POST /api/internal/update-live-activity`
Update a Live Activity.

## Configuration

### Required Environment Variables

- `APNS_KEY_ID`: Your APNs Key ID
- `APNS_TEAM_ID`: Your Apple Team ID
- `APNS_KEY_PATH`: Path to your .p8 key file
- `APNS_BUNDLE_ID`: Your app's bundle identifier

### Optional Environment Variables

- `PORT`: Server port (default: 3000)
- `NODE_ENV`: Environment (development/production)
- `APNS_ENVIRONMENT`: APNs environment (development/production)

## Production Deployment

For production use:

1. Use a proper database (PostgreSQL, MongoDB) instead of in-memory storage
2. Implement authentication/authorization
3. Add rate limiting
4. Set up monitoring and logging
5. Use environment-specific configurations
6. Implement proper error handling and retry logic
7. Add background jobs for polling OpenSky API and sending updates

## Testing

```bash
npm test
```

## License

MIT
