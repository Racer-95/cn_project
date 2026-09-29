# Machine 2: TLS / HTTPS Certificate Setup

This directory documents the generation and configuration of TLS certificates for HTTPS termination on Machine 2 (Edge Proxy).

> **SECURITY NOTICE:**
> - Private keys (`*.key`) and certificates (`*.crt`, `*.pem`) must **NEVER** be committed to Git.
> - The root `.gitignore` is configured to exclude all key and certificate files.
> - Do not share private keys across untrusted channels.

---

## Domain Names Covered
The TLS certificate must contain Subject Alternative Names (SAN) covering both project hostnames:
1. `app.team1.test`
2. `api.team1.test`

---

## Method 1: Using `mkcert` (Recommended for Local Zero-Warning Trust)

`mkcert` creates a local Certificate Authority (CA) installed in macOS Keychain, allowing both `curl` and browsers to validate HTTPS connections without `-k` or "Insecure Certificate" warnings.

### 1. Install `mkcert`
```bash
brew install mkcert
```

### 2. Install the Local CA into System Keychain
```bash
mkcert -install
```

### 3. Generate Certificate for the Domains
Run from within `machine2-nginx/tls/` (or your chosen secure cert folder):
```bash
mkcert -cert-file team1.test.crt -key-file team1.test.key app.team1.test api.team1.test localhost 10.7.12.181 127.0.0.1
```

### 4. Deploy Certificate to nginx Directory
```bash
sudo mkdir -p /opt/homebrew/etc/nginx/certs
sudo cp team1.test.crt /opt/homebrew/etc/nginx/certs/
sudo cp team1.test.key /opt/homebrew/etc/nginx/certs/
sudo chmod 600 /opt/homebrew/etc/nginx/certs/team1.test.key
```

### 5. Export Root CA to Client Machines (Optional for trusted curl)
To make Machine 1 or Machine 4 trust the certificate without `-k`:
```bash
# Locate the root CA on Machine 2:
mkcert -CAROOT
# Transfer rootCA.pem to client machines and import:
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain rootCA.pem
```

---

## Method 2: Using Standard `openssl` (Self-Signed with SAN)

If `mkcert` is not available, standard OpenSSL can generate a self-signed multi-domain certificate.

### 1. Create OpenSSL Configuration (`openssl-san.cnf`)
```ini
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
x509_extensions    = v3_req

[dn]
C  = US
ST = State
L  = City
O  = Team1 Network Lab
OU = Course Project
CN = app.team1.test

[v3_req]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[alt_names]
DNS.1 = app.team1.test
DNS.2 = api.team1.test
IP.1  = 10.7.12.181
IP.2  = 127.0.0.1
```

### 2. Generate Key and Certificate
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout team1.test.key \
  -out team1.test.crt \
  -config openssl-san.cnf
```

### 3. Copy to nginx Certificates Directory
```bash
sudo mkdir -p /opt/homebrew/etc/nginx/certs
sudo cp team1.test.crt /opt/homebrew/etc/nginx/certs/
sudo cp team1.test.key /opt/homebrew/etc/nginx/certs/
sudo chmod 600 /opt/homebrew/etc/nginx/certs/team1.test.key
```

---

## Verifying the Certificate

Inspect certificate details, expiry, and SAN extension using OpenSSL:
```bash
openssl x509 -in /opt/homebrew/etc/nginx/certs/team1.test.crt -noout -text | grep -A 2 "Subject Alternative Name"
```

Expected Output:
```text
X509v3 Subject Alternative Name:
    DNS:app.team1.test, DNS:api.team1.test, IP Address:10.7.12.181, IP Address:127.0.0.1
```

---

## Testing TLS Handshake with OpenSSL Client

Validate handshake negotiation from a client machine:
```bash
openssl s_client -connect 10.7.12.181:443 -servername app.team1.test
```
Check:
- Protocol: `TLSv1.3` or `TLSv1.2`
- Cipher: (e.g., `TLS_AES_256_GCM_SHA384` or `ECDHE-RSA-AES128-GCM-SHA256`)
- Verify return code: `0 (ok)` (if CA trusted) or `18 (self-signed certificate)`.
