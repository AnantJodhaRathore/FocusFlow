import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _googleSignInInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isLoggedInWithAccount {
    final user = _auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  bool get isGoogleSignInSupported {
    if (kIsWeb) return true;

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> initializeGoogleSignIn() async {
    if (kIsWeb || _googleSignInInitialized) return;

    await GoogleSignIn.instance.initialize();
    _googleSignInInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      }

      if (!isGoogleSignInSupported) {
        throw Exception(
          'Google Sign-In is not supported on this platform yet. Use email login or guest mode.',
        );
      }

      await initializeGoogleSignIn();

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw Exception('Google Sign-In is not available on this device.');
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final currentUser = _auth.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        try {
          return await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (error) {
          if (error.code == 'credential-already-in-use' ||
              error.code == 'email-already-in-use') {
            return await _auth.signInWithCredential(credential);
          }

          throw Exception(_messageFromFirebaseError(error));
        }
      }

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      throw Exception(_messageFromFirebaseError(error));
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');

      if (message.toLowerCase().contains('cancel')) {
        throw Exception('Google Sign-In was cancelled.');
      }

      throw Exception(message);
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(_messageFromFirebaseError(error));
    }
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );

      final currentUser = _auth.currentUser;

      UserCredential result;

      if (currentUser != null && currentUser.isAnonymous) {
        result = await currentUser.linkWithCredential(credential);
      } else {
        result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      }

      final user = result.user;

      if (user != null && displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
        await user.reload();
      }

      return result;
    } on FirebaseAuthException catch (error) {
      throw Exception(_messageFromFirebaseError(error));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw Exception(_messageFromFirebaseError(error));
    }
  }

  Future<void> signOutToGuestMode() async {
    try {
      if (!kIsWeb && isGoogleSignInSupported) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (error, stackTrace) {
      debugPrint('[FocusFlow] Google sign-out warning: $error');
      debugPrint('$stackTrace');
    }

    await _auth.signOut();

    try {
      await _auth.signInAnonymously();
    } catch (error, stackTrace) {
      debugPrint('[FocusFlow] Guest sign-in after logout failed: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No user is signed in.');
    }

    await user.updateDisplayName(displayName.trim());
    await user.reload();
  }

  String _messageFromFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account was found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return 'An account already exists with this email. Please sign in instead.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
