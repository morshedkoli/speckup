import { NextResponse } from 'next/server';

import { isAllowedAdminEmail } from './admin-emails';

type DecodedIdToken = {
  uid: string;
  email?: string;
  [key: string]: any;
};

type AdminGuardResult =
  | { ok: true; user: DecodedIdToken }
  | { ok: false; response: NextResponse };

export async function requireAdmin(request: Request): Promise<AdminGuardResult> {
  const authorization = request.headers.get('authorization');
  const token = authorization?.match(/^Bearer (.+)$/i)?.[1];

  if (!token) {
    return {
      ok: false,
      response: NextResponse.json({ error: 'Authentication required' }, { status: 401 }),
    };
  }

  try {
    // Use centralised wrapper — avoids direct 'firebase-admin/auth' import
    // which Turbopack would mangle in production builds.
    const { getAdminAuth } = await import('./firebase-admin');

    const adminAuth = await getAdminAuth();

    // verifyIdToken with checkRevoked=false for performance.
    // The token is a Firebase ID token issued by the client SDK.
    const decoded = await adminAuth.verifyIdToken(token);

    if (!isAllowedAdminEmail(decoded.email)) {
      return {
        ok: false,
        response: NextResponse.json({ error: 'Admin access denied' }, { status: 403 }),
      };
    }

    return { ok: true, user: decoded as DecodedIdToken };
  } catch (error: any) {
    const errorCode = error?.code || error?.errorInfo?.code || '';
    const errorMessage = error?.message || '';

    console.error('[admin auth] verifyIdToken failed:', {
      code: errorCode,
      message: errorMessage,
      // Log the first 60 chars of the token for debugging (safe — this is the header, not the signature)
      tokenPrefix: token.substring(0, 60) + '...',
      envCheck: {
        hasPrivateKey: !!process.env.FB_ADMIN_PRIVATE_KEY,
        hasClientEmail: !!process.env.FB_ADMIN_CLIENT_EMAIL,
        hasProjectId: !!process.env.FB_ADMIN_PROJECT_ID,
        hasFirebaseDefaults: !!process.env.__FIREBASE_DEFAULTS__,
      },
    });

    // Provide a more descriptive error back to the client
    let detail = errorCode || errorMessage;
    if (errorCode === 'auth/id-token-expired') {
      detail = 'Token expired — please refresh the page and try again.';
    } else if (errorCode === 'auth/argument-error') {
      detail = 'Invalid token format.';
    }

    return {
      ok: false,
      response: NextResponse.json(
        { error: 'Invalid admin session', detail },
        { status: 401 },
      ),
    };
  }
}
