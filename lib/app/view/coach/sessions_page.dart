import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';
import 'package:jsba_app/app/viewmodel/coach_view_model.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';

@RoutePage()
class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  // Selected month — defaults to current month
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _selectedFilter = 'all'; // all, upcoming, completed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSessions());
  }

  void _loadSessions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<CoachViewModel>().loadAllCoachSessions(user.uid);
    }
  }

  // Filter by selected month first, then by status
  List<TrainingModel> _applyFilters(List<TrainingModel> all) {
    // Month filter
    final byMonth = all.where((s) =>
        s.date.year == _selectedMonth.year &&
        s.date.month == _selectedMonth.month).toList();

    // Status filter
    switch (_selectedFilter) {
      case 'upcoming':
        return byMonth.where((s) => s.getEffectiveStatus() == 'upcoming').toList();
      case 'completed':
        return byMonth.where((s) => s.getEffectiveStatus() == 'completed').toList();
      default:
        return byMonth;
    }
  }

  void _previousMonth() =>
      setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void _nextMonth() {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    // Don't allow navigating past current month
    final now = DateTime.now();
    if (next.year > now.year || (next.year == now.year && next.month > now.month)) return;
    setState(() => _selectedMonth = next);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarTitle(title: 'My Sessions'),
      body: Consumer<CoachViewModel>(
        builder: (context, coachVM, child) {
          if (coachVM.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allSessions = coachVM.monthSessions;
          final filtered = _applyFilters(allSessions);
          // Sessions in the selected month (before status filter)
          final monthSessions = allSessions.where((s) =>
              s.date.year == _selectedMonth.year &&
              s.date.month == _selectedMonth.month).toList();

          return Column(
            children: [
              _buildMonthSelector(),
              _buildFilterBar(monthSessions),
              Expanded(child: _buildSessionsList(filtered)),
            ],
          );
        },
      ),
    );
  }

  // ── Month selector ────────────────────────────────────────────────────────

  Widget _buildMonthSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous month
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: AppTheme.primaryColor,
            onPressed: _previousMonth,
          ),

          // Month + year label — tap to pick from date picker
          GestureDetector(
            onTap: _showMonthPicker,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down,
                    color: AppTheme.primaryColor, size: 20),
              ],
            ),
          ),

          // Next month (greyed out when at current month)
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: _isCurrentMonth
                ? Colors.grey.shade300
                : AppTheme.primaryColor,
            onPressed: _isCurrentMonth ? null : _nextMonth,
          ),
        ],
      ),
    );
  }

  Future<void> _showMonthPicker() async {
    final now = DateTime.now();
    // Show a year/month grid using showDatePicker constrained to day 1
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select month',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppTheme.primaryColor,
              ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
  }

  // ── Status filter bar ─────────────────────────────────────────────────────

  Widget _buildFilterBar(List<TrainingModel> monthSessions) {
    final upcomingCount = monthSessions
        .where((s) => s.getEffectiveStatus() == 'upcoming')
        .length;
    final completedCount = monthSessions
        .where((s) => s.getEffectiveStatus() == 'completed')
        .length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _buildFilterChip('all', 'All (${monthSessions.length})'),
          const SizedBox(width: 8),
          _buildFilterChip('upcoming', 'Upcoming ($upcomingCount)'),
          const SizedBox(width: 8),
          _buildFilterChip('completed', 'Done ($completedCount)'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  // ── Sessions list ─────────────────────────────────────────────────────────

  Widget _buildSessionsList(List<TrainingModel> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No sessions in ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadSessions(),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.paddingOf(context).bottom + 100,
        ),
        itemCount: sessions.length,
        itemBuilder: (context, index) => _buildSessionCard(sessions[index]),
      ),
    );
  }

  Widget _buildSessionCard(TrainingModel session) {
    final status = session.getEffectiveStatus();
    final isUpcoming = status == 'upcoming';
    final statusColor = isUpcoming ? Colors.blue : Colors.green;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () =>
          context.router.push(SessionDetailsRoute(sessionId: session.id)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Date badge
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('d').format(session.date),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      DateFormat('MMM').format(session.date).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.className,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    _iconRow(Icons.access_time,
                        '${session.startTime} - ${session.computedEndTime}'),
                    const SizedBox(height: 2),
                    _iconRow(Icons.location_on,
                        '${session.venue} · ${session.classType}'),
                    const SizedBox(height: 2),
                    _iconRow(Icons.people_outline,
                        '${session.playerIds.length} player${session.playerIds.length == 1 ? '' : 's'}'),
                  ],
                ),
              ),
              // Status + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isUpcoming ? 'Upcoming' : 'Done',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right,
                      color: Colors.grey.shade400, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ],
    );
  }
}
