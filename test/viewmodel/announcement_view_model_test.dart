import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:jsba_app/app/repositories/announcement_repository.dart';
import 'package:jsba_app/app/viewmodel/announcement_view_model.dart';
import '../helpers/model_factories.dart';

class MockAnnouncementRepository extends Mock implements AnnouncementRepository {}

void main() {
  late MockAnnouncementRepository mockRepository;
  late AnnouncementViewModel viewModel;

  setUp(() {
    mockRepository = MockAnnouncementRepository();
    viewModel = AnnouncementViewModel(repository: mockRepository);
  });

  group('loadAnnouncements', () {
    test('loadAnnouncements sets announcements from repository', () async {
      final announcements = [
        TestModelFactory.createAnnouncement(id: '1', title: 'Ann1'),
        TestModelFactory.createAnnouncement(id: '2', title: 'Ann2'),
      ];
      when(() => mockRepository.getAnnouncements()).thenAnswer((_) async => announcements);

      expect(viewModel.isLoading, false);
      await viewModel.loadAnnouncements();

      expect(viewModel.isLoading, false);
      expect(viewModel.announcements.length, 2);
      expect(viewModel.announcements[0].title, 'Ann1');
      expect(viewModel.announcements[1].title, 'Ann2');
    });

    test('loadAnnouncements sets error on failure', () async {
      when(() => mockRepository.getAnnouncements()).thenThrow(Exception('Failed'));

      await viewModel.loadAnnouncements();

      expect(viewModel.isLoading, false);
      expect(viewModel.error, 'Exception: Failed');
      expect(viewModel.announcements, isEmpty);
    });
  });

  group('refresh', () {
    test('refresh delegates to loadAnnouncements', () async {
      final announcements = [
        TestModelFactory.createAnnouncement(id: '1', title: 'Refreshed'),
      ];
      when(() => mockRepository.getAnnouncements()).thenAnswer((_) async => announcements);

      await viewModel.refresh();

      expect(viewModel.announcements.length, 1);
      expect(viewModel.announcements.first.title, 'Refreshed');
      verify(() => mockRepository.getAnnouncements()).called(1);
    });
  });

  group('activeAnnouncements', () {
    test('activeAnnouncements filters out expired', () async {
      final announcements = [
        TestModelFactory.createAnnouncement(id: '1', title: 'Active'),
        TestModelFactory.createAnnouncement(
          id: '2',
          title: 'Expired',
          expiresAt: DateTime(2020, 1, 1),
        ),
      ];
      when(() => mockRepository.getAnnouncements()).thenAnswer((_) async => announcements);

      await viewModel.loadAnnouncements();

      expect(viewModel.activeAnnouncements.length, 1);
      expect(viewModel.activeAnnouncements.first.title, 'Active');
    });
  });

  group('pinnedAnnouncements', () {
    test('pinnedAnnouncements returns only pinned', () async {
      final announcements = [
        TestModelFactory.createAnnouncement(id: '1', title: 'Pinned', isPinned: true),
        TestModelFactory.createAnnouncement(id: '2', title: 'Normal'),
        TestModelFactory.createAnnouncement(id: '3', title: 'Also Pinned', isPinned: true),
      ];
      when(() => mockRepository.getAnnouncements()).thenAnswer((_) async => announcements);

      await viewModel.loadAnnouncements();

      expect(viewModel.pinnedAnnouncements.length, 2);
      expect(viewModel.pinnedAnnouncements.every((a) => a.isPinned), true);
    });
  });

  group('latestAnnouncements', () {
    test('latestAnnouncements returns top 5', () async {
      final announcements = List.generate(
        7,
        (i) => TestModelFactory.createAnnouncement(id: '$i', title: 'Ann $i'),
      );
      when(() => mockRepository.getAnnouncements()).thenAnswer((_) async => announcements);

      await viewModel.loadAnnouncements();

      expect(viewModel.latestAnnouncements.length, 5);
    });
  });

  group('dashboardAnnouncements', () {
    test('dashboardAnnouncements returns 1 pinned + 2 latest (max 3)', () async {
      final announcements = [
        TestModelFactory.createAnnouncement(id: '1', title: 'Normal 1'),
        TestModelFactory.createAnnouncement(id: '2', title: 'Pinned', isPinned: true),
        TestModelFactory.createAnnouncement(id: '3', title: 'Normal 2'),
        TestModelFactory.createAnnouncement(id: '4', title: 'Normal 3'),
      ];
      when(() => mockRepository.getAnnouncements()).thenAnswer((_) async => announcements);

      await viewModel.loadAnnouncements();

      expect(viewModel.dashboardAnnouncements.length, 3);
      expect(viewModel.dashboardAnnouncements[0].isPinned, true);
    });

    test('dashboardAnnouncements returns fewer when not enough announcements', () async {
      final announcements = [
        TestModelFactory.createAnnouncement(id: '1', title: 'Only One'),
      ];
      when(() => mockRepository.getAnnouncements()).thenAnswer((_) async => announcements);

      await viewModel.loadAnnouncements();

      expect(viewModel.dashboardAnnouncements.length, 1);
    });
  });
}
