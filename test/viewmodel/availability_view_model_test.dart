import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:jsba_app/app/service/availability_service.dart';
import 'package:jsba_app/app/viewmodel/availability_view_model.dart';
import '../helpers/model_factories.dart';

class MockAvailabilityService extends Mock implements AvailabilityService {}

void main() {
  late MockAvailabilityService mockService;
  late AvailabilityViewModel viewModel;

  setUp(() {
    mockService = MockAvailabilityService();
    viewModel = AvailabilityViewModel(service: mockService);
  });

  group('loadSlots', () {
    test('loadSlots fetches slots and updates state', () async {
      final slots = [
        TestModelFactory.createAvailabilitySlot(id: 'slot1', title: 'Session 1'),
        TestModelFactory.createAvailabilitySlot(id: 'slot2', title: 'Session 2'),
      ];
      when(() => mockService.getActiveSlots()).thenAnswer((_) async => slots);

      expect(viewModel.isLoading, false);
      expect(viewModel.slots, isEmpty);

      await viewModel.loadSlots();

      expect(viewModel.isLoading, false);
      expect(viewModel.slots.length, 2);
      expect(viewModel.slots[0].id, 'slot1');
      expect(viewModel.slots[1].id, 'slot2');
    });

    test('loadSlots sets error on failure', () async {
      when(() => mockService.getActiveSlots()).thenThrow(Exception('Failed'));

      await viewModel.loadSlots();

      expect(viewModel.isLoading, false);
      expect(viewModel.error, 'Exception: Failed');
      expect(viewModel.slots, isEmpty);
    });
  });

  group('respond', () {
    test('respond calls service and updates local slot', () async {
      final slot = TestModelFactory.createAvailabilitySlot(id: 'slot1', responses: {});
      when(() => mockService.getActiveSlots()).thenAnswer((_) async => [slot]);
      await viewModel.loadSlots();

      when(() => mockService.respond('slot1', 'player1', true))
          .thenAnswer((_) async {});

      final result = await viewModel.respond('slot1', 'player1', true);

      expect(result, true);
      expect(viewModel.slots.first.responses, containsPair('player1', true));
      verify(() => mockService.respond('slot1', 'player1', true)).called(1);
    });

    test('respond sets error on failure', () async {
      final slot = TestModelFactory.createAvailabilitySlot(id: 'slot1', responses: {});
      when(() => mockService.getActiveSlots()).thenAnswer((_) async => [slot]);
      await viewModel.loadSlots();

      when(() => mockService.respond(any(), any(), any()))
          .thenThrow(Exception('Service error'));

      final result = await viewModel.respond('slot1', 'player1', false);

      expect(result, false);
      expect(viewModel.error, 'Exception: Service error');
    });
  });

  group('removeResponse', () {
    test('removeResponse calls service and removes response', () async {
      final slot = TestModelFactory.createAvailabilitySlot(
        id: 'slot1',
        responses: {'player1': true, 'player2': false},
      );
      when(() => mockService.getActiveSlots()).thenAnswer((_) async => [slot]);
      await viewModel.loadSlots();
      expect(viewModel.slots.first.responses.length, 2);

      when(() => mockService.removeResponse('slot1', 'player1'))
          .thenAnswer((_) async {});

      final result = await viewModel.removeResponse('slot1', 'player1');

      expect(result, true);
      expect(viewModel.slots.first.responses.containsKey('player1'), false);
      expect(viewModel.slots.first.responses.length, 1);
      verify(() => mockService.removeResponse('slot1', 'player1')).called(1);
    });
  });

  group('clearError', () {
    test('clearError resets error state', () async {
      when(() => mockService.getActiveSlots()).thenThrow(Exception('Err'));
      await viewModel.loadSlots();
      expect(viewModel.error, isNotNull);

      viewModel.clearError();

      expect(viewModel.error, isNull);
    });
  });
}
