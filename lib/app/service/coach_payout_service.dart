import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/coach_payout_model.dart';

class CoachPayoutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _monthKey(int year, int month) {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  Future<List<CoachPayoutModel>> getPayoutsForCoachMonth(
    String coachId,
    int year,
    int month,
  ) async {
    final key = _monthKey(year, month);
    // Debug: log query parameters
    // ignore: avoid_print
    print(
      'CoachPayoutService.getPayoutsForCoachMonth coachId=$coachId key=$key',
    );
    final snapshot = await _db
        .collection('coachPayouts')
        .where('coachId', isEqualTo: coachId)
        .where('periodKey', isEqualTo: key)
        .get();

    // Debug: log result count and ids
    // ignore: avoid_print
    print('CoachPayoutService: found ${snapshot.docs.length} docs');

    final payouts = snapshot.docs
        .map((d) => CoachPayoutModel.fromMap(d.data(), id: d.id))
        .toList();

    payouts.sort(
      (a, b) => (b.generatedAt ?? DateTime.now()).compareTo(
        a.generatedAt ?? DateTime.now(),
      ),
    );
    return payouts;
  }

  Future<CoachPayoutModel?> getPayoutById(String id) async {
    final doc = await _db.collection('coachPayouts').doc(id).get();
    if (!doc.exists) return null;
    return CoachPayoutModel.fromMap(doc.data()!, id: doc.id);
  }
}
