# Lab Evidence & Verification Directory

This directory serves as the centralized repository for evaluation evidence, Wireshark packet captures (`.pcapng` / `.pcap`), command terminal outputs, and screenshot artifacts for the **Private Network Service Platform** project.

> **ACADEMIC HONESTY NOTICE:**
> In accordance with course guidelines, **no synthetic or fabricated evidence is stored in this repository**.
> Follow the guidelines in each subfolder below to capture, name, and archive genuine packet captures, log excerpts, and terminal outputs from the live 4-machine network deployment.

---

## Directory Index & Evidence Matrix

| Category | Folder Path | Required Artifacts | Key Protocol Filters / Indicators |
| :--- | :--- | :--- | :--- |
| **DNS Resolution** | [`evidence/dns/`](dns/README.md) | `dig` outputs, Wireshark `.pcapng` | `udp.port == 53`, `dns.flags.response == 1`, Query for `app.team1.test` |
| **TCP Handshake** | [`evidence/tcp/`](tcp/README.md) | Wireshark `.pcapng`, sequence charts | `tcp.flags.syn == 1`, 3-way handshake (SYN, SYN-ACK, ACK), 4-way teardown |
| **TLS Termination** | [`evidence/tls/`](tls/README.md) | Wireshark `.pcapng`, `openssl s_client` logs | `tls.handshake.type == 1` (Client Hello), Server Hello, Certificate, SNI |
| **Load Balancing** | [`evidence/load-balancing/`](load-balancing/README.md) | Test script logs, dual-stream packet capture | Alternating `X-Backend: A` / `X-Backend: B`, packets to `10.7.3.22` & `10.7.11.17` |
| **HTTP Caching** | [`evidence/caching/`](caching/README.md) | HTTP response logs, Wireshark capture | `Cache-Control: max-age=60`, `X-Cache-Status: MISS` vs `HIT`, 304 Not Modified |

---

## Wireshark Capture Instructions

1. **Selecting the Interface:**
   - On macOS, open Wireshark and capture on interface `en0` (or `any` if analyzing multi-interface routing).
2. **Applying Capture Filters (Pre-Capture):**
   - DNS: `udp port 53`
   - Edge HTTPS: `tcp port 443 or tcp port 80`
   - Backend Traffic: `tcp port 3001 or tcp port 3002`
3. **Saving Captures:**
   - Save captures in standard PCAP Next Generation format (`.pcapng`).
   - Use standardized filenames: `[category]-capture-[machine].pcapng` (e.g., `dns-resolution-machine1.pcapng`).
4. **Capturing Screenshots:**
   - Include the Wireshark packet details pane highlighting protocol fields.
   - Save screenshots in PNG format (`.png`).
