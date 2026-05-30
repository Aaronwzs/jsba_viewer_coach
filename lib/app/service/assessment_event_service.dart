import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/assessment_event_model.dart';
import 'package:jsba_app/app/model/training_model.dart';

class AssessmentEventService {
  final FirebaseFirestore _db;

  AssessmentEventService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance {
    if (firestore == null) {
      _db.settings = const Settings(persistenceEnabled: false);
    }
  }

  static const String _collection = 'assessmentEvents';

  Future<List<AssessmentEventModel>> getAll() async {
    final snapshot = await _db
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AssessmentEventModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<List<AssessmentEventModel>> getByDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final events = await getAllWithTraining();
    return events
        .where((entry) {
          final date = entry.date;
          if (date == null) return false;
          return !date.isBefore(from) && !date.isAfter(to);
        })
        .map((entry) => entry.event)
        .toList();
  }

  Future<List<AssessmentEventModel>> getByType(String type) async {
    final snapshot = await _db
        .collection(_collection)
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AssessmentEventModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<List<AssessmentEventModel>> getByTrainingId(String trainingId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('trainingId', isEqualTo: trainingId)
        .get();

    return snapshot.docs
        .map((doc) => AssessmentEventModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<AssessmentEventModel?> getById(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return AssessmentEventModel.fromMap(doc.data()!, id: doc.id);
  }

  Future<List<AssessmentEventWithTraining>> getAllWithTraining() async {
    final events = await getAll();
    return _withTrainings(events);
  }

  Future<AssessmentEventWithTraining?> getByIdWithTraining(String id) async {
    final event = await getById(id);
    if (event == null) return null;
    final entries = await _withTrainings([event]);
    return entries.isEmpty ? null : entries.first;
  }

  Future<List<AssessmentEventWithTraining>> _withTrainings(
    List<AssessmentEventModel> events,
  ) async {
    final trainingIds = events
        .map((event) => event.trainingId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final trainings = <String, TrainingModel>{};

    for (final id in trainingIds) {
      final doc = await _db.collection('trainings').doc(id).get();
      if (doc.exists && doc.data() != null) {
        trainings[id] = TrainingModel.fromMap(doc.data()!, id: doc.id);
      }
    }

    final entries = events
        .map(
          (event) => AssessmentEventWithTraining(
            event: event,
            training: trainings[event.trainingId],
          ),
        )
        .toList();
    entries.sort((a, b) {
      final aDate = a.date;
      final bDate = b.date;
      if (aDate == null && bDate == null) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return entries;
  }

  Future<String> create(AssessmentEventModel event) async {
    final docRef = await _db.collection(_collection).add(event.toJson());
    return docRef.id;
  }

  Future<void> update(String id, AssessmentEventModel event) async {
    await _db.collection(_collection).doc(id).update(event.toJson());
  }

  Future<void> markCompleted(String id) async {
    await _db.collection(_collection).doc(id).update({
      'status': AssessmentEventStatus.completed,
    });
  }

  Future<void> markCancelled(String id) async {
    await _db.collection(_collection).doc(id).update({
      'status': AssessmentEventStatus.cancelled,
    });
  }

  Future<void> delete(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }
}
