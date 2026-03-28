import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/model/attendance_model.dart';
import 'package:jsba_app/app/service/training_service.dart';
import 'package:jsba_app/app/service/attendance_service.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';

@RoutePage()
class ClassDetailPage extends StatefulWidget {
  final String trainingId;

  const ClassDetailPage({super.key, required this.trainingId});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  final TrainingService _trainingService = TrainingService();
  final AttendanceService _attendanceService = AttendanceService();
  final PlayerService _playerService = PlayerService();

  TrainingModel? _training;
  List<AttendanceModel> _attendances = [];
  Map<String, String> _playerNames = {};
  Map<String, String> _playerImages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final training = await _trainingService.getTrainingById(widget.trainingId);
    if (training == null) {
      setState(() => _isLoading = false);
      return;
    }

    final attendances = await _attendanceService.getAttendanceForTraining(
      widget.trainingId,
    );

    final playerIds = attendances.map((a) => a.playerId).toList();
    final playerNames = await _playerService.getPlayerNames(playerIds);
    final playerImages = await _playerService.getPlayerImages(playerIds);

    if (mounted) {
      setState(() {
        _training = training;
        _attendances = attendances;
        _playerNames = playerNames;
        _playerImages = playerImages;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarTitle(title: 'Class Details', blackBackButton: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _training == null
          ? const Center(child: Text('Class not found'))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClassHeader(),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 24),
            _buildAttendanceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassHeader() {
    final status = _training!.getEffectiveStatus();

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
          const Icon(Icons.fitness_center, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _training!.className,
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
                    status[0].toUpperCase() + status.substring(1),
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

  Widget _buildDetailsCard() {
    final training = _training!;
    final duration = training.durationMinutes;
    final durationText = duration >= 60
        ? '${duration ~/ 60}h${duration % 60 > 0 ? ' ${duration % 60}m' : ''}'
        : '${duration}m';

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
          const Text(
            'Class Information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.calendar_today,
            'Date',
            DateFormat('EEEE, MMM d, yyyy').format(training.date),
          ),
          _buildDetailRow(
            Icons.access_time,
            'Time',
            '${training.startTime} - ${training.computedEndTime}',
          ),
          _buildDetailRow(Icons.timer, 'Duration', durationText),
          _buildDetailRow(Icons.location_on, 'Venue', training.venue),
          _buildDetailRow(
            Icons.group,
            'Class Type',
            training.classType[0].toUpperCase() +
                training.classType.substring(1),
          ),
          _buildDetailRow(Icons.trending_up, 'Level', training.level),
          _buildDetailRow(
            Icons.attach_money,
            'Price',
            'RM ${training.price.toStringAsFixed(2)}',
          ),
          _buildDetailRow(
            Icons.people,
            'Max Players',
            '${training.getEffectiveMaxPlayers()}',
          ),
          if (training.coachId != null && training.coachId!.isNotEmpty)
            _buildDetailRow(Icons.person, 'Coach', training.coachId!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
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
                'Attendance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (_attendances.isNotEmpty)
                Text(
                  '${_attendances.where((a) => a.attendanceStatus == 'present').length}/${_attendances.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_attendances.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No attendance records yet',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ..._attendances.map(_buildAttendanceCard),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    final playerName = _playerNames[attendance.playerId] ?? 'Unknown Player';
    final playerImage = _playerImages[attendance.playerId];
    final statusColor = _getStatusColor(attendance.attendanceStatus);
    final statusText =
        attendance.attendanceStatus[0].toUpperCase() +
        attendance.attendanceStatus.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: statusColor.withValues(alpha: 0.15),
                backgroundImage: playerImage != null && playerImage.isNotEmpty
                    ? CachedNetworkImageProvider(playerImage)
                    : null,
                child: (playerImage == null || playerImage.isEmpty)
                    ? Icon(Icons.person, size: 18, color: statusColor)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  playerName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
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
            ],
          ),
          if (attendance.coachComments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.comment, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    attendance.coachComments,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ],
          if (attendance.reasonCharge.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.attach_money, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'Charge: ${attendance.reasonCharge}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
