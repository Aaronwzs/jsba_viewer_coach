import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jsba_app/app/viewmodel/app_view_model.dart';
import 'package:jsba_app/app/service/coach_payout_service.dart';
import 'package:jsba_app/app/model/coach_payout_model.dart';
import 'package:jsba_app/app/view/coach/payout_details_page.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';

@RoutePage()
class CoachBillingPage extends StatefulWidget {
  const CoachBillingPage({super.key});

  @override
  State<CoachBillingPage> createState() => _CoachBillingPageState();
}

class _CoachBillingPageState extends State<CoachBillingPage> {
  final CoachPayoutService _service = CoachPayoutService();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = false;
  String? _error;
  List<CoachPayoutModel> _payouts = [];

  // removed debug logs per UX cleanup

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appVM = context.read<AppViewModel>();
      final coachId = appVM.userId;
      // load payouts for the selected coach/month

      var effectiveCoachId = coachId;
      if (effectiveCoachId.isEmpty) {
        // Try FirebaseAuth fallback
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.uid.isNotEmpty) {
          effectiveCoachId = user.uid;
        }
      }

      if (effectiveCoachId.isEmpty) {
        _payouts = [];
      } else {
        _payouts = await _service.getPayoutsForCoachMonth(
          effectiveCoachId,
          _selectedMonth.year,
          _selectedMonth.month,
        );
        // payouts loaded
      }
    } catch (e) {
      _error = e.toString();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarTitle(showBackButton: false),
      body: _isLoading
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
                  _buildMonthSelector(),
                  const SizedBox(height: 8),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  _buildContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelector() {
    final month = _selectedMonth;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormat('MMMM yyyy').format(month),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  // Debug panel removed

  Widget _buildContent() {
    if (_payouts.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payments_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No payouts this month',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _payouts.map((p) => _buildPayoutCard(p)).toList(),
      ),
    );
  }

  Widget _buildPayoutCard(CoachPayoutModel payout) {
    final hasProof = payout.uploadProof != null && payout.uploadProof!.isNotEmpty;
    final isComplete = hasProof;

    final periodLabel = (() {
      try {
        final parts = payout.periodKey.split('-');
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return DateFormat('MMMM yyyy').format(DateTime(y, m));
      } catch (_) {
        return payout.periodKey;
      }
    })();

    // Modern card layout
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PayoutDetailsPage(payoutId: payout.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isComplete ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top section with status and period
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isComplete ? Colors.green.withValues(alpha: 0.08) : Colors.orange.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    periodLabel.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isComplete ? Icons.check_circle : Icons.pending,
                        size: 16,
                        color: isComplete ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isComplete ? 'PAID' : 'PENDING',
                        style: TextStyle(
                          color: isComplete ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom section with details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${payout.trainingIds.length} Trainings',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (payout.generatedAt != null)
                          Text(
                            'Generated ${DateFormat('dd MMM yyyy').format(payout.generatedAt!)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
