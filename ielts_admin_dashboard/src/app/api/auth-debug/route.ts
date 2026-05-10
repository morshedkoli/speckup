export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';

/**
 * GET /api/auth-debug
 * 
 * Returns diagnostic info about the Firebase Admin SDK initialization
 * and token verification without actually requiring a valid session.
 * This helps debug "Invalid admin session" errors in production.
 * 
 * IMPORTANT: This endpoint does NOT expose any secrets — only diagnostic info.
 */
export async function GET(request: Request) {
  const diagnostics: Record<string, any> = {
    timestamp: new Date().toISOString(),
    env: {
      hasPrivateKey: !!process.env.FB_ADMIN_PRIVATE_KEY,
      hasClientEmail: !!process.env.FB_ADMIN_CLIENT_EMAIL,
      hasProjectId: !!process.env.FB_ADMIN_PROJECT_ID,
      projectId: process.env.FB_ADMIN_PROJECT_ID || '(not set)',
      hasFirebaseDefaults: !!process.env.__FIREBASE_DEFAULTS__,
      nodeEnv: process.env.NODE_ENV,
    },
    adminSdk: { initialized: false, appName: null, error: null },
    tokenVerification: { attempted: false, result: null, error: null },
  };

  // Step 1: Try initializing the Admin SDK
  try {
    const { getAdminApp } = await import('@/lib/firebase-admin');
    const app = await getAdminApp();
    diagnostics.adminSdk.initialized = true;
    diagnostics.adminSdk.appName = app.name;
    diagnostics.adminSdk.projectId = app.options?.projectId || '(unknown)';

    // Step 2: If there's a token, try verifying it
    const authorization = request.headers.get('authorization');
    const token = authorization?.match(/^Bearer (.+)$/i)?.[1];

    if (token) {
      diagnostics.tokenVerification.attempted = true;
      diagnostics.tokenVerification.tokenLength = token.length;

      try {
        const { getAdminAuth } = await import('@/lib/firebase-admin');
        const adminAuth = await getAdminAuth();
        const decoded = await adminAuth.verifyIdToken(token);
        diagnostics.tokenVerification.result = {
          uid: decoded.uid,
          email: decoded.email,
          iss: decoded.iss,
          aud: decoded.aud,
          exp: new Date((decoded.exp || 0) * 1000).toISOString(),
          iat: new Date((decoded.iat || 0) * 1000).toISOString(),
        };
      } catch (verifyErr: any) {
        diagnostics.tokenVerification.error = {
          code: verifyErr?.code || verifyErr?.errorInfo?.code || 'unknown',
          message: verifyErr?.message?.slice(0, 200),
        };
      }
    } else {
      diagnostics.tokenVerification.attempted = false;
      diagnostics.tokenVerification.note = 'No Authorization header sent. Send "Bearer <token>" to test verification.';
    }
  } catch (initErr: any) {
    diagnostics.adminSdk.error = {
      code: initErr?.code || 'unknown',
      message: initErr?.message?.slice(0, 200),
    };
  }

  // Step 3: Check Firestore connectivity
  try {
    const { getAdminDb } = await import('@/lib/firebase-admin');
    const db = await getAdminDb();
    const snap = await db.collection('admin_settings').doc('ai_config').get();
    diagnostics.firestore = {
      connected: true,
      docExists: snap.exists,
    };
  } catch (dbErr: any) {
    diagnostics.firestore = {
      connected: false,
      error: dbErr?.message?.slice(0, 200),
    };
  }

  return NextResponse.json(diagnostics, { status: 200 });
}
