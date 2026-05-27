import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jsba_app/app/service/auth_service.dart';
import 'package:jsba_app/app/service/database_service.dart';
import 'package:jsba_app/app/service/notification_service.dart';
import 'package:jsba_app/app/model/user_model.dart';
import 'package:jsba_app/app/utils/starter_handler.dart' as starter_handler;

// Debug flag — set to true to enable verbose auth resolution logs
bool _authDebug = false;
void _log(String msg) {
  if (_authDebug) debugPrint('[AuthViewModel] $msg');
}

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final DatabaseService _databaseService;
  final NotificationService _notificationService;

  /// Tracks the async auth check so [checkAuth] is idempotent.
  Future<void>? _authCheckFuture;

  AuthViewModel({
    AuthService? authService,
    DatabaseService? databaseService,
    NotificationService? notificationService,
  })  : _authService = authService ?? AuthService(),
        _databaseService = databaseService ?? DatabaseService(),
        _notificationService = notificationService ??
            starter_handler.notificationService;
  // NOTE: checkAuth() is NOT called from the constructor to avoid issues
  // in test environments where mock bindings aren't set up yet.
  // It is called from the Provider create callback in app.dart, so it
  // fires eagerly when the widget tree first reads AuthViewModel.

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _phoneVerificationId;
  String? _lastPhoneNumber;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isCoach => _currentUser?.role == 'Coach';
  bool get isViewer => _currentUser?.role == 'Viewer';

  dynamic getCurrentUser() {
    return _authService.currentUser;
  }

  Future<void> loadUser(String uid) async {
    _currentUser = await _databaseService.getUser(uid);
    notifyListeners();
  }

  /// Idempotent auth check — returns the same Future if already running.
  /// Safe to call from SplashScreen, dashboard pages, or any widget.
  Future<void> checkAuth() {
    _authCheckFuture ??= _executeCheckAuth();
    return _authCheckFuture!;
  }

  /// Internal auth resolution logic. Extracted so both constructor and
  /// idempotent [checkAuth] share the same implementation.
  Future<void> _executeCheckAuth() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _log('=== checkAuth() START ===');
    _log('kIsWeb=$kIsWeb');

    try {
      // 🏷 Check persisted flag for previous login (survives page reload on web)
      final storedUid = starter_handler.cachedLoggedInUid;
      _log('0. cachedLoggedInUid=$storedUid');

      User? user = _authService.currentUser;
      _log('1. currentUser (sync) -> ${user != null ? "uid=${user.uid}" : "null"}');

      if (user == null && kIsWeb) {
        // On web, currentUser returns null on page reload because IndexedDB
        // hasn't resolved yet. Subscribe to authStateChanges which
        // asynchronously emits the restored user once IndexedDB resolves.
        //
        // ALSO poll currentUser every 500ms as a fallback, because on some
        // browsers the stream listener never fires but currentUser eventually
        // gets populated.
        //
        // If the user had a prior login session (storedUid != null), use a
        // longer timeout (30s) because IndexedDB can take 15-25 seconds to
        // resolve on slow connections or after a fresh page reload.
        final bool isReturningUser = storedUid != null;
        final int maxPollIterations = isReturningUser ? 60 : 30; // 30s vs 15s
        final int timeoutSeconds = isReturningUser ? 30 : 15;

        _log('2a. currentUser was null on web — combined stream + poll approach '
            '(isReturningUser=$isReturningUser, timeout=${timeoutSeconds}s)');
        final stopwatch = Stopwatch()..start();

        final streamFuture = _authService.authStateChanges
            .firstWhere((u) => u != null)
            .timeout(Duration(seconds: timeoutSeconds));

        final pollFuture = (() async {
          for (int i = 0; i < maxPollIterations; i++) {
            await Future.delayed(const Duration(milliseconds: 500));
            final u = _authService.currentUser;
            if (u != null) return u;
          }
          return null;
        })();

        try {
          user = await Future.any([streamFuture, pollFuture]);
          if (user != null) {
            _log('3a. ✅ resolved after ${stopwatch.elapsedMilliseconds}ms -> uid=${user.uid}');
          } else {
            _log('3a. ⏰ both stream and poll returned null after ${stopwatch.elapsedMilliseconds}ms');
          }
        } on TimeoutException {
          user = null;
          _log('3a. ⏰ both methods timed out after ${stopwatch.elapsedMilliseconds}ms');
        }
      } else if (user == null && !kIsWeb) {
        _log('2. currentUser was null on mobile — no session');
      } else {
        _log('2. currentUser was non-null, skipping web fallback');
      }

      if (user != null) {
        _log('4. Loading UserModel from Firestore for uid=${user.uid}...');
        UserModel? userModel = await _databaseService.getUser(user.uid);
        _log('5. Firestore getUser returned: ${userModel != null ? "uid=${userModel.uid} role=${userModel.role} name=${userModel.name}" : "null (will retry)"}');

        // Retry once if getUser() returned null — Firestore on web may need
        // a brief warm-up for the WebSocket connection.
        if (userModel == null && kIsWeb) {
          _log('5b. ⏳ getUser() was null on web — retrying after 1s delay...');
          await Future.delayed(const Duration(seconds: 1));
          userModel = await _databaseService.getUser(user.uid);
          _log('5c. Retry getUser returned: ${userModel != null ? "uid=${userModel.uid}" : "still null"}');
        }

        _currentUser = userModel;
        // ✅ Session restored — persist UID so it survives the next reload
        await starter_handler.writeCachedLoggedInUid(user.uid);
      } else {
        _log('4. No Firebase user — skipping Firestore load');
        // Clear stale flag if user is null
        await starter_handler.writeCachedLoggedInUid(null);
      }
    } catch (e) {
      _log('ERROR in checkAuth: $e');
      _error = e.toString();
    }

    _log('6. checkAuth() done — isLoggedIn=$isLoggedIn, currentUser=${currentUser != null ? "uid=${currentUser!.uid}" : "null"}');
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      _currentUser = await _databaseService.ensureUserDocumentExists(
        credential.user!.uid,
      );
      // Store UID in localStorage so checkAuth() can use longer timeout on reload
      await starter_handler.writeCachedLoggedInUid(credential.user!.uid);
      _log('[signIn] ✅ persisted jsba_logged_in_uid=${credential.user!.uid}');
      // Save FCM device token for push notifications
      await _notificationService.saveDeviceToken(credential.user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String name,
    String role,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );
      await _authService.updateDisplayName(name);
      await _databaseService.createUserForRegistration(
        uid: credential.user!.uid,
        email: email,
        name: name,
        role: role,
        status: 'active',
      );
      _currentUser = await _databaseService.getUser(credential.user!.uid);
      await starter_handler.writeCachedLoggedInUid(credential.user!.uid);
      _log('[register] ✅ persisted jsba_logged_in_uid=${credential.user!.uid}');
      // Save FCM device token for push notifications
      await _notificationService.saveDeviceToken(credential.user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Remove device token before signing out
      if (_currentUser != null) {
        await _notificationService.removeDeviceToken(_currentUser!.uid);
      }
      await _authService.signOut();
      _currentUser = null;
      // Clear persisted UID so checkAuth() uses short timeout next time
      await starter_handler.writeCachedLoggedInUid(null);
      _log('[signOut] ✅ cleared persisted jsba_logged_in_uid');
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateUserName(String newName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateDisplayName(newName);
      await _databaseService.updateUserProfile(
        _currentUser!.uid,
        name: newName,
      );
      _currentUser = await _databaseService.getUser(_currentUser!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No user signed in');
      await _authService.reauthenticateWithPassword(user.email!, oldPassword);
      await _authService.updatePassword(newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyCurrentPassword(String password) async {
    _error = null;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No user signed in');
      await _authService.reauthenticateWithPassword(user.email!, password);
      return true;
    } catch (e) {
      _error = 'Incorrect password';
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePasswordOnly(String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updatePassword(newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmail(String newEmail) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No user signed in');
      await user.verifyBeforeUpdateEmail(newEmail);
      await _databaseService.updateUserProfile(
        _currentUser!.uid,
        email: newEmail,
      );
      _currentUser = await _databaseService.getUser(_currentUser!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _mapAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendEmailVerification() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.sendEmailVerification();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _mapAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestPhoneOtp(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _phoneVerificationId = await _authService.verifyPhoneNumber(phoneNumber);
      _lastPhoneNumber = phoneNumber;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _mapAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendPhoneOtp() async {
    if (_lastPhoneNumber == null) {
      _error = 'Please enter a phone number first.';
      notifyListeners();
      return false;
    }
    return requestPhoneOtp(_lastPhoneNumber!);
  }

  Future<bool> checkUserExistsByPhone(String phoneNumber) async {
    _error = null;
    notifyListeners();
    try {
      final user = await _databaseService.getUserByPhone(phoneNumber);
      return user != null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPhoneOtp(String smsCode) async {
    if (_phoneVerificationId == null) {
      _error = 'Request an OTP before verification.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final credential = await _authService.signInWithPhoneCredential(
        verificationId: _phoneVerificationId!,
        smsCode: smsCode.trim(),
      );
      _currentUser = await _databaseService.ensureUserDocumentExists(
        credential.user!.uid,
      );
      await starter_handler.writeCachedLoggedInUid(credential.user!.uid);
      _log('[verifyPhoneOtp] ✅ persisted jsba_logged_in_uid=${credential.user!.uid}');
      // Save FCM device token for push notifications
      await _notificationService.saveDeviceToken(credential.user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _mapAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  bool get isEmailVerified => _authService.isEmailVerified;
  String? get currentEmail => _authService.currentEmail;
  bool get hasEmailProvider => false;

  Future<bool> changeEmail({
    required String password,
    required String newEmail,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.reauthenticateWithPassword(
        _authService.currentEmail ?? '',
        password,
      );
      await _authService.currentUser!.verifyBeforeUpdateEmail(newEmail);
      await _databaseService.updateUserProfile(
        _authService.currentUser!.uid,
        email: newEmail,
      );
      _currentUser = await _databaseService.getUser(
        _authService.currentUser!.uid,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _mapAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyAndAddPhone({
    required String phoneNumber,
    required String smsCode,
  }) async {
    if (_phoneVerificationId == null) {
      _error = 'Request an OTP first.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // If user already has a phone linked, unlink it first
      final user = _authService.currentUser;
      if (user != null) {
        final providers = user.providerData;
        final hasPhone = providers.any((p) => p.providerId == 'phone');
        if (hasPhone) {
          await _authService.unlinkPhone();
        }
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _phoneVerificationId!,
        smsCode: smsCode.trim(),
      );
      await _authService.linkPhoneNumber(credential);
      await _databaseService.updateUserProfile(
        _authService.currentUser!.uid,
        phone: phoneNumber,
      );
      _currentUser = await _databaseService.getUser(
        _authService.currentUser!.uid,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _mapAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      await user.reload();
      _currentUser = await _databaseService.getUser(user.uid);
      notifyListeners();
    }
  }

  String _mapAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-not-found':
          return 'No account found for this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        case 'invalid-phone-number':
          return 'Enter a valid phone number with country code.';
        case 'invalid-verification-code':
          return 'The OTP code is invalid.';
        case 'session-expired':
          return 'OTP expired. Request a new code.';
        default:
          return error.message ?? error.code;
      }
    }
    return error.toString();
  }
}
