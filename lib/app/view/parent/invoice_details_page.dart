import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/model/invoice_model.dart';
import 'package:jsba_app/app/service/storage_service.dart';
import 'package:jsba_app/app/viewmodel/billing_view_model.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/view/parent/widgets/pdf_ui_handler.dart';

@RoutePage()
class InvoiceDetailsPage extends StatefulWidget {
  final String id;

  const InvoiceDetailsPage({super.key, @PathParam('id') required this.id});

  @override
  State<InvoiceDetailsPage> createState() => _InvoiceDetailsPageState();
}

class _InvoiceDetailsPageState extends State<InvoiceDetailsPage> {
  final List<File> _filesToUpload = [];
  final List<String> _uploadedUrls = [];
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final billingVM = context.watch<BillingViewModel>();
    InvoiceModel? invoice;
    try {
      invoice = billingVM.invoices.firstWhere((i) => i.id == widget.id);
    } catch (_) {}

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Invoice',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final inv = invoice;
    final canPay = inv.status != 'paid';
    final periodLabel = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(inv.billingYear, inv.billingMonth));
    final pdfHandler = PdfUiHandler(
      context: context,
      pdfBuilder: () => billingVM.generateInvoicePdf(inv),
      documentNumber: inv.invoiceNumber,
      documentType: 'Invoice',
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Invoice',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        actions: pdfHandler.buildAppBarActions(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(inv, periodLabel),
          const SizedBox(height: 16),
          _buildLineItemsCard(inv),
          const SizedBox(height: 16),
          _buildSummaryCard(inv),
          if (inv.status == 'sent') ...[
            const SizedBox(height: 16),
            _buildPendingNotice(inv),
          ],
          if (inv.status == 'paid') ...[
            const SizedBox(height: 16),
            _buildPaidNotice(inv),
          ],
        ],
      ),
      bottomNavigationBar: canPay
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => _showPaymentDialog(context, inv),
                  icon: Icon(inv.status == 'sent' ? Icons.refresh : Icons.payment),
                  label: Text(inv.status == 'sent' ? 'Change Payment Method' : 'Pay Now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: inv.status == 'sent' ? Colors.blue : AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeaderCard(InvoiceModel invoice, String periodLabel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.billToName ?? invoice.playerName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoice.invoiceNumber,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(invoice),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(periodLabel, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            if (invoice.billToPhone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    invoice.billToPhone!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(InvoiceModel invoice) {
    final statusColor = invoice.status == 'paid'
        ? Colors.green
        : (invoice.status == 'sent' ? Colors.blue : Colors.orange);
    final statusLabel = invoice.status == 'paid'
        ? 'PAID'
        : (invoice.status == 'sent' ? 'PENDING' : 'UNPAID');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLineItemsCard(InvoiceModel invoice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Line Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...invoice.lineItems.map((item) {
              final dateLabel = item.date != null
                  ? DateFormat('MMM d').format(item.date!)
                  : '-';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '$dateLabel • ${item.attendanceStatus ?? "-"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${invoice.currency} ${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(InvoiceModel invoice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryRow('Subtotal', invoice.subTotal, invoice.currency),
            if (invoice.discountAmount > 0)
              _SummaryRow(
                'Discount',
                -invoice.discountAmount,
                invoice.currency,
              ),
            if (invoice.taxAmount > 0)
              _SummaryRow('Tax', invoice.taxAmount, invoice.currency),
            const Divider(height: 24),
            _SummaryRow(
              'Total',
              invoice.totalAmount,
              invoice.currency,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  String _fileNameFromUrl(String url) {
    try {
      return url.split('/').last;
    } catch (_) {
      return url;
    }
  }

  bool _isImageFile(File file) {
    final ext = file.path.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp');
  }

  Widget _buildPendingNotice(InvoiceModel invoice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Awaiting Approval',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (invoice.paymentMethod != null)
            Text(
              'Method: ${_paymentMethodLabel(invoice.paymentMethod)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (invoice.paymentReference != null && invoice.paymentReference!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _isImageUrl(invoice.paymentReference!)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        invoice.paymentReference!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            height: 160,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFileRefTile(invoice.paymentReference!);
                        },
                      ),
                    )
                  : _buildFileRefTile(invoice.paymentReference!),
            ),
          const SizedBox(height: 8),
          Text(
            'Tap "Change Payment Method" below to update',
            style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildFileRefTile(String url) {
    return Row(
      children: [
        const Icon(Icons.insert_drive_file_outlined, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _fileNameFromUrl(url),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPaidNotice(InvoiceModel invoice) {
    final billingVM = context.read<BillingViewModel>();
    final receipt = billingVM.getReceiptForInvoice(invoice.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 12),
              const Text(
                'Payment Confirmed',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (receipt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Receipt: ${receipt.receiptNumber}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              'Amount Paid: ${receipt.currency} ${receipt.amountPaid.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              'Method: ${_paymentMethodLabel(receipt.paymentMethod)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  String _paymentMethodLabel(String? method) {
    switch (method) {
      case 'e-wallet':
        return 'E-Wallet';
      case 'bank':
        return 'Bank';
      default:
        return (method ?? '').toUpperCase();
    }
  }

  Future<void> _uploadFileAndUpdate(File file, StateSetter setDialogState) async {
    setDialogState(() => _isUploading = true);
    final storage = StorageService();
    final url = await storage.uploadImage(file);
    setDialogState(() {
      if (url != null) _uploadedUrls.add(url);
      _isUploading = false;
    });
  }

  void _showUploadOptions(StateSetter setDialogState, BuildContext dialogContext) {
    showModalBottomSheet(
      context: dialogContext,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Add Image'),
              onTap: () async {
                Navigator.pop(ctx);
                final xFile = await openFile(acceptedTypeGroups: [
                  XTypeGroup(label: 'image', extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp']),
                ]);
                if (xFile == null) return;
                final file = File(xFile.path);
                setDialogState(() => _filesToUpload.add(file));
                _uploadFileAndUpdate(file, setDialogState);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Add PDF'),
              onTap: () async {
                Navigator.pop(ctx);
                final xFile = await openFile(acceptedTypeGroups: [
                  XTypeGroup(label: 'PDF', extensions: ['pdf']),
                ]);
                if (xFile == null) return;
                final file = File(xFile.path);
                setDialogState(() => _filesToUpload.add(file));
                _uploadFileAndUpdate(file, setDialogState);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, InvoiceModel invoice) {
    final isResubmit = invoice.status == 'sent';
    String selectedMethod = invoice.paymentMethod ?? 'e-wallet';
    _filesToUpload.clear();
    _uploadedUrls.clear();
    _isUploading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isResubmit ? 'Change Payment Method' : 'Pay Invoice'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount: ${invoice.currency} ${invoice.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Payment Method:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _PaymentOption(
                  value: 'e-wallet',
                  groupValue: selectedMethod,
                  icon: Icons.wallet,
                  title: 'E-Wallet',
                  onChanged: (v) => setDialogState(() => selectedMethod = v!),
                ),
                _PaymentOption(
                  value: 'bank',
                  groupValue: selectedMethod,
                  icon: Icons.account_balance,
                  title: 'Bank',
                  onChanged: (v) => setDialogState(() => selectedMethod = v!),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reference Proof',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                if (_filesToUpload.isNotEmpty)
                  ...List.generate(_filesToUpload.length, (index) {
                    final file = _filesToUpload[index];
                    final uploaded = index < _uploadedUrls.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          height: 80,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: _isImageFile(file)
                                    ? Image.file(file, width: 80, height: 80, fit: BoxFit.cover)
                                    : Container(
                                        color: Colors.grey[100],
                                        child: const Center(
                                          child: Icon(Icons.picture_as_pdf, size: 36, color: Colors.red),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      file.path.split('/').last,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    if (uploaded)
                                      Row(
                                        children: [
                                          Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                                          const SizedBox(width: 4),
                                          Text('Uploaded', style: TextStyle(fontSize: 11, color: Colors.green[600])),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              if (!_isUploading)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => setDialogState(() {
                                    _filesToUpload.removeAt(index);
                                    if (index < _uploadedUrls.length) {
                                      _uploadedUrls.removeAt(index);
                                    }
                                  }),
                                ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                if (!_isUploading)
                  TextButton.icon(
                    onPressed: () => _showUploadOptions(setDialogState, dialogContext),
                    icon: const Icon(Icons.add),
                    label: Text(
                      _filesToUpload.isEmpty ? 'Add Receipt File' : 'Add Another File',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                if (_filesToUpload.isEmpty && !_isUploading)
                  GestureDetector(
                    onTap: () => _showUploadOptions(setDialogState, dialogContext),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        color: AppTheme.primaryColor.withValues(alpha: 0.04),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              color: AppTheme.primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Tap to add receipt files',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPG, PNG, WEBP, BMP or PDF',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Uploading files...',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (!_isUploading && _filesToUpload.length > _uploadedUrls.length && _uploadedUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Some files failed. Tap to retry.',
                          style: TextStyle(color: Colors.red[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: (_isUploading || _uploadedUrls.isEmpty)
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      final billingVM = context.read<BillingViewModel>();
                      final ref = _uploadedUrls.join(',');
                      final success = await billingVM.markAsPaid(
                        invoiceId: invoice.id,
                        paymentMethod: selectedMethod,
                        paymentReference: ref,
                      );

                      if (!context.mounted) return;

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isResubmit ? 'Payment method updated' : 'Payment submitted for confirmation'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              billingVM.error ?? 'Failed to submit payment',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: Text(isResubmit ? 'Update Payment' : 'Submit Payment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final bool isBold;

  const _SummaryRow(
    this.label,
    this.amount,
    this.currency, {
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final IconData icon;
  final String title;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: value == groupValue ? AppTheme.primaryColor : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
