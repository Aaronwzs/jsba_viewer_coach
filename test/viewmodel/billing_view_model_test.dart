import 'package:flutter_test/flutter_test.dart';
import 'package:jsba_app/app/model/user_payment_model.dart';
import 'package:jsba_app/app/service/user_payment_service.dart';
import 'package:jsba_app/app/viewmodel/billing_view_model.dart';
import 'package:mocktail/mocktail.dart';

class MockUserPaymentService extends Mock implements UserPaymentService {}

void main() {
  group('BillingViewModel', () {
    late MockUserPaymentService userPaymentService;
    late BillingViewModel viewModel;

    setUp(() {
      userPaymentService = MockUserPaymentService();
      viewModel = BillingViewModel(userPaymentService: userPaymentService);
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
      test('loads and filters userPayments by selected month', () async {
        viewModel.setSelectedMonth(DateTime(2024, 6));

        final paymentJune = UserPaymentModel(
          id: 'up1',
          playerId: 'p1',
          playerName: 'Alice',
          parentId: 'parent1',
          amount: 100.0,
          paymentMethod: 'bank',
          paymentStatus: 'pending',
          billingPeriodKey: '2024-06',
          createdAt: DateTime(2024, 6, 15),
        );
        final paymentJuly = UserPaymentModel(
          id: 'up2',
          playerId: 'p1',
          playerName: 'Alice',
          parentId: 'parent1',
          amount: 100.0,
          paymentMethod: 'bank',
          paymentStatus: 'pending',
          billingPeriodKey: '2024-07',
          createdAt: DateTime(2024, 7, 15),
        );

        when(() => userPaymentService.getUserPaymentsForPeriod(['p1'], 2024, 6))
            .thenAnswer((_) async => [paymentJune]);
        when(() => userPaymentService.getUserPaymentsForPeriod(['p1'], 2024, 7))
            .thenAnswer((_) async => [paymentJuly]);

        await viewModel.loadInvoicesForPlayerIds(['p1']);

        expect(viewModel.isLoading, false);
        expect(viewModel.userPayments.length, 1);
        expect(viewModel.userPayments.first.id, 'up1');

        viewModel.setSelectedMonth(DateTime(2024, 7));
        await viewModel.loadInvoicesForPlayerIds(['p1']);
        expect(viewModel.userPayments.first.id, 'up2');
      });

      test('sets error on failure', () async {
        when(() => userPaymentService.getUserPaymentsForPeriod(any(), any(), any()))
            .thenThrow(Exception('Network error'));

        await viewModel.loadInvoicesForPlayerIds(['p1']);

        expect(viewModel.error, contains('Network error'));
        expect(viewModel.isLoading, false);
      });

      test('sets isLoading during load', () async {
        when(() => userPaymentService.getUserPaymentsForPeriod(any(), any(), any()))
            .thenAnswer((_) async => []);
        when(() => userPaymentService.getUserPaymentsForPeriod(any(), any(), any()))
            .thenAnswer((_) async => []);

        final future = viewModel.loadInvoicesForPlayerIds(['p1']);
        expect(viewModel.isLoading, true);
        await future;
        expect(viewModel.isLoading, false);
      });
    });

    group('pendingPayments / approvedPayments / rejectedPayments', () {
      test('filter correctly', () async {
        viewModel.setSelectedMonth(DateTime(2024, 6));

        final pendingPayment = UserPaymentModel(
          id: 'up1',
          playerId: 'p1',
          playerName: 'Alice',
          parentId: 'parent1',
          amount: 100.0,
          paymentMethod: 'bank',
          paymentStatus: 'pending',
          billingPeriodKey: '2024-06',
          createdAt: DateTime(2024, 6, 15),
        );
        final approvedPayment = UserPaymentModel(
          id: 'up2',
          playerId: 'p1',
          playerName: 'Alice',
          parentId: 'parent1',
          amount: 100.0,
          paymentMethod: 'bank',
          paymentStatus: 'approved',
          billingPeriodKey: '2024-06',
          createdAt: DateTime(2024, 6, 15),
        );
        final rejectedPayment = UserPaymentModel(
          id: 'up3',
          playerId: 'p1',
          playerName: 'Alice',
          parentId: 'parent1',
          amount: 100.0,
          paymentMethod: 'bank',
          paymentStatus: 'rejected',
          billingPeriodKey: '2024-06',
          createdAt: DateTime(2024, 6, 15),
        );

        when(() => userPaymentService.getUserPaymentsForPeriod(['p1'], 2024, 6))
            .thenAnswer((_) async => [pendingPayment, approvedPayment, rejectedPayment]);

        await viewModel.loadInvoicesForPlayerIds(['p1']);

        expect(viewModel.pendingPayments.length, 1);
        expect(viewModel.pendingPayments.first.id, 'up1');
        expect(viewModel.approvedPayments.length, 1);
        expect(viewModel.approvedPayments.first.id, 'up2');
        expect(viewModel.rejectedPayments.length, 1);
        expect(viewModel.rejectedPayments.first.id, 'up3');
      });
    });

    group('cancelUserPayment', () {
      test('removes payment from list on success', () async {
        viewModel.setSelectedMonth(DateTime(2024, 6));

        final payment = UserPaymentModel(
          id: 'up1',
          playerId: 'p1',
          playerName: 'Alice',
          parentId: 'parent1',
          amount: 100.0,
          paymentMethod: 'bank',
          paymentStatus: 'pending',
          billingPeriodKey: '2024-06',
          createdAt: DateTime(2024, 6, 15),
        );

        when(() => userPaymentService.getUserPaymentsForPeriod(['p1'], 2024, 6))
            .thenAnswer((_) async => [payment]);
        when(() => userPaymentService.cancelPayment('up1'))
            .thenAnswer((_) async {});

        await viewModel.loadInvoicesForPlayerIds(['p1']);
        final result = await viewModel.cancelUserPayment('up1');

        expect(result, true);
        expect(viewModel.userPayments.isEmpty, true);
      });

      test('sets error on failure', () async {
        when(() => userPaymentService.cancelPayment('up1'))
            .thenThrow(Exception('Cancel failed'));

        final result = await viewModel.cancelUserPayment('up1');

        expect(result, false);
        expect(viewModel.error, contains('Cancel failed'));
      });
    });

    group('clearError', () {
      test('resets error', () {
        viewModel.clearError();
        expect(viewModel.error, isNull);
      });
    });
  });
}
