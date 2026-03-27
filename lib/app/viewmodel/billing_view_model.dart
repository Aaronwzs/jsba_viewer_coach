import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jsba_app/app/model/invoice_model.dart';
import 'package:jsba_app/app/model/invoice_profile_model.dart';
import 'package:jsba_app/app/model/receipt_model.dart';
import 'package:jsba_app/app/service/academy_settings_service.dart';
import 'package:jsba_app/app/service/billing_service.dart';
import 'package:jsba_app/app/service/pdf_doc_service.dart';

class BillingViewModel extends ChangeNotifier {
  final BillingService _billingService = BillingService();
  final PdfService _pdfService = PdfService();
  final AcademySettingsService _academySettingsService =
      AcademySettingsService();
  final Dio _dio = Dio();

  List<InvoiceModel> _invoices = [];
  List<ReceiptModel> _receipts = [];
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  String? _error;
  InvoiceProfile _invoiceProfile = InvoiceProfile.empty();
  Uint8List? _logoBytes;
  Uint8List? _duitNowQrBytes;

  List<InvoiceModel> get invoices => _invoices;
  List<ReceiptModel> get receipts => _receipts;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get error => _error;
  InvoiceProfile get invoiceProfile => _invoiceProfile;

  List<InvoiceModel> get unpaidInvoices =>
      _invoices.where((i) => i.status != 'paid').toList();

  List<InvoiceModel> get paidInvoices =>
      _invoices.where((i) => i.status == 'paid').toList();

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  Future<void> loadInvoicesForPlayerIds(List<String> playerIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final allInvoices = await _billingService.getInvoicesForPlayerIds(
        playerIds,
      );
      _invoices = allInvoices
          .where(
            (i) =>
                i.billingYear == _selectedMonth.year &&
                i.billingMonth == _selectedMonth.month,
          )
          .toList();

      final allReceipts = await _billingService.getReceiptsForPlayerIds(
        playerIds,
      );
      _receipts = allReceipts
          .where(
            (r) =>
                r.billingPeriodKey ==
                '${_selectedMonth.year.toString().padLeft(4, '0')}-${_selectedMonth.month.toString().padLeft(2, '0')}',
          )
          .toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> markAsPaid({
    required String invoiceId,
    required String paymentMethod,
    String? paymentReference,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _billingService.markInvoiceAsCustomerPaid(
        invoiceId: invoiceId,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
      );

      final index = _invoices.indexWhere((i) => i.id == invoiceId);
      if (index != -1) {
        final invoice = _invoices[index];
        _invoices[index] = InvoiceModel(
          id: invoice.id,
          invoiceNumber: invoice.invoiceNumber,
          playerId: invoice.playerId,
          playerName: invoice.playerName,
          playerPhone: invoice.playerPhone,
          billingYear: invoice.billingYear,
          billingMonth: invoice.billingMonth,
          billingPeriodKey: invoice.billingPeriodKey,
          lineItems: invoice.lineItems,
          subTotal: invoice.subTotal,
          discountAmount: invoice.discountAmount,
          taxAmount: invoice.taxAmount,
          totalAmount: invoice.totalAmount,
          status: 'sent',
          notes: invoice.notes,
          createdAt: invoice.createdAt,
          sentAt: DateTime.now(),
          paidAt: invoice.paidAt,
          paymentMethod: paymentMethod,
          paymentReference: paymentReference,
          receiptId: invoice.receiptId,
          currency: invoice.currency,
          customFields: invoice.customFields,
          billToName: invoice.billToName,
          billToPhone: invoice.billToPhone,
          billToEmail: invoice.billToEmail,
          billToType: invoice.billToType,
          billingPlayerName: invoice.billingPlayerName,
          playerIds: invoice.playerIds,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ReceiptModel? getReceiptForInvoice(String invoiceId) {
    try {
      return _receipts.firstWhere((r) => r.invoiceId == invoiceId);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> generateInvoicePdf(InvoiceModel invoice) async {
    await _ensureProfileLoaded();
    return _pdfService.generateInvoicePdf(
      invoice: invoice,
      profile: _invoiceProfile,
      logoBytes: _logoBytes,
      duitNowQrBytes: _duitNowQrBytes,
    );
  }

  Future<Uint8List> generateReceiptPdf(ReceiptModel receipt) async {
    await _ensureProfileLoaded();
    return _pdfService.generateReceiptPdf(
      receipt: receipt,
      profile: _invoiceProfile,
      logoBytes: _logoBytes,
      duitNowQrBytes: _duitNowQrBytes,
    );
  }

  Future<void> _ensureProfileLoaded() async {
    if (_invoiceProfile.name == 'JSBA Badminton Academy' &&
        _logoBytes == null) {
      await _loadBillingProfileFromFirebase();
    }
  }

  Future<void> _loadBillingProfileFromFirebase() async {
    try {
      final settings = await _academySettingsService.getSettings();
      _invoiceProfile = InvoiceProfile.fromAcademySettings(settings);

      if (settings.billingLogoUrl != null &&
          settings.billingLogoUrl!.isNotEmpty) {
        try {
          final response = await _dio.get<List<int>>(
            settings.billingLogoUrl!,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.statusCode == 200 && response.data != null) {
            _logoBytes = Uint8List.fromList(response.data!);
          }
        } catch (_) {}
      }

      if (settings.duitNowQrUrl != null && settings.duitNowQrUrl!.isNotEmpty) {
        try {
          final response = await _dio.get<List<int>>(
            settings.duitNowQrUrl!,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.statusCode == 200 && response.data != null) {
            _duitNowQrBytes = Uint8List.fromList(response.data!);
          }
        } catch (_) {}
      }

      notifyListeners();
    } catch (e) {
      _invoiceProfile = InvoiceProfile.empty();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
