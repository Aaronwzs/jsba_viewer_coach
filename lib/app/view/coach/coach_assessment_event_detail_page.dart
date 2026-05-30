import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/model/assessment_event_model.dart';
import 'package:jsba_app/app/model/mini_competition_result_model.dart';
import 'package:jsba_app/app/model/physical_result_model.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/model/skill_result_model.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/view/coach/coach_mini_comp_result_form_page.dart';
import 'package:jsba_app/app/view/coach/coach_physical_result_form_page.dart';
import 'package:jsba_app/app/view/coach/coach_skill_result_form_page.dart';
import 'package:jsba_app/app/viewmodel/assessment_view_model.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';
import 'package:provider/provider.dart';

class CoachAssessmentEventDetailPage extends StatefulWidget {
  final AssessmentEventWithTraining event;

  const CoachAssessmentEventDetailPage({super.key, required this.event});

  @override
  State<CoachAssessmentEventDetailPage> createState() =>
      _CoachAssessmentEventDetailPageState();
}

class _CoachAssessmentEventDetailPageState
    extends State<CoachAssessmentEventDetailPage> {
  final PlayerService _playerService = PlayerService();
  late Future<List<PlayerModel>> _playersFuture;

  @override
  void initState() {
    super.initState();
    _playersFuture = _loadPlayers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AssessmentViewModel>().loadEventData(widget.event);
    });
  }

  Future<List<PlayerModel>> _loadPlayers() async {
    final allPlayers = await _playerService.getPlayers();
    final playerIds = widget.event.playerIds.toSet();
    final players =
        allPlayers.where((player) => playerIds.contains(player.id)).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return players;
  }

  Future<void> _refresh() async {
    setState(() => _playersFuture = _loadPlayers());
    await context.read<AssessmentViewModel>().loadEventData(widget.event);
  }

  Future<void> _openForm(
    PlayerModel player, {
    PhysicalResultModel? physical,
    SkillResultModel? skill,
    MiniCompetitionResultModel? match,
  }) async {
    final page = switch (widget.event.type) {
      AssessmentEventType.physical => CoachPhysicalResultFormPage(
        eventId: widget.event.id,
        eventDate: widget.event.date ?? DateTime.now(),
        playerId: player.id,
        playerName: player.name,
        existing: physical,
      ),
      AssessmentEventType.skill => CoachSkillResultFormPage(
        eventId: widget.event.id,
        eventDate: widget.event.date ?? DateTime.now(),
        playerId: player.id,
        playerName: player.name,
        existing: skill,
      ),
      AssessmentEventType.competition => CoachMiniCompResultFormPage(
        eventId: widget.event.id,
        eventDate: widget.event.date ?? DateTime.now(),
        playerId: player.id,
        playerName: player.name,
        existing: match,
      ),
      _ => null,
    };

    if (page == null) return;

    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => page));

    if (saved == true && mounted) {
      await context.read<AssessmentViewModel>().loadEventData(widget.event);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();

    return Scaffold(
      appBar: AppBarTitle(
        title: widget.event.typeDisplayName,
        icon: _eventIcon(widget.event.type),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            _EventInfoCard(event: widget.event),
            if (widget.event.trainingId.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.fitness_center, color: AppTheme.primaryColor),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Players are inherited from the linked training session.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Players',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (vm.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vm.errorMessage != null)
              _StateCard(
                icon: Icons.error_outline,
                title: 'Unable to load results',
                message: vm.errorMessage!,
                actionLabel: 'Retry',
                onAction: () => context
                    .read<AssessmentViewModel>()
                    .loadEventData(widget.event),
              )
            else
              FutureBuilder<List<PlayerModel>>(
                future: _playersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 64),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return _StateCard(
                      icon: Icons.error_outline,
                      title: 'Unable to load players',
                      message: snapshot.error.toString(),
                      actionLabel: 'Retry',
                      onAction: () =>
                          setState(() => _playersFuture = _loadPlayers()),
                    );
                  }

                  final players = snapshot.data ?? [];
                  if (players.isEmpty) {
                    return const _StateCard(
                      icon: Icons.people_outline,
                      title: 'No players assigned',
                      message: 'Admin-assigned players will appear here.',
                    );
                  }

                  return Column(
                    children: players
                        .map(
                          (player) => _PlayerResultTile(
                            event: widget.event,
                            player: player,
                            physical: _physicalFor(vm, player.id),
                            skill: _skillFor(vm, player.id),
                            match: _matchFor(vm, player.id),
                            onTap: widget.event.isCancelled
                                ? null
                                : () => _openForm(
                                    player,
                                    physical: _physicalFor(vm, player.id),
                                    skill: _skillFor(vm, player.id),
                                    match: _matchFor(vm, player.id),
                                  ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  PhysicalResultModel? _physicalFor(AssessmentViewModel vm, String playerId) {
    for (final result in vm.eventPhysicalResults) {
      if (result.playerId == playerId) return result;
    }
    return null;
  }

  SkillResultModel? _skillFor(AssessmentViewModel vm, String playerId) {
    for (final result in vm.eventSkillResults) {
      if (result.playerId == playerId) return result;
    }
    return null;
  }

  MiniCompetitionResultModel? _matchFor(
    AssessmentViewModel vm,
    String playerId,
  ) {
    for (final result in vm.eventMatchResults) {
      if (result.playerId == playerId) return result;
    }
    return null;
  }

  IconData _eventIcon(String type) {
    return switch (type) {
      AssessmentEventType.physical => Icons.directions_run,
      AssessmentEventType.skill => Icons.sports_tennis,
      AssessmentEventType.competition => Icons.emoji_events,
      _ => Icons.assignment,
    };
  }
}

class _EventInfoCard extends StatelessWidget {
  final AssessmentEventWithTraining event;

  const _EventInfoCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.typeDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              _StatusBadge(status: event.status),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: event.date == null
                ? 'Training not found'
                : DateFormat('EEE, MMM d, yyyy').format(event.date!),
          ),
          if (event.groupName != null && event.groupName!.isNotEmpty)
            _InfoRow(
              icon: Icons.group,
              label: 'Group',
              value: event.groupName!,
            ),
          if (event.coachId != null && event.coachId!.isNotEmpty)
            _InfoRow(
              icon: Icons.sports,
              label: 'Coach ID',
              value: event.coachId!,
            ),
          _InfoRow(
            icon: Icons.people,
            label: 'Players',
            value: '${event.playerIds.length}',
          ),
          if (event.notes != null && event.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(event.notes!, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ],
      ),
    );
  }
}

class _PlayerResultTile extends StatelessWidget {
  final AssessmentEventWithTraining event;
  final PlayerModel player;
  final PhysicalResultModel? physical;
  final SkillResultModel? skill;
  final MiniCompetitionResultModel? match;
  final VoidCallback? onTap;

  const _PlayerResultTile({
    required this.event,
    required this.player,
    this.physical,
    this.skill,
    this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasResult = switch (event.type) {
      AssessmentEventType.physical => physical != null,
      AssessmentEventType.skill => skill != null,
      AssessmentEventType.competition => match != null,
      _ => false,
    };

    final trailing = _trailingText();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
          child: Text(
            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          player.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(hasResult ? 'Recorded' : 'Not recorded yet'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(
                trailing,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(width: 8),
            Icon(
              hasResult ? Icons.edit_outlined : Icons.add_circle_outline,
              color: event.isCancelled ? Colors.grey : AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  String? _trailingText() {
    return switch (event.type) {
      AssessmentEventType.physical => physical?.physicalScore.toStringAsFixed(
        1,
      ),
      AssessmentEventType.skill => skill?.technicalScore.toStringAsFixed(1),
      AssessmentEventType.competition =>
        match == null
            ? null
            : '${match!.isWin ? 'W' : 'L'} ${match!.myPoints}-${match!.opponentPoints}',
      _ => null,
    };
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AssessmentEventStatus.completed => Colors.green,
      AssessmentEventStatus.cancelled => Colors.red,
      _ => Colors.orange,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
