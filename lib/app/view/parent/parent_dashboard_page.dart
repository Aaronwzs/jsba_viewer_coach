import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/viewmodel/announcement_view_model.dart';
import 'package:jsba_app/app/viewmodel/notification_view_model.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/utils/responsive_helper.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';
import 'package:jsba_app/app/model/announcement_model.dart';
import 'package:jsba_app/app/model/notification_item_model.dart';


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
      appBar: const AppBarTitle(showBackButton: false),
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
                  ResponsiveHelper.getHorizontalPadding(context),
                  16,
                  ResponsiveHelper.getHorizontalPadding(context),
                  MediaQuery.paddingOf(context).bottom + 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(context, authVM),
                    const SizedBox(height: 24),
                    _buildRecentNotificationsSection(context),
                    const SizedBox(height: 24),
                    _buildAboutAcademySection(context),
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
            Consumer<NotificationViewModel>(
              builder: (context, notifVM, child) {
                return Badge(
                  isLabelVisible: notifVM.unreadCount > 0,
                  label: Text(
                    '${notifVM.unreadCount}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      context.router.pushPath('/notifications');
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentNotificationsSection(BuildContext context) {
    return Consumer<NotificationViewModel>(
      builder: (context, notifVM, child) {
        final recent = notifVM.recentNotifications;
        if (recent.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Notifications',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.router.pushPath('/notifications'),
                  child: Text(
                    notifVM.unreadCount > 0
                        ? 'See All (${notifVM.unreadCount})'
                        : 'See All',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recent.map((notification) => _buildNotificationCard(
                  context,
                  notification,
                  notifVM,
                )),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationItemModel notification,
    NotificationViewModel notifVM,
  ) {
    final icon = NotificationViewModel.getNotificationIcon(notification.type);
    final bgColor = notification.isRead ? Colors.white : Colors.blue[50];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: notification.isRead
            ? Border.all(color: Colors.transparent, width: 0)
            : Border.all(color: Colors.blue[200]!, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          notifVM.markAsRead(notification.id);
          _navigateToNotification(context, notification);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToNotification(
      BuildContext context, NotificationItemModel notification) {
    final refId = notification.referenceId;
    final refCollection = notification.referenceCollection;

    if (refId == null || refCollection == null) return;

    switch (refCollection) {
      case 'announcements':
        context.router.pushPath('/announcement-details/$refId');
        break;
      case 'invoices':
        context.router.pushPath('/invoice-details/$refId');
        break;
      case 'receipts':
        context.router.pushPath('/receipt-details/$refId');
        break;
      case 'training':
        context.router.pushPath('/class-detail/$refId');
        break;
      case 'court_signups':
        context.router.pushPath('/open-court-detail/$refId');
        break;
      case 'feedbacks':
        context.router.pushPath('/feedback-report');
        break;
    }
  }

  Widget _buildAboutAcademySection(BuildContext context) {
    return InkWell(
      onTap: () => context.router.root.pushPath('/about-academy'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.star,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Discover JSBA Academy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Join Malaysia's premier badminton coaching program with expert coaches and state-of-the-art facilities.",
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Explore Now',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                ],
              ),
            ),
          ],
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
              onPressed: () => context.router.pushPath('/announcements'),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveHelper.getDeviceType(context) ==
                              DeviceType.web
                          ? MediaQuery.sizeOf(context).width * 0.4
                          : double.infinity,
                    ),
                    child: AspectRatio(
                      aspectRatio: 210 / 297, // A4 Portrait Aspect Ratio
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
