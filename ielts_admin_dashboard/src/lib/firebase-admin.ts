// Firebase Admin SDK — fully lazy-loaded with Turbopack-safe imports
//
// CRITICAL: Turbopack (Next.js 16 default bundler) mangles package names in
// dynamic imports, e.g. 'firebase-admin/auth' → 'firebase-admin-a14c8a5423a75469/auth'.
// This breaks at runtime in Cloud Functions because the mangled package doesn't exist.
//
// FIX: We use computed template-literal imports (`${pkg}/auth`) which Turbopack
// cannot statically analyse, so it leaves them as runtime imports untouched.
// All firebase-admin access is centralised here — no other file should import
// from 'firebase-admin/*' directly.

const _pkg = 'firebase-admin';

let adminApp: any;
let adminDb: any;

async function getAdminApp() {
  if (adminApp) return adminApp;

  // Turbopack-safe dynamic import — the template literal prevents name-mangling
  const { initializeApp, getApps, cert } =
    await import(/* webpackIgnore: true */ `${_pkg}/app`);

  // Check all apps — return any existing admin-named or default app
  const existing = getApps();
  const existingAdminApp = existing.find((c: any) => c.name === 'admin');
  if (existingAdminApp) {
    adminApp = existingAdminApp;
    return adminApp;
  }

  const projectId = process.env.FB_ADMIN_PROJECT_ID || 'speakup-ai-prod';
  const privateKey = process.env.FB_ADMIN_PRIVATE_KEY;
  const clientEmail = process.env.FB_ADMIN_CLIENT_EMAIL;

  if (privateKey && clientEmail) {
    // ── Local development ──────────────────────────────────────────────────
    // Explicit service-account cert from .env.local
    console.log('[firebase-admin] Initializing with explicit cert (local dev)');
    adminApp = initializeApp(
      {
        credential: cert({
          projectId,
          clientEmail,
          privateKey: privateKey.replace(/\\n/g, '\n'),
        }),
      },
      'admin',
    );
  } else {
    // ── Production (Firebase Hosting / Cloud Functions) ─────────────────────
    // initializeApp() without args auto-discovers credentials from the
    // GCP metadata server or FIREBASE_CONFIG env var.
    const defaultApp = existing.find((c: any) => c.name === '[DEFAULT]');
    if (defaultApp) {
      console.log('[firebase-admin] Default app exists in production, reusing it');
      adminApp = defaultApp;
    } else {
      console.log('[firebase-admin] Creating default app (production auto-discovery)');
      adminApp = initializeApp();
    }
  }

  return adminApp;
}

async function getAdminDb() {
  if (adminDb) return adminDb;

  const app = await getAdminApp();
  const { getFirestore } = await import(/* webpackIgnore: true */ `${_pkg}/firestore`);
  adminDb = getFirestore(app);
  return adminDb;
}

// ── Re-exported helpers ────────────────────────────────────────────────────
// These let other files use firebase-admin sub-packages without importing
// 'firebase-admin/*' directly (which Turbopack would mangle).

async function getAdminAuth() {
  const app = await getAdminApp();
  const { getAuth } = await import(/* webpackIgnore: true */ `${_pkg}/auth`);
  return getAuth(app);
}

async function getFieldValue() {
  const mod = await import(/* webpackIgnore: true */ `${_pkg}/firestore`);
  return mod.FieldValue;
}

export { getAdminApp, getAdminDb, getAdminAuth, getFieldValue };
