import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:jsba_app/app/service/feedback_service.dart';
import 'package:jsba_app/app/model/feedback_model.dart';
import '../helpers/model_factories.dart';

void main() {
  group('FeedbackService', () {
    late FakeFirebaseFirestore firestore;
    late FeedbackService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FeedbackService(firestore: firestore);
    });

    test('submitFeedback creates document in feedback collection', () async {
      final feedback = TestModelFactory.createFeedback();

      await service.submitFeedback(feedback);

      final snapshot = await firestore.collection('feedback').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['title'], feedback.title);
      expect(snapshot.docs.first.data()['description'], feedback.description);
      expect(snapshot.docs.first.data()['userId'], feedback.userId);
      expect(snapshot.docs.first.data()['type'], feedback.type.name);
    });
  });
}
