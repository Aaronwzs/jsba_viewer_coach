import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/viewmodel/billing_view_model.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:jsba_app/app/model/user_payment_model.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';

@RoutePage()
class ParentBillingPage extends StatefulWidget {
  const ParentBillingPage({super.key});

  @override
  State<ParentBillingPage> createState() => _ParentBillingPageState();
}

class _ParentBillingPageState extends State<ParentBillingPage> {
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
    final authVM = context.read<AuthViewModel>();
    final parentVM = context.read<ParentViewModel>();

    if (authVM.currentUser?.uid != null && parentVM.allKids.isEmpty) {
      await parentVM.loadMyKids(authVM.currentUser!.uid);
    }

    if (!mounted) return;

    final allPlayerIds = _buildAllPlayerIds(parentVM);
    if (allPlayerIds.isNotEmpty) {
      await context.read<BillingViewModel>().loadInvoicesForPlayerIds(
        allPlayerIds,
      );
    }
  }

  /// Payments awaiting admin approval (status == pending).
  List<UserPaymentModel> _pendingPayments(BillingViewModel vm) {
    return vm.userPayments
        .where((p) => p.paymentStatus == 'pending')
        .toList();
  }

  /// Payments that have proof uploaded and are not pending (approved/rejected).
  List<UserPaymentModel> _uploadedProofPayments(BillingViewModel vm) {
    return vm.userPayments
        .where((p) =>
            p.uploadProof != null && p.paymentStatus != 'pending')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final billingVM = context.watch<BillingViewModel>();
    final parentVM = context.watch<ParentViewModel>();

    return Scaffold(
      appBar: const AppBarTitle(showBackButton: false),
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
                  _buildContent(context, billingVM, parentVM),
                ],
              ),
            ),
    );
  }

  /// Resolves the player's display name from the [UserPaymentModel.playerId]
  /// using the loaded players, falling back to the stored [UserPaymentModel.playerName].
  String _playerName(ParentViewModel parentVM, UserPaymentModel payment) {
    return parentVM.playerNameById(payment.playerId) ?? payment.playerName;
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

  Widget _buildContent(
    BuildContext context,
    BillingViewModel billingVM,
    ParentViewModel parentVM,
  ) {
    final pending = _pendingPayments(billingVM);
    final uploadedProof = _uploadedProofPayments(billingVM);

    if (pending.isEmpty && uploadedProof.isEmpty) {
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
          if (pending.isNotEmpty) ...[
            _buildSectionHeader('Pending Payment', pending.length, Colors.orange),
            const SizedBox(height: 8),
            ...pending.map(
              (payment) => _UserPaymentTile(
                payment: payment,
                playerName: _playerName(parentVM, payment),
                sectionType: 'pending',
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (uploadedProof.isNotEmpty) ...[
            _buildSectionHeader('Uploaded Proof', uploadedProof.length, Colors.blue),
            const SizedBox(height: 8),
            ...uploadedProof.map(
              (payment) => _UserPaymentTile(
                payment: payment,
                playerName: _playerName(parentVM, payment),
                sectionType: 'uploaded',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
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
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserPaymentTile extends StatelessWidget {
  final UserPaymentModel payment;
  final String playerName;
  final String sectionType; // 'pending' or 'uploaded'

  const _UserPaymentTile({
    required this.payment,
    required this.playerName,
    required this.sectionType,
  });

  @override
  Widget build(BuildContext context) {
    final status = payment.paymentStatus;
    final isUploaded = sectionType == 'uploaded';
    final accentColor = isUploaded ? Colors.blue : Colors.orange;

    final statusLabel = switch (status) {
      'approved' => 'APPROVED',
      'rejected' => 'REJECTED',
      'pending' => 'PENDING',
      _ => 'NOT UPLOADED',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          context.router.pushPath('/user-payment-details/${payment.id}');
        },
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isUploaded ? Icons.check_circle : Icons.hourglass_top,
            color: accentColor,
          ),
        ),
        title: Text(
          playerName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${payment.attendanceIds.length} session${payment.attendanceIds.length == 1 ? '' : 's'}'
              '${payment.isInvoice ? ' · Invoiced' : ''}',
            ),
            Text(
              DateFormat('MMM d, yyyy').format(payment.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${payment.currency} ${payment.totalAmt > 0 ? payment.totalAmt : payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: accentColor,
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
