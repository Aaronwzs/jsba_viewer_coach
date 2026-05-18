import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsba_app/app/service/academy_settings_service.dart';
import 'package:jsba_app/app/service/billing_service.dart';
import 'package:jsba_app/app/service/pdf_doc_service.dart';
import 'package:jsba_app/app/viewmodel/billing_view_model.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/model_factories.dart';

class MockBillingService extends Mock implements BillingService {}
class MockPdfService extends Mock implements PdfService {}
class MockAcademySettingsService extends Mock implements AcademySettingsService {}
class MockDio extends Mock implements Dio {}

void main() {
  group('BillingViewModel', () {
    late MockBillingService billingService;
    late MockPdfService pdfService;
    late MockAcademySettingsService academySettingsService;
    late MockDio dio;
    late BillingViewModel viewModel;

    setUp(() {
      billingService = MockBillingService();
      pdfService = MockPdfService();
      academySettingsService = MockAcademySettingsService();
      dio = MockDio();
      viewModel = BillingViewModel(
        billingService: billingService,
        pdfService: pdfService,
        academySettingsService: academySettingsService,
        dio: dio,
      );
    });

    group('setSelectedMonth', () {
      test('updates selected month', () {
        final month = DateTime(2024, 7);
        viewModel.setSelectedMonth(month);
        expect(viewModel.selectedMonth.year, 2024);
        expect(viewModel.selectedMonth.month, 7);
      });

      test('sets day to 1 regardless of input day', () {
        final month = DateTime(2024, 7, 15);
        viewModel.setSelectedMonth(month);
        expect(viewModel.selectedMonth.day, 1);
      });
    });

    group('loadInvoicesForPlayerIds', () {
      test('loads and filters invoices by selected month', () async {
        viewModel.setSelectedMonth(DateTime(2024, 6));

        final invoiceJune = TestModelFactory.createInvoice(
          id: 'inv1',
          billingYear: 2024,
          billingMonth: 6,
        );
        final invoiceJuly = TestModelFactory.createInvoice(
          id: 'inv2',
          billingYear: 2024,
          billingMonth: 7,
        );
        final receiptJune = TestModelFactory.createReceipt(
          id: 'rec1',
          billingYear: 2024,
          billingMonth: 6,
        );

        when(() => billingService.getInvoicesForPlayerIds(['p1']))
            .thenAnswer((_) async => [invoiceJune, invoiceJuly]);
        when(() => billingService.getReceiptsForPlayerIds(['p1']))
            .thenAnswer((_) async => [receiptJune]);

        await viewModel.loadInvoicesForPlayerIds(['p1']);

        expect(viewModel.isLoading, false);
        expect(viewModel.invoices.length, 1);
        expect(viewModel.invoices.first.id, 'inv1');
        expect(viewModel.receipts.length, 1);
        expect(viewModel.receipts.first.id, 'rec1');
      });

      test('sets error on failure', () async {
        when(() => billingService.getInvoicesForPlayerIds(any()))
            .thenThrow(Exception('Network error'));

        await viewModel.loadInvoicesForPlayerIds(['p1']);

        expect(viewModel.error, contains('Network error'));
        expect(viewModel.isLoading, false);
      });

      test('sets isLoading during load', () async {
        when(() => billingService.getInvoicesForPlayerIds(any()))
            .thenAnswer((_) async => []);
        when(() => billingService.getReceiptsForPlayerIds(any()))
            .thenAnswer((_) async => []);

        final future = viewModel.loadInvoicesForPlayerIds(['p1']);
        expect(viewModel.isLoading, true);
        await future;
        expect(viewModel.isLoading, false);
      });
    });

    group('unpaidInvoices / paidInvoices', () {
      test('filter correctly', () async {
        viewModel.setSelectedMonth(DateTime(2024, 6));

        final paidInvoice = TestModelFactory.createInvoice(
          id: 'inv1',
          status: 'paid',
          billingYear: 2024,
          billingMonth: 6,
        );
        final unpaidInvoice = TestModelFactory.createInvoice(
          id: 'inv2',
          status: 'draft',
          billingYear: 2024,
          billingMonth: 6,
        );
        final sentInvoice = TestModelFactory.createInvoice(
          id: 'inv3',
          status: 'sent',
          billingYear: 2024,
          billingMonth: 6,
        );

        when(() => billingService.getInvoicesForPlayerIds(any()))
            .thenAnswer((_) async => [paidInvoice, unpaidInvoice, sentInvoice]);
        when(() => billingService.getReceiptsForPlayerIds(any()))
            .thenAnswer((_) async => []);

        await viewModel.loadInvoicesForPlayerIds(['p1']);

        expect(viewModel.paidInvoices.length, 1);
        expect(viewModel.paidInvoices.first.id, 'inv1');
        expect(viewModel.unpaidInvoices.length, 2);
        expect(viewModel.unpaidInvoices.map((i) => i.id),
            containsAll(['inv2', 'inv3']));
      });
    });

    group('markAsPaid', () {
      test('updates invoice status locally and calls service', () async {
        viewModel.setSelectedMonth(DateTime(2024, 6));
        final invoice = TestModelFactory.createInvoice(
          id: 'inv1',
          billingYear: 2024,
          billingMonth: 6,
        );

        when(() => billingService.getInvoicesForPlayerIds(any()))
            .thenAnswer((_) async => [invoice]);
        when(() => billingService.getReceiptsForPlayerIds(any()))
            .thenAnswer((_) async => []);
        when(() => billingService.markInvoiceAsCustomerPaid(
          invoiceId: any(named: 'invoiceId'),
          paymentMethod: any(named: 'paymentMethod'),
          paymentReference: any(named: 'paymentReference'),
        )).thenAnswer((_) async => {});

        await viewModel.loadInvoicesForPlayerIds(['p1']);
        final result = await viewModel.markAsPaid(
          invoiceId: 'inv1',
          paymentMethod: 'bank_transfer',
          paymentReference: 'REF123',
        );

        expect(result, true);
        expect(viewModel.isLoading, false);
        verify(() => billingService.markInvoiceAsCustomerPaid(
          invoiceId: 'inv1',
          paymentMethod: 'bank_transfer',
          paymentReference: 'REF123',
        )).called(1);
      });

      test('sets error on failure', () async {
        when(() => billingService.markInvoiceAsCustomerPaid(
          invoiceId: any(named: 'invoiceId'),
          paymentMethod: any(named: 'paymentMethod'),
          paymentReference: any(named: 'paymentReference'),
        )).thenThrow(Exception('Mark failed'));

        final result = await viewModel.markAsPaid(
          invoiceId: 'inv1',
          paymentMethod: 'cash',
        );

        expect(result, false);
        expect(viewModel.error, contains('Mark failed'));
        expect(viewModel.isLoading, false);
      });
    });

    group('getReceiptForInvoice', () {
      test('finds receipt by invoice ID', () async {
        viewModel.setSelectedMonth(DateTime(2024, 6));
        final invoice = TestModelFactory.createInvoice(
          id: 'inv1',
          billingYear: 2024,
          billingMonth: 6,
        );
        final receipt = TestModelFactory.createReceipt(
          id: 'rec1',
          invoiceId: 'inv1',
          billingYear: 2024,
          billingMonth: 6,
        );

        when(() => billingService.getInvoicesForPlayerIds(any()))
            .thenAnswer((_) async => [invoice]);
        when(() => billingService.getReceiptsForPlayerIds(any()))
            .thenAnswer((_) async => [receipt]);

        await viewModel.loadInvoicesForPlayerIds(['p1']);

        final found = viewModel.getReceiptForInvoice('inv1');
        expect(found, isNotNull);
        expect(found!.id, 'rec1');
      });

      test('returns null when not found', () {
        final result = viewModel.getReceiptForInvoice('nonexistent');
        expect(result, isNull);
      });
    });

    group('clearError', () {
      test('resets error', () {
        viewModel.setSelectedMonth(DateTime(2024, 6));

        when(() => billingService.getInvoicesForPlayerIds(any()))
            .thenThrow(Exception('Some error'));

        viewModel.loadInvoicesForPlayerIds(['p1']);

        viewModel.clearError();
        expect(viewModel.error, isNull);
      });
    });

  });
}
