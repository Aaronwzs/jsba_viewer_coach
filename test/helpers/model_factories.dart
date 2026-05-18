import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/academy_settings_model.dart';
import 'package:jsba_app/app/model/announcement_model.dart';
import 'package:jsba_app/app/model/attendance_model.dart';
import 'package:jsba_app/app/model/availability_model.dart';
import 'package:jsba_app/app/model/coach_payout_model.dart';
import 'package:jsba_app/app/model/feedback_model.dart';
import 'package:jsba_app/app/model/invoice_model.dart';
import 'package:jsba_app/app/model/open_court_model.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/model/receipt_model.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/model/user_model.dart';

class TestModelFactory {
  static DateTime _now = DateTime(2024, 6, 15, 10, 0, 0);

  static UserModel createUser({
    String uid = 'user1',
    String email = 'test@test.com',
    String name = 'Test User',
    String? role = 'Coach',
    String status = 'active',
  }) {
    return UserModel(uid: uid, email: email, name: name, role: role, status: status, createdAt: _now);
  }

  static PlayerModel createPlayer({
    String id = 'player1',
    String name = 'Alice',
    int age = 10,
    String level = 'Beginner',
    String phone = '0123456789',
    String parentId = 'parent1',
    bool isActive = true,
    String status = PlayerStatus.approved,
    bool isSelf = false,
    String? imageUrl,
  }) {
    return PlayerModel(
      id: id,
      name: name,
      age: age,
      level: level,
      phone: phone,
      createdAt: _now,
      isActive: isActive,
      parentId: parentId,
      status: status,
      isSelf: isSelf,
      imageUrl: imageUrl,
    );
  }

  static TrainingModel createTraining({
    String id = 'training1',
    String className = 'Class A',
    List<String> playerIds = const [],
    DateTime? date,
    String dayOfWeek = 'Monday',
    String venue = 'Desa Petaling',
    String startTime = '09:00',
    String classType = 'group',
    String level = 'Beginner',
    int durationMinutes = 60,
    double price = 10.0,
    String? coachId,
  }) {
    return TrainingModel(
      id: id,
      className: className,
      playerIds: playerIds,
      date: date ?? _now,
      dayOfWeek: dayOfWeek,
      venue: venue,
      startTime: startTime,
      classType: classType,
      level: level,
      durationMinutes: durationMinutes,
      price: price,
      coachId: coachId,
    );
  }

  static AnnouncementModel createAnnouncement({
    String id = 'ann1',
    String title = 'Test Announcement',
    String content = 'Content',
    bool isPinned = false,
    DateTime? createdAt,
    String createdBy = 'u1',
    DateTime? expiresAt,
  }) {
    return AnnouncementModel(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt ?? _now,
      createdBy: createdBy,
      isPinned: isPinned,
      expiresAt: expiresAt,
    );
  }

  static AttendanceModel createAttendance({
    String id = 'att1',
    String trainingId = 't1',
    String playerId = 'p1',
    String attendanceStatus = 'pending',
    double amountCharge = 10.0,
    String reasonCharge = '',
    String coachComments = '',
  }) {
    return AttendanceModel(
      id: id,
      trainingId: trainingId,
      playerId: playerId,
      attendanceStatus: attendanceStatus,
      amountCharge: amountCharge,
      reasonCharge: reasonCharge,
      coachComments: coachComments,
      createdAt: _now,
    );
  }

  static AvailabilityModel createAvailabilitySlot({
    String id = 'slot1',
    String adminId = 'admin1',
    String title = 'Session',
    String venue = 'Desa Petaling',
    String dayOfWeek = 'Monday',
    String startTime = '09:00',
    String endTime = '10:00',
    Map<String, bool> responses = const {},
    bool isActive = true,
  }) {
    return AvailabilityModel(
      id: id,
      adminId: adminId,
      title: title,
      venue: venue,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      responses: responses,
      isActive: isActive,
      createdAt: _now,
    );
  }

  static OpenCourtModel createOpenCourtSession({
    String id = 'oc1',
    String adminId = 'admin1',
    String venue = 'Desa Petaling',
    DateTime? date,
    String startTime = '20:00',
    int durationMinutes = 120,
    int maxPlayers = 6,
    String classType = OpenCourtModel.classTypeGroup,
    String level = OpenCourtModel.levelBeginner,
    String status = OpenCourtModel.statusOpenForBooking,
    List<String> playerIds = const [],
  }) {
    return OpenCourtModel(
      id: id,
      adminId: adminId,
      venue: venue,
      date: date ?? _now,
      startTime: startTime,
      durationMinutes: durationMinutes,
      maxPlayers: maxPlayers,
      classType: classType,
      level: level,
      status: status,
      playerIds: playerIds,
      createdAt: _now,
      updatedAt: _now,
    );
  }

  static InvoiceModel createInvoice({
    String id = 'inv1',
    String invoiceNumber = 'INV-001',
    String playerId = 'player1',
    String playerName = 'Alice',
    String playerPhone = '0123456789',
    int billingYear = 2024,
    int billingMonth = 6,
    List<InvoiceLineItem> lineItems = const [],
    double subTotal = 100.0,
    double discountAmount = 0,
    double taxAmount = 0,
    double totalAmount = 100.0,
    String status = 'draft',
  }) {
    return InvoiceModel(
      id: id,
      invoiceNumber: invoiceNumber,
      playerId: playerId,
      playerName: playerName,
      playerPhone: playerPhone,
      billingYear: billingYear,
      billingMonth: billingMonth,
      billingPeriodKey: '${billingYear.toString().padLeft(4, '0')}-${billingMonth.toString().padLeft(2, '0')}',
      lineItems: lineItems,
      subTotal: subTotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      status: status,
      createdAt: _now,
    );
  }

  static ReceiptModel createReceipt({
    String id = 'rec1',
    String receiptNumber = 'REC-001',
    String invoiceId = 'inv1',
    String playerId = 'player1',
    double amountPaid = 100.0,
    String paymentMethod = 'bank',
    int billingYear = 2024,
    int billingMonth = 6,
  }) {
    return ReceiptModel(
      id: id,
      receiptNumber: receiptNumber,
      invoiceId: invoiceId,
      playerId: playerId,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      issuedAt: _now,
      billingPeriodKey: '${billingYear.toString().padLeft(4, '0')}-${billingMonth.toString().padLeft(2, '0')}',
    );
  }

  static CoachPayoutModel createCoachPayout({
    String id = 'payout1',
    String coachId = 'coach1',
    String coachRatesId = 'rate1',
    String periodKey = '2024-06',
    List<String> trainingIds = const [],
  }) {
    return CoachPayoutModel(
      id: id,
      coachId: coachId,
      coachRatesId: coachRatesId,
      periodKey: periodKey,
      trainingIds: trainingIds,
      createdAt: _now,
      generatedAt: _now,
    );
  }

  static FeedbackModel createFeedback({
    String? id = 'fb1',
    FeedbackType type = FeedbackType.feedback,
    String title = 'Great app',
    String description = 'Love it',
    String userId = 'user1',
  }) {
    return FeedbackModel(
      id: id,
      type: type,
      title: title,
      description: description,
      userId: userId,
      deviceInfo: DeviceInfoModel.empty(),
      createdAt: _now,
    );
  }

  static AcademySettingsModel createAcademySettings({
    String billingName = 'JSBA Badminton Academy',
    String? billingLogoUrl,
    String? duitNowQrUrl,
  }) {
    return AcademySettingsModel(
      billingName: billingName,
      billingLogoUrl: billingLogoUrl,
      duitNowQrUrl: duitNowQrUrl,
    );
  }
}
