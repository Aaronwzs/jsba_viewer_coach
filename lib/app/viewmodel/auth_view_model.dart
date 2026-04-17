import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jsba_app/app/service/auth_service.dart';
import 'package:jsba_app/app/service/database_service.dart';
import 'package:jsba_app/app/model/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

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

  Future<void> checkAuth() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user != null) {
        _currentUser = await _databaseService.getUser(user.uid);
      }
    } catch (e) {
      _error = e.toString();
    }

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
      await _authService.signOut();
      _currentUser = null;
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
