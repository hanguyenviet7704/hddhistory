part of '../services.dart';

@lazySingleton
class AuthService implements IAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Initialize Google Sign In
      await _googleSignIn.initialize();

      // Trigger the Google Sign In flow with scope hint
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // Obtain the auth details from the account
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Get access token for the scopes
      final GoogleSignInClientAuthorization? authorization = await googleUser.authorizationClient.authorizationForScopes(['email', 'profile']);

      // Create a new credential with the Google tokens
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      throw AppException.generic('Google sign-in error: ${e.toString()}');
    } on FirebaseAuthException catch (e) {
      throw AppException.generic(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw AppException.generic('Failed to sign in with Google: ${e.toString()}');
    }
  }

  @override
  Future<UserCredential> signInWithApple() async {
    try {
      // Request Apple Sign In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuth credential for Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      return await _firebaseAuth.signInWithCredential(oauthCredential);
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AppException.generic(_getAppleAuthErrorMessage(e));
    } on FirebaseAuthException catch (e) {
      throw AppException.generic(_getFirebaseAuthErrorMessage(e));
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

      // Sign out from Google if currently signed in
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.signOut();
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
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'invalid-credential':
        return 'The credential is malformed or has expired.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }

  String _getAppleAuthErrorMessage(SignInWithAppleAuthorizationException e) {
    switch (e.code) {
      case AuthorizationErrorCode.canceled:
        return 'Apple sign-in was cancelled';
      case AuthorizationErrorCode.failed:
        return 'Apple sign-in failed';
      case AuthorizationErrorCode.invalidResponse:
        return 'Invalid response from Apple sign-in';
      case AuthorizationErrorCode.notHandled:
        return 'Apple sign-in was not handled';
      case AuthorizationErrorCode.unknown:
        return 'An unknown error occurred during Apple sign-in';
      case AuthorizationErrorCode.notInteractive:
        return 'Apple sign-in requires user interaction';
      default:
        return 'An Apple sign-in error occurred: ${e.message}';
    }
  }
}
