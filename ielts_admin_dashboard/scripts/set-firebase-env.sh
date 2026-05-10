#!/bin/bash
# Set Firebase environment variables for production deployment
# Usage: ./scripts/set-firebase-env.sh

set -e

ENV_FILE=".env.local"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found"
  exit 1
fi

echo "=== Setting Firebase Secrets ==="
echo ""

# Load env file and set secrets
while IFS='=' read -r key value; do
  # Skip comments and empty lines
  [[ -z "$key" || "$key" =~ ^# ]] && continue

  # Only set server-side secrets (not NEXT_PUBLIC_*)
  if [[ "$key" != NEXT_PUBLIC_* ]]; then
    # Remove surrounding quotes from value
    value="${value%\"}"
    value="${value#\"}"

    echo "Setting $key..."
    firebase functions:secrets:set "$key" --value "$value" || true
  fi
done < "$ENV_FILE"

echo ""
echo "=== Done ==="
echo ""
echo "Note: NEXT_PUBLIC_* variables are embedded at build time."
echo "Make sure to run 'npm run build' after setting build-time env vars."
