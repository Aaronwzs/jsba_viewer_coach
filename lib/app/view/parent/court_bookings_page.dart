import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/model/open_court_model.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/viewmodel/open_court_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';

@RoutePage()
class CourtBookingsPage extends StatefulWidget {
  const CourtBookingsPage({super.key});

  @override
  State<CourtBookingsPage> createState() => _CourtBookingsPageState();
}

class _CourtBookingsPageState extends State<CourtBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasLoadedMyClasses = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            Tab(text: 'Available'),
            Tab(text: 'My Classes'),
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

    return RefreshIndicator(
      onRefresh: () async {
        await openCourtVM.loadAvailableSessions();
        if (authVM.currentUser != null) {
          await parentVM.loadMyKids(authVM.currentUser!.uid);
        }
      },
      child: allSessions.isEmpty
          ? _buildEmptyState(openCourtVM)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allSessions.length,
              itemBuilder: (context, index) {
                final session = allSessions[index];
                return _buildSessionCard(
                  session,
                  authVM,
                  openCourtVM,
                  parentVM,
                );
              },
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
                Icon(Icons.class_outlined, size: 64, color: Colors.grey.shade400),
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
      padding: const EdgeInsets.all(16),
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
    final hasAnySessions = openCourtVM.sessions.isNotEmpty;
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
              if (hasAnySessions) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Debug: Existing sessions in DB:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ...openCourtVM.sessions.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${s.venue} - ${s.date.toString().substring(0, 10)} - Status: ${s.status}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
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
}
