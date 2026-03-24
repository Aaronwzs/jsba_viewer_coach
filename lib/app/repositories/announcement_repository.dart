import 'package:jsba_app/app/models/announcement_model.dart';
import 'package:jsba_app/app/services/announcement_service.dart';

class AnnouncementRepository {
  final AnnouncementService _service = AnnouncementService();

  Future<List<AnnouncementModel>> getAnnouncements() async {
    return await _service.getAnnouncements();
  }

  Future<List<AnnouncementModel>> getActiveAnnouncements() async {
    return await _service.getActiveAnnouncements();
  }

  Future<List<AnnouncementModel>> getPinnedAnnouncements() async {
    return await _service.getPinnedAnnouncements();
  }
}
