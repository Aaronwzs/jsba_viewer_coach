import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/model/open_court_model.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/model/availability_model.dart';
import 'package:jsba_app/app/model/user_model.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/service/database_service.dart';
import 'package:jsba_app/app/viewmodel/open_court_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:jsba_app/app/viewmodel/availability_view_model.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';

@RoutePage()
class CourtBookingsPage extends StatefulWidget {
  const CourtBookingsPage({super.key});

  @override
  State<CourtBookingsPage> createState() => _CourtBookingsPageState();
}

enum AvailabilityFilter {
  all,
  active,
  weekdays,
  weekends,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

class _CourtBookingsPageState extends State<CourtBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasLoadedMyClasses = false;
  bool _hasLoadedAvailability = false;
  AvailabilityFilter _currentFilter = AvailabilityFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      if (authVM.currentUser != null) {
        context.read<ParentViewModel>().loadMyKids(authVM.currentUser!.uid);
      }
      context.read<OpenCourtViewModel>().loadAvailableSessions();
    });
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_hasLoadedMyClasses) {
      _hasLoadedMyClasses = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMyClassesData();
      });
    }
    if (_tabController.index == 2) {
      final availabilityVM = context.read<AvailabilityViewModel>();
      // Load on first visit, or retry if previous load failed
      if (!_hasLoadedAvailability || availabilityVM.error != null) {
        _hasLoadedAvailability = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          availabilityVM.loadSlots();
        });
      }
    }
  }

  void _loadMyClassesData() {
    final parentVM = context.read<ParentViewModel>();
    final openCourtVM = context.read<OpenCourtViewModel>();

    final allPlayerIds = <String>[];
    if (parentVM.selfPlayer != null && parentVM.selfPlayer!.id.isNotEmpty) {
      allPlayerIds.add(parentVM.selfPlayer!.id);
    }
    for (final kid in parentVM.allKids) {
      if (kid.id.isNotEmpty) {
        allPlayerIds.add(kid.id);
      }
    }

    if (allPlayerIds.isNotEmpty) {
      openCourtVM.loadMyClasses(allPlayerIds);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final openCourtVM = context.watch<OpenCourtViewModel>();
    final parentVM = context.watch<ParentViewModel>();

    final allAvailableSessions = [
      ...openCourtVM.openForBookingSessions,
      ...openCourtVM.openForRegistrationSessions,
      ...openCourtVM.closedSessions,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Court Bookings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Sessions Open'),
            Tab(text: 'My Classes'),
            Tab(text: 'Availability'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableTab(
            allAvailableSessions,
            authVM,
            openCourtVM,
            parentVM,
          ),
          _buildMyClassesTab(authVM, openCourtVM, parentVM),
          _buildAvailabilityTab(authVM),
        ],
      ),
    );
  }

  Widget _buildAvailableTab(
    List<OpenCourtModel> allSessions,
    AuthViewModel authVM,
    OpenCourtViewModel openCourtVM,
    ParentViewModel parentVM,
  ) {
    if (openCourtVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter sessions by selected month
    final filteredSessions = allSessions.where((session) {
      return session.date.year == openCourtVM.selectedMonth.year &&
          session.date.month == openCourtVM.selectedMonth.month;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await openCourtVM.loadAvailableSessions();
        if (authVM.currentUser != null) {
          await parentVM.loadMyKids(authVM.currentUser!.uid);
        }
      },
      child: Column(
        children: [
          // Month selector
          _buildAvailableMonthSelector(openCourtVM),
          // Sessions list
          Expanded(
            child: filteredSessions.isEmpty
                ? _buildEmptyState(openCourtVM)
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      MediaQuery.paddingOf(context).bottom + 100,
                    ),
                    itemCount: filteredSessions.length,
                    itemBuilder: (context, index) {
                      final session = filteredSessions[index];
                      return _buildSessionCard(
                        session,
                        authVM,
                        openCourtVM,
                        parentVM,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableMonthSelector(OpenCourtViewModel openCourtVM) {
    final month = openCourtVM.selectedMonth;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              openCourtVM.setSelectedMonth(
                DateTime(month.year, month.month - 1),
              );
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(month),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              openCourtVM.setSelectedMonth(
                DateTime(month.year, month.month + 1),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMyClassesTab(
    AuthViewModel authVM,
    OpenCourtViewModel openCourtVM,
    ParentViewModel parentVM,
  ) {
    final user = authVM.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    if (openCourtVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allPlayerIds = <String>[];
    if (parentVM.selfPlayer != null && parentVM.selfPlayer!.id.isNotEmpty) {
      allPlayerIds.add(parentVM.selfPlayer!.id);
    }
    for (final kid in parentVM.allKids) {
      if (kid.id.isNotEmpty) {
        allPlayerIds.add(kid.id);
      }
    }

    return Column(
      children: [
        _buildMonthSelector(openCourtVM, allPlayerIds),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await openCourtVM.loadMyClasses(allPlayerIds);
            },
            child: _buildMyClassesList(openCourtVM),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector(
    OpenCourtViewModel openCourtVM,
    List<String> playerIds,
  ) {
    final month = openCourtVM.selectedMonth;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              openCourtVM.setSelectedMonth(
                DateTime(month.year, month.month - 1),
              );
              openCourtVM.loadMyClasses(playerIds);
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(month),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              openCourtVM.setSelectedMonth(
                DateTime(month.year, month.month + 1),
              );
              openCourtVM.loadMyClasses(playerIds);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMyClassesList(OpenCourtViewModel openCourtVM) {
    final trainings = openCourtVM.myTrainings;

    if (trainings.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.class_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No classes found',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.paddingOf(context).bottom + 100,
      ),
      itemCount: trainings.length,
      itemBuilder: (context, index) {
        return _buildTrainingCard(trainings[index]);
      },
    );
  }

  Widget _buildEnrolledSessionCard(OpenCourtModel session) {
    Color statusColor;
    switch (session.status) {
      case 'booked':
        statusColor = Colors.orange;
      case 'reserved_for_booking':
        statusColor = Colors.purple;
      case 'closed':
        statusColor = Colors.red;
      default:
        statusColor = Colors.green;
    }

    String statusText = session.statusDisplayName;
    if (session.status == 'reserved_for_booking' &&
        session.reservedByParentName != null) {
      statusText = 'Reserved by ${session.reservedByParentName}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          child: const Icon(Icons.sports_tennis, color: AppTheme.primaryColor),
        ),
        title: Text(
          session.venue,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('EEE, MMM d, yyyy').format(session.date)),
            Text('${session.startTime} - ${session.computedEndTime}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
        onTap: () =>
            context.router.push(OpenCourtDetailRoute(sessionId: session.id)),
      ),
    );
  }

  Widget _buildTrainingCard(TrainingModel training) {
    final status = training.getEffectiveStatus();
    Color statusColor = status == 'upcoming' ? Colors.blue : Colors.grey;

    return InkWell(
      onTap: () =>
          context.router.push(ClassDetailRoute(trainingId: training.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            backgroundColor: Colors.orange.withValues(alpha: 0.15),
            child: const Icon(Icons.fitness_center, color: Colors.orange),
          ),
          title: Text(
            training.className,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('EEE, MMM d, yyyy').format(training.date)),
              Text('${training.startTime} - ${training.computedEndTime}'),
              Text('${training.venue} - ${training.classType}'),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status == 'upcoming' ? 'Upcoming' : 'Completed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(OpenCourtViewModel openCourtVM) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_tennis, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No Courts Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for available court sessions',
                style: TextStyle(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(
    OpenCourtModel session,
    AuthViewModel authVM,
    OpenCourtViewModel openCourtVM,
    ParentViewModel parentVM,
  ) {
    final isOpenForBooking =
        session.status == OpenCourtModel.statusOpenForBooking;
    final isReservedForBooking =
        session.status == OpenCourtModel.statusReservedForBooking;
    final isOpenForRegistration =
        session.status == OpenCourtModel.statusOpenForRegistration;
    final isClosed = session.status == OpenCourtModel.statusClosed;

    Color statusColor = isOpenForBooking
        ? Colors.blue
        : (isReservedForBooking
              ? Colors.purple
              : (isOpenForRegistration
                    ? Colors.green
                    : (isClosed ? Colors.red : Colors.grey)));

    String statusText = session.statusDisplayName;
    if (isReservedForBooking && session.reservedByParentName != null) {
      statusText = 'Reserved by ${session.reservedByParentName}';
    }

    return InkWell(
      onTap: () =>
          context.router.push(OpenCourtDetailRoute(sessionId: session.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.sports_tennis,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.venue,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEE, MMM d, yyyy').format(session.date),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${session.startTime} - ${session.computedEndTime}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    isOpenForRegistration
                        ? '${session.filledSlots}/${session.maxPlayers} players'
                        : 'Max ${session.maxPlayers} players',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      session.classTypeDisplayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      session.levelDisplayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // AVAILABILITY TAB (Weekly Timetable)
  // ==========================================================================

  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _dayFullNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  List<AvailabilityModel> _applyFilter(List<AvailabilityModel> slots) {
    switch (_currentFilter) {
      case AvailabilityFilter.all:
        return slots;
      case AvailabilityFilter.active:
        return slots;
      case AvailabilityFilter.weekdays:
        return slots
            .where(
              (s) =>
                  s.dayOfWeek == 'Monday' ||
                  s.dayOfWeek == 'Tuesday' ||
                  s.dayOfWeek == 'Wednesday' ||
                  s.dayOfWeek == 'Thursday' ||
                  s.dayOfWeek == 'Friday',
            )
            .toList();
      case AvailabilityFilter.weekends:
        return slots
            .where((s) => s.dayOfWeek == 'Saturday' || s.dayOfWeek == 'Sunday')
            .toList();
      case AvailabilityFilter.monday:
        return slots.where((s) => s.dayOfWeek == 'Monday').toList();
      case AvailabilityFilter.tuesday:
        return slots.where((s) => s.dayOfWeek == 'Tuesday').toList();
      case AvailabilityFilter.wednesday:
        return slots.where((s) => s.dayOfWeek == 'Wednesday').toList();
      case AvailabilityFilter.thursday:
        return slots.where((s) => s.dayOfWeek == 'Thursday').toList();
      case AvailabilityFilter.friday:
        return slots.where((s) => s.dayOfWeek == 'Friday').toList();
      case AvailabilityFilter.saturday:
        return slots.where((s) => s.dayOfWeek == 'Saturday').toList();
      case AvailabilityFilter.sunday:
        return slots.where((s) => s.dayOfWeek == 'Sunday').toList();
    }
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', AvailabilityFilter.all),
            const SizedBox(width: 6),
            _buildFilterChip('Active', AvailabilityFilter.active),
            const SizedBox(width: 6),
            _buildFilterChip('Weekdays', AvailabilityFilter.weekdays),
            const SizedBox(width: 6),
            _buildFilterChip('Weekends', AvailabilityFilter.weekends),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, AvailabilityFilter filter) {
    final isSelected = _currentFilter == filter;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : AppTheme.primaryColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilter = selected ? filter : AvailabilityFilter.all;
        });
      },
      selectedColor: AppTheme.primaryColor,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      checkmarkColor: Colors.white,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  List<int> _getFilteredDayIndices(List<AvailabilityModel> slots) {
    switch (_currentFilter) {
      case AvailabilityFilter.all:
        return [0, 1, 2, 3, 4, 5, 6];
      case AvailabilityFilter.active:
        final activeDays = <int>{};
        final dayToIndex = {
          'Monday': 0,
          'Tuesday': 1,
          'Wednesday': 2,
          'Thursday': 3,
          'Friday': 4,
          'Saturday': 5,
          'Sunday': 6,
        };
        for (final slot in slots) {
          final index = dayToIndex[slot.dayOfWeek];
          if (index != null) activeDays.add(index);
        }
        return activeDays.toList()..sort();
      case AvailabilityFilter.weekdays:
        return [0, 1, 2, 3, 4];
      case AvailabilityFilter.weekends:
        return [5, 6];
      case AvailabilityFilter.monday:
        return [0];
      case AvailabilityFilter.tuesday:
        return [1];
      case AvailabilityFilter.wednesday:
        return [2];
      case AvailabilityFilter.thursday:
        return [3];
      case AvailabilityFilter.friday:
        return [4];
      case AvailabilityFilter.saturday:
        return [5];
      case AvailabilityFilter.sunday:
        return [6];
    }
  }

  String _getFilterLabel() {
    switch (_currentFilter) {
      case AvailabilityFilter.all:
        return 'all';
      case AvailabilityFilter.active:
        return 'active';
      case AvailabilityFilter.weekdays:
        return 'weekdays';
      case AvailabilityFilter.weekends:
        return 'weekends';
      case AvailabilityFilter.monday:
        return 'Monday';
      case AvailabilityFilter.tuesday:
        return 'Tuesday';
      case AvailabilityFilter.wednesday:
        return 'Wednesday';
      case AvailabilityFilter.thursday:
        return 'Thursday';
      case AvailabilityFilter.friday:
        return 'Friday';
      case AvailabilityFilter.saturday:
        return 'Saturday';
      case AvailabilityFilter.sunday:
        return 'Sunday';
    }
  }

  Widget _buildAvailabilityTab(AuthViewModel authVM) {
    final availabilityVM = context.watch<AvailabilityViewModel>();
    final userId = authVM.currentUser?.uid ?? '';

    if (availabilityVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show Firestore error if one exists
    if (availabilityVM.error != null) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Failed to load sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  availabilityVM.error!,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => availabilityVM.loadSlots(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    var slots = availabilityVM.slots;

    // Apply filter
    slots = _applyFilter(slots);

    if (slots.isEmpty) {
      return Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentFilter == AvailabilityFilter.all
                            ? 'No Availability Slots'
                            : 'No sessions for ${_getFilterLabel()}, Try a different filter or view all',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Group slots by day
    final Map<String, List<AvailabilityModel>> slotsByDay = {};
    for (final day in _dayFullNames) {
      slotsByDay[day] = [];
    }
    for (final slot in slots) {
      slotsByDay[slot.dayOfWeek]?.add(slot);
    }

    return RefreshIndicator(
      onRefresh: () => availabilityVM.loadSlots(),
      child: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          // Today indicator
          _buildTodayIndicator(),
          // Timetable
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 100,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _getFilteredDayIndices(slots).map((dayIndex) {
                    final dayName = _dayFullNames[dayIndex];
                    final daySlots = slotsByDay[dayName] ?? [];
                    return _buildDayColumn(
                      _dayLabels[dayIndex],
                      dayName,
                      daySlots,
                      userId,
                      availabilityVM,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayIndicator() {
    final todayIndex = DateTime.now().weekday - 1; // 0=Mon, 6=Sun
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Icon(Icons.today, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            'Today: ${_dayFullNames[todayIndex]}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayColumn(
    String dayLabel,
    String dayFullName,
    List<AvailabilityModel> slots,
    String userId,
    AvailabilityViewModel availabilityVM,
  ) {
    final isToday = dayFullName == _dayFullNames[DateTime.now().weekday - 1];

    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isToday
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                dayLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isToday ? Colors.white : AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          // Slots for this day
          Container(
            constraints: const BoxConstraints(minHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: slots.isEmpty
                ? SizedBox(
                    height: 180,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 32,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No sessions',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: slots
                        .map(
                          (slot) => _buildTimetableSlotCard(
                            slot,
                            userId,
                            availabilityVM,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableSlotCard(
    AvailabilityModel slot,
    String userId,
    AvailabilityViewModel availabilityVM,
  ) {
    final parentVM = context.watch<ParentViewModel>();
    final allPlayers = <PlayerModel>[];
    if (parentVM.selfPlayer != null && parentVM.selfPlayer!.id.isNotEmpty) {
      allPlayers.add(parentVM.selfPlayer!);
    }
    for (final kid in parentVM.allKids) {
      if (kid.id.isNotEmpty) {
        allPlayers.add(kid);
      }
    }
    final playerMap = {for (var p in allPlayers) p.id: p};

    return InkWell(
      onTap: () => _showSlotDetail(slot, userId, availabilityVM),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              slot.title.isNotEmpty ? slot.title : slot.dayOfWeek,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Time
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    slot.timeDisplay,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            // Venue
            if (slot.venue.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      slot.venue,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            // Response badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 10, color: Colors.green),
                      const SizedBox(width: 2),
                      Text(
                        '${slot.availableCount}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.close, size: 10, color: Colors.red),
                      const SizedBox(width: 2),
                      Text(
                        '${slot.unavailableCount}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Player responses - show avatars of players who responded
            if (slot.totalResponses > 0)
              Row(
                children: [
                  ...slot.responses.entries.take(5).map((entry) {
                    final player = playerMap[entry.key];
                    final isAvail = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child:
                          player?.imageUrl != null &&
                              player!.imageUrl!.isNotEmpty
                          ? CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(player.imageUrl!),
                            )
                          : CircleAvatar(
                              radius: 12,
                              backgroundColor: isAvail
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              child: Icon(
                                Icons.person,
                                size: 14,
                                color: isAvail ? Colors.green : Colors.red,
                              ),
                            ),
                    );
                  }),
                  if (slot.totalResponses > 5)
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        '+${slot.totalResponses - 5}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              )
            else
              Row(
                children: [
                  Icon(Icons.touch_app, size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to respond',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showSlotDetail(
    AvailabilityModel slot,
    String userId,
    AvailabilityViewModel availabilityVM,
  ) {
    final parentVM = context.read<ParentViewModel>();
    final players = <PlayerModel>[];
    if (parentVM.selfPlayer != null && parentVM.selfPlayer!.id.isNotEmpty) {
      players.add(parentVM.selfPlayer!);
    }
    for (final kid in parentVM.allKids) {
      if (kid.id.isNotEmpty) {
        players.add(kid);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<AvailabilityViewModel>(
        builder: (context, vm, _) {
          final latestSlot = vm.slots.firstWhere(
            (s) => s.id == slot.id,
            orElse: () => slot,
          );
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    slot.title.isNotEmpty ? slot.title : slot.dayOfWeek,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        slot.timeDisplay,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  if (slot.venue.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          slot.venue,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Response summary
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${latestSlot.availableCount}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Text(
                                'Available',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${latestSlot.unavailableCount}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const Text(
                                'Unavailable',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // View respondents button
                  if (latestSlot.totalResponses > 0) ...[
                    OutlinedButton.icon(
                      onPressed: () => _showRespondentsList(
                        context,
                        latestSlot,
                        availabilityVM,
                      ),
                      icon: const Icon(Icons.people),
                      label: Text(
                        'View ${latestSlot.totalResponses} Responses',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Player selection for responses
                  Text(
                    'Select players',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (players.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No players added. Add players in Settings to mark availability.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Consumer<AvailabilityViewModel>(
                      builder: (context, vm, _) {
                        // Get the latest slot data from the viewmodel
                        final latestSlot = vm.slots.firstWhere(
                          (s) => s.id == slot.id,
                          orElse: () => slot,
                        );
                        return Container(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: players.length,
                            itemBuilder: (context, index) {
                              final player = players[index];
                              // Response is tied to player id
                              final playerResponse = latestSlot.getUserResponse(
                                player.id,
                              );
                              final isPlayerAvailable = playerResponse == true;
                              final isPlayerUnavailable =
                                  playerResponse == false;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading:
                                      player.imageUrl != null &&
                                          player.imageUrl!.isNotEmpty
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            player.imageUrl!,
                                          ),
                                        )
                                      : CircleAvatar(
                                          backgroundColor: AppTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                          child: Icon(
                                            Icons.person,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                  title: Text(player.name),
                                  subtitle: Text(player.level),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          // If already available, remove response (make neutral); otherwise mark available
                                          if (isPlayerAvailable) {
                                            availabilityVM.removeResponse(
                                              latestSlot.id,
                                              player.id,
                                            );
                                          } else {
                                            availabilityVM.respond(
                                              latestSlot.id,
                                              player.id,
                                              true,
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          Icons.check_circle,
                                          color: isPlayerAvailable
                                              ? Colors.green
                                              : Colors.grey.shade300,
                                        ),
                                        tooltip: 'Available',
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          // If already unavailable, remove response (make neutral); otherwise mark unavailable
                                          if (isPlayerUnavailable) {
                                            availabilityVM.removeResponse(
                                              latestSlot.id,
                                              player.id,
                                            );
                                          } else {
                                            availabilityVM.respond(
                                              latestSlot.id,
                                              player.id,
                                              false,
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          Icons.cancel,
                                          color: isPlayerUnavailable
                                              ? Colors.red
                                              : Colors.grey.shade300,
                                        ),
                                        tooltip: "Can't make it",
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRespondentsList(
    BuildContext context,
    AvailabilityModel slot,
    AvailabilityViewModel availabilityVM,
  ) {
    final parentVM = context.read<ParentViewModel>();
    final allPlayers = <PlayerModel>[];
    if (parentVM.selfPlayer != null && parentVM.selfPlayer!.id.isNotEmpty) {
      allPlayers.add(parentVM.selfPlayer!);
    }
    for (final kid in parentVM.allKids) {
      if (kid.id.isNotEmpty) {
        allPlayers.add(kid);
      }
    }

    final playerMap = {for (var p in allPlayers) p.id: p};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer<AvailabilityViewModel>(
        builder: (ctx, vm, _) {
          final latestSlot = vm.slots.firstWhere(
            (s) => s.id == slot.id,
            orElse: () => slot,
          );
          final availablePlayerIds = latestSlot.responses.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList();
          final unavailablePlayerIds = latestSlot.responses.entries
              .where((e) => !e.value)
              .map((e) => e.key)
              .toList();

          String getPlayerName(String playerId) {
            final player = playerMap[playerId];
            return player?.name ?? playerId;
          }

          final availableNames = availablePlayerIds.map(getPlayerName).toList();
          final unavailableNames = unavailablePlayerIds
              .map(getPlayerName)
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (ctx, scrollController) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Responses',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    latestSlot.title.isNotEmpty
                        ? latestSlot.title
                        : latestSlot.dayOfWeek,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        if (availableNames.isNotEmpty) ...[
                          _buildRespondentSection(
                            'Available',
                            availableNames.length,
                            Colors.green,
                            availablePlayerIds,
                            playerMap,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (unavailableNames.isNotEmpty)
                          _buildRespondentSection(
                            'Unavailable',
                            unavailableNames.length,
                            Colors.red,
                            unavailablePlayerIds,
                            playerMap,
                          ),
                        if (latestSlot.totalResponses == 0)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 48,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No responses yet',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRespondentSection(
    String title,
    int count,
    Color color,
    List<String> playerIds,
    Map<String, PlayerModel> playerMap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
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
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (playerIds.isEmpty)
          Text(
            'No users',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: playerIds.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final playerId = playerIds[index];
                final player = playerMap[playerId];
                final name = player?.name ?? playerId;
                final imageUrl = player?.imageUrl;
                return ListTile(
                  leading: imageUrl != null && imageUrl.isNotEmpty
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(imageUrl),
                        )
                      : CircleAvatar(
                          radius: 16,
                          backgroundColor: color.withValues(alpha: 0.2),
                          child: Icon(Icons.person, size: 18, color: color),
                        ),
                  title: Text(name, style: const TextStyle(fontSize: 14)),
                  dense: true,
                );
              },
            ),
          ),
      ],
    );
  }

  Future<Map<String, UserModel>> _fetchUsers(List<String> userIds) async {
    final db = DatabaseService();
    final users = <String, UserModel>{};
    for (final id in userIds) {
      final user = await db.getUser(id);
      if (user != null) users[id] = user;
    }
    return users;
  }
}
