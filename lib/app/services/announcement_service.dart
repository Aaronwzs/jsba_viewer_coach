import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/models/announcement_model.dart';

class AnnouncementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<AnnouncementModel>> getAnnouncements() async {
    try {
      final snapshot = await _db
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();

      final announcements = snapshot.docs
          .map((doc) => AnnouncementModel.fromMap(doc.data(), id: doc.id))
          .toList();

      announcements.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      return announcements;
    } catch (e) {
      final snapshot = await _db.collection('announcements').get();
      return snapshot.docs
          .map((doc) => AnnouncementModel.fromMap(doc.data(), id: doc.id))
          .toList();
    }
  }

  Future<List<AnnouncementModel>> getActiveAnnouncements() async {
    final announcements = await getAnnouncements();
    return announcements.where((a) => !a.isExpired).toList();
  }

  Future<List<AnnouncementModel>> getPinnedAnnouncements() async {
    final announcements = await getActiveAnnouncements();
    return announcements.where((a) => a.isPinned).toList();
  }
}
