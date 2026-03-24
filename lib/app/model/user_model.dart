import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported user roles. SuperAdmin is the first admin; only they can approve new Admins.
class UserRole {
  UserRole._();
  static const String viewer = 'Viewer';
  static const String coach = 'Coach';
  static const String admin = 'Admin';
  static const String superAdmin = 'SuperAdmin';

  static const List<String> all = [viewer, coach, admin, superAdmin];

  static bool isAdminOrSuperAdmin(String? role) =>
      role == admin || role == superAdmin;

  static bool isSuperAdmin(String? role) => role == superAdmin;

  static String displayName(String? role) => role ?? '—';
}

/// Account status. Pending users cannot use the app until approved.
class UserStatus {
  UserStatus._();
  static const String active = 'active';
  static const String pending = 'pending';
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String? role;
  final String status;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.role,
    this.status = UserStatus.active,
    this.createdAt,
  });

  bool get isActive => status == UserStatus.active;
  bool get isPending => status == UserStatus.pending;
  bool get isAdminOrSuperAdmin => UserRole.isAdminOrSuperAdmin(role);
  bool get isSuperAdmin => UserRole.isSuperAdmin(role);

  /// Display name for UI (name or email fallback).
  String get displayName => name.trim().isNotEmpty ? name : email;

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    DateTime? createdAt;
    final createdAtValue = map['createdAt'];
    if (createdAtValue != null) {
      if (createdAtValue is DateTime) {
        createdAt = createdAtValue;
      } else if (createdAtValue is String) {
        createdAt = DateTime.tryParse(createdAtValue);
      } else if (createdAtValue is Timestamp) {
        createdAt = createdAtValue.toDate();
      }
    }

    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      role: map['role'] as String?,
      status: map['status'] as String? ?? UserStatus.active,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        if (phone != null) 'phone': phone,
        'role': role,
        'status': status,
        if (createdAt != null) 'createdAt': createdAt,
      };

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    String? role,
    String? status,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
