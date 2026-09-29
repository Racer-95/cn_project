/**
 * Computer Networks Course Project - Private Network Service Platform
 * Backend Server A
 *
 * Implements a lightweight, zero-dependency Node.js HTTP service.
 * Responds to GET / and GET /api/status, emitting the 'X-Backend: A' header.
 *
 * Configuration is dynamically loaded from environment variables or a local .env file.
 * Private IPs are not hardcoded.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

// --- Simple Zero-Dependency .env Loader ---
function loadEnv() {
  const envPath = path.resolve(__dirname, '.env');
  if (fs.existsSync(envPath)) {
    const content = fs.readFileSync(envPath, 'utf8');
    content.split('\n').forEach((line) => {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const [key, ...vals] = trimmed.split('=');
        if (key && vals.length > 0) {
          const val = vals.join('=').trim().replace(/^["']|["']$/g, '');
          if (!process.env[key.trim()]) {
            process.env[key.trim()] = val;
          }
        }
      }
    });
  }
}
loadEnv();

// --- Configuration ---
const HOST = process.env.HOST || '0.0.0.0';
const PORT = parseInt(process.env.PORT || '3001', 10);
const BACKEND_ID = process.env.BACKEND_ID || 'A';
const APP_NAME = process.env.APP_NAME || 'Private Network Service Platform - Backend A';

// --- Server Definition ---
const server = http.createServer((req, res) => {
  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';
  const startTime = Date.now();

  // Common response headers
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.setHeader('X-Backend', BACKEND_ID);

  // URL parsing
  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = parsedUrl.pathname;
  const method = req.method ? req.method.toUpperCase() : 'GET';

  // Log incoming request
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    console.log(`[${new Date().toISOString()}] ${method} ${pathname} -> ${res.statusCode} (${duration}ms) [Client: ${clientIp}]`);
  });

  // Routing
  if (method === 'GET' && pathname === '/api/status') {
    // Required endpoint per course specification
    const payload = {
      backend: BACKEND_ID,
      status: 'ok'
    };
    res.writeHead(200);
    res.end(JSON.stringify(payload, null, 2));
    return;
  }

  if (method === 'GET' && pathname === '/') {
    // Root information endpoint
    const payload = {
      message: 'Private Network Service Platform - Service Online',
      service: APP_NAME,
      backend: BACKEND_ID,
      serverTime: new Date().toISOString(),
      clientIp: clientIp,
      uptimeSeconds: Math.floor(process.uptime()),
      endpoints: [
        { path: '/', method: 'GET', description: 'Service metadata' },
        { path: '/api/status', method: 'GET', description: 'Health and backend identity check' }
      ]
    };
    res.writeHead(200);
    res.end(JSON.stringify(payload, null, 2));
    return;
  }

  // Fallback 404 for unhandled routes
  res.writeHead(404);
  res.end(JSON.stringify({
    error: 'Not Found',
    backend: BACKEND_ID,
    requestedPath: pathname
  }, null, 2));
});

// --- Server Listen ---
server.listen(PORT, HOST, () => {
  console.log('====================================================');
  console.log(` ${APP_NAME}`);
  console.log('====================================================');
  console.log(` Status      : Online`);
  console.log(` Backend ID  : ${BACKEND_ID}`);
  console.log(` Listening   : http://${HOST}:${PORT}`);
  console.log(` Health URL  : http://${HOST === '0.0.0.0' ? '127.0.0.1' : HOST}:${PORT}/api/status`);
  console.log(' Press Ctrl+C to stop.');
  console.log('====================================================');
});

// --- Graceful Shutdown ---
function shutdown(signal) {
  console.log(`\nReceived ${signal}. Shutting down gracefully...`);
  server.close(() => {
    console.log('HTTP server closed. Exiting process.');
    process.exit(0);
  });
  // Force shutdown after timeout if connections linger
  setTimeout(() => {
    console.error('Forceful shutdown triggered after timeout.');
    process.exit(1);
  }, 5000).unref();
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
