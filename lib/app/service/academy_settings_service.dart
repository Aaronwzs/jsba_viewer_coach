import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/academy_settings_model.dart';

class AcademySettingsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AcademySettingsService() {
    _db.settings = const Settings(persistenceEnabled: false);
  }

  static const String _collection = 'academySettings';
  static const String _docId = 'academy_settings';

  Future<AcademySettingsModel> getSettings() async {
    final doc = await _db.collection(_collection).doc(_docId).get();

    if (!doc.exists) {
      final defaults = AcademySettingsModel.defaults();
      await createSettings(defaults);
      return defaults;
    }

    return AcademySettingsModel.fromMap(doc.data()!);
  }

  Future<void> createSettings(AcademySettingsModel settings) async {
    await _db.collection(_collection).doc(_docId).set(settings.toJson());
  }
}
