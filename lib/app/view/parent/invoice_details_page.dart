import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/model/invoice_model.dart';
import 'package:jsba_app/app/viewmodel/billing_view_model.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';

@RoutePage()
class InvoiceDetailsPage extends StatefulWidget {
  final String id;

  const InvoiceDetailsPage({super.key, @PathParam('id') required this.id});

  @override
  State<InvoiceDetailsPage> createState() => _InvoiceDetailsPageState();
}

class _InvoiceDetailsPageState extends State<InvoiceDetailsPage> {
  InvoiceModel? _invoice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final billingVM = context.read<BillingViewModel>();
      try {
        _invoice = billingVM.invoices.firstWhere((i) => i.id == widget.id);
        setState(() {});
      } catch (_) {
        _invoice = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_invoice == null) {
      return Scaffold(
        appBar: const AppBarTitle(title: 'Invoice', blackBackButton: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final invoice = _invoice!;
    final canPay = invoice.status != 'paid';
    final periodLabel = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(invoice.billingYear, invoice.billingMonth));

    return Scaffold(
      appBar: const AppBarTitle(title: 'Invoice', blackBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(invoice, periodLabel),
          const SizedBox(height: 16),
          _buildLineItemsCard(invoice),
          const SizedBox(height: 16),
          _buildSummaryCard(invoice),
          if (invoice.status == 'sent') ...[
            const SizedBox(height: 16),
            _buildPendingNotice(invoice),
          ],
          if (invoice.status == 'paid') ...[
            const SizedBox(height: 16),
            _buildPaidNotice(invoice),
          ],
        ],
      ),
      bottomNavigationBar: canPay
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => _showPaymentDialog(context, invoice),
                  icon: Icon(invoice.status == 'sent' ? Icons.refresh : Icons.payment),
                  label: Text(invoice.status == 'sent' ? 'Change Payment Method' : 'Pay Now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: invoice.status == 'sent' ? Colors.blue : AppTheme.primaryColor,
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
              'Method: ${invoice.paymentMethod!.toUpperCase()}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (invoice.paymentReference != null && invoice.paymentReference!.isNotEmpty)
            Text(
              'Reference: ${invoice.paymentReference}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          Text(
            'Tap "Change Payment Method" below to update',
            style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
          ),
        ],
      ),
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
              'Method: ${receipt.paymentMethod.toUpperCase()}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, InvoiceModel invoice) {
    final isResubmit = invoice.status == 'sent';
    String selectedMethod = invoice.paymentMethod ?? 'transfer';
    final referenceController = TextEditingController(text: invoice.paymentReference ?? '');

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
                  value: 'cash',
                  groupValue: selectedMethod,
                  icon: Icons.money,
                  title: 'Cash',
                  onChanged: (v) => setDialogState(() => selectedMethod = v!),
                ),
                _PaymentOption(
                  value: 'transfer',
                  groupValue: selectedMethod,
                  icon: Icons.account_balance,
                  title: 'Bank Transfer',
                  onChanged: (v) => setDialogState(() => selectedMethod = v!),
                ),
                _PaymentOption(
                  value: 'tng',
                  groupValue: selectedMethod,
                  icon: Icons.wallet,
                  title: 'Touch n Go',
                  onChanged: (v) => setDialogState(() => selectedMethod = v!),
                ),
                _PaymentOption(
                  value: 'card',
                  groupValue: selectedMethod,
                  icon: Icons.credit_card,
                  title: 'Card',
                  onChanged: (v) => setDialogState(() => selectedMethod = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference (optional)',
                    hintText: 'Transaction ID',
                    border: OutlineInputBorder(),
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
              onPressed: () async {
                Navigator.pop(dialogContext);
                final billingVM = context.read<BillingViewModel>();
                final success = await billingVM.markAsPaid(
                  invoiceId: invoice.id,
                  paymentMethod: selectedMethod,
                  paymentReference: referenceController.text.trim().isEmpty
                      ? null
                      : referenceController.text.trim(),
                );

                if (!context.mounted) return;

                if (success) {
                  setState(() {
                    _invoice = billingVM.invoices.firstWhere(
                      (i) => i.id == invoice.id,
                    );
                  });
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
