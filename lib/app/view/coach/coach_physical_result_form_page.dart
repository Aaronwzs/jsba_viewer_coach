import 'package:flutter/material.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/model/metric_definition_model.dart';
import 'package:jsba_app/app/model/physical_result_model.dart';
import 'package:jsba_app/app/service/metric_definition_service.dart';
import 'package:jsba_app/app/viewmodel/assessment_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';
import 'package:provider/provider.dart';

class CoachPhysicalResultFormPage extends StatefulWidget {
  final String eventId;
  final DateTime eventDate;
  final String playerId;
  final String playerName;
  final PhysicalResultModel? existing;

  const CoachPhysicalResultFormPage({
    super.key,
    required this.eventId,
    required this.eventDate,
    required this.playerId,
    required this.playerName,
    this.existing,
  });

  @override
  State<CoachPhysicalResultFormPage> createState() =>
      _CoachPhysicalResultFormPageState();
}

class _CoachPhysicalResultFormPageState
    extends State<CoachPhysicalResultFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _metricService = MetricDefinitionService();
  final _noteCtrl = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};
  late Future<List<MetricDefinitionModel>> _metricsFuture;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _noteCtrl.text = widget.existing?.coachNote ?? '';
    _metricsFuture = _loadMetrics();
  }

  Future<List<MetricDefinitionModel>> _loadMetrics() async {
    final metrics = await _metricService.getByCategory(MetricCategory.physical);
    for (final metric in metrics) {
      _controllers.putIfAbsent(
        metric.key,
        () => TextEditingController(
          text: widget.existing?.metrics[metric.key]?.toString() ?? '',
        ),
      );
    }
    return metrics;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(List<MetricDefinitionModel> definitions) async {
    if (!_formKey.currentState!.validate()) return;
    final values = <String, dynamic>{};
    for (final metric in definitions) {
      final text = _controllers[metric.key]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      values[metric.key] = double.tryParse(text);
    }

    final result = PhysicalResultModel(
      id: widget.existing?.id ?? '',
      eventId: widget.eventId,
      playerId: widget.playerId,
      playerName: widget.playerName,
      date: widget.existing?.date ?? widget.eventDate,
      metrics: values,
      physicalScore: PhysicalResultModel.calculateScore(values, definitions),
      coachNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      recordedBy: _recordedBy(),
      createdAt: widget.existing?.createdAt,
      personalBests: widget.existing?.personalBests,
    );

    final vm = context.read<AssessmentViewModel>();
    final ok = _isEdit
        ? await vm.updatePhysicalResult(widget.existing!.id, result)
        : await vm.savePhysicalResult(result);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Failed to save result')),
      );
    }
  }

  String _recordedBy() {
    final name = context.read<AuthViewModel>().currentUser?.displayName ?? '';
    return name.trim().isEmpty ? 'Coach' : name.trim();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<AssessmentViewModel>().isSaving;
    return Scaffold(
      appBar: AppBarTitle(
        title: _isEdit ? 'Edit Physical' : 'Add Physical',
        icon: Icons.directions_run,
      ),
      body: FutureBuilder<List<MetricDefinitionModel>>(
        future: _metricsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final definitions = snapshot.data ?? [];
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load metrics: ${snapshot.error}'),
            );
          }
          if (definitions.isEmpty) {
            return const Center(child: Text('No physical metrics'));
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...definitions.map(
                  (metric) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.unit.isEmpty
                              ? metric.label
                              : '${metric.label} (${metric.unit})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _controllers[metric.key],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Best ${metric.bestValue}, worst ${metric.worstValue}',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            return double.tryParse(value) == null
                                ? 'Invalid number'
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Coach note'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () => _save(definitions),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Result'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
