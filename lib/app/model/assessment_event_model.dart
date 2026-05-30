import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/training_model.dart';

class AssessmentEventType {
  static const String physical = 'physical';
  static const String skill = 'skill';
  static const String competition = 'competition';

  static String displayName(String type) {
    switch (type) {
      case physical:
        return 'Physical Test Day';
      case skill:
        return 'Skill Test Day';
      case competition:
        return 'Mini Competition';
      default:
        return type;
    }
  }
}

class AssessmentEventStatus {
  static const String planned = 'planned';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class AssessmentEventModel {
  final String id;
  final String trainingId;
  final String type;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final String? notes;

  AssessmentEventModel({
    required this.id,
    required this.trainingId,
    required this.type,
    this.status = AssessmentEventStatus.planned,
    required this.createdBy,
    DateTime? createdAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  String get typeDisplayName => AssessmentEventType.displayName(type);

  bool get isCompleted => status == AssessmentEventStatus.completed;
  bool get isCancelled => status == AssessmentEventStatus.cancelled;

  Map<String, dynamic> toJson() => {
    'type': type,
    'trainingId': trainingId,
    'status': status,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'notes': notes,
  };

  factory AssessmentEventModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime parseDate(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is DateTime) return field;
      return DateTime.now();
    }

    return AssessmentEventModel(
      id: id,
      trainingId: map['trainingId'] as String? ?? '',
      type: map['type'] as String? ?? AssessmentEventType.physical,
      status: map['status'] as String? ?? AssessmentEventStatus.planned,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
      notes: map['notes'] as String?,
    );
  }

  AssessmentEventModel copyWith({
    String? id,
    String? trainingId,
    String? type,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    String? notes,
  }) {
    return AssessmentEventModel(
      id: id ?? this.id,
      trainingId: trainingId ?? this.trainingId,
      type: type ?? this.type,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}

class AssessmentEventWithTraining {
  final AssessmentEventModel event;
  final TrainingModel? training;

  const AssessmentEventWithTraining({required this.event, this.training});

  String get id => event.id;
  String get trainingId => event.trainingId;
  String get type => event.type;
  String get status => event.status;
  String get createdBy => event.createdBy;
  DateTime get createdAt => event.createdAt;
  String? get notes => event.notes;
  String get typeDisplayName => event.typeDisplayName;
  bool get isCompleted => event.isCompleted;
  bool get isCancelled => event.isCancelled;

  DateTime? get date => training?.date;
  String? get coachId => training?.coachId;
  List<String> get playerIds => training?.playerIds ?? const [];
  String? get groupName => training?.className;

  AssessmentEventWithTraining copyWith({
    AssessmentEventModel? event,
    TrainingModel? training,
  }) {
    return AssessmentEventWithTraining(
      event: event ?? this.event,
      training: training ?? this.training,
    );
  }
}
