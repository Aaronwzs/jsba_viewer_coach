import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FeedbackService() {
    _db.settings = const Settings(persistenceEnabled: false);
  }

  Future<void> submitFeedback(FeedbackModel feedback) async {
    await _db.collection('feedback').add(feedback.toJson());
  }
}
