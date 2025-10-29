#!/bin/bash

# Script to check wallet balance using JSON-RPC
# Requires: curl, jq
# Environment: GLIF_TOKEN (required) - API token for authentication
# Usage: GLIF_TOKEN=<token> wallet-balance.sh <network> <wallet_address>
# Example: GLIF_TOKEN=your_token wallet-balance.sh calibration 0xb649bb54c5006103c08c183f36b335ee20b7829b

set -euo pipefail

# Check required environment variables
GLIF_TOKEN="${GLIF_TOKEN:?Missing GLIF_TOKEN environment variable}"

ENVIRONMENT="${1:?Missing ENVIRONMENT argument (calibration or mainnet)}"
WALLET_ADDRESS="${2:?Missing WALLET_ADDRESS argument}"

if [[ -n "${RPC_URL:-}" ]]; then
  RPC_URL="${RPC_URL}"
elif [[ "$ENVIRONMENT" == "calibration" ]]; then
  RPC_URL="https://api.calibration.node.glif.io/rpc/v1"
else
  RPC_URL="https://api.node.glif.io/rpc/v1"
fi

BALANCE_HEX=$(curl -sS -X POST "$RPC_URL" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer ${GLIF_TOKEN}" \
  --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$WALLET_ADDRESS\",\"latest\"],\"id\":1}" \
  | jq -r '.result // "0x0"')

BALANCE=$(printf "%d" "$BALANCE_HEX")

MEASUREMENT="wallet_balance"
TAGS="environment=${ENVIRONMENT},address=${WALLET_ADDRESS}"
FIELDS="balance=${BALANCE}i"

printf '%s,%s %s\n' "$MEASUREMENT" "$TAGS" "$FIELDS"
