import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/invoice_model.dart';
import 'package:jsba_app/app/model/receipt_model.dart';
import 'package:jsba_app/app/utils/starter_handler.dart' as starter_handler;

class BillingService {
  final FirebaseFirestore _db;

  BillingService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    if (firestore == null) {
      _db.settings = const Settings(persistenceEnabled: false);
    }
  }

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

    final seen = <String>{};
    final invoices = <InvoiceModel>[];
    final chunks = _chunkList(playerIds, 30);

    for (final chunk in chunks) {
      try {
        final byPlayerId = await _db
            .collection('invoices')
            .where('playerId', whereIn: chunk)
            .get();

        for (final doc in byPlayerId.docs) {
          if (seen.add(doc.id)) {
            invoices.add(InvoiceModel.fromMap(doc.data(), id: doc.id));
          }
        }
      } catch (_) {}

      try {
        final byPlayerIds = await _db
            .collection('invoices')
            .where('playerIds', arrayContainsAny: chunk)
            .get();

        for (final doc in byPlayerIds.docs) {
          if (seen.add(doc.id)) {
            invoices.add(InvoiceModel.fromMap(doc.data(), id: doc.id));
          }
        }
      } catch (_) {}
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

    final seen = <String>{};
    final receipts = <ReceiptModel>[];
    final chunks = _chunkList(playerIds, 30);

    for (final chunk in chunks) {
      try {
        final byPlayerId = await _db
            .collection('receipts')
            .where('playerId', whereIn: chunk)
            .get();

        for (final doc in byPlayerId.docs) {
          if (seen.add(doc.id)) {
            receipts.add(ReceiptModel.fromMap(doc.data(), id: doc.id));
          }
        }
      } catch (_) {}

      try {
        final byPlayerIds = await _db
            .collection('receipts')
            .where('playerIds', arrayContainsAny: chunk)
            .get();

        for (final doc in byPlayerIds.docs) {
          if (seen.add(doc.id)) {
            receipts.add(ReceiptModel.fromMap(doc.data(), id: doc.id));
          }
        }
      } catch (_) {}
    }

    receipts.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return receipts;
  }

  List<List<String>> _chunkList(List<String> list, int chunkSize) {
    final chunks = <List<String>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  Future<void> markInvoiceAsCustomerPaid({
    required String invoiceId,
    required String paymentMethod,
    String? paymentReference,
    List<String> receiptUrls = const [],
    /// The user ID to send a confirmation notification to
    required String userId,
  }) async {
    // Get invoice details for the notification body
    final invoiceDoc = await _db.collection('invoices').doc(invoiceId).get();
    final invoiceData = invoiceDoc.data();
    final invoiceNumber = invoiceData?['invoiceNumber'] as String? ?? '';
    final totalAmount = (invoiceData?['totalAmount'] as num?)?.toDouble() ?? 0;

    await _db.collection('invoices').doc(invoiceId).update({
      'paymentMethod': paymentMethod,
      'paymentReference':
          receiptUrls.isNotEmpty ? receiptUrls.first : paymentReference,
      'receiptUrls': receiptUrls,
      'status': 'sent',
      'sentAt': Timestamp.fromDate(DateTime.now()),
    });

    // Write a notification to the user's in-app feed
    starter_handler.notificationService.sendNotificationToUserIds(
      userIds: [userId],
      type: 'invoice',
      title: 'Payment Submitted',
      body: 'Invoice $invoiceNumber for RM${totalAmount.toStringAsFixed(2)} has been submitted for confirmation.',
      referenceId: invoiceId,
      referenceCollection: 'invoices',
    );
  }
}
