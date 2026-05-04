import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/service/training_service.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';

@RoutePage()
class SessionDetailsPage extends StatefulWidget {
  final String? sessionId;

  const SessionDetailsPage({
    super.key,
    @PathParam('sessionId') this.sessionId,
  });

  String get effectiveSessionId => sessionId ?? '';

  @override
  State<SessionDetailsPage> createState() => _SessionDetailsPageState();
}

class _SessionDetailsPageState extends State<SessionDetailsPage> {
  final _trainingService = TrainingService();
  final _playerService = PlayerService();

  TrainingModel? _training;
  List<PlayerModel> _players = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (widget.effectiveSessionId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    _training = await _trainingService.getTrainingById(widget.effectiveSessionId);

    if (_training != null && _training!.playerIds.isNotEmpty) {
      final allPlayers = await _playerService.getPlayers();
      final enrolledIds = _training!.playerIds.toSet();
      _players = allPlayers.where((p) => enrolledIds.contains(p.id)).toList();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _goToAttendance() async {
    if (_training == null) return;
    await context.router.push(AttendanceRoute(trainingId: _training!.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarTitle(
        title: _training?.className ?? 'Session Details',
        icon: Icons.sports_tennis,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _training == null
              ? const Center(child: Text('Training not found'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final t = _training!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = t.getEffectiveStatus();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          _buildStatusBanner(status, isDark),
          const SizedBox(height: 16),

          // Main info card
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Training Details'),
                _buildRow(Icons.class_outlined, 'Class Name', t.className),
                _buildDivider(),
                _buildRow(
                  Icons.calendar_today,
                  'Date',
                  DateFormat('EEEE, MMMM d, yyyy').format(t.date),
                ),
                _buildDivider(),
                _buildRow(
                  Icons.access_time,
                  'Time',
                  '${t.startTime} – ${t.computedEndTime}',
                ),
                _buildDivider(),
                _buildRow(Icons.timer_outlined, 'Duration', '${t.durationMinutes} min'),
                _buildDivider(),
                _buildRow(Icons.location_on_outlined, 'Venue', t.venue),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Class info card
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Class Info'),
                _buildRow(
                  Icons.category_outlined,
                  'Type',
                  _capitalize(t.classType),
                ),
                _buildDivider(),
                _buildRow(Icons.speed_outlined, 'Level', t.level),
                _buildDivider(),
                _buildRow(
                  Icons.attach_money,
                  'Price per Session',
                  'RM ${t.price.toStringAsFixed(2)}',
                  valueColor: AppTheme.primaryColor,
                ),
                _buildDivider(),
                _buildRow(
                  Icons.group_outlined,
                  'Max Players',
                  '${t.getEffectiveMaxPlayers()} players',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Players card
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  'Enrolled Players',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${t.playerIds.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                if (t.playerIds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      'No players enrolled yet',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                else
                  ..._buildPlayerList(isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Mark Attendance button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _goToAttendance,
              icon: const Icon(Icons.how_to_reg),
              label: const Text('Mark Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildStatusBanner(String status, bool isDark) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle_rounded;
        label = 'Completed';
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel_rounded;
        label = 'Cancelled';
      default:
        color = Colors.orange;
        icon = Icons.schedule_rounded;
        label = 'Upcoming';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Text(
            DateFormat('d MMM yyyy').format(_training!.date),
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.primaryColor,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 46,
      endIndent: 16,
      color: Colors.grey.withValues(alpha: 0.15),
    );
  }

  List<Widget> _buildPlayerList(bool isDark) {
    // Show players we fetched; fall back to showing IDs for any not found
    final enrolledIds = _training!.playerIds;
    final playerMap = {for (final p in _players) p.id: p};

    return List.generate(enrolledIds.length, (i) {
      final id = enrolledIds[i];
      final player = playerMap[id];
      final isLast = i == enrolledIds.length - 1;
      final initial = (player?.name.isNotEmpty == true)
          ? player!.name[0].toUpperCase()
          : '?';

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player?.name ?? 'Unknown Player',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (player?.level.isNotEmpty == true)
                        Text(
                          player!.level,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (player?.phone.isNotEmpty == true)
                  Text(
                    player!.phone,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              indent: 64,
              endIndent: 16,
              color: Colors.grey.withValues(alpha: 0.15),
            ),
          if (isLast) const SizedBox(height: 8),
        ],
      );
    });
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
