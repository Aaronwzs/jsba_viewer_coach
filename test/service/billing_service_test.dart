import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/service/billing_service.dart';
import 'package:jsba_app/app/model/invoice_model.dart';
import 'package:jsba_app/app/model/receipt_model.dart';
import '../helpers/model_factories.dart';

void main() {
  group('BillingService', () {
    late FakeFirebaseFirestore firestore;
    late BillingService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = BillingService(firestore: firestore);
    });

    group('Invoices', () {
      test('createInvoice and getInvoiceById', () async {
        final invoice = TestModelFactory.createInvoice();
        final id = await service.createInvoice(invoice);
        expect(id.isNotEmpty, true);

        final fetched = await service.getInvoiceById(id);
        expect(fetched, isNotNull);
        expect(fetched!.playerId, 'player1');
        expect(fetched.totalAmount, 100.0);
        expect(fetched.status, 'draft');
      });

      test('getInvoiceById returns null for missing document', () async {
        final fetched = await service.getInvoiceById('nonexistent');
        expect(fetched, isNull);
      });

      test('updateInvoice', () async {
        final invoice = TestModelFactory.createInvoice();
        final id = await service.createInvoice(invoice);

        final updated = InvoiceModel(
          id: id,
          invoiceNumber: 'INV-002',
          playerId: 'player1',
          playerName: 'Alice Updated',
          playerPhone: '0123456789',
          billingYear: 2024,
          billingMonth: 6,
          billingPeriodKey: '2024-06',
          lineItems: const [],
          subTotal: 200.0,
          discountAmount: 0,
          taxAmount: 0,
          totalAmount: 200.0,
          status: 'sent',
          createdAt: DateTime.now(),
        );

        await service.updateInvoice(id, updated);

        final fetched = await service.getInvoiceById(id);
        expect(fetched, isNotNull);
        expect(fetched!.totalAmount, 200.0);
        expect(fetched.status, 'sent');
      });

      test('getInvoicesForMonth filters by billing period key', () async {
        final inv1 = TestModelFactory.createInvoice(
          id: 'inv1',
          invoiceNumber: 'INV-001',
          billingYear: 2024,
          billingMonth: 6,
        );
        final inv2 = TestModelFactory.createInvoice(
          id: 'inv2',
          invoiceNumber: 'INV-002',
          billingYear: 2024,
          billingMonth: 6,
        );
        final inv3 = TestModelFactory.createInvoice(
          id: 'inv3',
          invoiceNumber: 'INV-003',
          billingYear: 2024,
          billingMonth: 7,
        );

        await service.createInvoice(inv1);
        await service.createInvoice(inv2);
        await service.createInvoice(inv3);

        final juneInvoices = await service.getInvoicesForMonth(2024, 6);
        expect(juneInvoices.length, 2);

        final julyInvoices = await service.getInvoicesForMonth(2024, 7);
        expect(julyInvoices.length, 1);
      });

      test('getInvoicesForPlayerMonth filters by player within month', () async {
        final inv1 = TestModelFactory.createInvoice(
          id: 'inv1',
          invoiceNumber: 'INV-001',
          playerId: 'player1',
          billingYear: 2024,
          billingMonth: 6,
        );
        final inv2 = TestModelFactory.createInvoice(
          id: 'inv2',
          invoiceNumber: 'INV-002',
          playerId: 'player2',
          billingYear: 2024,
          billingMonth: 6,
        );

        await service.createInvoice(inv1);
        await service.createInvoice(inv2);

        final result = await service.getInvoicesForPlayerMonth('player1', 2024, 6);
        expect(result.length, 1);
        expect(result.first.playerId, 'player1');
      });

      test('deleteInvoice removes document', () async {
        final invoice = TestModelFactory.createInvoice();
        final id = await service.createInvoice(invoice);

        await service.deleteInvoice(id);

        final fetched = await service.getInvoiceById(id);
        expect(fetched, isNull);
      });

      test('markInvoiceAsCustomerPaid updates status and payment fields', () async {
        final invoice = TestModelFactory.createInvoice(status: 'draft');
        final id = await service.createInvoice(invoice);

        await service.markInvoiceAsCustomerPaid(
          invoiceId: id,
          paymentMethod: 'bank',
          paymentReference: 'REF-001',
        );

        final fetched = await service.getInvoiceById(id);
        expect(fetched, isNotNull);
        expect(fetched!.status, 'sent');
        expect(fetched.paymentMethod, 'bank');
        expect(fetched.paymentReference, 'REF-001');
        expect(fetched.sentAt, isNotNull);
      });

      test('getInvoicesForPlayerIds returns empty for empty list', () async {
        final result = await service.getInvoicesForPlayerIds([]);
        expect(result, isEmpty);
      });

      test('getInvoicesForPlayerIds returns matching invoices', () async {
        final inv1 = TestModelFactory.createInvoice(
          id: 'inv1',
          invoiceNumber: 'INV-001',
          playerId: 'player1',
        );
        final inv2 = TestModelFactory.createInvoice(
          id: 'inv2',
          invoiceNumber: 'INV-002',
          playerId: 'player2',
        );

        await service.createInvoice(inv1);
        await service.createInvoice(inv2);

        final result = await service.getInvoicesForPlayerIds(['player1']);
        expect(result.length, 1);
        expect(result.first.playerId, 'player1');
      });
    });

    group('Receipts', () {
      test('createReceipt and getReceiptById', () async {
        final receipt = TestModelFactory.createReceipt();
        final id = await service.createReceipt(receipt);
        expect(id.isNotEmpty, true);

        final fetched = await service.getReceiptById(id);
        expect(fetched, isNotNull);
        expect(fetched!.receiptNumber, 'REC-001');
        expect(fetched.amountPaid, 100.0);
        expect(fetched.paymentMethod, 'bank');
      });

      test('getReceiptById returns null for missing document', () async {
        final fetched = await service.getReceiptById('nonexistent');
        expect(fetched, isNull);
      });

      test('deleteReceipt removes document', () async {
        final receipt = TestModelFactory.createReceipt();
        final id = await service.createReceipt(receipt);

        await service.deleteReceipt(id);

        final fetched = await service.getReceiptById(id);
        expect(fetched, isNull);
      });

      test('getReceiptByInvoiceId finds receipt by invoice', () async {
        final receipt = TestModelFactory.createReceipt(invoiceId: 'inv-target');
        await service.createReceipt(receipt);

        final fetched = await service.getReceiptByInvoiceId('inv-target');
        expect(fetched, isNotNull);
        expect(fetched!.invoiceId, 'inv-target');
      });

      test('getReceiptByInvoiceId returns null when no receipt matches', () async {
        final fetched = await service.getReceiptByInvoiceId('nonexistent');
        expect(fetched, isNull);
      });

      test('getReceiptsForMonth filters by billing period key', () async {
        final rec1 = TestModelFactory.createReceipt(
          id: 'rec1',
          receiptNumber: 'REC-001',
          billingYear: 2024,
          billingMonth: 6,
        );
        final rec2 = TestModelFactory.createReceipt(
          id: 'rec2',
          receiptNumber: 'REC-002',
          billingYear: 2024,
          billingMonth: 6,
        );
        final rec3 = TestModelFactory.createReceipt(
          id: 'rec3',
          receiptNumber: 'REC-003',
          billingYear: 2024,
          billingMonth: 7,
        );

        await service.createReceipt(rec1);
        await service.createReceipt(rec2);
        await service.createReceipt(rec3);

        final juneReceipts = await service.getReceiptsForMonth(2024, 6);
        expect(juneReceipts.length, 2);

        final julyReceipts = await service.getReceiptsForMonth(2024, 7);
        expect(julyReceipts.length, 1);
      });

      test('getReceiptsForInvoiceIds returns empty for empty list', () async {
        final result = await service.getReceiptsForInvoiceIds([]);
        expect(result, isEmpty);
      });

      test('getReceiptsForInvoiceIds returns matching receipts', () async {
        final rec1 = TestModelFactory.createReceipt(
          id: 'rec1',
          receiptNumber: 'REC-001',
          invoiceId: 'inv1',
        );
        final rec2 = TestModelFactory.createReceipt(
          id: 'rec2',
          receiptNumber: 'REC-002',
          invoiceId: 'inv2',
        );

        await service.createReceipt(rec1);
        await service.createReceipt(rec2);

        final result = await service.getReceiptsForInvoiceIds(['inv1']);
        expect(result.length, 1);
        expect(result.first.invoiceId, 'inv1');
      });

      test('getReceiptsForPlayerIds returns empty for empty list', () async {
        final result = await service.getReceiptsForPlayerIds([]);
        expect(result, isEmpty);
      });

      test('getReceiptsForPlayerIds returns matching receipts', () async {
        final rec1 = TestModelFactory.createReceipt(
          id: 'rec1',
          receiptNumber: 'REC-001',
          playerId: 'player1',
        );
        final rec2 = TestModelFactory.createReceipt(
          id: 'rec2',
          receiptNumber: 'REC-002',
          playerId: 'player2',
        );

        await service.createReceipt(rec1);
        await service.createReceipt(rec2);

        final result = await service.getReceiptsForPlayerIds(['player1']);
        expect(result.length, 1);
        expect(result.first.playerId, 'player1');
      });
    });
  });
}
