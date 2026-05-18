import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/viewmodel/notification_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/model/notification_item_model.dart';

@RoutePage()
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      if (authVM.currentUser != null) {
        context
            .read<NotificationViewModel>()
            .startListening(authVM.currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        actions: [
          Consumer<NotificationViewModel>(
            builder: (context, notifVM, child) {
              if (notifVM.unreadCount > 0) {
                return TextButton(
                  onPressed: () => notifVM.markAllAsRead(),
                  child: const Text('Mark all read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, notifVM, child) {
          if (notifVM.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notifVM.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will see updates here',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: notifVM.notifications.length,
            itemBuilder: (context, index) {
              return _NotificationCard(
                notification: notifVM.notifications[index],
                onTap: () {
                  notifVM.markAsRead(
                    notifVM.notifications[index].id,
                  );
                  _navigateToNotification(
                    context,
                    notifVM.notifications[index],
                  );
                },
              );
            },
          );
        },
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
      default:
        // Navigate to notifications page itself if no specific handler
        break;
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItemModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = notification.isRead ? Colors.white : Colors.blue[50];
    final icon = NotificationViewModel.getNotificationIcon(notification.type);
    final typeLabel =
        NotificationViewModel.getNotificationTypeLabel(notification.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: notification.isRead ? 0 : 2,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead
            ? BorderSide.none
            : BorderSide(color: Colors.blue[200]!, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getIconBgColor(notification.type),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getIconBgColor(notification.type)
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getIconBgColor(notification.type),
                            ),
                          ),
                        ),
                        const Spacer(),
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
                    const SizedBox(height: 6),
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight:
                            notification.isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(notification.createdAt),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIconBgColor(String type) {
    switch (type) {
      case 'announcement':
        return Colors.orange[100]!;
      case 'invoice':
      case 'receipt':
        return Colors.green[100]!;
      case 'payment_due':
        return Colors.red[100]!;
      case 'availability':
        return Colors.purple[100]!;
      case 'session':
      case 'training':
        return Colors.blue[100]!;
      case 'attendance':
        return Colors.teal[100]!;
      case 'feedback':
        return Colors.indigo[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return 'Just now';
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