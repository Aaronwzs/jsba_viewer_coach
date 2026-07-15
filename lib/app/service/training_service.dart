// lib/app/service/training_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/service/notification_service.dart';
import 'package:jsba_app/app/utils/starter_handler.dart' as starter_handler;


class TrainingService {
  final FirebaseFirestore _db;

  TrainingService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  // Get all trainings
  Stream<List<TrainingModel>> getAllTrainings() {
    return _db
        .collection('trainings')
        .snapshots()
        .map((snapshot) {
      final trainings = snapshot.docs
          .map((doc) => TrainingModel.fromMap(doc.data(), id: doc.id))
          .toList();
      trainings.sort((a, b) => a.date.compareTo(b.date));
      return trainings;
    });
  }

  // Get trainings for a specific month
  Future<List<TrainingModel>> getTrainingsForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final snapshot = await _db
        .collection('trainings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final trainings = snapshot.docs
        .map((doc) => TrainingModel.fromMap(doc.data(), id: doc.id))
        .toList();
    trainings.sort((a, b) => a.date.compareTo(b.date));
    return trainings;
  }

  // Get trainings for a specific date
  Future<List<TrainingModel>> getTrainingsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _db
        .collection('trainings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    final trainings = snapshot.docs
        .map((doc) => TrainingModel.fromMap(doc.data(), id: doc.id))
        .toList();
    trainings.sort((a, b) => a.date.compareTo(b.date));
    return trainings;
  }

  // Get single training by ID
  Future<TrainingModel?> getTrainingById(String id) async {
    final doc = await _db.collection('trainings').doc(id).get();
    if (doc.exists) {
      return TrainingModel.fromMap(doc.data()!, id: doc.id);
    }
    return null;
  }

  /// Fetches multiple trainings by their IDs (batched in chunks of 30 to
  /// respect Firestore's `whereIn` limit). Returns them in document-id order.
  Future<List<TrainingModel>> getTrainingsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final results = <TrainingModel>[];
    for (var i = 0; i < ids.length; i += 30) {
      final batch = ids.sublist(i, (i + 30).clamp(0, ids.length));
      final snapshot = await _db
          .collection('trainings')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in snapshot.docs) {
        results.add(TrainingModel.fromMap(doc.data(), id: doc.id));
      }
    }
    results.sort((a, b) => a.date.compareTo(b.date));
    return results;
  }

  // Add new training
  Future<String> addTraining(TrainingModel training) async {
    final docRef = _db.collection('trainings').doc();
    await docRef.set(training.toJson());
    return docRef.id;
  }

  // Update training
  Future<void> updateTraining(String id, TrainingModel training) async {
    final data = training.toJson();
    await _db.collection('trainings').doc(id).update(data);
  }

  // Delete training
  Future<void> deleteTraining(String id) async {
    await _db.collection('trainings').doc(id).delete();
  }

  // Update training status
  Future<void> updateTrainingStatus(String id, String status) async {
    // Get training details before updating
    final trainingDoc = await _db.collection('trainings').doc(id).get();
    final trainingData = trainingDoc.data();
    final rawPlayerIds = trainingData?['playerIds'];
    final List<String> playerIds = [];
    if (rawPlayerIds is List) {
      for (final e in rawPlayerIds) {
        if (e != null) {
          playerIds.add(e.toString());
        }
      }
    }
    final className = trainingData?['className'] as String? ?? 'Training';

    await _db.collection('trainings').doc(id).update({'status': status});

    // Notify parents when training is cancelled
    if (status == 'cancelled' && playerIds.isNotEmpty) {
      final parentIds =
          await NotificationService.getParentIdsForPlayers(playerIds);
      if (parentIds.isNotEmpty) {
        starter_handler.notificationService.sendNotificationToUserIds(
          userIds: parentIds,
          type: 'training',
          title: 'Training Cancelled',
          body: '$className has been cancelled.',
          referenceId: id,
          referenceCollection: 'training',
        );
      }
    }
  }

  // Get all trainings for a specific player in a given month/year
  Future<List<TrainingModel>> getTrainingsForPlayerInMonth(
      String playerId,
      int year,
      int month,
      ) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final snapshot = await _db
        .collection('trainings')
        .where('playerIds', arrayContains: playerId)
        .get();

    final trainings = snapshot.docs
        .map((doc) => TrainingModel.fromMap(doc.data(), id: doc.id))
        .where((t) => !t.date.isBefore(startDate) && !t.date.isAfter(endDate))
        .toList();
    trainings.sort((a, b) => b.date.compareTo(a.date));
    return trainings;

  }
  // Get trainings for today
  Future<List<TrainingModel>> getTrainingsForToday() async {
    final now = DateTime.now();
    return getTrainingsForDate(now);
  }

  // Get trainings for month (alias, clearer naming)
  Future<List<TrainingModel>> getTrainingsForMonthYear(int year, int month) async {
    return getTrainingsForMonth(DateTime(year, month, 1));
  }

  // Get trainings for multiple players in a given month/year
  Future<List<TrainingModel>> getTrainingsForPlayersInMonth(
    List<String> playerIds,
    int year,
    int month,
  ) async {
    if (playerIds.isEmpty) return [];

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final trainingMap = <String, TrainingModel>{};

    for (final playerId in playerIds) {
      final snapshot = await _db
          .collection('trainings')
          .where('playerIds', arrayContains: playerId)
          .get();

      for (final doc in snapshot.docs) {
        final training = TrainingModel.fromMap(doc.data(), id: doc.id);
        // Filter by date in-memory to avoid needing a composite index
        if (training.date.isBefore(startDate) || training.date.isAfter(endDate)) continue;
        trainingMap[training.id] = training;
      }
    }

    final trainings = trainingMap.values.toList();
    trainings.sort((a, b) => a.date.compareTo(b.date));
    return trainings;
  }

Future<List<TrainingModel>> getTrainingsForCoachInMonth(
    String coachId,
    int year,
    int month,
  ) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final snapshot = await _db
        .collection('trainings')
        .where('coachId', isEqualTo: coachId)
        .get();

    final allTrainings = snapshot.docs
        .map((doc) => TrainingModel.fromMap(doc.data(), id: doc.id))
        .toList();

    final filtered = allTrainings.where((t) => 
      t.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
      t.date.isBefore(endDate.add(const Duration(days: 1))))
    .toList();

    filtered.sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  }

  Future<List<TrainingModel>> getTrainingsForCoach(String coachId) async {
    final snapshot = await _db
        .collection('trainings')
        .where('coachId', isEqualTo: coachId)
        .get();

    final results = snapshot.docs
        .map((doc) => TrainingModel.fromMap(doc.data(), id: doc.id))
        .toList();

    // Sort in memory — avoids needing a composite Firestore index
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }
}