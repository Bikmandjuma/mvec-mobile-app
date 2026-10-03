import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../widgets/common.dart';
import '../../../widgets/mv_icon.dart';
import '../models/vendor_notification.dart';
import '../vendor_dependencies.dart';

/// Categorized vendor alert feed with read state and contextual navigation.
class VendorNotificationsScreen extends ConsumerStatefulWidget {
  const VendorNotificationsScreen({super.key});

  @override
  ConsumerState<VendorNotificationsScreen> createState() =>
      _VendorNotificationsScreenState();
}

class _VendorNotificationsScreenState
    extends ConsumerState<VendorNotificationsScreen> {
  NotificationCategory? _category;

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(vendorNotificationsProvider(_category));
    final all =
        ref.watch(vendorNotificationsProvider(null)).valueOrNull ??
        const <VendorNotification>[];
    final unread = all.where((notification) => !notification.read).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'INBOX',
          title: 'Notifications',
          subtitle:
              unread == 0
                  ? 'You are up to date.'
                  : '$unread unread update${unread == 1 ? '' : 's'}',
          actions: [
            TextButton.icon(
              onPressed: unread == 0 ? null : () => _markAllRead(all),
              icon: const Icon(Icons.done_all, size: 17),
              label: const Text('Mark all read'),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('All', null),
              for (final category in NotificationCategory.values) ...[
                const SizedBox(width: 8),
                _filterChip(category.label, category),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        switch (feedAsync) {
          AsyncLoading() => const SizedBox(height: 250, child: LoadingState()),
          AsyncError(:final error) => ErrorState(
            message: friendlyError(error),
            onRetry:
                () => ref.invalidate(vendorNotificationsProvider(_category)),
          ),
          AsyncData(:final value) => _feed(value),
          _ => const SizedBox(height: 250, child: LoadingState()),
        },
      ],
    );
  }

  Widget _filterChip(String label, NotificationCategory? category) => Padding(
    padding: const EdgeInsets.only(right: 2),
    child: ChoiceChip(
      label: Text(label),
      selected: _category == category,
      onSelected: (_) => setState(() => _category = category),
    ),
  );

  Widget _feed(List<VendorNotification> notifications) {
    if (notifications.isEmpty) {
      return const EmptyState(message: 'No notifications in this category.');
    }
    return Column(
      children: [
        for (final notification in notifications)
          _notificationTile(notification),
      ],
    );
  }

  Widget _notificationTile(VendorNotification notification) {
    final palette = context.mv;
    final severityColor = switch (notification.severity) {
      NotificationSeverity.success => MvColors.successText,
      NotificationSeverity.warning => MvColors.warningText,
      NotificationSeverity.critical => MvColors.errorText,
      NotificationSeverity.info => MvColors.primaryDeep,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 66,
              decoration: BoxDecoration(
                color: severityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: MvIcon(
                  notification.category.icon,
                  size: 17,
                  color: severityColor,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                notification.read
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: MvColors.primaryDeep,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${notification.category.label} · ${shortDateTime(notification.at)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: palette.textMuted,
                        ),
                      ),
                      if (notification.actionPath != null)
                        TextButton(
                          onPressed: () => _openAction(notification),
                          child: Text(notification.actionLabel ?? 'Open'),
                        ),
                      TextButton(
                        onPressed:
                            () => _setRead(notification, !notification.read),
                        child: Text(
                          notification.read ? 'Mark unread' : 'Mark read',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setRead(VendorNotification notification, bool read) async {
    try {
      await ref
          .read(vendorNotificationModuleProvider)
          .setRead(notification.id, read);
      ref.invalidate(vendorNotificationsProvider(_category));
      ref.invalidate(vendorNotificationsProvider(null));
    } catch (error) {
      if (mounted) showMvSnack(context, friendlyError(error));
    }
  }

  Future<void> _markAllRead(List<VendorNotification> items) async {
    try {
      for (final item in items.where((notification) => !notification.read)) {
        await ref.read(vendorNotificationModuleProvider).setRead(item.id, true);
      }
      ref.invalidate(vendorNotificationsProvider(_category));
      ref.invalidate(vendorNotificationsProvider(null));
    } catch (error) {
      if (mounted) showMvSnack(context, friendlyError(error));
    }
  }

  void _openAction(VendorNotification notification) {
    final path = notification.actionPath;
    if (path == null) return;
    if (notification.category == NotificationCategory.dispute &&
        notification.orderId != null) {
      context.go(
        '/vendor/orders?order=${Uri.encodeComponent(notification.orderId!)}',
      );
    } else {
      context.go(path);
    }
    if (!notification.read) _setRead(notification, true);
  }
}
