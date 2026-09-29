# Evidence: Round-Robin Load Balancing

This directory contains artifacts proving that nginx on Machine 2 distributes inbound traffic across both Backend A (Machine 3 @ `10.7.3.22:3001`) and Backend B (Machine 4 @ `10.7.11.17:3002`).

---

## Required Artifacts Checklist

- [ ] **Artifact 1:** `load-balancing-test-run.txt`
  - Complete output log from executing:
    ```bash
    ./scripts/test-load-balancing.sh 10 https://app.team1.test/api/status > evidence/load-balancing/load-balancing-test-run.txt
    ```
  - Must clearly show sequential alternation between `Backend A` and `Backend B`.
- [ ] **Artifact 2:** `load-balancing-wireshark.pcapng`
  - Wireshark capture recorded on Machine 2 while test script is running.
  - Demonstrates outbound TCP sessions initiated by Machine 2 alternating between:
    - Destination `10.7.3.22:3001` (Backend A)
    - Destination `10.7.11.17:3002` (Backend B)
- [ ] **Artifact 3:** `load-balancing-distribution.png`
  - Wireshark conversation or I/O graph screenshot displaying balanced packet volume across both backend IP addresses.
- [ ] **Artifact 4:** `nginx-upstream-access.log`
  - Access log extract from Machine 2 (`/var/log/nginx/access.log`) showing the `$upstream_addr` variable alternating:
    ```text
    10.7.12.181 - - [...] "GET /api/status HTTP/1.1" 200 ... upstream="10.7.3.22:3001"
    10.7.12.181 - - [...] "GET /api/status HTTP/1.1" 200 ... upstream="10.7.11.17:3002"
    ```

---

## Wireshark Filters

### Display Filter on Machine 2:
```wireshark
tcp.port == 3001 || tcp.port == 3002
```
Look for alternating SYN packets directed to `10.7.3.22` followed by `10.7.11.17`.
