import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jsba_app/app/model/notification_item_model.dart';
import 'package:jsba_app/app/viewmodel/notification_view_model.dart';

/// Shared notification card with subtle visual cues for read/unread state.
///
/// Used in three places (full list page, parent dashboard, coach dashboard) to
/// keep the unread/read treatment in sync.
///
/// Visual treatment:
/// - **Unread:** subtle pulse on the icon (1.5s cycle, auto-stops after ~6s so
///   it stays subtle and does not drain the battery). Blue-tinted background,
///   thin blue border, bold title, small blue dot indicator.
/// - **Read:** entire card wrapped in [Opacity] at 0.6 to de-emphasize it.
class NotificationCard extends StatefulWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.compact = false,
  });

  /// Test-only key attached to the pulsing icon wrapper so tests can locate
  /// the pulse independently of the framework widgets (e.g. InkWell splash).
  @visibleForTesting
  static const pulseKey = ValueKey<String>('NotificationCard.pulse');

  final NotificationItemModel notification;
  final VoidCallback? onTap;

  /// `true` produces the compact dashboard layout (icon + title + body only).
  /// `false` produces the full-list layout (icon + type chip + title + body + date).
  final bool compact;

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _pulseStopTimer;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (!widget.notification.isRead) {
      _startPulse();
    }
  }

  /// Run the pulse animation for ~4 cycles then stop. Safe to call again to
  /// restart the pulse (e.g. when a previously-read card becomes unread).
  void _startPulse() {
    _pulse.repeat(reverse: true);
    _pulseStopTimer?.cancel();
    _pulseStopTimer = Timer(const Duration(milliseconds: 6000), () {
      if (mounted) {
        _pulse.stop();
      }
    });
  }

  void _stopPulse() {
    _pulseStopTimer?.cancel();
    _pulseStopTimer = null;
    _pulse.stop();
    _pulse.value = 0;
  }

  @override
  void didUpdateWidget(NotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasUnread = !oldWidget.notification.isRead;
    final isUnread = !widget.notification.isRead;
    if (wasUnread && !isUnread) {
      _stopPulse();
    } else if (!wasUnread && isUnread) {
      _startPulse();
    }
  }

  @override
  void dispose() {
    _pulseStopTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notif = widget.notification;
    final isUnread = !notif.isRead;

    final card = widget.compact
        ? _buildCompact(notif, isUnread)
        : _buildDetailed(notif, isUnread);

    // Read cards are de-emphasized with a 0.6 opacity wrapper applied to the
    // whole card (background + content).
    if (!isUnread) {
      return Opacity(opacity: 0.6, child: card);
    }
    return card;
  }

  // ── Detailed (full list) layout ────────────────────────────────────────────

  Widget _buildDetailed(NotificationItemModel notif, bool isUnread) {
    final bgColor = isUnread ? Colors.blue[50] : Colors.white;
    final icon = NotificationViewModel.getNotificationIcon(notif.type);
    final typeLabel =
        NotificationViewModel.getNotificationTypeLabel(notif.type);
    final iconBg = _iconBgColor(notif.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isUnread ? 2 : 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnread
            ? BorderSide(color: Colors.blue[200]!, width: 0.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(
                notif,
                isUnread,
                withBackground: true,
                iconBg: iconBg,
                icon: icon,
              ),
              const SizedBox(width: 12),
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
                            color: iconBg.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: iconBg,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isUnread) _unreadDot(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(notif.createdAt),
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

  // ── Compact (dashboard) layout ─────────────────────────────────────────────

  Widget _buildCompact(NotificationItemModel notif, bool isUnread) {
    final icon = NotificationViewModel.getNotificationIcon(notif.type);
    final bgColor = isUnread ? Colors.blue[50] : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isUnread
            ? Border.all(color: Colors.blue[200]!, width: 0.5)
            : Border.all(color: Colors.transparent, width: 0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildIcon(
                notif,
                isUnread,
                withBackground: false,
                iconBg: null,
                icon: icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.body,
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
              if (isUnread) _unreadDot(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared building blocks ─────────────────────────────────────────────────

  Widget _buildIcon(
    NotificationItemModel notif,
    bool isUnread, {
    required bool withBackground,
    required Color? iconBg,
    required String icon,
  }) {
    final content = Text(icon, style: TextStyle(fontSize: withBackground ? 20 : 18));
    final decorated = withBackground
        ? Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: content,
          )
        : content;

    if (!isUnread) return decorated;
    // Pulse only the icon — scale 0.95↔1.05, opacity 0.85↔1.0, 1.5s cycle.
    return _PulsingIcon(
      key: NotificationCard.pulseKey,
      animation: _pulse,
      child: decorated,
    );
  }

  Widget _unreadDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
      ),
    );
  }

  Color _iconBgColor(String type) {
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

/// Applies a subtle pulse (scale + fade) to its child using the given animation.
class _PulsingIcon extends StatelessWidget {
  const _PulsingIcon({
    super.key,
    required this.animation,
    required this.child,
  });
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: 0.85 + 0.15 * t,
          child: Transform.scale(
            scale: 0.95 + 0.10 * t,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
