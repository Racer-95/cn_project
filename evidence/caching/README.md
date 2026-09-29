# Evidence: Reverse Proxy & HTTP Caching

This directory contains evidence verifying the operation of the HTTP caching mechanism implemented in nginx on Machine 2.

---

## Required Artifacts Checklist

- [ ] **Artifact 1:** `cache-hit-miss-terminal.txt`
  - Sequential `curl -i` requests to `https://app.team1.test/cached/status`.
  - **Request 1:** Shows `X-Cache-Status: MISS`, `Cache-Control: public, max-age=60`, and an upstream dispatch in nginx logs.
  - **Request 2:** Shows `X-Cache-Status: HIT`, same response timestamp, and zero requests logged on Backend A or Backend B.
- [ ] **Artifact 2:** `caching-wireshark.pcapng`
  - Wireshark capture comparing the initial request (which triggers backend TCP traffic to port 3001/3002) against subsequent cached requests (where Machine 2 replies instantly to the client without initiating any backend TCP packets).
- [ ] **Artifact 3:** `cache-status-screenshot.png`
  - Screenshot of terminal or browser developer tools showing HTTP response headers `X-Cache-Status: HIT` and `Cache-Control: max-age=60`.
- [ ] **Artifact 4:** `cache-expiry-terminal.txt`
  - Terminal log demonstrating that after 60 seconds have elapsed, the subsequent request returns `X-Cache-Status: EXPIRED` or a new `MISS` with an updated response payload.

---

## How to Reproduce Caching Evidence

```bash
# 1. Initial Request (MISS)
curl -k -i https://10.7.12.181/cached/status -H "Host: app.team1.test" > evidence/caching/cache-hit-miss-terminal.txt

# 2. Subsequent Request within 60 seconds (HIT)
curl -k -i https://10.7.12.181/cached/status -H "Host: app.team1.test" >> evidence/caching/cache-hit-miss-terminal.txt

# 3. Wait 65 seconds and test cache expiration:
sleep 65
curl -k -i https://10.7.12.181/cached/status -H "Host: app.team1.test" > evidence/caching/cache-expiry-terminal.txt
```
