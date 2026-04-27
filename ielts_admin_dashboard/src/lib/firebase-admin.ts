import { initializeApp, getApps, cert, App, applicationDefault } from 'firebase-admin/app';
import { getFirestore, Firestore } from 'firebase-admin/firestore';

let adminApp: App;
let adminDb: Firestore;

function getAdminDb(): Firestore {
  if (adminDb) return adminDb;

  if (!getApps().length) {
    // Try service-account credentials from env first
    const privateKey = process.env.FIREBASE_ADMIN_PRIVATE_KEY;
    const clientEmail = process.env.FIREBASE_ADMIN_CLIENT_EMAIL;
    const projectId = process.env.FIREBASE_ADMIN_PROJECT_ID || 'speakup-ai-prod';

    if (privateKey && clientEmail) {
      adminApp = initializeApp({
        credential: cert({
          projectId,
          clientEmail,
          privateKey: privateKey.replace(/\\n/g, '\n'),
        }),
      }, 'admin');
    } else {
      // Fall back to Application Default Credentials (works with GOOGLE_APPLICATION_CREDENTIALS env var
      // or when deployed to Firebase Hosting / Cloud Run)
      adminApp = initializeApp({
        credential: applicationDefault(),
        projectId
      }, 'admin');
    }
  } else {
    adminApp = getApps().find(a => a.name === 'admin') || getApps()[0];
  }

  adminDb = getFirestore(adminApp);
  return adminDb;
}

export { getAdminDb };
