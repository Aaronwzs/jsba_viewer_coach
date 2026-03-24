import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/model/open_court_model.dart';
import 'package:jsba_app/app/viewmodel/open_court_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';

@RoutePage()
class OpenCourtDetailPage extends StatefulWidget {
  final String sessionId;

  const OpenCourtDetailPage({super.key, required this.sessionId});

  @override
  State<OpenCourtDetailPage> createState() => _OpenCourtDetailPageState();
}

class _OpenCourtDetailPageState extends State<OpenCourtDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OpenCourtViewModel>().loadSession(widget.sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final openCourtVM = context.watch<OpenCourtViewModel>();
    final parentVM = context.watch<ParentViewModel>();
    final user = authVM.currentUser;

    return Scaffold(
      appBar: const AppBarTitle(title: 'Court Details', blackBackButton: true),
      body: openCourtVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : openCourtVM.currentSession == null
          ? const Center(child: Text('Session not found'))
          : _buildContent(
              context,
              openCourtVM.currentSession!,
              authVM,
              openCourtVM,
              parentVM,
              user?.uid ?? '',
            ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OpenCourtModel session,
    AuthViewModel authVM,
    OpenCourtViewModel openCourtVM,
    ParentViewModel parentVM,
    String userId,
  ) {
    final isReservedForBooking =
        session.status == OpenCourtModel.statusReservedForBooking;
    final isOpenForRegistration =
        session.status == OpenCourtModel.statusOpenForRegistration;
    final isBooked = session.status == OpenCourtModel.statusBooked;

    final isUserReserved = session.reservedByUserId == userId;
    final isUserBooked = session.bookedByUserId == userId;
    final selfPlayer = parentVM.selfPlayer;
    final kids = parentVM.myKids;

    final allPlayerIds = <String>[];
    if (selfPlayer != null && selfPlayer.id.isNotEmpty) {
      allPlayerIds.add(selfPlayer.id);
    }
    for (final kid in kids) {
      if (kid.id.isNotEmpty) {
        allPlayerIds.add(kid.id);
      }
    }

    final isUserRegistered = allPlayerIds.any(
      (playerId) => session.isPlayerRegistered(playerId),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(session),
          const SizedBox(height: 16),
          _buildDetailsCard(session),
          const SizedBox(height: 16),
          if (isBooked) _buildBookingInfoCard(session),
          if (isReservedForBooking)
            _buildReservationInfoCard(session, isUserReserved),
          const SizedBox(height: 16),
          if (isOpenForRegistration ||
              session.status == OpenCourtModel.statusClosed)
            _buildParticipantsCard(session, openCourtVM),
          const SizedBox(height: 16),
          _buildActionSection(
            context,
            session,
            authVM,
            openCourtVM,
            parentVM,
            isUserReserved,
            isUserBooked,
            isUserRegistered,
            userId,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(OpenCourtModel session) {
    String statusText;

    switch (session.status) {
      case 'draft':
        statusText = 'Draft';
      case 'open_for_booking':
        statusText = 'Open for Booking';
      case 'reserved_for_booking':
        statusText = 'Reserved for Booking';
      case 'booked':
        statusText = 'Booked';
      case 'open_for_registration':
        statusText = 'Open for Registration';
      case 'closed':
        statusText = 'Closed';
      default:
        statusText = session.status;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_tennis, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.venue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(OpenCourtModel session) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          _buildDetailRow(
            Icons.calendar_today,
            'Date',
            DateFormat('EEEE, MMM d, yyyy').format(session.date),
          ),
          _buildDetailRow(
            Icons.access_time,
            'Time',
            '${session.startTime} - ${session.computedEndTime}',
          ),
          _buildDetailRow(
            Icons.timer,
            'Duration',
            '${session.durationMinutes ~/ 60}h ${session.durationMinutes % 60 == 0 ? '' : '${session.durationMinutes % 60}m'}',
          ),
          _buildDetailRow(
            Icons.group,
            'Class Type',
            session.classTypeDisplayName,
          ),
          _buildDetailRow(Icons.trending_up, 'Level', session.levelDisplayName),
          _buildDetailRow(
            Icons.people,
            'Capacity',
            '${session.filledSlots}/${session.maxPlayers} players',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBookingInfoCard(OpenCourtModel session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text(
                'Booked By',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Parent Name', session.bookedByParentName ?? 'Unknown'),
        ],
      ),
    );
  }

  Widget _buildParticipantsCard(
    OpenCourtModel session,
    OpenCourtViewModel openCourtVM,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Registered Players',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Text(
                '${session.filledSlots}/${session.maxPlayers}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (session.playerIds.isEmpty)
            const Text('No players registered yet')
          else
            ...session.playerIds.asMap().entries.map((entry) {
              final playerName =
                  openCourtVM.playerNames[entry.value] ??
                  'Player ${entry.key + 1}';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(
                    alpha: 0.15,
                  ),
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
                title: Text(playerName),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildReservationInfoCard(
    OpenCourtModel session,
    bool isUserReserved,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUserReserved ? Colors.purple.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUserReserved
              ? Colors.purple.shade200
              : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer,
                color: isUserReserved
                    ? Colors.purple.shade700
                    : Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                isUserReserved
                    ? 'You Reserved to Book'
                    : 'Reserved for Booking',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isUserReserved) ...[
            Text(
              '${session.reservedByParentName ?? 'Someone'} is booking this court.',
              style: TextStyle(color: Colors.orange.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait for them to confirm or cancel.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ] else ...[
            Text(
              'Please book the court in the booking app and confirm here once done.',
              style: TextStyle(color: Colors.purple.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    OpenCourtModel session,
    AuthViewModel authVM,
    OpenCourtViewModel openCourtVM,
    ParentViewModel parentVM,
    bool isUserReserved,
    bool isUserBooked,
    bool isUserRegistered,
    String userId,
  ) {
    final isOpenForBooking =
        session.status == OpenCourtModel.statusOpenForBooking;
    final isReservedForBooking =
        session.status == OpenCourtModel.statusReservedForBooking;
    final isBooked = session.status == OpenCourtModel.statusBooked;
    final isOpenForRegistration =
        session.status == OpenCourtModel.statusOpenForRegistration;

    if (isOpenForBooking) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () =>
              _showReserveDialog(context, session, authVM, openCourtVM),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.volunteer_activism),
          label: const Text('Reserve to Book'),
        ),
      );
    }

    if (isReservedForBooking) {
      if (isUserReserved) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.timer, color: Colors.purple),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have reserved this court',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Please book in the booking app, then confirm below.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showConfirmBookingDialog(
                    context,
                    session,
                    authVM,
                    openCourtVM,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Booked'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCancelReservationDialog(
                    context,
                    session,
                    openCourtVM,
                  ),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Cancel Reservation'),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${session.reservedByParentName ?? "Someone"} is booking this court',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait for them to confirm or cancel their reservation.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (isBooked) {
      if (isUserBooked) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have booked this court',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Waiting for admin to open registration for other parents.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showUndoBookingDialog(context, session, openCourtVM),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.undo),
                  label: const Text('Undo Booking'),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${session.bookedByParentName ?? "Someone"} has booked this court',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Waiting for admin to open registration.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (isOpenForRegistration) {
      if (isUserRegistered) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'You are registered for this session',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showWithdrawDialog(
                    context,
                    session,
                    authVM,
                    openCourtVM,
                    false,
                  ),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Withdraw'),
                ),
              ),
            ],
          ),
        );
      }

      if (session.isFull) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Session is Full',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showRegistrationDialog(
            context,
            session,
            authVM,
            openCourtVM,
            parentVM,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.person_add),
          label: const Text('Register Player'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showRegistrationDialog(
    BuildContext context,
    OpenCourtModel session,
    AuthViewModel authVM,
    OpenCourtViewModel openCourtVM,
    ParentViewModel parentVM,
  ) {
    final user = authVM.currentUser;
    if (user == null) return;

    final kids = parentVM.myKids;
    String? selectedPlayerId;
    bool registerForSelf = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Register Player'),
                const SizedBox(height: 16),
                RadioListTile<String>(
                  title: Text('${user.name} (You)'),
                  value: 'self',
                  groupValue: registerForSelf ? 'self' : selectedPlayerId,
                  onChanged: (value) {
                    setModalState(() {
                      registerForSelf = true;
                      selectedPlayerId = null;
                    });
                  },
                ),
                ...kids.map(
                  (kid) => RadioListTile<String>(
                    title: Text(kid.name),
                    value: kid.id,
                    groupValue: registerForSelf ? 'self' : selectedPlayerId,
                    onChanged: (value) {
                      setModalState(() {
                        registerForSelf = false;
                        selectedPlayerId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      String? playerId;

                      if (registerForSelf) {
                        playerId = parentVM.selfPlayer?.id;
                      } else if (selectedPlayerId != null) {
                        playerId = selectedPlayerId;
                      }

                      if (playerId == null || playerId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a player'),
                          ),
                        );
                        return;
                      }

                      Navigator.of(ctx).pop();

                      final success = await openCourtVM.registerPlayer(
                        sessionId: session.id,
                        playerId: playerId,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Player registered successfully!'
                                  : (openCourtVM.errorMessage ??
                                        'Failed to register'),
                            ),
                            backgroundColor: success
                                ? Colors.green
                                : Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Register'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showWithdrawDialog(
    BuildContext context,
    OpenCourtModel session,
    AuthViewModel authVM,
    OpenCourtViewModel openCourtVM,
    bool isBooking,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw'),
        content: Text(
          isBooking
              ? 'Are you sure you want to withdraw your booking? Once you withdraw, other parents can book this court.'
              : 'Are you sure you want to withdraw? Once you withdraw, other users can register for this session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              if (isBooking) {
                await openCourtVM.updateStatus(
                  session.id,
                  OpenCourtModel.statusOpenForBooking,
                );
                await openCourtVM.loadSession(session.id);
              } else {
                final user = authVM.currentUser;
                if (user != null) {
                  final selfPlayer = context.read<ParentViewModel>().selfPlayer;
                  final kids = context.read<ParentViewModel>().myKids;

                  String? playerIdToRemove;
                  if (selfPlayer != null &&
                      session.isPlayerRegistered(selfPlayer.id)) {
                    playerIdToRemove = selfPlayer.id;
                  } else {
                    for (final kid in kids) {
                      if (session.isPlayerRegistered(kid.id)) {
                        playerIdToRemove = kid.id;
                        break;
                      }
                    }
                  }

                  if (playerIdToRemove != null) {
                    await openCourtVM.removePlayer(
                      session.id,
                      playerIdToRemove,
                    );
                  }
                }
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Withdrawn successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showReserveDialog(
    BuildContext context,
    OpenCourtModel session,
    AuthViewModel authVM,
    OpenCourtViewModel openCourtVM,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reserve to Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'By reserving, you commit to booking this court in the booking app.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Other parents will see that you are booking this court.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Venue', session.venue),
            _buildInfoRow(
              'Date',
              DateFormat('EEE, MMM d, yyyy').format(session.date),
            ),
            _buildInfoRow(
              'Time',
              '${session.startTime} - ${session.computedEndTime}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final user = authVM.currentUser;
              if (user == null) return;

              final success = await openCourtVM.reserveCourt(
                sessionId: session.id,
                parentName: user.name,
                userId: user.uid,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Court reserved! Please book in the booking app.'
                          : 'Failed to reserve court',
                    ),
                    backgroundColor: success ? Colors.purple : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reserve'),
          ),
        ],
      ),
    );
  }

  void _showConfirmBookingDialog(
    BuildContext context,
    OpenCourtModel session,
    AuthViewModel authVM,
    OpenCourtViewModel openCourtVM,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Have you successfully booked this court in the booking app?'),
            SizedBox(height: 12),
            Text(
              'After confirmation, an admin will review and open the court for registration by other parents.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final user = authVM.currentUser;
              if (user == null) return;

              final success = await openCourtVM.confirmBooking(
                sessionId: session.id,
                parentName: user.name,
                userId: user.uid,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Booking confirmed! Waiting for admin to open registration.'
                          : 'Failed to confirm booking',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Booked'),
          ),
        ],
      ),
    );
  }

  void _showCancelReservationDialog(
    BuildContext context,
    OpenCourtModel session,
    OpenCourtViewModel openCourtVM,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text(
          'Are you sure you want to cancel your reservation? This will allow other parents to book this court.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              final success = await openCourtVM.cancelReservation(session.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Reservation cancelled'
                          : 'Failed to cancel reservation',
                    ),
                    backgroundColor: success ? Colors.orange : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showUndoBookingDialog(
    BuildContext context,
    OpenCourtModel session,
    OpenCourtViewModel openCourtVM,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Undo Booking'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to undo your booking?'),
            SizedBox(height: 8),
            Text(
              'This will allow other parents to book this court.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              final success = await openCourtVM.undoBooking(session.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Booking undone. You can now reserve again.'
                          : 'Failed to undo booking',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Undo'),
          ),
        ],
      ),
    );
  }
}
