# Machine 2: Edge Reverse Proxy & Load Balancer (`nginx`)

Machine 2 functions as the entry point and perimeter security layer for the **Private Network Service Platform**. All client requests arriving from the private DNS (`app.team1.test` and `api.team1.test`) reach Machine 2 on port 80 (HTTP) or port 443 (HTTPS).

---

## Machine Specification

| Parameter | Value |
| :--- | :--- |
| **Role** | Edge Reverse Proxy, TLS Terminator & L7 Load Balancer |
| **Assigned IP (Example)** | `10.7.12.181` |
| **Ports** | `80` (HTTP Redirect), `443` (HTTPS Termination) |
| **Software** | `nginx` via Homebrew on macOS |
| **Upstream Pool** | Backend A (`10.7.3.22:3001`), Backend B (`10.7.11.17:3002`) |
| **Balancing Method** | Round-Robin |
| **TLS Certificates** | Multi-domain SAN cert covering `app.team1.test` and `api.team1.test` |

---

## Architecture & Responsibilities

1. **HTTP to HTTPS Redirection:**
   Inbound requests to plaintext HTTP (Port 80) receive an immediate `301 Moved Permanently` redirect to `https://$host$request_uri`.
2. **TLS 1.2 / 1.3 Termination:**
   Handshakes are negotiated and decrypted at Machine 2. Upstream connections to backends remain within the secure private local network.
3. **Round-Robin Load Balancing:**
   Dynamic requests targeting `/api/status` or `/` are forwarded sequentially between Backend A (Machine 3) and Backend B (Machine 4).
4. **Header Enrichment:**
   Nginx injects standard proxy forwarding headers (`X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`) and preserves backend identification headers (`X-Backend`).
5. **HTTP Caching Layer:**
   Endpoints mapped under `/cached/` leverage an in-memory disk-backed cache with `Cache-Control: max-age=60`, reducing redundant compute cycles on upstream nodes.

---

## Installation & Setup on macOS

### 1. Install nginx via Homebrew
```bash
brew install nginx
```

### 2. Prepare Cache & Log Directories
```bash
sudo mkdir -p /tmp/nginx_cache
sudo mkdir -p /var/log/nginx
sudo chmod 755 /tmp/nginx_cache
```

### 3. Generate or Install TLS Certificates
Follow instructions in [tls/README.md](tls/README.md) to generate `team1.test.crt` and `team1.test.key`.
Store them in `/opt/homebrew/etc/nginx/certs/`:
```bash
sudo mkdir -p /opt/homebrew/etc/nginx/certs
# Ensure certs are present at:
# /opt/homebrew/etc/nginx/certs/team1.test.crt
# /opt/homebrew/etc/nginx/certs/team1.test.key
```

### 4. Deploy Configuration
Copy `nginx.conf.example` to the active nginx configuration path:

- **Apple Silicon Mac:**
  ```bash
  sudo cp nginx.conf.example /opt/homebrew/etc/nginx/nginx.conf
  ```
- **Intel Mac:**
  ```bash
  sudo cp nginx.conf.example /usr/local/etc/nginx/nginx.conf
  ```

### 5. Validate Configuration Syntax
Always test the nginx configuration before starting:
```bash
sudo nginx -t
```
Output should state:
```text
nginx: the configuration file /opt/homebrew/etc/nginx/nginx.conf syntax is ok
nginx: configuration file /opt/homebrew/etc/nginx/nginx.conf test is successful
```

### 6. Start or Reload nginx
Ports 80 and 443 require root privileges:
```bash
# Start nginx:
sudo nginx

# Reload configuration without dropping connections:
sudo nginx -s reload

# Stop nginx:
sudo nginx -s stop
```

---

## Verification & Testing

### 1. Test HTTP to HTTPS Redirection
```bash
curl -i http://10.7.12.181/api/status -H "Host: app.team1.test"
```
Expected output:
```text
HTTP/1.1 301 Moved Permanently
Location: https://app.team1.test/api/status
```

### 2. Test HTTPS Load Balancing
```bash
# Query 1
curl -k -i https://10.7.12.181/api/status -H "Host: app.team1.test"
# Look for: X-Backend: A

# Query 2
curl -k -i https://10.7.12.181/api/status -H "Host: app.team1.test"
# Look for: X-Backend: B
```

### 3. Test HTTP Caching
```bash
# Request 1 (Initial Cache Miss)
curl -k -i https://10.7.12.181/cached/status -H "Host: app.team1.test"
# Look for: X-Cache-Status: MISS and Cache-Control: public, max-age=60

# Request 2 (Within 60 seconds -> Cache Hit)
curl -k -i https://10.7.12.181/cached/status -H "Host: app.team1.test"
# Look for: X-Cache-Status: HIT
```

---

## Troubleshooting

- **Permission Denied binding to port 80 / 443:**
  Standard macOS users cannot bind to ports below 1024. Always run `sudo nginx`.
- **Address already in use (98 / 48):**
  Check which process is holding port 80 or 443:
  ```bash
  sudo lsof -i :80
  sudo lsof -i :443
  ```
  Terminate any lingering process or macOS built-in Apache (`sudo apachectl stop`).
- **502 Bad Gateway:**
  Nginx cannot reach Backend A (`10.7.3.22:3001`) or Backend B (`10.7.11.17:3002`). Ensure Node.js processes are running on Machine 3 and 4 and their firewalls allow inbound traffic on ports 3001 and 3002.
