#!/usr/bin/env ts-node
/**
 * Set Firebase environment variables for production deployment.
 *
 * Usage:
 *   npx ts-node scripts/set-firebase-env.ts
 *
 * This script reads from .env.local and sets Firebase Hosting secrets.
 * Secrets are available to server-side API routes at runtime.
 */

import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';

const envPath = path.join(__dirname, '..', '.env.local');

function loadEnvFile(filePath: string): Record<string, string> {
  const content = fs.readFileSync(filePath, 'utf-8');
  const env: Record<string, string> = {};

  for (const line of content.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;

    const match = trimmed.match(/^([^=]+)=(.*)$/);
    if (match) {
      let [, key, value] = match;
      // Remove surrounding quotes
      value = value.replace(/^["']|["']$/g, '');
      env[key.trim()] = value;
    }
  }

  return env;
}

function setFirebaseSecret(key: string, value: string): void {
  try {
    // Use firebase functions:secrets:set command
    execSync(`firebase functions:secrets:set ${key} --value "${value.replace(/"/g, '\\"')}`, {
      stdio: 'pipe',
    });
  } catch (error: any) {
    console.error(`Failed to set secret ${key}:`, error.message);
  }
}

async function main() {
  console.log('Loading environment from:', envPath);

  if (!fs.existsSync(envPath)) {
    console.error('Error: .env.local not found');
    process.exit(1);
  }

  const env = loadEnvFile(envPath);

  // Server-side secrets (not NEXT_PUBLIC_*)
  const secrets = {
    FIREBASE_ADMIN_PROJECT_ID: env.FIREBASE_ADMIN_PROJECT_ID,
    FIREBASE_ADMIN_CLIENT_EMAIL: env.FIREBASE_ADMIN_CLIENT_EMAIL,
    FIREBASE_ADMIN_PRIVATE_KEY: env.FIREBASE_ADMIN_PRIVATE_KEY,
    OPENROUTER_API_KEY: env.OPENROUTER_API_KEY,
  };

  console.log('\n=== Setting Firebase Secrets ===\n');

  for (const [key, value] of Object.entries(secrets)) {
    if (value) {
      console.log(`Setting ${key}...`);
      setFirebaseSecret(key, value);
    } else {
      console.warn(`Skipping ${key}: value is empty`);
    }
  }

  console.log('\n=== Done ===\n');
  console.log('Note: NEXT_PUBLIC_* variables are set at build time.');
  console.log('To set build-time env vars, use: firebase hosting:channel:deploy with env file');
}

main().catch(console.error);
