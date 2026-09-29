#!/usr/bin/env bash
# ==============================================================================
# Script: test-backend-b.sh
# Purpose: Directly tests Backend Server B (Machine 4) health and identity
# Usage: ./test-backend-b.sh [BACKEND_B_HOST] [PORT]
# ==============================================================================

set -euo pipefail

# Configuration
TARGET_HOST="${1:-${BACKEND_B_HOST:-10.7.11.17}}"
TARGET_PORT="${2:-${BACKEND_B_PORT:-3002}}"
ENDPOINT="http://${TARGET_HOST}:${TARGET_PORT}/api/status"

# Terminal Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE} Direct Verification: Backend Server B${NC}"
echo -e "${BLUE} Target URL: ${YELLOW}${ENDPOINT}${NC}"
echo -e "${BLUE}====================================================${NC}"

# Check for curl
if ! command -v curl &> /dev/null; then
  echo -e "${RED}[ERROR] 'curl' command not found.${NC}"
  exit 1
fi

TEMP_HEADERS=$(mktemp)
TEMP_BODY=$(mktemp)
trap 'rm -f "${TEMP_HEADERS}" "${TEMP_BODY}"' EXIT

HTTP_CODE=$(curl -s -S -w "%{http_code}" -o "${TEMP_BODY}" -D "${TEMP_HEADERS}" --connect-timeout 4 "${ENDPOINT}" || echo "000")

echo -e "HTTP Status Code : ${HTTP_CODE}"
echo -e "\nResponse Headers :"
cat "${TEMP_HEADERS}" | grep -E -i "HTTP/|Content-Type|X-Backend|Date" || true

echo -e "\nResponse Body    :"
cat "${TEMP_BODY}"
echo ""

# Validation
X_BACKEND=$(grep -i "^X-Backend:" "${TEMP_HEADERS}" | tr -d '\r\n' | awk '{print $2}' || true)

if [ "${HTTP_CODE}" -eq 200 ] && [ "${X_BACKEND}" = "B" ] && grep -q '"backend":[[:space:]]*"B"' "${TEMP_BODY}"; then
  echo -e "${GREEN}====================================================${NC}"
  echo -e "${GREEN}[PASS] Backend Server B verified successfully!${NC}"
  echo -e "${GREEN}       Received HTTP 200, Header X-Backend: B, JSON status: ok${NC}"
  echo -e "${GREEN}====================================================${NC}"
  exit 0
else
  echo -e "${RED}====================================================${NC}"
  echo -e "${RED}[FAIL] Backend Server B verification failed.${NC}"
  echo -e "${YELLOW}Hint: Verify Machine 4 is online and 'node server.js' is running on port ${TARGET_PORT}.${NC}"
  echo -e "${RED}====================================================${NC}"
  exit 1
fi
