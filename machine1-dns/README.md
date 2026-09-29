# Machine 1: Private DNS Server (`dnsmasq`) & Test Client

Machine 1 acts as the **authoritative private DNS server** for the `.test` top-level domain on our isolated course project network. It also serves as a designated **Test Client** to validate end-to-end DNS queries, TCP handshakes, TLS handshakes, and HTTP traffic.

---

## Machine Specification

| Parameter | Value |
| :--- | :--- |
| **Role** | Authoritative Private DNS Server & Test Client |
| **Assigned IP (Example)** | `10.7.11.22` |
| **Port** | `53` (UDP/TCP) |
| **Software** | `dnsmasq` via Homebrew on macOS |
| **Mapped Domains** | `app.team1.test` → `10.7.12.181` (Machine 2)<br>`api.team1.test` → `10.7.12.181` (Machine 2) |

---

## Installation & Setup on macOS

### 1. Install `dnsmasq`
Using Homebrew:
```bash
brew install dnsmasq
```

### 2. Locate Active Network Interface and IP
Find the active interface and its IP address on macOS:
```bash
ifconfig en0 | grep "inet "
# Or list all active interfaces:
networksetup -listallhardwareports
```
Ensure your interface name matches `interface=en0` and `listen-address=127.0.0.1,<your-ip>` in the config file.

### 3. Deploy Configuration
Copy the provided example configuration to dnsmasq's configuration directory:

- **Apple Silicon (M1/M2/M3):**
  ```bash
  sudo cp dnsmasq.conf.example /opt/homebrew/etc/dnsmasq.conf
  ```
- **Intel Mac:**
  ```bash
  sudo cp dnsmasq.conf.example /usr/local/etc/dnsmasq.conf
  ```

Ensure the configuration file permissions are correct:
```bash
sudo chmod 644 /opt/homebrew/etc/dnsmasq.conf
```

### 4. Start dnsmasq Service
DNS operates on privileged port **53**, so root privileges (`sudo`) are required:

```bash
# Start dnsmasq via Homebrew services with sudo
sudo brew services start dnsmasq

# Or run directly in foreground for debugging and live packet capture:
sudo dnsmasq --no-daemon -C /opt/homebrew/etc/dnsmasq.conf
```

To stop or restart:
```bash
sudo brew services restart dnsmasq
sudo brew services stop dnsmasq
```

---

## Configuring Client Machines to Use Machine 1

To direct other machines (Machine 2, Machine 3, Machine 4, or client laptops) to resolve `.test` domains using Machine 1:

### Option A: Set macOS DNS Resolver (System Preferences / CLI)
Run on the client machine:
```bash
# Find your network service name (e.g., "Wi-Fi" or "Ethernet")
networksetup -listallnetworkservices

# Set DNS server to Machine 1 IP (e.g., 10.7.11.22)
sudo networksetup -setdnsservers "Wi-Fi" 10.7.11.22
```

### Option B: macOS Domain-Specific Resolver Directory
macOS supports resolver files in `/etc/resolver/` to route only specific domains to a custom nameserver without altering global internet DNS:
```bash
sudo mkdir -p /etc/resolver
sudo tee /etc/resolver/test > /dev/null <<EOF
nameserver 10.7.11.22
port 53
EOF
```
Now, any query ending in `.test` (such as `app.team1.test`) is sent directly to `10.7.11.22`.

---

## Verification & Testing

### 1. Test Locally on Machine 1
```bash
dig @127.0.0.1 app.team1.test +noall +answer
dig @127.0.0.1 api.team1.test +noall +answer
```

Expected Output:
```text
app.team1.test.     0   IN  A   10.7.12.181
api.team1.test.     0   IN  A   10.7.12.181
```

### 2. Test Remotely from Another Machine (Machine 2, 3, or 4)
```bash
dig @10.7.11.22 app.team1.test
```

### 3. Verify PTR (Reverse DNS) Lookup
```bash
dig @10.7.11.22 -x 10.7.12.181 +short
# Expected output: app.team1.test.
```

---

## Troubleshooting

- **Port 53 already in use:**
  On macOS, `mDNSResponder` or another instance of `dnsmasq` might be bound to port 53.
  ```bash
  sudo lsof -i :53
  ```
  Kill any rogue process or stop previous instances: `sudo killall dnsmasq`.
- **Query Refused or Timed Out:**
  Verify that `listen-address` in `dnsmasq.conf` contains the machine's actual LAN IP (`10.7.11.22`) and not just `127.0.0.1`.
- **macOS Firewall Blocking UDP 53:**
  Check Firewall status in `System Settings > Network > Firewall` or disable temporarily for testing.
