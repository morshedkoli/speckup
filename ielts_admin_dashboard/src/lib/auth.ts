import { getAuth, GoogleAuthProvider, signInWithPopup, signOut, onAuthStateChanged, User } from 'firebase/auth';
import { app } from './firebase';
import { ADMIN_EMAILS, isAllowedAdminEmail } from './admin-emails';

export const ADMIN_EMAIL = ADMIN_EMAILS[0];

export const auth = getAuth(app);
export const googleProvider = new GoogleAuthProvider();

export async function signInWithGoogle(): Promise<User> {
  const result = await signInWithPopup(auth, googleProvider);
  const user = result.user;

  if (!isAllowedAdminEmail(user.email)) {
    await signOut(auth);
    throw new Error(`Access denied. Only ${ADMIN_EMAIL} is authorized as admin.`);
  }

  return user;
}

export async function adminSignOut(): Promise<void> {
  await signOut(auth);
}

export function onAdminAuthStateChanged(callback: (user: User | null) => void) {
  return onAuthStateChanged(auth, (user) => {
    if (user && isAllowedAdminEmail(user.email)) {
      callback(user);
    } else {
      callback(null);
    }
  });
}
