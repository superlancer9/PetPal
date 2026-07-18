import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// ViewModel: Authentication
/// Manages user authentication state and logic using Firebase Auth
class AuthVM extends ChangeNotifier {
  FirebaseAuth? _auth;
  bool _isLoading = false;
  String? _errorMessage;
  bool _firebaseInitialized = false;

  bool get isAuthenticated {
    if (!_firebaseInitialized || _auth == null) return false;
    try {
      return _auth!.currentUser != null;
    } catch (e) {
      debugPrint('⚠️ Error checking auth state: $e');
      return false;
    }
  }
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _auth?.currentUser;

  AuthVM() {
    // Initialize Firebase synchronously if available
    _checkAndInitializeFirebase();
    // Sign out any persisted users so app always starts at login page
    // Use a small delay to ensure Firebase is fully initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      _signOutPersistedUser();
    });
  }

  void _checkAndInitializeFirebase() {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        debugPrint('⚠️ Firebase not initialized yet');
        _firebaseInitialized = false;
        return;
      }
      
      _auth = FirebaseAuth.instance;
      _firebaseInitialized = true;
      
      // Listen to auth state changes
      _auth!.authStateChanges().listen((User? user) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('⚠️ Firebase Auth not available: $e');
      _firebaseInitialized = false;
    }
  }

  /// Sign out any persisted user to ensure app always starts at login page
  Future<void> _signOutPersistedUser() async {
    try {
      // Wait a bit more to ensure Firebase Auth is ready
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (_firebaseInitialized && _auth != null) {
        final currentUser = _auth!.currentUser;
        if (currentUser != null) {
          debugPrint('Signing out persisted user: ${currentUser.email}');
          await _auth!.signOut();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error signing out persisted user: $e');
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    if (!_firebaseInitialized || _auth == null) {
      _errorMessage = 'Firebase is not initialized. Please restart the app.';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Attempt login - this may throw a plugin error even if it succeeds
      try {
        await _auth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        // If we get here without error, login succeeded
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (pluginError) {
        // Check if this is the plugin error - if so, verify auth state
        if (pluginError.toString().contains('PigeonUserDetails') || 
            pluginError.toString().contains('type cast') ||
            pluginError.toString().contains('List<Object?>')) {
          // This is the plugin bug - check if auth actually succeeded
          debugPrint('Plugin error caught, checking auth state: $pluginError');
          // Re-throw to be caught by outer catch block
          rethrow;
        }
        // Real error - re-throw
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      debugPrint('Login FirebaseAuthException: ${e.code} - ${e.message}');
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      debugPrint('Login catch block: $e');
      
      // Handle type casting errors from Firebase plugin
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        debugPrint('Firebase Auth plugin error (type cast): $e');
        
        // Wait and check multiple times if auth actually succeeded
        for (int i = 0; i < 5; i++) {
          await Future.delayed(const Duration(milliseconds: 400));
          if (_auth!.currentUser != null) {
            debugPrint('✅ Login succeeded despite plugin error (attempt ${i + 1})');
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
            return true;
          }
        }
        
        // Final check after longer delay
        await Future.delayed(const Duration(milliseconds: 1000));
        if (_auth!.currentUser != null) {
          debugPrint('✅ Login succeeded after final check');
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        }
        
        // If still no user, show error but suggest checking
        _isLoading = false;
        _errorMessage = 'Login may have succeeded. Please wait a moment and check.';
        debugPrint('⚠️ Plugin error - user not found after all retries');
        notifyListeners();
        return false;
      } else {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        debugPrint('Login unexpected error: $e');
        debugPrint('Stack trace: $stackTrace');
        notifyListeners();
        return false;
      }
    }
  }

  /// Sign up with email and password
  Future<bool> signUp(String name, String email, String password) async {
    if (!_firebaseInitialized || _auth == null) {
      _errorMessage = 'Firebase is not initialized. Please restart the app.';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Update user display name
      if (userCredential.user != null) {
        try {
          await userCredential.user!.updateDisplayName(name);
          await userCredential.user!.reload();
        } catch (e) {
          // Display name update failed, but account was created
          debugPrint('Warning: Failed to update display name: $e');
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      debugPrint('Signup error: ${e.code} - ${e.message}');
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      // Handle type casting errors from Firebase plugin
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        debugPrint('Firebase Auth plugin error (type cast): $e');
        // This is a known plugin bug - check if account was actually created
        // Wait a bit for Firebase to update
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Check multiple times to ensure we catch the auth state
        for (int i = 0; i < 3; i++) {
          if (_auth!.currentUser != null) {
            debugPrint('✅ Signup succeeded despite plugin error');
            // Try to update display name
            try {
              await _auth!.currentUser!.updateDisplayName(name);
              await _auth!.currentUser!.reload();
            } catch (updateError) {
              debugPrint('Warning: Failed to update display name: $updateError');
            }
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
            return true;
          }
          await Future.delayed(const Duration(milliseconds: 300));
        }
        
        // If still no user, it's a real error
        _isLoading = false;
        _errorMessage = 'Account may have been created. Please try logging in.';
        debugPrint('⚠️ Plugin error but user not found after retries');
        notifyListeners();
        return false;
      } else {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        debugPrint('Signup unexpected error: $e');
        debugPrint('Stack trace: $stackTrace');
        notifyListeners();
        return false;
      }
    }
  }

  /// Logout current user
  Future<void> logout() async {
    if (!_firebaseInitialized || _auth == null) {
      return;
    }
    
    try {
      await _auth!.signOut();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to logout. Please try again.';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user-friendly error message from Firebase error code
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No account found for that email. Please sign up first.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      default:
        debugPrint('Unhandled Firebase error code: $code');
        return 'Authentication failed. Please try again.';
    }
  }
}

