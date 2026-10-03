/// Notifications the vendor receives: new orders, money movements, platform
/// policy changes and dispute cases.
library;

import '../../../models/user.dart';

/// The four alert families, matching the filter chips on the feed.
enum NotificationCategory {
  order,
  financial,
  policy,
  dispute;

  String get slug => switch (this) {
        NotificationCategory.order => 'ORDERS',
        NotificationCategory.financial => 'FINANCIAL',
        NotificationCategory.policy => 'SYSTEM_POLICY',
        NotificationCategory.dispute => 'DISPUTES',
      };

  /// Chip / section label.
  String get label => switch (this) {
        NotificationCategory.order => 'Orders',
        NotificationCategory.financial => 'Financial',
        NotificationCategory.policy => 'System Policy',
        NotificationCategory.dispute => 'Disputes',
      };

  String get icon => switch (this) {
        NotificationCategory.order => 'cart',
        NotificationCategory.financial => 'wallet',
        NotificationCategory.policy => 'shield',
        NotificationCategory.dispute => 'bell',
      };

  /// Key for the per-category accent so each family is recognisable.
  String get tone => slug;

  static NotificationCategory parse(String? raw) {
    final v = raw?.trim().toLowerCase().replaceAll('-', '_');
    return switch (v) {
      'financial' || 'finance' || 'payments' => NotificationCategory.financial,
      'system_policy' || 'policy' || 'system' => NotificationCategory.policy,
      'disputes' || 'dispute' => NotificationCategory.dispute,
      _ => NotificationCategory.order,
    };
  }
}

/// Severity, drives the row's left rail colour.
enum NotificationSeverity {
  info,
  success,
  warning,
  critical;

  String get slug => name.toUpperCase();

  /// True when the vendor must acknowledge the alert.
  bool get isUrgent => this == NotificationSeverity.warning || this == NotificationSeverity.critical;

  static NotificationSeverity parse(String? raw) {
    final v = raw?.trim().toLowerCase();
    return switch (v) {
      'success' || 'resolved' => NotificationSeverity.success,
      'warning' || 'warn' => NotificationSeverity.warning,
      'critical' || 'error' || 'urgent' => NotificationSeverity.critical,
      _ => NotificationSeverity.info,
    };
  }
}

/// A single alert in the vendor's feed.
///
/// [actionPath] and [actionLabel] are what make the feed actionable: tapping
/// the row deep-links straight to the order, the payout or the case it is
/// about, instead of making the vendor go hunting.
class VendorNotification {
  const VendorNotification({
    required this.id,
    required this.at,
    required this.category,
    required this.title,
    required this.body,
    this.severity = NotificationSeverity.info,
    this.read = false,
    this.actionPath,
    this.actionLabel,
    this.amount,
    this.orderId,
    this.orderNumber,
  });

  final String id;
  final DateTime at;
  final NotificationCategory category;
  final NotificationSeverity severity;
  final String title;
  final String body;
  final bool read;

  /// In-app route opened by the row's action button, e.g. `/vendor/orders`.
  final String? actionPath;

  /// Verb shown on the action button, e.g. `"View order"`.
  final String? actionLabel;

  /// Monetary value the alert is about, when it is about money.
  final num? amount;

  final String? orderId;
  final String? orderNumber;

  /// Newest first is the feed's natural order, so a descending sort is enough.
  factory VendorNotification.fromJson(Map<String, dynamic> j) {
    final category = NotificationCategory.parse('${j['category'] ?? j['type'] ?? ''}');
    return VendorNotification(
      id: '${j['_id'] ?? j['id'] ?? ''}',
      at: parseDate(j['at'] ?? j['createdAt'] ?? j['date']) ?? DateTime.now(),
      category: category,
      severity: NotificationSeverity.parse('${j['severity'] ?? j['level'] ?? ''}'),
      title: '${j['title'] ?? j['subject'] ?? category.label}',
      body: '${j['body'] ?? j['message'] ?? j['description'] ?? ''}',
      read: (j['read'] ?? j['isRead'] ?? false) == true,
      actionPath: j['actionPath'] == null ? null : '${j['actionPath']}',
      actionLabel: j['actionLabel'] == null ? null : '${j['actionLabel']}',
      amount: j['amount'] == null
          ? null
          : (j['amount'] is num ? j['amount'] as num : num.tryParse('${j['amount']}')),
      orderId: j['orderId'] == null ? null : '${j['orderId']}',
      orderNumber: j['orderNumber'] == null ? null : '${j['orderNumber']}',
    );
  }

  /// Returns a copy with the read flag flipped, for optimistic marking.
  VendorNotification copyWith({bool? read}) => VendorNotification(
        id: id,
        at: at,
        category: category,
        severity: severity,
        title: title,
        body: body,
        read: read ?? this.read,
        actionPath: actionPath,
        actionLabel: actionLabel,
        amount: amount,
        orderId: orderId,
        orderNumber: orderNumber,
      );
}
