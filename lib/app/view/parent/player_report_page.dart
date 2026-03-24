import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';

@RoutePage()
class PlayerReportPage extends StatefulWidget {
  final String playerId;

  const PlayerReportPage({super.key, required this.playerId});

  @override
  State<PlayerReportPage> createState() => _PlayerReportPageState();
}

class _PlayerReportPageState extends State<PlayerReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      if (authVM.currentUser != null) {
        context.read<ParentViewModel>().loadMyKids(authVM.currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final parentVM = context.watch<ParentViewModel>();

    final allPlayers = [
      if (parentVM.selfPlayer != null) parentVM.selfPlayer!,
      ...parentVM.allKids,
    ];

    final player = allPlayers.where((p) => p.id == widget.playerId).firstOrNull;

    if (parentVM.isLoading) {
      return Scaffold(
        appBar: const AppBarTitle(
          title: 'Player Report',
          blackBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (player == null) {
      return Scaffold(
        appBar: const AppBarTitle(
          title: 'Player Report',
          blackBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Player not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.router.back(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final isSelf = player.isSelf;

    return Scaffold(
      appBar: AppBarTitle(
        title: isSelf ? 'My Report' : '${player.name} Report',
        blackBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlayerHeader(player, isSelf),
            const SizedBox(height: 24),
            _buildPlayerInfoSection(player),
            const SizedBox(height: 24),
            _buildPlayerReportSection(),
            const SizedBox(height: 24),
            _buildPlayerProgressSection(),
            const SizedBox(height: 24),
            if (!isSelf && player.status == PlayerStatus.pending)
              _buildPendingNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader(PlayerModel player, bool isSelf) {
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
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(
              isSelf ? Icons.person : Icons.child_care,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSelf ? 'My Profile' : 'My Kid',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfoSection(PlayerModel player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Player Info',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
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
              children: [
                _buildDetailRow(Icons.person, 'Name', player.name),
                _buildDetailRow(Icons.cake, 'Age', '${player.age} years old'),
                _buildDetailRow(Icons.trending_up, 'Level', player.level),
                _buildDetailRow(
                  Icons.phone,
                  'Phone',
                  player.phone.isNotEmpty ? player.phone : 'Not provided',
                ),
                if (player.parentName != null)
                  _buildDetailRow(
                    Icons.supervisor_account,
                    'Guardian',
                    player.parentName!,
                  ),
                if (player.parentPhone != null && player.parentPhone!.isNotEmpty)
                  _buildDetailRow(
                    Icons.phone_android,
                    'Guardian Phone',
                    player.parentPhone!,
                  ),
                if (player.parentEmail != null && player.parentEmail!.isNotEmpty)
                  _buildDetailRow(Icons.email, 'Guardian Email', player.parentEmail!),
                _buildDetailRow(
                  Icons.verified,
                  'Status',
                  player.status == PlayerStatus.approved ? 'Approved' : 'Pending Approval',
                  valueColor: player.status == PlayerStatus.approved ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

Widget _buildPlayerReportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Player Report',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Player reports will be available here',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Coming soon',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Player Progress',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.trending_up, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Player progress will be available here',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Coming soon',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This player is pending admin approval. Some features may be limited.',
              style: TextStyle(color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
