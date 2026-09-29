# Phase 1: Baseline Architecture & DNS Integration

## 1. Phase 1 Objectives

Phase 1 establishes the baseline networking foundation for the course project:
1. Verify physical/virtual host-to-host IP connectivity across all assigned machines.
2. Deploy and validate authoritative private name resolution on **Machine 1** using `dnsmasq`.
3. Deploy **Backend Server A** on **Machine 3** listening on port 3001.
4. Deploy **Machine 2** as an unencrypted HTTP reverse proxy routing traffic from `http://app.team1.test` to Backend Server A.
5. Collect baseline network evidence (Wireshark packet captures of DNS and cleartext HTTP).

---

## 2. Milestone Deliverables

| Task ID | Component | Success Criteria | Evidence Location |
| :--- | :--- | :--- | :--- |
| **P1-1** | Network Reachability | Bi-directional ICMP `ping` between all 4 nodes | Terminal outputs |
| **P1-2** | Private DNS | `dig @10.7.11.22 app.team1.test` returns `10.7.12.181` | `evidence/dns/` |
| **P1-3** | Backend A | `curl http://10.7.3.22:3001/api/status` returns `{"backend":"A","status":"ok"}` | Terminal output |
| **P1-4** | Reverse Proxy | `curl http://10.7.12.181/api/status` proxies to Backend A | `evidence/tcp/` |
| **P1-5** | Packet Captures | Wireshark captures of DNS query/response and cleartext HTTP | `evidence/dns/`, `evidence/tcp/` |

---

## 3. Configuration Steps

### Step 3.1: Ping Connectivity Verification
Run from Machine 1 (or any test client):
```bash
ping -c 3 10.7.11.22   # Machine 1
ping -c 3 10.7.12.181  # Machine 2
ping -c 3 10.7.3.22    # Machine 3
ping -c 3 10.7.11.17   # Machine 4
```

### Step 3.2: Machine 1 (DNS)
1. Install `dnsmasq`: `brew install dnsmasq`
2. Configure `dnsmasq.conf`:
   ```text
   interface=en0
   listen-address=127.0.0.1,10.7.11.22
   bind-interfaces
   address=/app.team1.test/10.7.12.181
   address=/api.team1.test/10.7.12.181
   ```
3. Start service: `sudo brew services start dnsmasq`
4. Test with `./scripts/test-dns.sh 10.7.11.22`

### Step 3.3: Machine 3 (Backend A)
1. Navigate to `backend-a/`: `cd backend-a`
2. Create `.env`: `cp .env.example .env`
3. Launch server: `node server.js`
4. Verify locally: `curl -i http://127.0.0.1:3001/api/status`

### Step 3.4: Machine 2 (Basic HTTP Reverse Proxy)
In Phase 1, Machine 2 operates a minimal HTTP-only server block forwarding directly to Backend A:
```nginx
server {
    listen 80;
    server_name app.team1.test api.team1.test;

    location /api/ {
        proxy_pass http://10.7.3.22:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass_header X-Backend;
    }
}
```

---

## 4. Phase 1 Verification Script

Run the automated verification suite:
```bash
# 1. Validate DNS
./scripts/test-dns.sh 10.7.11.22

# 2. Validate Backend A directly
./scripts/test-backend-a.sh 10.7.3.22 3001

# 3. Validate Reverse Proxy through Machine 2
curl -i http://10.7.12.181/api/status -H "Host: app.team1.test"
```
Output must contain:
```text
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
X-Backend: A

{
  "backend": "A",
  "status": "ok"
}
```
