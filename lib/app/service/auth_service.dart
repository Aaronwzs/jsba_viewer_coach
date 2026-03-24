import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Sign in
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Register (create new Auth user)
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Reauthenticate (required before sensitive operations)
  Future<UserCredential> reauthenticateWithPassword(String email, String password) async {
    final credential = EmailAuthProvider.credential(email: email, password: password);
    return await _auth.currentUser!.reauthenticateWithCredential(credential);
  }

  // Update display name in Firebase Auth
  Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
  }

  // Update password (call after reauthenticate)
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  /// Link email + password to current user (e.g. phone-only user adding email/password).
  Future<UserCredential> linkWithEmailAndPassword(String email, String password) async {
    final credential = EmailAuthProvider.credential(email: email.trim(), password: password);
    return await _auth.currentUser!.linkWithCredential(credential);
  }

  /// Update the current user's phone number. Call after verifying new number with OTP.
  Future<void> updatePhoneNumber(PhoneAuthCredential credential) async {
    await _auth.currentUser!.updatePhoneNumber(credential);
  }

  // Delete Firebase Auth user (call after reauthenticate)
  Future<void> deleteAuthUser() async {
    await _auth.currentUser?.delete();
  }

  // Get current user's role from Firestore
  Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['role'] as String?;
  }

  /// Send OTP to [phoneNumber] (E.164 format, e.g. +60123456789). Returns verificationId for signInWithPhoneCredential.
  Future<String> verifyPhoneNumber(String phoneNumber) async {
    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future;
  }

  /// Sign in with the OTP code. Use after verifyPhoneNumber.
  Future<UserCredential> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }
}