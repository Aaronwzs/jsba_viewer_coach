import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/service/storage_service.dart';
import 'package:jsba_app/app/utils/image_crop_helper.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

@RoutePage()
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      final parentVM = context.read<ParentViewModel>();
      if (authVM.currentUser != null && !authVM.isCoach) {
        parentVM.loadMyKids(authVM.currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isCoach = authVM.isCoach;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 100),
        children: [
          _buildProfileSection(context, authVM),
          if (!isCoach) ...[
            const SizedBox(height: 20),
            _buildPlayersSection(context),
          ],
          const SizedBox(height: 20),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  // ==========================================================================
  // PROFILE SECTION
  // ==========================================================================

  Widget _buildProfileSection(BuildContext context, AuthViewModel authVM) {
    final user = authVM.currentUser;
    final displayName = user?.name ?? 'User';
    final displayEmail = user?.email ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Profile',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Top profile card
        Container(
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayEmail,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.black),
                onPressed: () => _showProfileOptionsSheet(context, authVM),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showProfileOptionsSheet(BuildContext context, AuthViewModel authVM) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _profileOptionTile(
              icon: Icons.edit_outlined,
              title: 'Edit Name',
              subtitle: 'Change your display name',
              onTap: () {
                Navigator.pop(ctx);
                _showEditNameSheet(context, authVM);
              },
            ),
            const Divider(height: 1),
            _profileOptionTile(
              icon: Icons.email_outlined,
              title: 'Change Email',
              subtitle: 'Coming soon',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Coming Soon')));
              },
            ),
            const Divider(height: 1),
            _profileOptionTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your password',
              onTap: () {
                Navigator.pop(ctx);
                _showVerifyPasswordSheet(context, authVM);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  void _showEditNameSheet(BuildContext context, AuthViewModel authVM) {
    final controller = TextEditingController(
      text: authVM.currentUser?.name ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Edit Name',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final newName = controller.text.trim();
                    if (newName.isEmpty) return;
                    Navigator.pop(ctx);
                    final success = await authVM.updateUserName(newName);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name updated'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(authVM.error ?? 'Failed to update'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerifyPasswordSheet(BuildContext context, AuthViewModel authVM) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Change Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your current password to continue',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _verifyAndProceed(ctx, authVM, controller),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _verifyAndProceed(ctx, authVM, controller),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyAndProceed(
    BuildContext sheetCtx,
    AuthViewModel authVM,
    TextEditingController controller,
  ) async {
    final password = controller.text.trim();
    if (password.isEmpty) return;

    EasyLoading.show(status: 'Verifying...');
    final verified = await authVM.verifyCurrentPassword(password);
    EasyLoading.dismiss();

    if (!sheetCtx.mounted) return;
    Navigator.pop(sheetCtx);

    if (verified && mounted) {
      _showNewPasswordSheet(context, authVM);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVM.error ?? 'Incorrect password'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNewPasswordSheet(BuildContext context, AuthViewModel authVM) {
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Set New Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: newPwController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPwController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != newPwController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final newPw = newPwController.text;
                      Navigator.pop(ctx);
                      final success = await authVM.changePasswordOnly(newPw);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password changed'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              authVM.error ?? 'Failed to change password',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // PLAYERS SECTION
  // ==========================================================================

  Widget _buildPlayersSection(BuildContext context) {
    final parentVM = context.watch<ParentViewModel>();

    if (parentVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Players',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ),
        ..._buildPlayerCards(context, parentVM),
      ],
    );
  }

  List<Widget> _buildPlayerCards(
    BuildContext context,
    ParentViewModel parentVM,
  ) {
    final selfPlayer = parentVM.selfPlayer;
    final kids = parentVM.allKids;

    if (selfPlayer == null && kids.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(32),
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
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.sports_tennis_outlined,
                  size: 40,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 10),
                Text(
                  'No players yet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final List<Widget> cards = [];
    if (selfPlayer != null) {
      cards.add(_buildPlayerCard(selfPlayer));
      cards.add(const SizedBox(height: 12));
    }
    for (var i = 0; i < kids.length; i++) {
      cards.add(_buildPlayerCard(kids[i]));
      if (i < kids.length - 1) cards.add(const SizedBox(height: 12));
    }
    return cards;
  }

  Widget _buildPlayerCard(PlayerModel player) {
    final levelColors = {
      'Beginner': Colors.blue,
      'Intermediate': Colors.orange,
      'Advanced': Colors.green,
    };
    final levelColor = levelColors[player.level] ?? Colors.grey;
    final isPending = player.status == PlayerStatus.pending;

    return GestureDetector(
      onTap: () => _showPlayerInfoSheet(context, player),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isPending
                      ? Colors.grey[200]
                      : AppTheme.primaryColor.withValues(alpha: 0.08),
                  image: player.imageUrl != null && player.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(player.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (player.imageUrl == null || player.imageUrl!.isEmpty)
                    ? Center(
                        child: Text(
                          player.name.isNotEmpty
                              ? player.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: isPending
                                ? Colors.grey[500]
                                : AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isPending
                                  ? Colors.grey[500]
                                  : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (player.isSelf) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Me',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (isPending) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: levelColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            player.level,
                            style: TextStyle(
                              color: levelColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Age ${player.age}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // PLAYER INFO SHEET
  // ==========================================================================

  void _showPlayerInfoSheet(BuildContext context, PlayerModel player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[100],
                  image: player.imageUrl != null && player.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(player.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (player.imageUrl == null || player.imageUrl!.isEmpty)
                    ? Center(
                        child: Text(
                          player.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              Text(
                player.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (player.isSelf)
                Text(
                  'Me',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.cake_outlined, 'Age', '${player.age}'),
                    _infoRow(Icons.trending_up, 'Level', player.level),
                    _infoRow(
                      Icons.phone_outlined,
                      'Phone',
                      player.phone.isNotEmpty ? player.phone : 'Not set',
                    ),
                    if (player.parentName != null &&
                        player.parentName!.isNotEmpty)
                      _infoRow(
                        Icons.supervisor_account_outlined,
                        'Guardian',
                        player.parentName!,
                      ),
                    if (player.parentPhone != null &&
                        player.parentPhone!.isNotEmpty)
                      _infoRow(
                        Icons.phone_android_outlined,
                        'Guardian Phone',
                        player.parentPhone!,
                      ),
                    if (player.parentEmail != null &&
                        player.parentEmail!.isNotEmpty)
                      _infoRow(
                        Icons.email_outlined,
                        'Guardian Email',
                        player.parentEmail!,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showEditPlayerSheet(context, player);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Player'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // EDIT PLAYER SHEET
  // ==========================================================================

  void _showEditPlayerSheet(BuildContext context, PlayerModel player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _EditPlayerSheetContent(player: player);
      },
    );
  }

  // ==========================================================================
  // LOGOUT
  // ==========================================================================

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        final authVM = context.read<AuthViewModel>();
        await authVM.signOut();
        if (context.mounted) {
          context.router.replaceNamed('/academy-dashboard');
        }
      },
      icon: const Icon(Icons.logout, color: Colors.red),
      label: const Text('Logout', style: TextStyle(color: Colors.red)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// =============================================================================
// EDIT PLAYER SHEET CONTENT (Stateful)
// =============================================================================

class _EditPlayerSheetContent extends StatefulWidget {
  final PlayerModel player;
  const _EditPlayerSheetContent({required this.player});

  @override
  State<_EditPlayerSheetContent> createState() =>
      _EditPlayerSheetContentState();
}

class _EditPlayerSheetContentState extends State<_EditPlayerSheetContent> {
  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController phoneController;
  late TextEditingController parentNameController;
  late TextEditingController parentPhoneController;
  late TextEditingController parentEmailController;
  late String selectedLevel;
  File? selectedImage;
  final formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.player.name);
    ageController = TextEditingController(text: widget.player.age.toString());
    phoneController = TextEditingController(text: widget.player.phone);
    parentNameController = TextEditingController(
      text: widget.player.parentName ?? '',
    );
    parentPhoneController = TextEditingController(
      text: widget.player.parentPhone ?? '',
    );
    parentEmailController = TextEditingController(
      text: widget.player.parentEmail ?? '',
    );
    selectedLevel = widget.player.level;

    // Auto-fill parent info for non-self players under 20
    if (!widget.player.isSelf && widget.player.age < 20) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          final authVM = context.read<AuthViewModel>();
          final parentVM = context.read<ParentViewModel>();
          final selfPlayer = parentVM.selfPlayer;
          setState(() {
            if (parentNameController.text.isEmpty) {
              parentNameController.text =
                  selfPlayer?.name ?? authVM.currentUser?.name ?? '';
            }
            if (parentPhoneController.text.isEmpty) {
              parentPhoneController.text =
                  selfPlayer?.phone ?? authVM.currentUser?.phone ?? '';
            }
            if (parentEmailController.text.isEmpty) {
              parentEmailController.text = authVM.currentUser?.email ?? '';
            }
          });
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    parentNameController.dispose();
    parentPhoneController.dispose();
    parentEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final age = int.tryParse(ageController.text) ?? widget.player.age;
    final needsParentInfo = !widget.player.isSelf && age < 20;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit ${widget.player.isSelf ? "Me" : widget.player.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : (widget.player.imageUrl != null &&
                                    widget.player.imageUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    widget.player.imageUrl!,
                                  )
                                : null),
                      child:
                          selectedImage == null &&
                              (widget.player.imageUrl == null ||
                                  widget.player.imageUrl!.isEmpty)
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final a = int.tryParse(v);
                  if (a == null || a < 1 || a > 100) return 'Invalid age';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'Level',
                  border: OutlineInputBorder(),
                ),
                items: ['Beginner', 'Intermediate', 'Advanced']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => selectedLevel = v ?? widget.player.level),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              if (needsParentInfo) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.supervisor_account_outlined,
                            color: Colors.blue[700],
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Parent/Guardian Info',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: parentNameController,
                        decoration: const InputDecoration(
                          labelText: 'Parent Name',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: parentPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Parent Phone',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: parentEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Parent Email',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _savePlayer,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null) return;

    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 100,
    );
    if (image == null) return;

    if (!mounted) return;
    final cropped = await ImageCropHelper.cropImage(
      sourcePath: image.path,
      context: context,
    );
    if (cropped == null) return;

    setState(() => selectedImage = cropped);
  }

  Future<void> _savePlayer() async {
    if (!formKey.currentState!.validate()) return;

    final age = int.parse(ageController.text.trim());
    if (age < 20 &&
        !widget.player.isSelf &&
        parentNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Parent/guardian name is required for players under 20',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    String? imageUrl = widget.player.imageUrl;

    if (selectedImage != null) {
      final storageService = StorageService();
      final uploadedUrl = await storageService.uploadImage(selectedImage!);
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isSaving = false);
        return;
      }
    }

    final updatedPlayer = PlayerModel(
      id: widget.player.id,
      name: nameController.text.trim(),
      age: age,
      level: selectedLevel,
      phone: phoneController.text.trim(),
      createdAt: widget.player.createdAt,
      isActive: widget.player.isActive,
      parentId: widget.player.parentId,
      parentName: age < 20 && !widget.player.isSelf
          ? parentNameController.text.trim()
          : null,
      parentPhone: age < 20 && !widget.player.isSelf
          ? parentPhoneController.text.trim()
          : null,
      parentEmail: age < 20 && !widget.player.isSelf
          ? parentEmailController.text.trim()
          : null,
      status: widget.player.status,
      isSelf: widget.player.isSelf,
      imageUrl: imageUrl,
    );

    // Read providers BEFORE await to avoid context issues
    final playerService = PlayerService();
    late final ParentViewModel parentVM;
    late final String uid;
    try {
      parentVM = context.read<ParentViewModel>();
      final authVM = context.read<AuthViewModel>();
      uid = authVM.currentUser!.uid;
    } catch (_) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      await playerService.updatePlayer(widget.player.id, updatedPlayer);
      await parentVM.loadMyKids(uid);

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Player updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
