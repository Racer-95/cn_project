# Evidence: Private DNS Resolution

This directory contains verification artifacts confirming that Machine 1 (`dnsmasq` @ `10.7.11.22`) authoritatively resolves the `.test` domain names to Machine 2 (`10.7.12.181`).

---

## Required Artifacts Checklist

- [ ] **Artifact 1:** `dns-query-terminal.txt` (or `.png`)
  - Terminal output from running `dig @10.7.11.22 app.team1.test` and `dig @10.7.11.22 api.team1.test`.
  - Must show: `status: NOERROR`, `ANSWER SECTION: app.team1.test. 0 IN A 10.7.12.181`, Query time, Server IP.
- [ ] **Artifact 2:** `dns-wireshark-capture.pcapng`
  - Wireshark capture of UDP port 53 traffic between Client (e.g. `10.7.11.22` or `10.7.11.17`) and DNS Server.
- [ ] **Artifact 3:** `dns-packet-details.png`
  - Screenshot of Wireshark showing:
    - DNS Query packet (`Standard query 0x... A app.team1.test`).
    - DNS Response packet (`Standard query response 0x... A app.team1.test A 10.7.12.181`).
- [ ] **Artifact 4:** `dnsmasq-service.log`
  - Excerpt from `/var/log/dnsmasq.log` showing query receipt and resolution:
    ```text
    dnsmasq[...]: query[A] app.team1.test from 10.7.11.17
    dnsmasq[...]: config app.team1.test is 10.7.12.181
    ```

---

## How to Capture This Evidence

### Step 1: Capture Terminal Query
```bash
dig @10.7.11.22 app.team1.test > evidence/dns/dns-query-terminal.txt
dig @10.7.11.22 api.team1.test >> evidence/dns/dns-query-terminal.txt
```

### Step 2: Wireshark Display Filter
Filter for DNS packets during capture:
```wireshark
udp.port == 53 && (ip.src == 10.7.11.22 || ip.dst == 10.7.11.22)
```
