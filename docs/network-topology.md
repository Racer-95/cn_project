# Network Topology & Addressing Plan

## 1. Network Subnetting Analysis

The **Private Network Service Platform** operates across a local class-A private addressing block (`10.7.0.0/16` or campus/lab partitioned `/24` subnets).

| Node | Machine Role | Primary IP | Port(s) | Protocol(s) | Default Interface |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Machine 1** | Private DNS Resolver + Test Client | `10.7.11.22` | `53` (UDP/TCP) | DNS | `en0` |
| **Machine 2** | Edge Reverse Proxy & Load Balancer | `10.7.12.181` | `80` (TCP), `443` (TCP) | HTTP, HTTPS/TLS | `en0` |
| **Machine 3** | Backend Application Server A | `10.7.3.22` | `3001` (TCP) | HTTP | `en0` |
| **Machine 4** | Backend Application Server B + Client | `10.7.11.17` | `3002` (TCP) | HTTP | `en0` |

---

## 2. Addressing & Routing Matrix

```
       [ Client / Machine 1 ]                 [ Edge Proxy / Machine 2 ]
          IP: 10.7.11.22                             IP: 10.7.12.181
         Port: 53 (DNS)                             Port: 80 / 443
                │                                          │
                │         Campus / Lab Switch Fabric        │
                ├──────────────────────────────────────────┤
                │                                          │
       [ Backend A / Machine 3 ]              [ Backend B / Machine 4 ]
          IP: 10.7.3.22                              IP: 10.7.11.17
         Port: 3001 (HTTP)                          Port: 3002 (HTTP)
```

### Subnet Considerations:
- **Intra-subnet communication:** Machine 1 (`10.7.11.22`) and Machine 4 (`10.7.11.17`) reside within the `10.7.11.0/24` subnet. Packets between them resolve Layer 2 hardware MAC addresses directly via Address Resolution Protocol (ARP).
- **Inter-subnet communication:** Machine 2 (`10.7.12.181`) and Machine 3 (`10.7.3.22`) reside in adjacent subnets if using `/24` masks, routed through the default lab gateway, or communicate directly if configured under a `/16` netmask (`255.255.0.0`).
- Ensure all nodes have routing table entries allowing ICMP and TCP traffic across all four IP addresses.

---

## 3. Protocol Stack & Packet Traversal Step-by-Step

### Phase A: DNS Query
```
[Client]                                                        [Machine 1]
   │                                                                 │
   │── UDP 53: Query A app.team1.test ──────────────────────────────>│
   │<─ UDP 53: Response A 10.7.12.181 ───────────────────────────────│
```
- **Layer 2:** Broadcast ARP request for `10.7.11.22` MAC address (if not in ARP cache).
- **Layer 3:** Source IP = `10.7.x.x`, Destination IP = `10.7.11.22`.
- **Layer 4:** UDP Source Port = Ephemeral (e.g. `54321`), Destination Port = `53`.
- **Layer 7:** Standard DNS Query (`IN A app.team1.test`).

### Phase B: TLS Connection & HTTP Request
```
[Client]                                                        [Machine 2]
   │                                                                 │
   │── TCP SYN (Port 443) ──────────────────────────────────────────>│
   │<─ TCP SYN-ACK ──────────────────────────────────────────────────│
   │── TCP ACK ─────────────────────────────────────────────────────>│
   │── TLS 1.3 Client Hello (SNI: app.team1.test) ──────────────────>│
   │<─ TLS 1.3 Server Hello + Certificate + Finished ────────────────│
   │── Encrypted Application Data (GET /api/status) ────────────────>│
```
- **Layer 3:** Source IP = Client IP, Destination IP = `10.7.12.181`.
- **Layer 4:** TCP Handshake establishes bidirectional stream with flow control and sequence numbering.
- **Layer 6 (Presentation):** TLS encryption ensures payload confidentiality and server authentication.

### Phase C: Edge Upstream Proxying
```
[Machine 2]                                                     [Machine 3 / 4]
   │                                                                 │
   │── TCP SYN (Port 3001 or 3002) ─────────────────────────────────>│
   │<─ TCP SYN-ACK ──────────────────────────────────────────────────│
   │── TCP ACK ─────────────────────────────────────────────────────>│
   │── HTTP/1.1 GET /api/status (Host: app.team1.test) ─────────────>│
   │<─ HTTP/1.1 200 OK (X-Backend: A/B, JSON body) ──────────────────│
```
- Machine 2 establishes an independent internal TCP stream to the chosen backend server.
- The request passes headers including `X-Real-IP` and `X-Forwarded-For`.
- The backend replies with HTTP 200 and custom headers.

---

## 4. Port and Firewall Configuration

To ensure seamless communication without firewall drops, the following ports must be opened across the nodes:

| Machine | Inbound Port | Protocol | Purpose | Access Restricted To |
| :--- | :--- | :--- | :--- | :--- |
| **Machine 1** | `53` | UDP & TCP | DNS Queries | All lab nodes & clients |
| **Machine 2** | `80` | TCP | HTTP Redirection | All lab nodes & clients |
| **Machine 2** | `443` | TCP | HTTPS Secure Gateway | All lab nodes & clients |
| **Machine 3** | `3001` | TCP | Backend A Service | Machine 2 (and direct test clients) |
| **Machine 4** | `3002` | TCP | Backend B Service | Machine 2 (and direct test clients) |
