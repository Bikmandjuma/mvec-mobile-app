import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../features/supplier/data/supplier_workspace.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';

/// Supplier notifications, mirroring the web app's `NotificationPanel`: the
/// unread-tinted / dimmed-read card rows defined by `.notification-card`.
///
/// Backed by the real notifications feed in [supplierWorkspaceProvider]; tapping
/// a notice marks it read.
class SupplierNotificationsScreen extends ConsumerWidget {
  const SupplierNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(supplierWorkspaceProvider);
    final unread =
        workspace.valueOrNull?.notifications.where((n) => !n.read).length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPPORT',
          title: 'Notifications',
          subtitle: 'Updates about your orders, catalogue and account.',
          actions: [
            if (unread > 0)
              OutlineMvButton(
                label: 'Mark all read',
                icon: 'check',
                onPressed: () {
                  for (final notice in workspace.valueOrNull!.notifications) {
                    if (!notice.read) {
                      ref
                          .read(supplierWorkspaceProvider.notifier)
                          .markNotificationRead(notice.id);
                    }
                  }
                },
              ),
          ],
        ),
        switch (workspace) {
          AsyncLoading() => const LoadingState(),
          AsyncError(:final error) => ErrorState(
            message: friendlyError(error),
            onRetry: () => ref.invalidate(supplierWorkspaceProvider),
          ),
          AsyncData(:final value) => _Notices(
            notices: value.notifications,
            unavailable: value.notificationsUnavailable,
          ),
          _ => const LoadingState(),
        },
      ],
    );
  }
}

class _Notices extends ConsumerWidget {
  const _Notices({required this.notices, required this.unavailable});

  final List<SupplierNotice> notices;
  final bool unavailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notices.isEmpty) {
      return DataCard(
        title: 'Notifications',
        child: EmptyState(
          message: unavailable
              ? 'Notifications could not be loaded. Please retry in a moment.'
              : 'You have no notifications right now',
        ),
      );
    }

    return DataCard(
      title: 'Notifications',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final notice in notices)
            _NoticeRow(
              notice: notice,
              onTap:
                  () => ref
                      .read(supplierWorkspaceProvider.notifier)
                      .markNotificationRead(notice.id),
            ),
        ],
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.notice, required this.onTap});

  final SupplierNotice notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: notice.read ? .78 : 1,
      child: InkWell(
        onTap: notice.read ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: notice.read ? Colors.transparent : context.mv.soft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.mv.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.mv.soft,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: MvIcon('bell', size: 18, color: context.mv.accentDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (notice.message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notice.message,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: context.mv.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM yyyy · HH:mm').format(notice.createdAt),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF98A3A8)),
                    ),
                  ],
                ),
              ),
              if (!notice.read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: MvColors.badgeRed,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
