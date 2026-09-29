# Evidence: TLS Termination & HTTPS Handshake

This directory contains artifacts verifying Transport Layer Security (TLS) configuration and handshake termination at Machine 2 (`10.7.12.181`).

---

## Required Artifacts Checklist

- [ ] **Artifact 1:** `tls-handshake.pcapng`
  - Wireshark capture of an HTTPS request to `https://app.team1.test/api/status`.
  - Must clearly show:
    1. **Client Hello**: Demonstrating Server Name Indication (SNI) extension containing `app.team1.test`.
    2. **Server Hello**: Demonstrating negotiated protocol (`TLSv1.2` or `TLSv1.3`) and selected cipher suite.
    3. **Certificate**: Showing the server certificate with Subject Alternative Names (`app.team1.test`, `api.team1.test`).
    4. **Encrypted Application Data**: Demonstrating that HTTP request payloads are completely ciphertext on the wire.
- [ ] **Artifact 2:** `tls-sni-client-hello.png`
  - Screenshot of Wireshark highlighting the SNI field under `Transport Layer Security > Handshake Protocol: Client Hello > Extension: server_name`.
- [ ] **Artifact 3:** `tls-certificate-details.png`
  - Screenshot showing certificate SAN extension and validity.
- [ ] **Artifact 4:** `openssl-sclient-verify.txt`
  - Output log of:
    ```bash
    openssl s_client -connect 10.7.12.181:443 -servername app.team1.test -showcerts
    ```

---

## Wireshark Filters for TLS Verification

### Display Filter:
```wireshark
tls.handshake.type == 1 || tls.handshake.type == 2 || tls.handshake.type == 11
```

### Display Filter for SNI:
```wireshark
tls.handshake.extensions_server_name == "app.team1.test"
```
