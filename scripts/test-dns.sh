#!/usr/bin/env bash
# ==============================================================================
# Script: test-dns.sh
# Purpose: Validates authoritative DNS resolution for app.team1.test & api.team1.test
# Usage: ./test-dns.sh [DNS_SERVER_IP]
# ==============================================================================

set -euo pipefail

# Configurable Parameters (Override via argument or environment variable)
DNS_SERVER="${1:-${DNS_SERVER_IP:-10.7.11.22}}"
EXPECTED_IP="${EXPECTED_RESOLVED_IP:-10.7.12.181}"
DOMAINS=("app.team1.test" "api.team1.test")

# Terminal Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE} DNS Resolution Verification Test${NC}"
echo -e "${BLUE} Target DNS Server : ${YELLOW}${DNS_SERVER}:53${NC}"
echo -e "${BLUE} Expected Answer   : ${YELLOW}${EXPECTED_IP}${NC}"
echo -e "${BLUE}====================================================${NC}"

# Check for dig utility
if ! command -v dig &> /dev/null; then
  echo -e "${RED}[ERROR] 'dig' command not found. Please install dnsutils or bind-utils.${NC}"
  exit 1
fi

TOTAL_TESTS=0
PASSED_TESTS=0

for DOMAIN in "${DOMAINS[@]}"; do
  ((TOTAL_TESTS++))
  echo -e "\n[Testing] Querying A record for: ${YELLOW}${DOMAIN}${NC} via @${DNS_SERVER}..."

  # Query DNS server directly
  RESPONSE=$(dig @"${DNS_SERVER}" "${DOMAIN}" +short +time=2 +tries=2 || true)

  if [ -z "${RESPONSE}" ]; then
    echo -e "${RED}[FAILED] No response received from DNS server ${DNS_SERVER} for ${DOMAIN}.${NC}"
    echo -e "${YELLOW}Hint: Verify Machine 1 (dnsmasq) is running: 'sudo brew services list' or 'sudo lsof -i :53'.${NC}"
    continue
  fi

  echo -e "  Resolved Address: ${RESPONSE}"

  # Verify if resolved IP matches expected IP
  if echo "${RESPONSE}" | grep -q "${EXPECTED_IP}"; then
    echo -e "${GREEN}[PASS] ${DOMAIN} successfully resolved to ${EXPECTED_IP}.${NC}"
    ((PASSED_TESTS++))
  else
    echo -e "${RED}[MISMATCH] ${DOMAIN} resolved to '${RESPONSE}', expected '${EXPECTED_IP}'.${NC}"
  fi
done

echo -e "\n${BLUE}====================================================${NC}"
if [ "${PASSED_TESTS}" -eq "${TOTAL_TESTS}" ]; then
  echo -e "${GREEN} ALL DNS TESTS PASSED (${PASSED_TESTS}/${TOTAL_TESTS})${NC}"
  echo -e "${BLUE}====================================================${NC}"
  exit 0
else
  echo -e "${RED} SOME DNS TESTS FAILED (${PASSED_TESTS}/${TOTAL_TESTS})${NC}"
  echo -e "${BLUE}====================================================${NC}"
  exit 1
fi
