#!/bin/bash
# Deploy to Firebase Hosting with environment variables
# Usage: ./scripts/deploy.sh

set -e

echo "=== Deploying to Firebase Hosting ==="
echo ""

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
  echo "Error: .env.local not found"
  exit 1
fi

# Create .env file for Firebase deployment (build-time variables)
echo "Creating .env for build-time environment variables..."
grep "^NEXT_PUBLIC_" .env.local > .env 2>/dev/null || true

# Set Firebase secrets (runtime variables)
echo ""
echo "Setting Firebase secrets..."

# Load and set secrets
while IFS='=' read -r key value; do
  # Skip comments, empty lines, and NEXT_PUBLIC_* variables
  [[ -z "$key" || "$key" =~ ^# || "$key" == NEXT_PUBLIC_* ]] && continue

  # Remove surrounding quotes from value
  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"

  if [ -n "$value" ]; then
    echo "  Setting $key..."
    firebase functions:secrets:set "$key" --value "$value" --quiet || true
  fi
done < ".env.local"

# Build the Next.js app with environment variables
echo ""
echo "Building Next.js app..."
export $(grep "^NEXT_PUBLIC_" .env.local | xargs)
npm run build

# Deploy to Firebase
echo ""
echo "Deploying to Firebase Hosting..."
firebase deploy --only hosting

# Cleanup
rm -f .env

echo ""
echo "=== Deployment Complete ==="
