#!/usr/bin/env bash
# ==============================================================================
# Script: test-load-balancing.sh
# Purpose: Demonstrates round-robin load balancing across Backend A and Backend B
#          by sending sequential HTTPS requests through the nginx Edge Proxy.
# Usage: ./test-load-balancing.sh [NUM_REQUESTS] [TARGET_URL]
# ==============================================================================

set -euo pipefail

# Configuration
NUM_REQUESTS="${1:-${REQUEST_COUNT:-10}}"
TARGET_URL="${2:-${EDGE_URL:-https://app.team1.test/api/status}}"
EDGE_IP="${EDGE_PROXY_IP:-10.7.12.181}"

# Terminal Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE} nginx Layer 7 Load Balancing Verification${NC}"
echo -e "${BLUE} Target URL        : ${YELLOW}${TARGET_URL}${NC}"
echo -e "${BLUE} Requests to send  : ${YELLOW}${NUM_REQUESTS}${NC}"
echo -e "${BLUE} Insecure SSL (-k) : ${YELLOW}Enabled (for self-signed/lab certs)${NC}"
echo -e "${BLUE}================================================================${NC}"

# Check for curl
if ! command -v curl &> /dev/null; then
  echo -e "${RED}[ERROR] 'curl' command not found.${NC}"
  exit 1
fi

COUNT_A=0
COUNT_B=0
COUNT_FAIL=0

printf "\n%-8s | %-12s | %-15s | %-12s | %-10s\n" "Req #" "HTTP Code" "X-Backend" "Upstream" "Result"
echo "----------------------------------------------------------------"

for ((i=1; i<=NUM_REQUESTS; i++)); do
  HEADER_FILE=$(mktemp)
  BODY_FILE=$(mktemp)

  # Execute request: resolve app.team1.test to EDGE_IP if DNS is not globally configured
  HTTP_CODE=$(curl -k -s -S -w "%{http_code}" \
    --resolve "app.team1.test:443:${EDGE_IP}" \
    --resolve "api.team1.test:443:${EDGE_IP}" \
    -o "${BODY_FILE}" \
    -D "${HEADER_FILE}" \
    --connect-timeout 3 \
    "${TARGET_URL}" || echo "000")

  X_BACKEND=$(grep -i "^X-Backend:" "${HEADER_FILE}" | tr -d '\r\n' | awk '{print $2}' || true)
  X_SERVED_BY=$(grep -i "^X-Served-By:" "${HEADER_FILE}" | tr -d '\r\n' | awk '{print $2}' || true)

  rm -f "${HEADER_FILE}" "${BODY_FILE}"

  if [ "${HTTP_CODE}" -eq 200 ]; then
    if [ "${X_BACKEND}" = "A" ]; then
      ((COUNT_A++))
      STATUS_COLOR="${GREEN}Backend A${NC}"
      RESULT_TEXT="${GREEN}OK${NC}"
    elif [ "${X_BACKEND}" = "B" ]; then
      ((COUNT_B++))
      STATUS_COLOR="${CYAN}Backend B${NC}"
      RESULT_TEXT="${CYAN}OK${NC}"
    else
      ((COUNT_FAIL++))
      STATUS_COLOR="${YELLOW}Unknown (${X_BACKEND})${NC}"
      RESULT_TEXT="${YELLOW}WARN${NC}"
    fi
  else
    ((COUNT_FAIL++))
    STATUS_COLOR="${RED}N/A${NC}"
    RESULT_TEXT="${RED}ERR (${HTTP_CODE})${NC}"
  fi

  printf "%-8d | %-12s | %-24b | %-12s | %-10b\n" "$i" "$HTTP_CODE" "$STATUS_COLOR" "${X_SERVED_BY:-nginx-edge}" "$RESULT_TEXT"
  sleep 0.2
done

echo "----------------------------------------------------------------"
echo -e "\n${BLUE}===================== Traffic Summary ==========================${NC}"
echo -e " Total Requests Sent  : ${NUM_REQUESTS}"
echo -e " Routed to Backend A  : ${GREEN}${COUNT_A}${NC} ($(( COUNT_A * 100 / NUM_REQUESTS ))%)"
echo -e " Routed to Backend B  : ${CYAN}${COUNT_B}${NC} ($(( COUNT_B * 100 / NUM_REQUESTS ))%)"
echo -e " Failed Requests      : ${RED}${COUNT_FAIL}${NC}"
echo -e "${BLUE}================================================================${NC}"

if [ "${COUNT_A}" -gt 0 ] && [ "${COUNT_B}" -gt 0 ] && [ "${COUNT_FAIL}" -eq 0 ]; then
  echo -e "${GREEN}[SUCCESS] Load balancing verified! Requests distributed across both backends.${NC}\n"
  exit 0
else
  echo -e "${RED}[WARNING] Traffic was not distributed evenly across both backends.${NC}"
  echo -e "${YELLOW}Hint: Ensure both Backend A and Backend B processes are running and reachable by nginx.${NC}\n"
  exit 1
fi
