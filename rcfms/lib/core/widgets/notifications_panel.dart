import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/approval_repository.dart';

class NotificationsPanel extends StatefulWidget {
  final VoidCallback? onNotificationRead;

  const NotificationsPanel({super.key, this.onNotificationRead});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  final ApprovalRepository _approvalRepository = ApprovalRepository();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    try {
      _subscription = _approvalRepository.subscribeToNotifications(
        onUpdate: () {
          if (mounted) _loadNotifications();
        },
      );
    } catch (e) {
      debugPrint('Panel failed to subscribe: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _approvalRepository.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
      // Notify parent to update the badge count
      widget.onNotificationRead?.call();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _approvalRepository.markAsRead(notificationId);
      _loadNotifications();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _approvalRepository.markAllAsRead();
      _loadNotifications();
    } catch (e) {
      // Handle error silently
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'approval_request':
        return LucideIcons.clipboardList;
      case 'approval_approved':
        return LucideIcons.circleCheck;
      case 'approval_rejected':
        return LucideIcons.circleX;
      case 'form_submitted':
        return LucideIcons.fileText;
      case 'admission':
        return LucideIcons.userPlus;
      default:
        return LucideIcons.bell;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'approval_request':
        return AppColors.warning;
      case 'approval_approved':
        return AppColors.success;
      case 'approval_rejected':
        return AppColors.error;
      case 'form_submitted':
      case 'admission':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_notifications.any((n) => !n.isRead))
                  TextButton(
                    onPressed: _markAllAsRead,
                    child: const Text('Mark all as read'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: _isLoading && _notifications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.bell,
                              size: 64,
                              color: AppColors.textTertiary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications',
                              style: TextStyle(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          final color =
                              _getNotificationColor(notification.type);
                          return InkWell(
                            onTap: () {
                              if (!notification.isRead) {
                                _markAsRead(notification.id);
                              }
                              // Add navigation logic if needed
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: notification.isRead
                                    ? Colors.transparent
                                    : color.withOpacity(0.05),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(
                                  color: notification.isRead
                                      ? Theme.of(context).dividerColor
                                      : color.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getNotificationIcon(notification.type),
                                      color: color,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notification.title,
                                          style: TextStyle(
                                            fontWeight: notification.isRead
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          notification.message,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTimeAgo(
                                              notification.createdAt),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!notification.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
