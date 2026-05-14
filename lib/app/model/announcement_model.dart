import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementType { general, event, urgent, update }

class AnnouncementModel {
  String id;
  String title;
  String content;
  AnnouncementType type;
  List<String> imageUrls;
  DateTime createdAt;
  String createdBy;
  String? createdByName;
  List<String> viewerIds;
  bool isPinned;
  DateTime? expiresAt;

  static const int maxImages = 10;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.type = AnnouncementType.general,
    List<String>? imageUrls,
    required this.createdAt,
    required this.createdBy,
    this.createdByName,
    this.viewerIds = const [],
    this.isPinned = false,
    this.expiresAt,
  }) : imageUrls = imageUrls ?? [];

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'type': type.name,
    'imageUrls': imageUrls,
    'createdAt': Timestamp.fromDate(createdAt),
    'createdBy': createdBy,
    'createdByName': createdByName,
    'viewerIds': viewerIds,
    'isPinned': isPinned,
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
  };

  factory AnnouncementModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime? createdAt;
    final createdAtField = map['createdAt'];
    if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else if (createdAtField is DateTime) {
      createdAt = createdAtField;
    }

    DateTime? expiresAt;
    final expiresAtField = map['expiresAt'];
    if (expiresAtField is Timestamp) {
      expiresAt = expiresAtField.toDate();
    } else if (expiresAtField is DateTime) {
      expiresAt = expiresAtField;
    }

    List<String> imageUrls = [];
    final imageUrlsField = map['imageUrls'];
    if (imageUrlsField is List) {
      imageUrls = imageUrlsField.cast<String>();
    }

    return AnnouncementModel(
      id: id,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      type: AnnouncementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AnnouncementType.general,
      ),
      imageUrls: imageUrls,
      createdAt: createdAt ?? DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String?,
      viewerIds: (map['viewerIds'] as List<dynamic>?)?.cast<String>() ?? [],
      isPinned: map['isPinned'] as bool? ?? false,
      expiresAt: expiresAt,
    );
  }

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    AnnouncementType? type,
    List<String>? imageUrls,
    DateTime? createdAt,
    String? createdBy,
    String? createdByName,
    List<String>? viewerIds,
    bool? isPinned,
    DateTime? expiresAt,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      viewerIds: viewerIds ?? this.viewerIds,
      isPinned: isPinned ?? this.isPinned,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get hasImages => imageUrls.isNotEmpty;
  int get imageCount => imageUrls.length;
  bool get canAddMoreImages => imageUrls.length < maxImages;

  String get typeLabel {
    switch (type) {
      case AnnouncementType.general:
        return 'General';
      case AnnouncementType.event:
        return 'Event';
      case AnnouncementType.urgent:
        return 'Urgent';
      case AnnouncementType.update:
        return 'Update';
    }
  }
}
