#!/bin/bash

# Script to check Filecoin wallet balance using JSON-RPC
# Usage: wallet-balance.sh <environment> <wallet_address>
# Example: wallet-balance.sh calibration t410fnasgpvm7kz44wc7rgek5jskfkc4cddhskqqkh6i

set -euo pipefail

ENVIRONMENT="${1:?Missing ENVIRONMENT argument (calibration or mainnet)}"
WALLET_ADDRESS="${2:?Missing WALLET_ADDRESS argument}"

IS_ETH_ADDRESS=false
if [[ "$WALLET_ADDRESS" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
  IS_ETH_ADDRESS=true
fi

# Set JSON-RPC URL based on network (can be overridden by RPC_URL environment variable)
if [[ -n "${RPC_URL:-}" ]]; then
  # Use the provided RPC_URL environment variable
  RPC_URL="${RPC_URL}"
elif [[ "$ENVIRONMENT" == "calibration" ]]; then
  RPC_URL="https://api.calibration.node.glif.io/rpc/v1"
else
  RPC_URL="https://api.node.glif.io/rpc/v1"
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if [[ "$IS_ETH_ADDRESS" == "true" ]]; then
  # For Ethereum addresses, use eth_getBalance method
  JSON_REQUEST=$(cat <<EOF
{
  "jsonrpc": "2.0",
  "method": "eth_getBalance",
  "params": ["$WALLET_ADDRESS", "latest"],
  "id": 1
}
EOF
)
else
  # For Filecoin addresses, use Filecoin.WalletBalance method
  JSON_REQUEST=$(cat <<EOF
{
  "jsonrpc": "2.0",
  "method": "Filecoin.WalletBalance",
  "params": ["$WALLET_ADDRESS"],
  "id": 1
}
EOF
)
fi

curl -sS -o "$tmp" \
  -X POST "$RPC_URL" \
  -H 'Content-Type: application/json' \
  --data "$JSON_REQUEST"

if [[ "$IS_ETH_ADDRESS" == "true" ]]; then
  BALANCE_HEX=$(jq -r '.result // "0x0"' "$tmp")
  BALANCE_ATTO=$(printf "%d" "$BALANCE_HEX")
else
  BALANCE_ATTO=$(jq -r '.result // "0"' "$tmp")
fi

MEASUREMENT="wallet_balance"
TAGS="environment=${ENVIRONMENT},address=${WALLET_ADDRESS}"
FIELDS="balance=${BALANCE_ATTO}i"

printf '%s,%s %s\n' "$MEASUREMENT" "$TAGS" "$FIELDS"
