# Phase 2: Load Balancing, TLS Termination & Edge Caching

## 1. Phase 2 Objectives

Phase 2 transitions the infrastructure into an enterprise-grade, secure, and horizontally scalable service platform:
1. Deploy **Backend Server B** on **Machine 4** listening on port 3002 (`X-Backend: B`).
2. Implement **Layer 7 Round-Robin Load Balancing** on Machine 2 across Backend A and Backend B.
3. Configure **TLS 1.2 / TLS 1.3 Termination** on port 443 using Subject Alternative Name (SAN) certificates covering `app.team1.test` and `api.team1.test`.
4. Enforce **HTTP to HTTPS Redirection** (HTTP 301) for all plaintext traffic on port 80.
5. Implement **HTTP Reverse Proxy Caching** (`Cache-Control: max-age=60`) on Machine 2.
6. Collect comprehensive Wireshark packet captures verifying encrypted application data, TLS handshakes, round-robin upstream distribution, and cache hits.

---

## 2. Milestone Deliverables

| Task ID | Feature | Specification | Evidence Location |
| :--- | :--- | :--- | :--- |
| **P2-1** | Backend B Deployment | `curl http://10.7.11.17:3002/api/status` returns `{"backend":"B","status":"ok"}` | Terminal output |
| **P2-2** | Load Balancing | Alternate sequential requests between Backend A and B | `evidence/load-balancing/` |
| **P2-3** | TLS Termination | HTTPS on port 443 with SAN cert; encrypted payloads | `evidence/tls/` |
| **P2-4** | HTTP Redirection | Plaintext port 80 responds with `301 Moved Permanently` | `evidence/tls/` |
| **P2-5** | Reverse Proxy Caching | `X-Cache-Status: HIT` within 60s window | `evidence/caching/` |

---

## 3. Configuration & Implementation

### 3.1. Deploying Backend B (Machine 4)
1. Navigate to `backend-b/`: `cd backend-b`
2. Create `.env`: `cp .env.example .env`
3. Launch server: `node server.js`
4. Test directly: `./scripts/test-backend-b.sh 10.7.11.17 3002`

### 3.2. Configuring Nginx Upstream Pool & TLS (Machine 2)
Deploy `machine2-nginx/nginx.conf.example` into `/opt/homebrew/etc/nginx/nginx.conf`:
- **Load Balancer Pool:**
  ```nginx
  upstream backend_pool {
      server 10.7.3.22:3001 max_fails=3 fail_timeout=10s;
      server 10.7.11.17:3002 max_fails=3 fail_timeout=10s;
      keepalive 32;
  }
  ```
- **Port 80 Redirect:**
  ```nginx
  server {
      listen 80;
      server_name app.team1.test api.team1.test;
      return 301 https://$host$request_uri;
  }
  ```
- **Port 443 TLS Block:**
  ```nginx
  server {
      listen 443 ssl;
      server_name app.team1.test api.team1.test;
      ssl_certificate     /opt/homebrew/etc/nginx/certs/team1.test.crt;
      ssl_certificate_key /opt/homebrew/etc/nginx/certs/team1.test.key;
      ssl_protocols TLSv1.2 TLSv1.3;
      ...
  }
  ```
- **Caching Block:**
  ```nginx
  location /cached/ {
      rewrite ^/cached/(.*) /api/$1 break;
      proxy_pass http://backend_pool;
      proxy_cache STATIC_CACHE;
      proxy_cache_valid 200 60s;
      add_header Cache-Control "public, max-age=60";
      add_header X-Cache-Status $upstream_cache_status always;
  }
  ```

---

## 4. Comprehensive Phase 2 Verification Suite

Run each of the following verification commands to demonstrate complete platform functionality:

### 1. Test Load Balancing
Execute the automated test script to send 10 sequential requests:
```bash
./scripts/test-load-balancing.sh 10 https://app.team1.test/api/status
```
Observe the output table demonstrating exact round-robin alternation between Backend A and Backend B:
```text
Req #    | HTTP Code    | X-Backend       | Upstream     | Result    
----------------------------------------------------------------
1        | 200          | Backend A       | nginx-edge   | OK        
2        | 200          | Backend B       | nginx-edge   | OK        
3        | 200          | Backend A       | nginx-edge   | OK        
4        | 200          | Backend B       | nginx-edge   | OK        
...
```

### 2. Test HTTP to HTTPS Redirection
```bash
curl -i http://10.7.12.181/api/status -H "Host: app.team1.test"
# Validates HTTP 301 -> https://app.team1.test/api/status
```

### 3. Test Edge Caching
```bash
# First request: Cache MISS
curl -k -i https://app.team1.test/cached/status
# Inspect header: X-Cache-Status: MISS

# Second request within 60 seconds: Cache HIT
curl -k -i https://app.team1.test/cached/status
# Inspect header: X-Cache-Status: HIT
```
Notice that the second request does not appear in the logs of Backend A or Backend B because it is served directly from the nginx memory/disk cache.
