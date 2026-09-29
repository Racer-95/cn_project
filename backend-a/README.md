# Backend Server A (Machine 3)

Backend Server A is one of two upstream application servers in the **Private Network Service Platform**. It provides core JSON status endpoints and custom response headers utilized by the nginx Edge Load Balancer (Machine 2) to demonstrate round-robin traffic distribution.

---

## Machine Specification

| Parameter | Assigned Value | Configurable Variable |
| :--- | :--- | :--- |
| **Assigned Machine** | Machine 3 | N/A |
| **Assigned IP (Example)** | `10.7.3.22` | `HOST` (defaults to `0.0.0.0`) |
| **Port** | `3001` | `PORT` |
| **Backend Identifier** | `A` | `BACKEND_ID` |
| **Response Header** | `X-Backend: A` | Automatically injected |

> **Note:** Private IPs are **not** hardcoded in the codebase. All network bindings and ports are managed via environment variables.

---

## Endpoints

### 1. Health & Identity Endpoint
- **Method:** `GET`
- **Path:** `/api/status`
- **Status Code:** `200 OK`
- **Response Headers:**
  - `Content-Type: application/json; charset=utf-8`
  - `X-Backend: A`
- **Response Body:**
  ```json
  {
    "backend": "A",
    "status": "ok"
  }
  ```

### 2. Service Root
- **Method:** `GET`
- **Path:** `/`
- **Status Code:** `200 OK`
- **Response Body:** Provides service metadata, server time, uptime, and available route listings.

---

## Setup & Running

### Prerequisites
- Node.js (version 16 or newer). Native `http` module is used, so no external dependencies (`npm install`) are strictly required.

### 1. Configuration
Create a local `.env` file from the provided template:
```bash
cp .env.example .env
```
Adjust parameters if your machine interface IP differs:
```env
HOST=0.0.0.0
PORT=3001
BACKEND_ID=A
APP_NAME=Private Network Service Platform - Backend A
```

### 2. Start the Server
Run directly using Node.js:
```bash
node server.js
```
Or via npm:
```bash
npm start
```

For development auto-reloading (Node.js 18+):
```bash
npm run dev
```

---

## Local Verification

Test the service directly using `curl`:

```bash
# Verify the health check and header
curl -i http://127.0.0.1:3001/api/status

# Expected Output:
# HTTP/1.1 200 OK
# Content-Type: application/json; charset=utf-8
# X-Backend: A
# Date: ...
# Connection: keep-alive
# Keep-Alive: timeout=5
# Content-Length: 42
#
# {
#   "backend": "A",
#   "status": "ok"
# }
```

From another machine on the private network (e.g., Machine 2 or Machine 1):
```bash
curl -i http://10.7.3.22:3001/api/status
```
