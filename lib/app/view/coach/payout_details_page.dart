import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/service/coach_payout_service.dart';
import 'package:jsba_app/app/service/training_service.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/model/coach_payout_model.dart';
import 'package:jsba_app/app/view/coach/session_details_page.dart';

class PayoutDetailsPage extends StatefulWidget {
  final String payoutId;

  const PayoutDetailsPage({super.key, required this.payoutId});

  @override
  State<PayoutDetailsPage> createState() => _PayoutDetailsPageState();
}

class _PayoutDetailsPageState extends State<PayoutDetailsPage> {
  final CoachPayoutService _payoutService = CoachPayoutService();
  final TrainingService _trainingService = TrainingService();

  CoachPayoutModel? _payout;
  List<TrainingModel> _trainings = [];
  final Map<String, Map<String, dynamic>> _sessionRateCache = {};
  Map<String, dynamic> _coachRates = {};

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final payout = await _payoutService.getPayoutById(widget.payoutId);
      if (payout == null) {
        setState(() {
          _error = 'Payout not found';
          _isLoading = false;
        });
        return;
      }

      _payout = payout;

      // Load coachRates doc
      if (payout.coachRatesId.isNotEmpty) {
        final snap = await FirebaseFirestore.instance.collection('coachRates').doc(payout.coachRatesId).get();
        if (snap.exists) _coachRates = snap.data() ?? {};
      }

      // Load trainings
      _trainings = await _loadTrainings(payout.trainingIds);

      // Determine which sessionRates docs we need and fetch them in parallel
      final needed = <String>{};
      for (final t in _trainings) {
        final field = _rateFieldForClassType(t.classType);
        final id = _coachRates[field] as String? ?? '';
        if (id.isNotEmpty) needed.add(id);
      }

      final futures = needed.map((id) => FirebaseFirestore.instance.collection('sessionRates').doc(id).get()).toList();
      final snaps = await Future.wait(futures);
      for (final s in snaps) {
        if (s.exists) _sessionRateCache[s.id] = s.data() ?? {};
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<List<TrainingModel>> _loadTrainings(List<String> ids) async {
    if (ids.isEmpty) return [];
    final futures = ids.map((id) => _trainingService.getTrainingById(id)).toList();
    final results = await Future.wait(futures);
    return results.whereType<TrainingModel>().toList();
  }

  String _rateFieldForClassType(String classType) {
    switch (classType) {
      case 'group':
        return 'groupRateId';
      case 'private':
        return 'privateRateId';
      case 'sparring':
        return 'sparringRateId';
      default:
        return 'othersRateId';
    }
  }

  double _priceForTraining(TrainingModel t) {
    final field = _rateFieldForClassType(t.classType);
    final rateId = _coachRates[field] as String? ?? '';
    if (rateId.isNotEmpty) {
      final sr = _sessionRateCache[rateId];
      if (sr != null) {
        final price = sr['price'];
        if (price is num) return price.toDouble();
      }
    }
    return t.price;
  }

  double _computeTotal() {
    return _trainings.fold(0.0, (double sum, t) => sum + _priceForTraining(t));
  }

  Color _classTypeColor(String classType) {
    switch (classType) {
      case 'private':
        return Colors.deepPurple;
      case 'sparring':
        return Colors.redAccent;
      case 'group':
      default:
        return AppTheme.primaryColor;
    }
  }

  

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Payout Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Payout Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        body: Center(child: Text(_error!)),
      );
    }

    final payout = _payout!;
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

    final hasProof = payout.uploadProof != null && payout.uploadProof!.isNotEmpty;

    final total = _computeTotal();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Payout Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(periodLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('${payout.trainingIds.length} trainings', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: hasProof ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(hasProof ? Icons.check_circle : Icons.hourglass_bottom, size: 18, color: hasProof ? Colors.green : Colors.orange),
                          const SizedBox(width: 8),
                          Text(hasProof ? 'COMPLETE' : 'INCOMPLETE', style: TextStyle(color: hasProof ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payout Total', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('RM ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (payout.generatedAt != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Generated', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(DateFormat('d MMM yyyy').format(payout.generatedAt!), style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Upload proof hint removed per request

          // Trainings
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trainings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_trainings.isEmpty)
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('No trainings', style: TextStyle(color: Colors.grey[600])))
                  else
                    ..._trainings.map((t) {
                      final price = _priceForTraining(t);
                      return InkWell(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionDetailsPage(sessionId: t.id))),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              // Leading circle icon / avatar
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _classTypeColor(t.classType).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(
                                    t.classType == 'private'
                                        ? Icons.person
                                        : (t.classType == 'sparring' ? Icons.sports_martial_arts : Icons.group),
                                    color: _classTypeColor(t.classType),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Title and meta
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(t.className, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text('${DateFormat('EEE, MMM d').format(t.date)} • ${t.startTime} – ${t.computedEndTime}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ]),
                              ),
                              const SizedBox(width: 12),
                              // Price and tag
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8)),
                                  child: Text('RM ${price.toStringAsFixed(2)}', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: _classTypeColor(t.classType).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                  child: Text(t.classType.toUpperCase(), style: TextStyle(fontSize: 11, color: _classTypeColor(t.classType), fontWeight: FontWeight.w700)),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Created At
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Created At', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(payout.createdAt != null ? DateFormat('MMM d, yyyy h:mm a').format(payout.createdAt!) : '-', style: TextStyle(color: Colors.grey[700])),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          // Proof card (shows image when available, otherwise shows incomplete message)
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Proof', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (hasProof) ...[
                  GestureDetector(
                    onTap: () => showDialog(context: context, builder: (_) => Dialog(child: InteractiveViewer(child: Image.network(payout.uploadProof!)))),
                    child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(payout.uploadProof!, height: 200, width: double.infinity, fit: BoxFit.cover)),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.info_outline, color: Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                          Text('INCOMPLETE', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text('Not uploaded yet', style: TextStyle(color: Colors.grey)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
