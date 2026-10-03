/// Store configuration for the vendor account settings module.
library;

import '../../../models/user.dart';

/// What a staff member is allowed to do. The permission set is derived from
/// the role, but is stored per member so a single permission can be
/// overridden without inventing new roles.
enum VendorPermission {
  viewDashboard,
  manageProducts,
  manageOrders,
  managePayouts,
  manageStaff,
  viewAnalytics;

  String get slug => name.toUpperCase();

  String get label => switch (this) {
    VendorPermission.viewDashboard => 'View dashboard',
    VendorPermission.manageProducts => 'Manage products',
    VendorPermission.manageOrders => 'Manage orders',
    VendorPermission.managePayouts => 'Manage payouts',
    VendorPermission.manageStaff => 'Manage staff',
    VendorPermission.viewAnalytics => 'View analytics',
  };

  /// Permissions that move money or expose it — the ones worth confirming
  /// before removing a team member.
  bool get isSensitive =>
      this == VendorPermission.managePayouts ||
      this == VendorPermission.manageStaff;

  static VendorPermission? parse(String? raw) {
    final v = raw?.trim().toUpperCase();
    for (final p in VendorPermission.values) {
      if (p.slug == v) return p;
    }
    return null;
  }
}

/// The three staff roles. [Owner] is not assignable — the account holder is
/// implicit and cannot be removed from their own store.
enum StaffRole {
  owner,
  manager,
  staff;

  String get label => switch (this) {
    StaffRole.owner => 'Owner',
    StaffRole.manager => 'Manager',
    StaffRole.staff => 'Staff',
  };

  /// Default permissions granted when someone is invited with this role.
  Set<VendorPermission> get defaults => switch (this) {
    StaffRole.owner => VendorPermission.values.toSet(),
    StaffRole.manager => {
      VendorPermission.viewDashboard,
      VendorPermission.manageProducts,
      VendorPermission.manageOrders,
      VendorPermission.viewAnalytics,
    },
    StaffRole.staff => {
      VendorPermission.viewDashboard,
      VendorPermission.manageOrders,
    },
  };

  /// Roles an admin may assign to a new member.
  static List<StaffRole> get assignable => const [
    StaffRole.manager,
    StaffRole.staff,
  ];

  static StaffRole parse(String? raw) {
    final v = raw?.trim().toLowerCase();
    return switch (v) {
      'manager' => StaffRole.manager,
      'staff' => StaffRole.staff,
      _ => StaffRole.owner,
    };
  }
}

/// One day of the store's opening hours. [open] false means closed all day.
class OperatingDay {
  const OperatingDay({
    required this.label,
    required this.open,
    this.from = '08:00',
    this.to = '18:00',
  });

  final String label;
  final bool open;
  final String from;
  final String to;

  /// `'Closed'` or `'08:00 – 18:00'`, ready to display.
  String get display => open ? '$from – $to' : 'Closed';

  OperatingDay copyWith({bool? open, String? from, String? to}) => OperatingDay(
    label: label,
    open: open ?? this.open,
    from: from ?? this.from,
    to: to ?? this.to,
  );
}

/// The store's weekly opening hours, Monday first, as the vendor wrote them.
class OperatingHours {
  const OperatingHours(this.days);

  final List<OperatingDay> days;

  /// True when the store trades on the given weekday, used to warn about
  /// orders arriving outside opening hours.
  bool isOpenOn(DateTime date) {
    if (days.isEmpty) return true;
    final i = date.weekday - 1; // DateTime.monday == 1
    return days[i.clamp(0, days.length - 1)].open;
  }

  String get summary =>
      days.where((d) => d.open).isEmpty
          ? 'Closed all week'
          : '${days.where((d) => d.open).length} days a week';

  factory OperatingHours.fromJson(dynamic raw) {
    final defaults = [
      for (final d in const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ])
        OperatingDay(label: d, open: true),
      const OperatingDay(label: 'Sunday', open: false),
    ];
    if (raw is! Map) return OperatingHours(defaults);
    final m = Map<String, dynamic>.from(raw);
    return OperatingHours([
      for (final d in defaults)
        if (m[d.label.toLowerCase()] is Map) ...[
          OperatingDay(
            label: d.label,
            open: (m[d.label.toLowerCase()]!['open'] ?? true) == true,
            from: '${m[d.label.toLowerCase()]!['from'] ?? d.from}',
            to: '${m[d.label.toLowerCase()]!['to'] ?? d.to}',
          ),
        ] else
          d,
    ]);
  }
}

/// How the store charges and promises delivery.
enum ShippingRuleType {
  flat,
  free,
  percentage;

  String get label => switch (this) {
    ShippingRuleType.flat => 'Flat rate',
    ShippingRuleType.free => 'Free delivery',
    ShippingRuleType.percentage => 'Percentage of order',
  };

  static ShippingRuleType parse(String? raw) {
    final v = raw?.trim().toLowerCase();
    return switch (v) {
      'free' => ShippingRuleType.free,
      'percentage' || 'percent' => ShippingRuleType.percentage,
      _ => ShippingRuleType.flat,
    };
  }
}

/// One shipping option offered at checkout.
class ShippingRule {
  const ShippingRule({
    required this.id,
    required this.name,
    required this.type,
    required this.etaDays,
    this.amount = 0,
    this.minimumOrder = 0,
  });

  final String id;
  final String name;
  final ShippingRuleType type;

  /// Charge for this rule. Always `0` for [ShippingRuleType.free].
  final num amount;

  /// Order subtotal below which the rule does not apply (free-shipping
  /// thresholds, mostly).
  final num minimumOrder;

  /// Handling time in days, shown next to the rule.
  final int etaDays;

  bool get isFree => type == ShippingRuleType.free;

  /// A one-line summary for the settings list, e.g.
  /// `'Free above RWF 50,000 · 1–2 days'`.
  String get summary =>
      isFree
          ? (minimumOrder > 0
              ? 'Free above ${_plain(minimumOrder)}'
              : 'Always free')
          : '${_plain(type == ShippingRuleType.percentage ? amount / 100 : amount)} · $etaDays day${etaDays == 1 ? '' : 's'}';

  factory ShippingRule.fromJson(Map<String, dynamic> j) => ShippingRule(
    id: '${j['_id'] ?? j['id'] ?? j['name']}',
    name: '${j['name'] ?? 'Standard delivery'}',
    type: ShippingRuleType.parse('${j['type'] ?? ''}'),
    amount:
        (j['amount'] ?? j['fee'] ?? 0) is num
            ? j['amount'] ?? j['fee'] ?? 0
            : num.tryParse('${j['amount'] ?? j['fee'] ?? 0}') ?? 0,
    minimumOrder:
        (j['minimumOrder'] ?? j['minOrder'] ?? 0) is num
            ? j['minimumOrder'] ?? j['minOrder'] ?? 0
            : num.tryParse('${j['minimumOrder'] ?? j['minOrder'] ?? 0}') ?? 0,
    etaDays:
        (j['etaDays'] ?? j['days'] ?? 2) is int
            ? (j['etaDays'] ?? j['days'] ?? 2) as int
            : int.tryParse('${j['etaDays'] ?? j['days'] ?? 2}') ?? 2,
  );

  ShippingRule copyWith({
    String? name,
    ShippingRuleType? type,
    num? amount,
    num? minimumOrder,
    int? etaDays,
  }) => ShippingRule(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    minimumOrder: minimumOrder ?? this.minimumOrder,
    etaDays: etaDays ?? this.etaDays,
  );
}

/// A member of the store's team.
class VendorStaffMember {
  const VendorStaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
    this.phone,
    this.active = true,
    this.invitedAt,
  });

  final String id;
  final String name;
  final String email;
  final StaffRole role;
  final Set<VendorPermission> permissions;
  final String? phone;

  /// A revoked member stays in the list for the audit trail but cannot sign in.
  final bool active;
  final DateTime? invitedAt;

  bool get isOwner => role == StaffRole.owner;

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory VendorStaffMember.fromJson(Map<String, dynamic> j) {
    final role = StaffRole.parse('${j['role'] ?? ''}');
    final raw = (j['permissions'] ?? j['permissionsList']);
    return VendorStaffMember(
      id: '${j['_id'] ?? j['id'] ?? j['email']}',
      name: '${j['name'] ?? j['fullname'] ?? 'Team member'}',
      email: '${j['email'] ?? ''}',
      phone: j['phone'] == null ? null : '${j['phone']}',
      role: role,
      permissions:
          raw is List
              ? {
                for (final p in raw)
                  if (VendorPermission.parse('$p') case final granted?) granted,
              }
              : role.defaults,
      active: (j['active'] ?? j['isActive'] ?? true) == true,
      invitedAt: parseDate(j['invitedAt'] ?? j['createdAt']),
    );
  }

  VendorStaffMember copyWith({
    StaffRole? role,
    Set<VendorPermission>? permissions,
    bool? active,
  }) => VendorStaffMember(
    id: id,
    name: name,
    email: email,
    phone: phone,
    role: role ?? this.role,
    permissions: permissions ?? this.permissions,
    active: active ?? this.active,
    invitedAt: invitedAt,
  );
}

/// Everything the account settings screens read and write.
///
/// One document for all four sub-tabs, so a single save endpoint can persist a
/// partial change without the UI having to know which section it came from.
class VendorStoreSettings {
  const VendorStoreSettings({
    this.storeName = '',
    this.storeSlug = '',
    this.logoUrl,
    this.phone = '',
    this.supportEmail = '',
    this.description = '',
    this.businessAddress = '',
    this.businessPhone = '',
    this.taxId = '',
    this.hours = const OperatingHours([]),
    this.shippingRules = const [],
    this.defaultShippingRuleId,
    this.twoFactorEnabled = false,
    this.lastPasswordChangeAt,
    this.staff = const [],
    this.marketplaceLive = true,
  });

  // General store details
  final String storeName;
  final String storeSlug;
  final String? logoUrl;
  final String phone;
  final String supportEmail;
  final String description;

  // Business & delivery
  final String businessAddress;
  final String businessPhone;
  final String taxId;
  final OperatingHours hours;
  final List<ShippingRule> shippingRules;
  final String? defaultShippingRuleId;

  // Security
  final bool twoFactorEnabled;
  final DateTime? lastPasswordChangeAt;

  // Team
  final List<VendorStaffMember> staff;

  /// Whether the store accepts new orders from the marketplace.
  final bool marketplaceLive;

  List<VendorStaffMember> get activeStaff =>
      staff.where((m) => m.active).toList();

  ShippingRule? get defaultShippingRule {
    if (shippingRules.isEmpty) return null;
    return shippingRules.firstWhere(
      (r) => r.id == defaultShippingRuleId,
      orElse: () => shippingRules.first,
    );
  }

  factory VendorStoreSettings.fromJson(Map<String, dynamic> j) {
    final staffRaw = j['staff'] ?? j['team'] ?? j['members'];
    return VendorStoreSettings(
      storeName: '${j['storeName'] ?? j['name'] ?? ''}',
      storeSlug: '${j['storeSlug'] ?? j['slug'] ?? ''}',
      logoUrl: j['logo'] ?? j['logoUrl'],
      phone: '${j['phone'] ?? j['contactPhone'] ?? ''}',
      supportEmail: '${j['supportEmail'] ?? j['email'] ?? ''}',
      description: '${j['description'] ?? j['about'] ?? ''}',
      businessAddress: '${j['businessAddress'] ?? j['address'] ?? ''}',
      businessPhone: '${j['businessPhone'] ?? j['telephone'] ?? ''}',
      taxId: '${j['taxId'] ?? j['tin'] ?? ''}',
      hours: OperatingHours.fromJson(j['operatingHours'] ?? j['hours']),
      shippingRules:
          (j['shippingRules'] ?? j['deliveryRules']) is List
              ? (j['shippingRules'] ?? j['deliveryRules'])
                  .whereType<Map>()
                  .map(
                    (e) => ShippingRule.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList()
              : const <ShippingRule>[],
      defaultShippingRuleId:
          j['defaultShippingRuleId'] == null
              ? null
              : '${j['defaultShippingRuleId']}',
      twoFactorEnabled:
          (j['twoFactorEnabled'] ?? j['twoFactor'] ?? false) == true,
      lastPasswordChangeAt: parseDate(
        j['lastPasswordChangeAt'] ?? j['passwordChangedAt'],
      ),
      marketplaceLive:
          (j['marketplaceLive'] ?? j['acceptingOrders'] ?? true) == true,
      staff:
          staffRaw is List
              ? staffRaw
                  .whereType<Map>()
                  .map(
                    (e) => VendorStaffMember.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList()
              : const <VendorStaffMember>[],
    );
  }

  /// Serialises the whole document for `PUT /stores/mine/settings`.
  ///
  /// Every section is included so a save from any sub-tab is a complete
  /// document, which keeps the backend from needing partial-update semantics.
  Map<String, dynamic> toJson() => {
    'storeName': storeName,
    'storeSlug': storeSlug,
    'logo': logoUrl,
    'phone': phone,
    'supportEmail': supportEmail,
    'description': description,
    'businessAddress': businessAddress,
    'businessPhone': businessPhone,
    'taxId': taxId,
    'marketplaceLive': marketplaceLive,
    'operatingHours': {
      for (final d in hours.days)
        d.label.toLowerCase(): {'open': d.open, 'from': d.from, 'to': d.to},
    },
    'shippingRules': [
      for (final r in shippingRules)
        {
          'id': r.id,
          'name': r.name,
          'type': r.type.name,
          'amount': r.amount,
          'minimumOrder': r.minimumOrder,
          'etaDays': r.etaDays,
        },
    ],
    'defaultShippingRuleId': defaultShippingRuleId ?? defaultShippingRule?.id,
    'twoFactorEnabled': twoFactorEnabled,
    'staff': [
      for (final m in staff)
        {
          'id': m.id,
          'name': m.name,
          'email': m.email,
          'phone': m.phone,
          'role': m.role.name,
          'active': m.active,
          'permissions': [for (final p in m.permissions) p.slug],
        },
    ],
  };

  VendorStoreSettings copyWith({
    String? storeName,
    String? storeSlug,
    String? logoUrl,
    String? phone,
    String? supportEmail,
    String? description,
    String? businessAddress,
    String? businessPhone,
    String? taxId,
    OperatingHours? hours,
    List<ShippingRule>? shippingRules,
    String? defaultShippingRuleId,
    bool? twoFactorEnabled,
    List<VendorStaffMember>? staff,
    bool? marketplaceLive,
  }) => VendorStoreSettings(
    storeName: storeName ?? this.storeName,
    storeSlug: storeSlug ?? this.storeSlug,
    logoUrl: logoUrl ?? this.logoUrl,
    phone: phone ?? this.phone,
    supportEmail: supportEmail ?? this.supportEmail,
    description: description ?? this.description,
    businessAddress: businessAddress ?? this.businessAddress,
    businessPhone: businessPhone ?? this.businessPhone,
    taxId: taxId ?? this.taxId,
    hours: hours ?? this.hours,
    shippingRules: shippingRules ?? this.shippingRules,
    defaultShippingRuleId: defaultShippingRuleId ?? this.defaultShippingRuleId,
    twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    staff: staff ?? this.staff,
    marketplaceLive: marketplaceLive ?? this.marketplaceLive,
  );
}

/// Plain RWF amount without the currency suffix, for text inside sentences.
String _plain(num amount) {
  final s = amount.toStringAsFixed(0);
  final parts = s.split('.');
  final buf = StringBuffer();
  for (var i = 0; i < parts[0].length; i++) {
    if (i > 0 && (parts[0].length - i) % 3 == 0) buf.write(',');
    buf.write(parts[0][i]);
  }
  return buf.toString();
}
