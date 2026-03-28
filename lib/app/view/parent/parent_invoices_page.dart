import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/viewmodel/billing_view_model.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:jsba_app/app/model/invoice_model.dart';
import 'package:jsba_app/app/model/receipt_model.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';

@RoutePage()
class ParentInvoicesPage extends StatefulWidget {
  const ParentInvoicesPage({super.key});

  @override
  State<ParentInvoicesPage> createState() => _ParentInvoicesPageState();
}

class _ParentInvoicesPageState extends State<ParentInvoicesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
    });
  }

  List<String> _buildAllPlayerIds(ParentViewModel parentVM) {
    final ids = <String>[];
    if (parentVM.selfPlayer != null && parentVM.selfPlayer!.id.isNotEmpty) {
      ids.add(parentVM.selfPlayer!.id);
    }
    for (final kid in parentVM.allKids) {
      if (kid.id.isNotEmpty) {
        ids.add(kid.id);
      }
    }
    return ids;
  }

  Future<void> _reload() async {
    final parentVM = context.read<ParentViewModel>();
    final allPlayerIds = _buildAllPlayerIds(parentVM);
    if (allPlayerIds.isNotEmpty) {
      await context.read<BillingViewModel>().loadInvoicesForPlayerIds(
        allPlayerIds,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingVM = context.watch<BillingViewModel>();

    return Scaffold(
      appBar: const AppBarTitle(),
      body: billingVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.paddingOf(context).bottom + 100,
                ),
                children: [
                  _buildMonthSelector(billingVM),
                  _buildContent(context, billingVM),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelector(BillingViewModel billingVM) {
    final month = billingVM.selectedMonth;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              billingVM.setSelectedMonth(DateTime(month.year, month.month - 1));
              _reload();
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(month),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              billingVM.setSelectedMonth(DateTime(month.year, month.month + 1));
              _reload();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, BillingViewModel billingVM) {
    if (billingVM.invoices.isEmpty && billingVM.receipts.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No billing records this month',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (billingVM.unpaidInvoices.isNotEmpty) ...[
            _buildSectionHeader(
              'Pending Payment',
              billingVM.unpaidInvoices.length,
            ),
            const SizedBox(height: 8),
            ...billingVM.unpaidInvoices.map(
              (invoice) => _InvoiceTile(invoice: invoice),
            ),
            const SizedBox(height: 24),
          ],
          if (billingVM.paidInvoices.isNotEmpty) ...[
            _buildSectionHeader('Paid', billingVM.paidInvoices.length),
            const SizedBox(height: 8),
            ...billingVM.paidInvoices.map(
              (invoice) => _InvoiceTile(invoice: invoice),
            ),
            const SizedBox(height: 24),
          ],
          if (billingVM.receipts.isNotEmpty) ...[
            _buildSectionHeader('Receipts', billingVM.receipts.length),
            const SizedBox(height: 8),
            ...billingVM.receipts.map(
              (receipt) => _ReceiptTile(receipt: receipt),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final InvoiceModel invoice;

  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final statusColor = invoice.status == 'paid'
        ? Colors.green
        : (invoice.status == 'sent' ? Colors.blue : Colors.orange);
    final statusLabel = invoice.status == 'paid'
        ? 'PAID'
        : (invoice.status == 'sent' ? 'AWAITING APPROVAL' : 'UNPAID');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          context.router.pushNamed('/invoice-details/${invoice.id}');
        },
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            invoice.status == 'paid' ? Icons.check_circle : Icons.receipt_long,
            color: statusColor,
          ),
        ),
        title: Text(
          invoice.billToName ?? invoice.playerName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invoice.invoiceNumber),
            Text(
              DateFormat(
                'MMM yyyy',
              ).format(DateTime(invoice.billingYear, invoice.billingMonth)),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${invoice.currency} ${invoice.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  final ReceiptModel receipt;

  const _ReceiptTile({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          context.router.pushNamed('/receipt-details/${receipt.id}');
        },
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.description, color: Colors.green),
        ),
        title: Text(
          receipt.billToName ?? receipt.playerName ?? 'Receipt',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(receipt.receiptNumber),
            Text(
              DateFormat('MMM d, yyyy').format(receipt.issuedAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${receipt.currency} ${receipt.amountPaid.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              receipt.paymentMethod.toUpperCase(),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
