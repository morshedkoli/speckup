import { initializeApp, getApps, getApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || 'AIzaSyCLsloYVCZh2Od9E7YGfg2UaVEklV502OE',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || 'speakup-ai-prod.firebaseapp.com',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || 'speakup-ai-prod',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || 'speakup-ai-prod.firebasestorage.app',
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '955029235432',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '1:955029235432:web:bc6059e484c81adbb54b5d',
};

const app = !getApps().length ? initializeApp(firebaseConfig) : getApp();

// Lazy getter — avoids calling getFirestore() at module-load time which crashes
// during Next.js static pre-rendering ("Service firestore is not available").
let _db: ReturnType<typeof getFirestore> | null = null;
function getDb() {
  if (!_db) _db = getFirestore(app);
  return _db;
}

// Keep `db` as a property so existing imports continue to work.
// It resolves lazily on first access.
const db = new Proxy({} as ReturnType<typeof getFirestore>, {
  get(_target, prop) {
    return (getDb() as any)[prop];
  },
});

export { app, db };

