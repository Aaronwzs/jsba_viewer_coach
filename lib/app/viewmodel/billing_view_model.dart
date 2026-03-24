import 'package:flutter/material.dart';
import 'package:jsba_app/app/model/invoice_model.dart';
import 'package:jsba_app/app/model/receipt_model.dart';
import 'package:jsba_app/app/service/billing_service.dart';

class BillingViewModel extends ChangeNotifier {
  final BillingService _billingService = BillingService();

  List<InvoiceModel> _invoices = [];
  List<ReceiptModel> _receipts = [];
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  String? _error;

  List<InvoiceModel> get invoices => _invoices;
  List<ReceiptModel> get receipts => _receipts;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
      final allInvoices = await _billingService.getInvoicesForPlayerIds(playerIds);
      _invoices = allInvoices
          .where((i) => i.billingYear == _selectedMonth.year && i.billingMonth == _selectedMonth.month)
          .toList();

      final allReceipts = await _billingService.getReceiptsForPlayerIds(playerIds);
      _receipts = allReceipts
          .where((r) => r.billingPeriodKey == '${_selectedMonth.year.toString().padLeft(4, '0')}-${_selectedMonth.month.toString().padLeft(2, '0')}')
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
