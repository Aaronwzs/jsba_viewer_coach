import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/model/assessment_event_model.dart';
import 'package:jsba_app/app/view/coach/coach_assessment_event_detail_page.dart';
import 'package:jsba_app/app/viewmodel/assessment_view_model.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';
import 'package:provider/provider.dart';

@RoutePage()
class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AssessmentViewModel>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();

    return Scaffold(
      appBar: const AppBarTitle(showBackButton: false, title: 'Assessments'),
      body: RefreshIndicator(onRefresh: vm.loadEvents, child: _buildBody(vm)),
    );
  }

  Widget _buildBody(AssessmentViewModel vm) {
    if (vm.isLoading && vm.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null && vm.events.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            vm.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: vm.loadEvents, child: const Text('Retry')),
        ],
      );
    }

    if (vm.events.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No assessment events yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Admin-created physical tests, skill tests, and mini competitions will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      itemCount: vm.events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _AssessmentEventTile(
        event: vm.events[index],
        onTap: () => _openEvent(vm.events[index]),
      ),
    );
  }

  Future<void> _openEvent(AssessmentEventWithTraining event) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CoachAssessmentEventDetailPage(event: event),
      ),
    );

    if (changed == true && mounted) {
      await context.read<AssessmentViewModel>().loadEvents();
    }
  }
}

class _AssessmentEventTile extends StatelessWidget {
  final AssessmentEventWithTraining event;
  final VoidCallback onTap;

  const _AssessmentEventTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (event.status) {
      AssessmentEventStatus.completed => Colors.green,
      AssessmentEventStatus.cancelled => Colors.red,
      _ => Colors.orange,
    };

    final icon = switch (event.type) {
      AssessmentEventType.physical => Icons.directions_run,
      AssessmentEventType.skill => Icons.sports_tennis,
      AssessmentEventType.competition => Icons.emoji_events,
      _ => Icons.assignment,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.typeDisplayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.date == null
                        ? 'Training not found'
                        : DateFormat('MMM d, yyyy').format(event.date!),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event.playerIds.length} players',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                event.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
