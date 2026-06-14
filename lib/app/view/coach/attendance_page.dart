import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/model/attendance_model.dart';
import 'package:jsba_app/app/model/coach_entry_model.dart';
import 'package:jsba_app/app/service/training_service.dart';
import 'package:jsba_app/app/service/attendance_service.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';

@RoutePage()
class AttendancePage extends StatefulWidget {
  final String? trainingId;

  const AttendancePage({
    super.key,
    this.trainingId,
  });

  String get effectiveTrainingId => trainingId ?? '';

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _trainingService = TrainingService();
  final _attendanceService = AttendanceService();
  final _playerService = PlayerService();

  final _commentControllers = <String, TextEditingController>{};
  final _selectedCategories = <String, String>{};

  TrainingModel? _training;
  List<AttendanceModel> _attendances = [];
  Map<String, PlayerModel> _playersMap = {};
  bool _isLoading = true;
  bool _isSaving = false;

  String? get _coachId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.effectiveTrainingId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    _training = await _trainingService.getTrainingById(widget.effectiveTrainingId);

    if (_training != null) {
      final allAttendances = await _attendanceService
          .getAttendanceForTraining(widget.effectiveTrainingId);

      final enrolledPlayerIds = _training!.playerIds.toSet();

      _attendances = allAttendances
          .where((a) => enrolledPlayerIds.contains(a.playerId))
          .toList();

      if (_attendances.isEmpty && _training!.playerIds.isNotEmpty) {
        await _attendanceService.createAttendanceBatch(
          _training!.id,
          _training!.playerIds,
          _training!.price,
          coachId: _coachId,
        );
        final refetched = await _attendanceService
            .getAttendanceForTraining(widget.effectiveTrainingId);
        _attendances = refetched
            .where((a) => enrolledPlayerIds.contains(a.playerId))
            .toList();
      }

      if (_training!.playerIds.isNotEmpty) {
        final allPlayers = await _playerService.getPlayers();
        final enrolledIds = _training!.playerIds.toSet();
        _playersMap = {
          for (final p in allPlayers)
            if (enrolledIds.contains(p.id)) p.id: p,
        };
      }

      for (final a in _attendances) {
        _commentControllers[a.id] ??= TextEditingController();
        _selectedCategories[a.id] ??= CoachCommentCategory.general;
      }
    }

    setState(() => _isLoading = false);
  }

  void _markAllPresent() {
    if (_training == null) return;
    setState(() {
      for (final a in _attendances) {
        a.attendanceStatus = 'attended';
        a.amountCharge = _training!.price;
        a.reasonCharge = '';
      }
    });
  }

  void _addEntry(AttendanceModel a) {
    final controller = _commentControllers[a.id];
    if (controller == null || controller.text.trim().isEmpty) return;

    setState(() {
      a.coachEntries.add(CoachEntry(
        category: _selectedCategories[a.id] ?? CoachCommentCategory.general,
        comment: controller.text.trim(),
      ));
      controller.clear();
    });
  }

  void _removeEntry(AttendanceModel a, int index) {
    setState(() {
      a.coachEntries.removeAt(index);
    });
  }

  Future<void> _saveAttendance() async {
    for (final a in _attendances) {
      final controller = _commentControllers[a.id];
      if (controller != null && controller.text.trim().isNotEmpty) {
        a.coachEntries.add(CoachEntry(
          category: _selectedCategories[a.id] ?? CoachCommentCategory.general,
          comment: controller.text.trim(),
        ));
        controller.clear();
      }
    }

    setState(() => _isSaving = true);

    try {
      await _attendanceService.batchUpdateAttendance(_attendances);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.router.maybePop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  int get _presentCount =>
      _attendances.where((a) => a.attendanceStatus == 'attended').length;
  int get _absentCount =>
      _attendances.where((a) => a.attendanceStatus == 'absent').length;
  int get _pendingCount =>
      _attendances.where((a) => a.attendanceStatus == 'pending').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarTitle(
        title: _training?.className ?? 'Attendance',
        icon: Icons.how_to_reg,
        actions: [
          if (_attendances.isNotEmpty)
            IconButton(
              tooltip: 'Mark all present',
              icon: const Icon(Icons.done_all, color: AppTheme.primaryColor),
              onPressed: _markAllPresent,
            ),
          TextButton(
            onPressed: _isSaving ? null : _saveAttendance,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _training == null
              ? const Center(child: Text('Training not found'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildSummaryHeader(isDark),
        Expanded(
          child: _attendances.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No attendance records',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Players need to be enrolled in this session',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    MediaQuery.paddingOf(context).bottom + 24,
                  ),
                  itemCount: _attendances.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAttendanceCard(_attendances[index], isDark),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(bool isDark) {
    final t = _training!;

    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                      DateFormat('EEE, d MMM yyyy').format(t.date),
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${t.startTime} – ${t.computedEndTime}  ·  ${t.venue}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Text(
                'RM ${t.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildChip('Present', _presentCount, Colors.green),
              const SizedBox(width: 8),
              _buildChip('Absent', _absentCount, Colors.red),
              const SizedBox(width: 8),
              _buildChip('Pending', _pendingCount, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel a, bool isDark) {
    final player = _playersMap[a.playerId];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(player),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player?.name ?? 'Unknown Player',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (player?.level.isNotEmpty == true)
                      Text(
                        player!.level,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                  ],
                ),
              ),
              _buildChargeBadge(a),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusBtn(a, 'attended', 'Present', Colors.green),
              const SizedBox(width: 8),
              _buildStatusBtn(a, 'absent', 'Absent', Colors.red),
              const SizedBox(width: 8),
              _buildStatusBtn(a, 'pending', 'Pending', Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          _buildExistingEntries(a),
          if (a.coachEntries.isNotEmpty) const SizedBox(height: 8),
          _buildCategorySelector(a),
          const SizedBox(height: 6),
          _buildCommentInput(a),
        ],
      ),
    );
  }

  Widget _buildExistingEntries(AttendanceModel a) {
    if (a.coachEntries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: a.coachEntries.asMap().entries.map((entry) {
        final index = entry.key;
        final coachEntry = entry.value;
        return _buildEntryChip(a, coachEntry, index);
      }).toList(),
    );
  }

  Widget _buildEntryChip(AttendanceModel a, CoachEntry entry, int index) {
    final color = _categoryColor(entry.category);
    final label = CoachCommentCategory.label(entry.category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              entry.comment,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeEntry(a, index),
            child: Icon(Icons.close, size: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(AttendanceModel a) {
    final selected = _selectedCategories[a.id] ?? CoachCommentCategory.general;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CoachCommentCategory.all.map((cat) {
          final isSelected = selected == cat;
          final color = _categoryColor(cat);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategories[a.id] = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? color : color.withValues(alpha: 0.4),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  CoachCommentCategory.label(cat),
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCommentInput(AttendanceModel a) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _commentControllers[a.id],
            decoration: InputDecoration(
              hintText: 'Add comment for ${CoachCommentCategory.label(_selectedCategories[a.id] ?? CoachCommentCategory.general)}...',
              hintStyle:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            onSubmitted: (_) => _addEntry(a),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _addEntry(a),
          icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
          iconSize: 28,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Color _categoryColor(String category) => switch (category) {
        CoachCommentCategory.footwork => Colors.blue,
        CoachCommentCategory.fitness => Colors.orange,
        CoachCommentCategory.technique => Colors.purple,
        CoachCommentCategory.matchPlay => Colors.teal,
        CoachCommentCategory.attitude => Colors.pink,
        _ => Colors.grey,
      };

  Widget _buildAvatar(PlayerModel? player) {
    final initial = (player?.name.isNotEmpty == true)
        ? player!.name[0].toUpperCase()
        : '?';
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            fontSize: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildChargeBadge(AttendanceModel a) {
    final hasCharge = a.amountCharge > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: hasCharge
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'RM ${a.amountCharge.toStringAsFixed(0)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: hasCharge ? AppTheme.primaryColor : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildStatusBtn(
      AttendanceModel a, String status, String label, Color color) {
    final isSelected = a.attendanceStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          a.attendanceStatus = status;
          if (status == 'attended') {
            a.amountCharge = _training!.price;
            a.reasonCharge = '';
          } else if (status == 'absent') {
            a.amountCharge = 0;
            a.reasonCharge = 'Absent';
          } else {
            a.amountCharge = 0;
            a.reasonCharge = '';
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.4),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
