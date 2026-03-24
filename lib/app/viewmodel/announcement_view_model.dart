import 'package:flutter/foundation.dart';
import 'package:jsba_app/app/models/announcement_model.dart';
import 'package:jsba_app/app/repositories/announcement_repository.dart';

class AnnouncementViewModel extends ChangeNotifier {
  final AnnouncementRepository _repository = AnnouncementRepository();

  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  String? _error;

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<AnnouncementModel> get activeAnnouncements =>
      _announcements.where((a) => !a.isExpired).toList();

  List<AnnouncementModel> get pinnedAnnouncements =>
      activeAnnouncements.where((a) => a.isPinned).toList();

  List<AnnouncementModel> get latestAnnouncements => activeAnnouncements.take(5).toList();

  List<AnnouncementModel> get dashboardAnnouncements {
    final pinned = pinnedAnnouncements.take(1).toList();
    final latest = activeAnnouncements
        .where((a) => !a.isPinned)
        .take(2)
        .toList();
    final combined = [...pinned, ...latest];
    return combined.take(3).toList();
  }

  Future<void> loadAnnouncements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _announcements = await _repository.getAnnouncements();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadAnnouncements();
  }
}
