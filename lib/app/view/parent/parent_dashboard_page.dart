import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/viewmodel/announcement_view_model.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';
import 'package:jsba_app/app/models/announcement_model.dart';

@RoutePage()
class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      if (authVM.currentUser != null) {
        context.read<ParentViewModel>().loadMyKids(authVM.currentUser!.uid);
      }
      context.read<AnnouncementViewModel>().loadAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final parentVM = context.watch<ParentViewModel>();

    return Scaffold(
      appBar: const AppBarTitle(),
      body: parentVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (authVM.currentUser != null) {
                  await parentVM.loadMyKids(authVM.currentUser!.uid);
                }
                await context.read<AnnouncementViewModel>().loadAnnouncements();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.paddingOf(context).bottom + 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(context, authVM),
                    const SizedBox(height: 24),
                    _buildAnnouncementsSection(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, AuthViewModel authVM) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome,',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  Text(
                    authVM.currentUser?.name ?? 'Parent',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                context.router.pushNamed('/announcements');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyKidsSection(BuildContext context, ParentViewModel parentVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Kids',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => context.router.pushNamed('/add-child'),
              icon: const Icon(Icons.add),
              label: const Text('Add Child'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (parentVM.myKids.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.child_care, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No children added yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => context.router.pushNamed('/add-child'),
                      child: const Text('Add Your First Child'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...parentVM.myKids.map(
            (kid) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.secondaryColor.withValues(
                    alpha: 0.1,
                  ),
                  child: Icon(Icons.child_care, color: AppTheme.secondaryColor),
                ),
                title: Text(
                  kid.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Level: ${kid.level}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.router.pushNamed('/child-details/${kid.id}');
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.sports_tennis,
                label: 'Book Court',
                onTap: () => context.router.pushNamed('/create-booking'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.event_available,
                label: 'Session Slots',
                onTap: () => context.router.pushNamed('/session-slots'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.receipt_long,
                label: 'Invoices',
                onTap: () => context.router.pushNamed('/parent-invoices'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.announcement,
                label: 'Announcements',
                onTap: () => context.router.pushNamed('/announcements'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Announcements',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.router.pushNamed('/announcements'),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<AnnouncementViewModel>(
          builder: (context, announcementVM, child) {
            if (announcementVM.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (announcementVM.announcements.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.announcement_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No announcements yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: announcementVM.dashboardAnnouncements
                  .map(
                    (announcement) =>
                        _buildAnnouncementCard(context, announcement),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    AnnouncementModel announcement,
  ) {
    final Color typeColor;
    final IconData typeIcon;

    switch (announcement.type) {
      case AnnouncementType.urgent:
        typeColor = Colors.red;
        typeIcon = Icons.warning;
        break;
      case AnnouncementType.event:
        typeColor = Colors.orange;
        typeIcon = Icons.event;
        break;
      case AnnouncementType.update:
        typeColor = Colors.blue;
        typeIcon = Icons.update;
        break;
      case AnnouncementType.general:
      default:
        typeColor = AppTheme.primaryColor;
        typeIcon = Icons.info;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                if (announcement.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.push_pin, size: 16, color: typeColor),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        announcement.typeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (announcement.hasImages)
            SizedBox(
              height: 180,
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      itemCount: announcement.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(
                                announcement.imageUrls[index],
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (announcement.imageUrls.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          announcement.imageUrls.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.content,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (announcement.createdByName != null) ...[
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        announcement.createdByName!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(announcement.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
