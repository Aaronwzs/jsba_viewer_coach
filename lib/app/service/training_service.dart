// lib/app/service/training_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/training_model.dart';


class TrainingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get all trainings
  Stream<List<TrainingModel>> getAllTrainings() {
    return _db
        .collection('trainings')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TrainingModel.fromMap(doc.data(), id: doc.id))
        .toList());
  }

  // Get trainings for a specific month
  Future<List<TrainingModel>> getTrainingsForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final snapshot = await _db
        .collection('trainings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date')
        .get();

    return snapshot.docs
        .map((doc) => TrainingModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  // Get trainings for a specific date
  Future<List<TrainingModel>> getTrainingsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _db
        .collection('trainings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .get();

    return snapshot.docs
        .map((doc) => TrainingModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  // Get single training by ID
  Future<TrainingModel?> getTrainingById(String id) async {
    final doc = await _db.collection('trainings').doc(id).get();
    if (doc.exists) {
      return TrainingModel.fromMap(doc.data()!, id: doc.id);
    }
    return null;
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
    await _db.collection('trainings').doc(id).update({'status': status});
  }

  // Get all trainings for a specific player in a given month/year
  Future<List<TrainingModel>> getTrainingsForPlayerInMonth(
      String playerId,
      int year,
      int month,
      ) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Last day of month

    final snapshot = await _db
        .collection('trainings')
        .where('playerIds', arrayContains: playerId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TrainingModel.fromMap(doc.data(), id: doc.id))
        .toList();

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
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      for (final doc in snapshot.docs) {
        final training = TrainingModel.fromMap(doc.data(), id: doc.id);
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