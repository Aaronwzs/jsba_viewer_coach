import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:jsba_app/app/model/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserModel> ensureUserDocumentExists(String uid) async {
    try {
      final docRef = _db.collection('users').doc(uid);
      final docSnapshot = await docRef.get();

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

        return UserModel(
          uid: uid,
          email: userData['email'] as String,
          name: userData['name'] as String,
          role: userData['role'] as String,
        );
      } else {
        // Document exists — return it
        final data = docSnapshot.data()!;
        return UserModel.fromMap(data, uid);
      }
    } catch (e) {
      throw Exception('Failed to ensure user document: $e');
    }
  }

  /// Update user profile in Firestore (e.g. name, phone, email)
  Future<void> updateUserProfile(String uid, {String? name, String? phone, String? email}) async {
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
    return UserModel.fromMap(doc.data()!, uid);
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