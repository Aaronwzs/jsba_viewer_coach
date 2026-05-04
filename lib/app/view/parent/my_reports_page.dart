import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';

@RoutePage()
class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
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
    final authVM = context.watch<AuthViewModel>();
    final parentVM = context.watch<ParentViewModel>();

    return Scaffold(
      appBar: const AppBarTitle(title: 'My Reports', showBackButton: false),
      body: parentVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (authVM.currentUser != null) {
                  await parentVM.loadMyKids(authVM.currentUser!.uid);
                }
              },
              child: _buildContent(context, authVM, parentVM),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddPlayerDialog(context, authVM, parentVM),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildContent(
    BuildContext context,
    AuthViewModel authVM,
    ParentViewModel parentVM,
  ) {
    final selfPlayer = parentVM.selfPlayer;
    final allKids = parentVM.allKids;

    if (parentVM.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${parentVM.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (authVM.currentUser != null) {
                  parentVM.loadMyKids(authVM.currentUser!.uid);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (selfPlayer == null && allKids.isEmpty) {
      return _buildEmptyState(context, authVM);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.paddingOf(context).bottom + 100,
      ),
      children: [
        if (selfPlayer != null) ...[
          const Text(
            'My Profile',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildSelfCard(context, selfPlayer),
          const SizedBox(height: 16),
        ],
        if (allKids.isNotEmpty) ...[
          const Text(
            'My Players',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...allKids.map((kid) {
            if (kid.status == PlayerStatus.pending) {
              return _buildPendingKidCard(context, kid);
            } else {
              return _buildKidCard(context, kid);
            }
          }),
        ],
      ],
    );
  }

  Widget _buildSelfCard(BuildContext context, PlayerModel self) {
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
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          backgroundImage: self.imageUrl != null && self.imageUrl!.isNotEmpty
              ? CachedNetworkImageProvider(self.imageUrl!)
              : null,
          child: self.imageUrl == null || self.imageUrl!.isEmpty
              ? const Icon(Icons.person, color: AppTheme.primaryColor)
              : null,
        ),
        title: Text(
          '${self.name} (You)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.cake, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('Age: ${self.age}'),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.trending_up, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('Level: ${self.level}'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.router.push(PlayerReportRoute(playerId: self.id));
        },
      ),
    );
  }

  Widget _buildPendingKidCard(BuildContext context, PlayerModel kid) {
    return Opacity(
      opacity: 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
            child: const Icon(Icons.hourglass_empty, color: Colors.grey),
          ),
          title: Text(
            kid.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.cake, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('Age: ${kid.age}'),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Awaiting admin approval',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.lock, color: Colors.grey),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This player is not approved yet. Please wait for admin approval.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AuthViewModel authVM) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.child_care, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No Reports Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add yourself or your children to get started',
                style: TextStyle(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddPlayerDialog(
                  context,
                  context.read<AuthViewModel>(),
                  context.read<ParentViewModel>(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Player'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKidCard(BuildContext context, PlayerModel kid) {
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
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          backgroundImage: kid.imageUrl != null && kid.imageUrl!.isNotEmpty
              ? CachedNetworkImageProvider(kid.imageUrl!)
              : null,
          child: (kid.imageUrl == null || kid.imageUrl!.isEmpty)
              ? Text(
                  kid.name.isNotEmpty ? kid.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                )
              : null,
        ),
        title: Text(
          kid.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.cake, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('Age: ${kid.age}'),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.trending_up, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('Level: ${kid.level}'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.router.push(PlayerReportRoute(playerId: kid.id));
        },
      ),
    );
  }

  void _showAddPlayerDialog(
    BuildContext context,
    AuthViewModel authVM,
    ParentViewModel parentVM,
  ) {
    final user = authVM.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add a player')),
      );
      return;
    }

    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final phoneController = TextEditingController();
    final parentNameController = TextEditingController();

    final selfPlayer = parentVM.selfPlayer;
    if (selfPlayer != null) {
      parentNameController.text = selfPlayer.name;
    }

    String level = 'Beginner';
    bool isAddingForSelf = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final hasSelfAdded = parentVM.hasSelfAdded;
          final age = int.tryParse(ageController.text) ?? 0;
          final needsParentInfo = age < 20;

          return SingleChildScrollView(
            child: Padding(
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
                  const Text(
                    'Add Player',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text(
                      hasSelfAdded
                          ? 'Add myself (Already added)'
                          : 'Add myself',
                    ),
                    value: isAddingForSelf,
                    onChanged: hasSelfAdded
                        ? null
                        : (value) {
                            if (!context.mounted) return;
                            setModalState(() {
                              isAddingForSelf = value ?? false;
                              if (isAddingForSelf) {
                                nameController.text = user.name;
                              } else {
                                nameController.clear();
                              }
                            });
                          },
                    contentPadding: EdgeInsets.zero,
                  ),
                  TextField(
                    controller: nameController,
                    enabled: !isAddingForSelf,
                    decoration: const InputDecoration(
                      labelText: 'Player Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      if (!context.mounted) return;
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: level,
                    decoration: const InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Beginner', 'Intermediate', 'Advanced']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (value) {
                      if (!context.mounted) return;
                      setModalState(() {
                        level = value ?? 'Beginner';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (needsParentInfo) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Since the player is under 20 years old, please provide parent/guardian name:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: parentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Parent/Guardian Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a name'),
                            ),
                          );
                          return;
                        }

                        final age = int.tryParse(ageController.text) ?? 0;
                        if (age <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid age'),
                            ),
                          );
                          return;
                        }

                        if (age < 20 && parentNameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please provide parent/guardian name',
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.of(ctx).pop();

                        bool success;
                        String message;

                        if (isAddingForSelf) {
                          success = await parentVM.addSelf(
                            user.uid,
                            nameController.text,
                            age,
                            level,
                            phoneController.text,
                          );
                          message = 'Your profile has been added!';
                        } else {
                          final selfPlayer = parentVM.selfPlayer;
                          final guardianName = age < 20
                              ? parentNameController.text
                              : (selfPlayer?.name ?? user.name);

                          final player = PlayerModel(
                            id: '',
                            name: nameController.text,
                            age: age,
                            level: level,
                            phone: phoneController.text,
                            createdAt: DateTime.now(),
                            isActive: true,
                            parentId: user.uid,
                            parentName: guardianName,
                            parentPhone: selfPlayer?.phone ?? user.phone,
                            parentEmail: user.email,
                          );

                          success = await parentVM.addChild(player);
                          message = 'Child added! Waiting for admin approval.';
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Add Player'),
                    ),
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
}
