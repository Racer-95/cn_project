# Backend Server B (Machine 4)

Backend Server B is the second upstream application server in the **Private Network Service Platform**. In addition to serving backend traffic, Machine 4 is designated as an **active Test Client** to simulate client-side traffic originating from within the private subnet.

---

## Machine Specification

| Parameter | Assigned Value | Configurable Variable |
| :--- | :--- | :--- |
| **Assigned Machine** | Machine 4 | N/A |
| **Assigned IP (Example)** | `10.7.11.17` | `HOST` (defaults to `0.0.0.0`) |
| **Port** | `3002` | `PORT` |
| **Backend Identifier** | `B` | `BACKEND_ID` |
| **Response Header** | `X-Backend: B` | Automatically injected |
| **Secondary Role** | Test Client | Used to run verification scripts |

> **Note:** Private IPs are **not** hardcoded in the codebase. All network bindings and ports are managed via environment variables.

---

## Endpoints

### 1. Health & Identity Endpoint
- **Method:** `GET`
- **Path:** `/api/status`
- **Status Code:** `200 OK`
- **Response Headers:**
  - `Content-Type: application/json; charset=utf-8`
  - `X-Backend: B`
- **Response Body:**
  ```json
  {
    "backend": "B",
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
PORT=3002
BACKEND_ID=B
APP_NAME=Private Network Service Platform - Backend B
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
curl -i http://127.0.0.1:3002/api/status

# Expected Output:
# HTTP/1.1 200 OK
# Content-Type: application/json; charset=utf-8
# X-Backend: B
# Date: ...
# Connection: keep-alive
# Keep-Alive: timeout=5
# Content-Length: 42
#
# {
#   "backend": "B",
#   "status": "ok"
# }
```

From another machine on the private network (e.g., Machine 2 or Machine 1):
```bash
curl -i http://10.7.11.17:3002/api/status
```
