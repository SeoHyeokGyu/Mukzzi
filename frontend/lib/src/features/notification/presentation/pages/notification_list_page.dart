import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/gradient_scaffold.dart';
import 'package:mukzzi/src/core/widgets/collection_states.dart';
import 'package:mukzzi/src/features/notification/presentation/providers/notification_provider.dart';
import 'package:mukzzi/src/features/notification/data/models/notification_model.dart';

class NotificationListPage extends ConsumerWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: const Text('전체 읽음'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.fetchNotifications(),
        child: state.isLoading && state.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.notifications.isEmpty
                ? const CollectionEmptyState(
                    icon: Icons.notifications_none_outlined,
                    title: '알림이 없어요',
                    subtitle: '새로운 소식이 오면 알려드릴게요',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final n = state.notifications[index];
                      return _NotificationItem(
                        notification: n,
                        onTap: () {
                          // 1. 읽음 처리
                          if (!n.isRead) notifier.markAsRead(n.id);
                          
                          // 2. 관련 페이지로 이동
                          context.push(n.navigationPath);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? AppColors.surface.withValues(alpha: 0.5) 
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead 
              ? null 
              : Border.all(color: AppColors.orange.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                          color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatTime(notification.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: notification.isRead ? AppColors.textTertiary : AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.friendRequest:
      case NotificationType.friendAccepted:
        icon = Icons.person_add_outlined;
        color = Colors.blue;
        break;
      case NotificationType.nudge:
        icon = Icons.favorite_border;
        color = Colors.pink;
        break;
      case NotificationType.guestbook:
        icon = Icons.chat_bubble_outline;
        color = Colors.green;
        break;
      case NotificationType.levelUp:
        icon = Icons.auto_awesome;
        color = Colors.amber;
        break;
      case NotificationType.badgeAcquired:
        icon = Icons.military_tech_outlined;
        color = AppColors.orange;
        break;
      case NotificationType.mealTag:
        icon = Icons.restaurant_outlined;
        color = Colors.deepPurple;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = AppColors.textSecondary;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time.toLocal());

    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return DateFormat('MM.dd').format(time.toLocal());
  }
}
