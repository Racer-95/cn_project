# Evidence: TCP Handshake & Connection Analysis

This directory stores network evidence demonstrating the underlying Layer 4 TCP connection dynamics across the two hops of our private architecture:
1. **Hop 1:** Client ↔ Machine 2 Edge Proxy (Port 443 / Port 80)
2. **Hop 2:** Machine 2 Edge Proxy ↔ Backend Server A / B (Port 3001 / 3002)

---

## Required Artifacts Checklist

- [ ] **Artifact 1:** `tcp-3way-handshake.pcapng`
  - Raw packet capture demonstrating complete 3-way handshakes:
    - Packet 1: `[SYN]` Client → Edge (`Seq=0`)
    - Packet 2: `[SYN, ACK]` Edge → Client (`Seq=0, Ack=1`)
    - Packet 3: `[ACK]` Client → Edge (`Seq=1, Ack=1`)
- [ ] **Artifact 2:** `tcp-handshake-screenshot.png`
  - Annotated screenshot of Wireshark showing TCP flags: `SYN`, `ACK`, Window Size, and MSS negotiation.
- [ ] **Artifact 3:** `tcp-flow-graph.png`
  - Wireshark TCP Flow Graph (`Statistics > Flow Graph > TCP Flow`) illustrating end-to-end packet transmission and connection closure (`FIN, ACK`).

---

## Recommended Wireshark Filters

### Capture Filter (Edge Proxy)
```wireshark
tcp port 443 or tcp port 80
```

### Display Filter (Handshake Only)
```wireshark
tcp.flags.syn == 1
```

### Display Filter (Full Flow with Edge Proxy IP)
```wireshark
ip.addr == 10.7.12.181 && tcp.port == 443
```
