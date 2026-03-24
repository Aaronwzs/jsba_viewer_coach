import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/invoice_model.dart';
import 'package:jsba_app/app/model/receipt_model.dart';

class BillingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _monthKey(int year, int month) {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  // -------------------- Invoices --------------------
  Future<String> createInvoice(InvoiceModel invoice) async {
    final docRef = _db.collection('invoices').doc();
    await docRef.set(invoice.toJson());
    return docRef.id;
  }

  Future<void> updateInvoice(String id, InvoiceModel invoice) async {
    await _db.collection('invoices').doc(id).update(invoice.toJson());
  }

  Future<InvoiceModel?> getInvoiceById(String id) async {
    final doc = await _db.collection('invoices').doc(id).get();
    if (!doc.exists) return null;
    return InvoiceModel.fromMap(doc.data()!, id: doc.id);
  }

  Future<List<InvoiceModel>> getInvoicesForMonth(int year, int month) async {
    final key = _monthKey(year, month);
    final snapshot = await _db
        .collection('invoices')
        .where('billingPeriodKey', isEqualTo: key)
        .get();

    final invoices = snapshot.docs
        .map((doc) => InvoiceModel.fromMap(doc.data(), id: doc.id))
        .toList();

    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  Future<List<InvoiceModel>> getInvoicesForPlayerMonth(
    String playerId,
    int year,
    int month,
  ) async {
    final invoices = await getInvoicesForMonth(year, month);
    return invoices.where((i) => i.playerId == playerId).toList();
  }

  Future<void> deleteInvoice(String id) async {
    await _db.collection('invoices').doc(id).delete();
  }

  Future<void> deleteReceipt(String id) async {
    await _db.collection('receipts').doc(id).delete();
  }

  // -------------------- Receipts --------------------
  Future<String> createReceipt(ReceiptModel receipt) async {
    final docRef = _db.collection('receipts').doc();
    await docRef.set(receipt.toJson());
    return docRef.id;
  }

  Future<ReceiptModel?> getReceiptById(String id) async {
    final doc = await _db.collection('receipts').doc(id).get();
    if (!doc.exists) return null;
    return ReceiptModel.fromMap(doc.data()!, id: doc.id);
  }

  Future<ReceiptModel?> getReceiptByInvoiceId(String invoiceId) async {
    final snapshot = await _db
        .collection('receipts')
        .where('invoiceId', isEqualTo: invoiceId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return ReceiptModel.fromMap(doc.data(), id: doc.id);
  }

  Future<List<ReceiptModel>> getReceiptsForMonth(int year, int month) async {
    final key = _monthKey(year, month);
    final snapshot = await _db
        .collection('receipts')
        .where('billingPeriodKey', isEqualTo: key)
        .get();

    final receipts = snapshot.docs
        .map((doc) => ReceiptModel.fromMap(doc.data(), id: doc.id))
        .toList();

    receipts.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return receipts;
  }

  // -------------------- Customer App Methods --------------------
  Future<List<InvoiceModel>> getInvoicesForPlayerIds(
    List<String> playerIds,
  ) async {
    if (playerIds.isEmpty) return [];

    final byPlayerId = _db
        .collection('invoices')
        .where('playerId', whereIn: playerIds)
        .get();

    final byPlayerIds = _db
        .collection('invoices')
        .where('playerIds', arrayContainsAny: playerIds)
        .get();

    final results = await Future.wait([byPlayerId, byPlayerIds]);

    final seen = <String>{};
    final invoices = <InvoiceModel>[];

    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        if (seen.add(doc.id)) {
          invoices.add(InvoiceModel.fromMap(doc.data(), id: doc.id));
        }
      }
    }

    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  Future<List<ReceiptModel>> getReceiptsForInvoiceIds(
    List<String> invoiceIds,
  ) async {
    if (invoiceIds.isEmpty) return [];

    final snapshot = await _db
        .collection('receipts')
        .where('invoiceId', whereIn: invoiceIds)
        .get();

    return snapshot.docs
        .map((doc) => ReceiptModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<List<ReceiptModel>> getReceiptsForPlayerIds(
    List<String> playerIds,
  ) async {
    if (playerIds.isEmpty) return [];

    final byPlayerId = _db
        .collection('receipts')
        .where('playerId', whereIn: playerIds)
        .get();

    final byPlayerIds = _db
        .collection('receipts')
        .where('playerIds', arrayContainsAny: playerIds)
        .get();

    final results = await Future.wait([byPlayerId, byPlayerIds]);

    final seen = <String>{};
    final receipts = <ReceiptModel>[];

    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        if (seen.add(doc.id)) {
          receipts.add(ReceiptModel.fromMap(doc.data(), id: doc.id));
        }
      }
    }

    receipts.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return receipts;
  }

  Future<void> markInvoiceAsCustomerPaid({
    required String invoiceId,
    required String paymentMethod,
    String? paymentReference,
  }) async {
    await _db.collection('invoices').doc(invoiceId).update({
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'status': 'sent',
      'sentAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
