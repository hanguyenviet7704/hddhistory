part of '../services.dart';

@lazySingleton
class AuthService implements IAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Create a GoogleAuthProvider
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Add custom scopes if needed
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Sign in with Google using Firebase Auth
      return await _firebaseAuth.signInWithProvider(googleProvider);
    } catch (e) {
      throw AppException.generic('Failed to sign in with Google: ${e.toString()}');
    }
  }

  @override
  Future<UserCredential> signInWithApple() async {
    try {
      // Create an AppleAuthProvider
      final AppleAuthProvider appleProvider = AppleAuthProvider();

      // Add custom scopes if needed
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      // Sign in with Apple using Firebase Auth
      return await _firebaseAuth.signInWithProvider(appleProvider);
    } catch (e) {
      throw AppException.generic('Failed to sign in with Apple: ${e.toString()}');
    }
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AppException.generic(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw AppException.generic('Failed to sign in with email: ${e.toString()}');
    }
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AppException.generic(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw AppException.generic('Failed to sign up with email: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw AppException.generic('Failed to sign out: ${e.toString()}');
    }
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }
}
