import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

class PlayerModel {
  String id;
  String name;
  int age;
  String level;
  DateTime createdAt;
  String? imageUrl;
  String phone;
  bool? isActive;
  String? parentName;
  String? parentPhone;
  String? parentEmail;
  String? parentId;
  String? coachId;
  String status;
  bool isSelf;

  PlayerModel({
    required this.id,
    this.imageUrl,
    required this.name,
    required this.age,
    required this.level,
    required this.createdAt,
    required this.phone,
    this.isActive = false,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.parentId,
    this.coachId,
    this.status = PlayerStatus.pending,
    this.isSelf = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'level': level,
    'phone': phone,
    'isActive': isActive,
    'createdAt': createdAt,
    'imageUrl': imageUrl,
    'parentName': parentName,
    'parentPhone': parentPhone,
    'parentEmail': parentEmail,
    'parentId': parentId,
    'coachId': coachId,
    'status': status,
    'isSelf': isSelf,
  };

  factory PlayerModel.fromMap(Map<String, dynamic> map, {required String id}) {
    DateTime? createdAt;
    final createdAtField = map['createdAt'];
    if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else if (createdAtField is DateTime) {
      createdAt = createdAtField;
    } else {
      createdAt = DateTime.now(); // fallback
    }

    return PlayerModel(
      id: id,
      name: map['name'] as String? ?? '',
      age: map['age'] as int? ?? 0,
      level: map['level'] as String? ?? 'Beginner',
      phone: map['phone'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: createdAt,
      imageUrl: map['imageUrl'] as String?,
      parentName: map['parentName'] as String?,
      parentPhone: map['parentPhone'] as String?,
      parentEmail: map['parentEmail'] as String?,
      parentId: map['parentId'] as String?,
      coachId: map['coachId'] as String?,
      status: map['status'] as String? ?? PlayerStatus.pending,
      isSelf: map['isSelf'] as bool? ?? false,
    );
  }

  factory PlayerModel.empty() => PlayerModel(
    id: '',
    name: 'Unknown',
    age: 0,
    level: 'Beginner',
    phone: '',
    isActive: false,
    createdAt: DateTime.now(),
    imageUrl: null,
    parentName: null,
    parentPhone: null,
    parentEmail: null,
    parentId: null,
    coachId: null,
    status: PlayerStatus.pending,
    isSelf: false,
  );
}
