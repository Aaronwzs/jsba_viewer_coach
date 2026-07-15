import 'package:flutter/material.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/model/user_payment_model.dart';
import 'package:jsba_app/app/service/attendance_service.dart';
import 'package:jsba_app/app/service/training_service.dart';
import 'package:jsba_app/app/service/user_payment_service.dart';

class BillingViewModel extends ChangeNotifier {
  final UserPaymentService _userPaymentService;
  AttendanceService? _attendanceServiceInstance;
  TrainingService? _trainingServiceInstance;

  BillingViewModel({
    UserPaymentService? userPaymentService,
    AttendanceService? attendanceService,
    TrainingService? trainingService,
  }) : _userPaymentService = userPaymentService ?? UserPaymentService() {
    _attendanceServiceInstance = attendanceService;
    _trainingServiceInstance = trainingService;
  }

  AttendanceService get _attendanceService =>
      _attendanceServiceInstance ??= AttendanceService();
  TrainingService get _trainingService =>
      _trainingServiceInstance ??= TrainingService();

  List<UserPaymentModel> _userPayments = [];
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  String? _error;

  List<UserPaymentModel> get userPayments => _userPayments;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<UserPaymentModel> get pendingPayments =>
      _userPayments.where((p) => p.paymentStatus == 'pending').toList();

  List<UserPaymentModel> get approvedPayments =>
      _userPayments.where((p) => p.paymentStatus == 'approved').toList();

  List<UserPaymentModel> get rejectedPayments =>
      _userPayments.where((p) => p.paymentStatus == 'rejected').toList();

  /// Payments that have no uploaded proof yet. These appear in a separate
  /// "Not Uploaded" section before any approval workflow begins.
  List<UserPaymentModel> get notUploadedPayments => _userPayments
      .where((p) => p.uploadProof == null && p.paymentStatus != 'rejected')
      .toList();

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  /// Gets the player IDs for the current user, queries the userPayments
  /// collection filtered by those player IDs, then filters by the selected
  /// month.
  Future<void> loadInvoicesForPlayerIds(List<String> playerIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userPayments = await _userPaymentService.getUserPaymentsForPeriod(
        playerIds,
        _selectedMonth.year,
        _selectedMonth.month,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitUserPayment({
    required UserPaymentModel payment,
    required String userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userPaymentService.submitPayment(
        payment: payment,
        userId: userId,
      );
      await loadInvoicesForPlayerIds([payment.playerId]);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserPaymentModel?> getUserPaymentById(String id) async {
    return _userPaymentService.getUserPaymentById(id);
  }

  /// Resolves the training sessions for a payment by looking up its
  /// [attendanceIds] and matching each to its training, filtered to the
  /// player on the payment. Returns trainings sorted by date.
  Future<List<TrainingModel>> getSessionsForPayment(
    UserPaymentModel payment,
  ) async {
    if (payment.attendanceIds.isEmpty) return [];

    final attendanceDocs = await _attendanceService.getAttendanceByIds(
      payment.attendanceIds,
    );
    final trainingIds = attendanceDocs
        .where((a) => a.playerId == payment.playerId)
        .map((a) => a.trainingId)
        .toSet()
        .toList();

    if (trainingIds.isEmpty) return [];
    final trainings = await _trainingService.getTrainingsByIds(trainingIds);
    trainings.sort((a, b) => a.date.compareTo(b.date));
    return trainings;
  }

  Future<bool> cancelUserPayment(String paymentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userPaymentService.cancelPayment(paymentId);
      _userPayments.removeWhere((p) => p.id == paymentId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Uploads a payment-proof screenshot for the given user payment (parent
  /// billing flow) by populating [UserPaymentModel.uploadProof], then
  /// refreshes the list so the record moves out of the "Not Uploaded" section.
  Future<bool> uploadUserPaymentProof({
    required String paymentId,
    required String url,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userPaymentService.uploadUserPaymentProof(id: paymentId, url: url);
      final updated = await _userPaymentService.getUserPaymentById(paymentId);
      if (updated != null) {
        final index = _userPayments.indexWhere((p) => p.id == paymentId);
        if (index != -1) {
          _userPayments[index] = updated;
        } else {
          _userPayments.add(updated);
        }
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
