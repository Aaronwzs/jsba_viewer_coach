import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:jsba_app/app/model/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  DatabaseService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<UserModel> ensureUserDocumentExists(String uid) async {
    try {
      print('[DBG ensureUserDocumentExists] START uid=$uid');
      final docRef = _db.collection('users').doc(uid);
      final docSnapshot = await docRef.get();
      print('[DBG ensureUserDocumentExists] docSnapshot.exists=${docSnapshot.exists}');

      if (!docSnapshot.exists) {
        // Get current user from Firebase Auth
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw Exception('No authenticated user found');
        }

        // Prepare user data
        final userData = {
          'email': currentUser.email ?? '',
          'name': currentUser.displayName ?? 'Admin User',
          'role': 'admin', // default role for now
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Create the document
        await docRef.set(userData);
        print('[DBG ensureUserDocumentExists] doc created');

        return UserModel(
          uid: uid,
          email: userData['email'] as String,
          name: userData['name'] as String,
          role: userData['role'] as String,
        );
      } else {
        // Document exists — return it. Guard against null data on web.
        final data = docSnapshot.data();
        if (data == null || data.isEmpty) {
          print('[DBG ensureUserDocumentExists] doc exists but data is null/empty — recreating');
          final currentUser = _auth.currentUser;
          final userData = {
            'email': currentUser?.email ?? '',
            'name': currentUser?.displayName ?? 'Admin User',
            'role': 'admin',
            'updatedAt': FieldValue.serverTimestamp(),
          };
          await docRef.set(userData, SetOptions(merge: true));
          return UserModel(
            uid: uid,
            email: userData['email'] as String,
            name: userData['name'] as String,
            role: userData['role'] as String,
          );
        }
        print('[DBG ensureUserDocumentExists] doc exists with data — keys=${data.keys.toList()}');
        return UserModel.fromMap(data, uid);
      }
    } catch (e, st) {
      print('[DBG ensureUserDocumentExists] ERROR: $e');
      print('[DBG ensureUserDocumentExists] STACK: $st');
      throw Exception('Failed to ensure user document: $e');
    }
  }

  /// Update user profile in Firestore (e.g. name, phone, email)
  Future<void> updateUserProfile(
    String uid, {
    String? name,
    String? phone,
    String? email,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    if (updates.isEmpty) return;
    await _db.collection('users').doc(uid).update(updates);
  }

  /// Delete user document from Firestore (e.g. when account is deleted)
  Future<void> deleteUserDocument(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  /// Get user by uid from Firestore (returns null if not found)
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null || data.isEmpty) return null;
    return UserModel.fromMap(data, uid);
  }

  /// Get user by phone number from Firestore (returns null if not found)
  Future<UserModel?> getUserByPhone(String phone) async {
    final normalizedPhone = phone.trim();
    final snapshot = await _db
        .collection('users')
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return UserModel.fromMap(
      snapshot.docs.first.data(),
      snapshot.docs.first.id,
    );
  }

  /// Returns true if at least one active Admin or SuperAdmin exists.
  Future<bool> hasAnyActiveAdminOrSuperAdmin() async {
    final snapshot = await _db
        .collection('users')
        .where('status', isEqualTo: UserStatus.active)
        .get();
    return snapshot.docs.any((d) {
      final role = d.data()['role'] as String?;
      return role == UserRole.admin || role == UserRole.superAdmin;
    });
  }

  /// Create user document for registration (no auto-role; caller sets role and status).
  Future<void> createUserForRegistration({
    required String uid,
    required String email,
    required String name,
    required String role,
    required String status,
    String? phone,
  }) async {
    final data = <String, dynamic>{
      'email': email,
      'name': name,
      'role': role,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (phone != null && phone.trim().isNotEmpty) data['phone'] = phone.trim();
    await _db.collection('users').doc(uid).set(data);
  }

  /// List users with status pending (for approval screen).
  Future<List<UserModel>> getPendingUsers() async {
    final snapshot = await _db
        .collection('users')
        .where('status', isEqualTo: UserStatus.pending)
        .get();
    final list = snapshot.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .toList();
    list.sort((a, b) => b.email.compareTo(a.email));
    return list;
  }

  /// Approve a user (set status to active).
  Future<void> approveUser(String uid) async {
    await _db.collection('users').doc(uid).update({
      'status': UserStatus.active,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }
}
