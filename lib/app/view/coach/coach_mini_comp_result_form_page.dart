import 'package:flutter/material.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/model/mini_competition_result_model.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/viewmodel/assessment_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';
import 'package:provider/provider.dart';

class CoachMiniCompResultFormPage extends StatefulWidget {
  final String eventId;
  final DateTime eventDate;
  final String playerId;
  final String playerName;
  final MiniCompetitionResultModel? existing;

  const CoachMiniCompResultFormPage({
    super.key,
    required this.eventId,
    required this.eventDate,
    required this.playerId,
    required this.playerName,
    this.existing,
  });

  @override
  State<CoachMiniCompResultFormPage> createState() =>
      _CoachMiniCompResultFormPageState();
}

class _CoachMiniCompResultFormPageState
    extends State<CoachMiniCompResultFormPage> {
  String? _opponentId;
  String _opponentName = '';
  int _myPoints = 0;
  int _oppPoints = 0;
  bool _isStarPlayer = false;
  final _noteCtrl = TextEditingController();

  bool get _isEdit => widget.existing != null;
  bool get _canSave => _opponentId != null && _myPoints != _oppPoints;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _opponentId = existing.opponentId;
      _opponentName = existing.opponentName;
      _myPoints = existing.myPoints;
      _oppPoints = existing.opponentPoints;
      _isStarPlayer = existing.isStarPlayer;
      _noteCtrl.text = existing.note ?? '';
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickOpponent() async {
    List<PlayerModel> players;
    try {
      players = await PlayerService().getPlayers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load players: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (!mounted) return;
    final candidates =
        players
            .where(
              (player) =>
                  player.id != widget.playerId && player.isActive == true,
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final picked = await showModalBottomSheet<PlayerModel>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _OpponentPickerSheet(players: candidates),
    );

    if (picked == null || !mounted) return;
    setState(() {
      _opponentId = picked.id;
      _opponentName = picked.name;
    });
  }

  Future<void> _save() async {
    if (!_canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _opponentId == null
                ? 'Please select an opponent'
                : 'Points must not be tied for a 5-point game',
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    final vm = context.read<AssessmentViewModel>();
    final result = MiniCompetitionResultModel(
      id: widget.existing?.id ?? '',
      eventId: widget.eventId,
      playerId: widget.playerId,
      playerName: widget.playerName,
      opponentId: _opponentId!,
      opponentName: _opponentName,
      date: widget.existing?.date ?? widget.eventDate,
      myPoints: _myPoints,
      opponentPoints: _oppPoints,
      ratingBefore: widget.existing?.ratingBefore ?? 1000.0,
      ratingAfter: widget.existing?.ratingAfter ?? 1000.0,
      ratingDeviation: widget.existing?.ratingDeviation ?? 350.0,
      isStarPlayer: _isStarPlayer,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      recordedBy: _recordedBy(),
      createdAt: widget.existing?.createdAt,
    );

    final ok = _isEdit
        ? await vm.updateMiniCompResult(widget.existing!.id, result)
        : await vm.saveMiniCompResult(result);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(vm.errorMessage ?? 'Failed to save result'),
        backgroundColor: Colors.red.shade700,
      ),
    );
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
        title: _isEdit ? 'Edit Match' : 'Add Match',
        icon: Icons.emoji_events,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Opponent'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickOpponent,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _opponentId == null
                            ? Colors.orange.shade300
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _opponentId == null
                              ? Icons.person_add_outlined
                              : Icons.person,
                          color: _opponentId == null
                              ? Colors.orange.shade400
                              : AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _opponentId == null
                                ? 'Tap to select opponent'
                                : _opponentName,
                            style: TextStyle(
                              fontWeight: _opponentId == null
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              color: _opponentId == null
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade500),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Column(
              children: [
                const _SectionLabel('Score (5-point game)'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _scoreColumn(
                        widget.playerName,
                        _myPoints,
                        (value) => setState(() => _myPoints = value),
                        AppTheme.primaryColor,
                        isHighlighted: _myPoints > _oppPoints,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _scoreColumn(
                        _opponentName.isEmpty ? 'Opponent' : _opponentName,
                        _oppPoints,
                        (value) => setState(() => _oppPoints = value),
                        Colors.red.shade400,
                        isHighlighted: _oppPoints > _myPoints,
                      ),
                    ),
                  ],
                ),
                if (_myPoints == _oppPoints && _myPoints > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tied scores are not allowed for 5-point games',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: _isStarPlayer ? Colors.amber.shade600 : Colors.grey,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Star Player Performance',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Mark exceptional performance for this match',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isStarPlayer,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (value) => setState(() => _isStarPlayer = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Match observations...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Match Result',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreColumn(
    String name,
    int points,
    ValueChanged<int> onChanged,
    Color color, {
    required bool isHighlighted,
  }) {
    return Column(
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isHighlighted ? color.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pointButton(
                Icons.remove,
                points > 0 ? () => onChanged(points - 1) : null,
              ),
              const SizedBox(width: 14),
              Text(
                '$points',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? color : Colors.black87,
                ),
              ),
              const SizedBox(width: 14),
              _pointButton(
                Icons.add,
                points < 5 ? () => onChanged(points + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pointButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap == null
              ? Colors.grey.shade200
              : AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.grey : AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
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
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _OpponentPickerSheet extends StatefulWidget {
  final List<PlayerModel> players;

  const _OpponentPickerSheet({required this.players});

  @override
  State<_OpponentPickerSheet> createState() => _OpponentPickerSheetState();
}

class _OpponentPickerSheetState extends State<_OpponentPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.players
        .where(
          (player) =>
              _search.isEmpty ||
              player.name.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          children: [
            const Text(
              'Select Opponent',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => setState(() => _search = value),
                decoration: InputDecoration(
                  hintText: 'Search players...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No players found'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final player = filtered[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            child: Text(
                              player.name.isNotEmpty
                                  ? player.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(player.name),
                          subtitle: Text(
                            'Age ${player.computedAge} · ${player.level}',
                          ),
                          onTap: () => Navigator.pop(context, player),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
