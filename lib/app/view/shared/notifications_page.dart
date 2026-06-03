import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/service/notification_service.dart';
import 'package:jsba_app/app/utils/starter_handler.dart' as starter_handler;
import 'package:jsba_app/app/viewmodel/notification_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/model/notification_item_model.dart';
import 'package:jsba_app/app/widgets/notification_card.dart';

@RoutePage()
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  /// True after the user grants push permission or dismisses the banner.
  /// Defaults to `false` (banner visible) on every page load so we don't
  /// silently consume permission state — the user must opt in explicitly.
  bool _pushPromptHandled = false;

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
            itemCount: notifVM.notifications.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _PushPermissionBanner(
                  onHandled: () => setState(() => _pushPromptHandled = true),
                  hidden: _pushPromptHandled,
                );
              }
              final notification = notifVM.notifications[index - 1];
              return NotificationCard(
                notification: notification,
                onTap: () {
                  notifVM.markAsRead(notification.id);
                  _navigateToNotification(context, notification);
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

/// Banner shown above the notification list to prompt the user to enable
/// push notifications. Web Push best practice is to ask permission after
/// the user shows interest (e.g. by clicking "Enable"), not on first app
/// load — see [NotificationService.enablePushNotifications].
class _PushPermissionBanner extends StatefulWidget {
  const _PushPermissionBanner({
    required this.onHandled,
    required this.hidden,
  });

  /// Called when the user has either granted permission (hide the banner)
  /// or dismissed it (also hide the banner).
  final VoidCallback onHandled;

  /// When true, the banner is not rendered. The parent rebuilds with
  /// `hidden: true` after a successful enable or dismiss action.
  final bool hidden;

  @override
  State<_PushPermissionBanner> createState() => _PushPermissionBannerState();
}

class _PushPermissionBannerState extends State<_PushPermissionBanner> {
  bool _busy = false;
  PushPermissionResult? _result;

  NotificationService get _service => starter_handler.notificationService;

  Future<void> _onEnable() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await _service.enablePushNotifications();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
    });
    if (result == PushPermissionResult.granted) {
      widget.onHandled();
    }
  }

  void _onDismiss() {
    widget.onHandled();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hidden) return const SizedBox.shrink();

    // After the user taps Enable and gets denied, the browser will not
    // re-prompt from JS. Tell them how to fix it in browser settings.
    if (_result == PushPermissionResult.denied) {
      return _bannerContainer(
        color: Colors.orange[50]!,
        borderColor: Colors.orange[200]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_off, color: Colors.orange[800], size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Notifications are blocked',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'To get push notifications, allow them in your browser\'s site settings, then reload this page.',
              style: TextStyle(color: Colors.grey[800], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return _bannerContainer(
      color: Colors.blue[50]!,
      borderColor: Colors.blue[200]!,
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: Colors.blue[800], size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Get push notifications when you\'re not in the app',
              style: TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _onEnable,
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enable'),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _busy ? null : _onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _bannerContainer({
    required Color color,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: child,
    );
  }
}