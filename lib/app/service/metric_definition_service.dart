import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/metric_definition_model.dart';

class MetricDefinitionService {
  final FirebaseFirestore _db;

  MetricDefinitionService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance {
    if (firestore == null) {
      _db.settings = const Settings(persistenceEnabled: false);
    }
  }

  static const String _collection = 'metricDefinitions';

  Future<List<MetricDefinitionModel>> getAll() async {
    final snapshot = await _db
        .collection(_collection)
        .orderBy('sortOrder')
        .get();
    return snapshot.docs
        .map((doc) => MetricDefinitionModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<List<MetricDefinitionModel>> getByCategory(String category) async {
    final snapshot = await _db
        .collection(_collection)
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .get();
    return snapshot.docs
        .map((doc) => MetricDefinitionModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }
}
