import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/errors/app_exception.dart';
import '../../core/logging/logger.dart';

class AuthService {
  final FirebaseAuth auth;
  final GoogleSignIn googleSignIn;

  AuthService({
    required this.auth,
    required this.googleSignIn,
  });

  Future<UserCredential> signInWithGoogle() async {
    try {
      logger.i('Starting Google Sign-In flow');
      
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        userCredential = await auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw const AuthException('Google Sign-In canceled by user.');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await auth.signInWithCredential(credential);
      }

      logger.i('Successfully signed in as ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Exception: ${e.message}', error: e);
      throw AuthException(e.message ?? 'Authentication failed', e.code);
    } catch (e, st) {
      logger.e('Unexpected Auth Exception: $e', error: e, stackTrace: st);
      throw AuthException(e.toString());
    }
  }

  Future<void> signOut() async {
    await googleSignIn.signOut();
    await auth.signOut();
    logger.i('User signed out');
  }
}
