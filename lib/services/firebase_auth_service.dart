// services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Initialize the service (call this in main.dart)
  Future<void> initialize() async {
    try {
      // Ensure Firebase Auth is properly initialized
      await _auth.setLanguageCode('en');

      // For debugging - remove in production
      if (kDebugMode) {
        print('Firebase Auth initialized successfully');
        print('Current user: ${_auth.currentUser?.email}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Auth initialization error: $e');
      }
    }
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Clear any existing auth state first
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Create user with email and password
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name if user creation was successful
      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName.trim());
        await credential.user!.reload();

        // Get the updated user
        final updatedUser = _auth.currentUser;
        if (kDebugMode) {
          print('User created successfully: ${updatedUser?.email}');
        }
      }

      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException during sign up: ${e.code} - ${e.message}');
      }
      throw Exception(_handleAuthException(e));
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during sign up: $e');
      }
      throw Exception('Failed to create account. Please try again.');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Clear any existing auth state first
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Add a small delay to ensure clean state
      await Future.delayed(const Duration(milliseconds: 100));

      // Attempt to sign in
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (kDebugMode) {
        print('User signed in successfully: ${credential.user?.email}');
      }

      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException during sign in: ${e.code} - ${e.message}');
      }
      throw Exception(_handleAuthException(e));
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during sign in: $e');
        print('Error type: ${e.runtimeType}');
      }

      // Handle the specific PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        throw Exception(
          'Authentication service error. Please restart the app and try again.',
        );
      }

      throw Exception(
        'Failed to sign in. Please check your credentials and try again.',
      );
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Clear any existing auth state first
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Clear Google Sign-In cache
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (kDebugMode) {
        print('Google sign in successful: ${userCredential.user?.email}');
      }

      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print(
          'FirebaseAuthException during Google sign in: ${e.code} - ${e.message}',
        );
      }
      throw Exception(_handleAuthException(e));
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during Google sign in: $e');
      }

      if (e.toString().contains('PigeonUserDetails')) {
        throw Exception(
          'Google sign-in service error. Please restart the app and try again.',
        );
      }

      throw Exception('Google sign-in failed. Please try again.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from both Google and Firebase
      await Future.wait([_googleSignIn.signOut(), _auth.signOut()]);

      if (kDebugMode) {
        print('User signed out successfully');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error during sign out: $e');
      }
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      if (kDebugMode) {
        print('Password reset email sent to: $email');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print(
          'FirebaseAuthException during password reset: ${e.code} - ${e.message}',
        );
      }
      throw Exception(_handleAuthException(e));
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during password reset: $e');
      }
      throw Exception('Failed to send password reset email. Please try again.');
    }
  }

  // Update profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName.trim());
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();

      if (kDebugMode) {
        print('Profile updated successfully');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
      throw Exception('Failed to update profile. Please try again.');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      await user.delete();

      if (kDebugMode) {
        print('Account deleted successfully');
      }

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Please sign in again before deleting your account');
      }
      throw Exception(_handleAuthException(e));
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting account: $e');
      }
      throw Exception('Failed to delete account. Please try again.');
    }
  }

  // Re-authenticate user (required for sensitive operations)
  Future<void> reauthenticateWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      if (kDebugMode) {
        print('User re-authenticated successfully');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print(
          'FirebaseAuthException during re-authentication: ${e.code} - ${e.message}',
        );
      }
      throw Exception(_handleAuthException(e));
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during re-authentication: $e');
      }
      throw Exception('Re-authentication failed. Please try again.');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
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
        return 'This sign-in method is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      case 'invalid-credential':
        return 'The provided credentials are invalid.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different account.';
      default:
        return 'Authentication failed: ${e.message ?? 'Unknown error'}';
    }
  }

  // Get user data for display
  Map<String, dynamic> get userData {
    final user = _auth.currentUser;
    return {
      'uid': user?.uid ?? '',
      'email': user?.email ?? '',
      'displayName': user?.displayName ?? '',
      'photoURL': user?.photoURL ?? '',
      'emailVerified': user?.emailVerified ?? false,
      'creationTime': user?.metadata.creationTime?.toIso8601String() ?? '',
      'lastSignInTime': user?.metadata.lastSignInTime?.toIso8601String() ?? '',
    };
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      await user.sendEmailVerification();

      if (kDebugMode) {
        print('Email verification sent to: ${user.email}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending email verification: $e');
      }
      throw Exception('Failed to send verification email. Please try again.');
    }
  }

  // Reload user to get updated information
  Future<void> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reloading user: $e');
      }
    }
  }

  // Check auth state consistency
  Future<bool> checkAuthState() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return _auth.currentUser != null;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking auth state: $e');
      }
      return false;
    }
  }
}
