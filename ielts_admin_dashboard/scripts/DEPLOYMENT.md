# Firebase Deployment with Environment Variables

## Problem

After deploying to Firebase Hosting, API keys configured in the admin panel are not persisted. This happens because:

1. **Build-time variables** (`NEXT_PUBLIC_*`) are embedded during `npm run build`
2. **Runtime variables** (server-side secrets) must be set via Firebase Secrets

## Solution

### Option 1: Quick Deploy (Recommended)

Use the deployment script which handles both build-time and runtime variables:

**Windows:**
```bash
scripts\deploy.bat
```

**Unix/Mac:**
```bash
./scripts/deploy.sh
```

### Option 2: Manual Setup

#### Step 1: Set Runtime Secrets

Run this command to set all server-side secrets:

```bash
# From .env.local values
firebase functions:secrets:set FIREBASE_ADMIN_PROJECT_ID
firebase functions:secrets:set FIREBASE_ADMIN_CLIENT_EMAIL
firebase functions:secrets:set FIREBASE_ADMIN_PRIVATE_KEY
firebase functions:secrets:set OPENROUTER_API_KEY
```

Or use the setup script:
```bash
# Windows
scripts\set-firebase-env.bat

# Unix/Mac
./scripts/set-firebase-env.sh
```

#### Step 2: Build with Environment Variables

```bash
# Load NEXT_PUBLIC_* variables and build
export $(grep "^NEXT_PUBLIC_" .env.local | xargs)
npm run build
```

**Windows PowerShell:**
```powershell
Get-Content .env.local | ForEach-Object { if ($_ -match '^NEXT_PUBLIC_') { iex $_ } }
npm run build
```

#### Step 3: Deploy

```bash
firebase deploy --only hosting
```

## Verify Deployment

After deployment, check the Firebase Console:

1. Go to **Firebase Console** → **Functions** → **Secrets**
2. Verify all secrets are set:
   - `FIREBASE_ADMIN_PROJECT_ID`
   - `FIREBASE_ADMIN_CLIENT_EMAIL`
   - `FIREBASE_ADMIN_PRIVATE_KEY`
   - `OPENROUTER_API_KEY`

## Debugging

If API keys still don't persist after deployment:

1. **Check Logs**: Go to Firebase Console → Functions → Logs
2. Look for `[ai-config] Failed to init admin DB` errors
3. Check if environment variables are set correctly

## Environment Variables Reference

| Variable | Type | When Used |
|----------|------|-----------|
| `NEXT_PUBLIC_FIREBASE_API_KEY` | Build | Client-side Firebase init |
| `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` | Build | Client-side Firebase init |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | Build | Client-side Firebase init |
| `FIREBASE_ADMIN_PROJECT_ID` | Runtime | Server-side Admin SDK |
| `FIREBASE_ADMIN_CLIENT_EMAIL` | Runtime | Server-side Admin SDK |
| `FIREBASE_ADMIN_PRIVATE_KEY` | Runtime | Server-side Admin SDK |

## Security Notes

- Never commit `.env.local` to git
- Secrets are encrypted at rest in Firebase
- Only admin users can view/set secrets
- Rotate keys periodically
