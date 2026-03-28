import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/model/receipt_model.dart';
import 'package:jsba_app/app/viewmodel/billing_view_model.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/view/parent/widgets/pdf_ui_handler.dart';

@RoutePage()
class ReceiptDetailsPage extends StatefulWidget {
  final String id;

  const ReceiptDetailsPage({super.key, @PathParam('id') required this.id});

  @override
  State<ReceiptDetailsPage> createState() => _ReceiptDetailsPageState();
}

class _ReceiptDetailsPageState extends State<ReceiptDetailsPage> {
  ReceiptModel? _receipt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final billingVM = context.read<BillingViewModel>();
      try {
        _receipt = billingVM.receipts.firstWhere((r) => r.id == widget.id);
        setState(() {});
      } catch (_) {
        _receipt = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_receipt == null) {
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
            'Receipt',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final receipt = _receipt!;
    final periodLabel = DateFormat('MMMM yyyy').format(
      DateTime(
        int.parse(receipt.billingPeriodKey.substring(0, 4)),
        int.parse(receipt.billingPeriodKey.substring(5, 7)),
      ),
    );
    final billingVM = context.read<BillingViewModel>();
    final pdfHandler = PdfUiHandler(
      context: context,
      pdfBuilder: () => billingVM.generateReceiptPdf(receipt),
      documentNumber: receipt.receiptNumber,
      documentType: 'Receipt',
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
          'Receipt',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        actions: pdfHandler.buildAppBarActions(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(receipt, periodLabel),
          const SizedBox(height: 16),
          _buildPaymentDetailsCard(receipt),
          const SizedBox(height: 16),
          _buildAmountCard(receipt),
          if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildNotesCard(receipt),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ReceiptModel receipt, String periodLabel) {
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
                        receipt.billToName ?? receipt.playerName ?? 'Receipt',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        receipt.receiptNumber,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PAID',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
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
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM d, yyyy h:mm a').format(receipt.issuedAt),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (receipt.billToPhone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    receipt.billToPhone!,
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

  Widget _buildPaymentDetailsCard(ReceiptModel receipt) {
    final methodLabel = {
      'cash': 'Cash',
      'transfer': 'Bank Transfer',
      'tng': 'Touch n Go',
      'card': 'Card',
    }[receipt.paymentMethod] ?? receipt.paymentMethod.toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Method: $methodLabel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (receipt.paymentReference != null && receipt.paymentReference!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.confirmation_number, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Reference: ${receipt.paymentReference}',
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

  Widget _buildAmountCard(ReceiptModel receipt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount Paid',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${receipt.currency} ${receipt.amountPaid.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(ReceiptModel receipt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              receipt.notes!,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
