import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/feedback_model.dart';
import 'package:jsba_app/app/utils/starter_handler.dart' as starter_handler;

class FeedbackService {
  final FirebaseFirestore _db;

  FeedbackService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    if (firestore == null) {
      _db.settings = const Settings(persistenceEnabled: false);
    }
  }

  Future<void> submitFeedback(FeedbackModel feedback) async {
    await _db.collection('feedback').add(feedback.toJson());

    // Notify admins when feedback is submitted
    final adminSnapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'Admin')
        .get();
    final adminIds = adminSnapshot.docs.map((doc) => doc.id).toList();

    if (adminIds.isNotEmpty) {
      starter_handler.notificationService.sendNotificationToUserIds(
        userIds: adminIds,
        type: 'feedback',
        title: 'New Feedback',
        body: feedback.title.isNotEmpty
            ? feedback.title
            : 'New feedback submitted by ${feedback.userId}',
        referenceId: feedback.userId,
        referenceCollection: 'feedbacks',
      );
    }
  }
}
