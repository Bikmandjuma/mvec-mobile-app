import '../../../../models/user.dart';

/// Affiliate account: identity, verification state, payout details and the
/// referral code that anchors every promotional link.
///
/// Field names are tolerant of both the MVEC backend (`Fullname`, `_id`) and
/// the affiliate Prisma service (`affiliateCode`, `availableBalance`) so the
/// same parser works before and after the backend ships.
class AffiliateProfile {
  const AffiliateProfile({
    this.id,
    this.userId,
    this.fullName,
    this.email,
    this.phone,
    this.displayName,
    this.bio,
    this.website,
    this.country,
    this.referralCode,
    this.referralUrl,
    this.status,
    this.verificationStatus,
    this.verificationNote,
    this.commissionRate,
    this.payoutMethod,
    this.payoutAccountName,
    this.payoutAccountNumber,
    this.avatar,
    this.joinedAt,
    this.verifiedAt,
  });

  final String? id;
  final String? userId;
  final String? fullName;
  final String? email;
  final String? phone;

  /// Public publisher name shown on shared campaigns.
  final String? displayName;
  final String? bio;
  final String? website;
  final String? country;

  /// The affiliate's own referral code, e.g. `AFF-1042-9F3C1A`.
  final String? referralCode;
  final String? referralUrl;

  /// Account lifecycle status (`ACTIVE`, `SUSPENDED`, `PENDING`).
  final String? status;

  /// Verification state (`UNVERIFIED`, `PENDING`, `VERIFIED`, `REJECTED`).
  final String? verificationStatus;

  /// Reviewer note shown when verification is rejected or queried.
  final String? verificationNote;

  /// Default commission rate for this affiliate, e.g. 8 (percent).
  final num? commissionRate;

  final String? payoutMethod;
  final String? payoutAccountName;
  final String? payoutAccountNumber;
  final String? avatar;
  final DateTime? joinedAt;
  final DateTime? verifiedAt;

  factory AffiliateProfile.fromJson(Map<String, dynamic> j) {
    final user = j['user'] is Map ? Map<String, dynamic>.from(j['user']) : null;
    final wallet = j['wallet'] is Map ? Map<String, dynamic>.from(j['wallet']) : null;
    return AffiliateProfile(
      id: j['_id'] ?? j['id'] ?? j['affiliateId'],
      userId: j['affiliateUserId'] is Map
          ? (j['affiliateUserId']['_id'] ?? j['affiliateUserId']['id'])?.toString()
          : j['affiliateUserId']?.toString() ?? j['userId']?.toString(),
      fullName: j['Fullname'] ?? j['fullname'] ?? j['fullName'] ?? j['name'] ?? user?['Fullname'] ?? user?['fullname'],
      email: j['email'] ?? user?['email'],
      phone: j['phone'] ?? j['telephone'] ?? user?['phone'],
      displayName: j['displayName'] ?? j['publisherName'] ?? j['affiliateName'],
      bio: j['bio'] ?? j['about'] ?? j['description'],
      website: j['website'] ?? j['websiteUrl'] ?? j['site'],
      country: j['country'] ?? j['countryOfResidence'],
      referralCode: j['affiliateCode'] ?? j['referralCode'] ?? j['code'],
      referralUrl: j['referralUrl'] ?? j['referralLink'] ?? j['link'],
      status: (j['status'] ?? 'ACTIVE')?.toString().toUpperCase(),
      verificationStatus: (j['verificationStatus'] ?? j['verification'] ?? 'UNVERIFIED')?.toString().toUpperCase(),
      verificationNote: j['verificationNote'] ?? j['rejectionReason'] ?? j['reviewNote'],
      commissionRate: (j['commissionRate'] ?? j['rate'] ?? wallet?['commissionRate']) as num?,
      payoutMethod: j['paymentMethod'] ?? j['payoutMethod'],
      payoutAccountName: j['accountName'],
      payoutAccountNumber: j['accountNumber'] ?? j['phoneNumber'],
      avatar: j['avatar'] ?? j['profileImage'] ?? user?['avatar'],
      joinedAt: parseDate(j['createdAt'] ?? j['joinedAt']),
      verifiedAt: parseDate(j['verifiedAt']),
    );
  }

  /// Builds a profile from the shared auth [UserRecord] so the shell always
  /// has an identity to render, even before `/affiliates/profile` responds.
  factory AffiliateProfile.fromUser(UserRecord user, {String? referralCode}) {
    return AffiliateProfile(
      id: user.id,
      userId: user.id,
      fullName: user.fullname,
      email: user.email,
      phone: user.phone,
      status: (user.status ?? 'ACTIVE').toUpperCase(),
      verificationStatus: user.status?.toUpperCase() == 'VERIFIED' ? 'VERIFIED' : 'UNVERIFIED',
      referralCode: referralCode,
      avatar: user.avatar,
    );
  }

  /// Only these keys are sent back on update — the backend owns status,
  /// verification and commission values.
  Map<String, dynamic> toUpdateJson() => {
        if (displayName != null && displayName!.trim().isNotEmpty) 'displayName': displayName!.trim(),
        if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
        if (bio != null) 'bio': bio,
        if (website != null) 'website': website,
        if (country != null) 'country': country,
        if (payoutMethod != null) 'paymentMethod': payoutMethod,
        if (payoutAccountName != null && payoutAccountName!.trim().isNotEmpty) 'accountName': payoutAccountName!.trim(),
        if (payoutAccountNumber != null && payoutAccountNumber!.trim().isNotEmpty)
          'accountDetails': {'phoneNumber': payoutAccountNumber!.trim()},
      };

  String get display => fullName ?? email ?? phone ?? 'Affiliate';

  bool get isVerified => verificationStatus == 'VERIFIED';

  bool get isSuspended => status == 'SUSPENDED';

  /// The code shown in the UI, falling back to a placeholder while it loads.
  String get code => referralCode ?? '—';

  /// The shareable link. Prefers the backend-built URL, otherwise composes the
  /// storefront deep link from the referral code.
  String get shareUrl => referralUrl ?? (referralCode == null ? '—' : affiliateShareUrl(referralCode!));

  AffiliateProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? displayName,
    String? bio,
    String? website,
    String? country,
    String? referralCode,
    String? referralUrl,
    String? status,
    String? verificationStatus,
    String? verificationNote,
    num? commissionRate,
    String? payoutMethod,
    String? payoutAccountName,
    String? payoutAccountNumber,
    String? avatar,
    DateTime? verifiedAt,
  }) =>
      AffiliateProfile(
        id: id,
        userId: userId,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        displayName: displayName ?? this.displayName,
        bio: bio ?? this.bio,
        website: website ?? this.website,
        country: country ?? this.country,
        referralCode: referralCode ?? this.referralCode,
        referralUrl: referralUrl ?? this.referralUrl,
        status: status ?? this.status,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        verificationNote: verificationNote ?? this.verificationNote,
        commissionRate: commissionRate ?? this.commissionRate,
        payoutMethod: payoutMethod ?? this.payoutMethod,
        payoutAccountName: payoutAccountName ?? this.payoutAccountName,
        payoutAccountNumber: payoutAccountNumber ?? this.payoutAccountNumber,
        avatar: avatar ?? this.avatar,
        joinedAt: joinedAt,
        verifiedAt: verifiedAt ?? this.verifiedAt,
      );
}

/// Verification state machine shown on the profile and dashboard.
///
/// Mirrors the frontend copy so the mobile wording matches the web console.
class AffiliateVerification {
  const AffiliateVerification({
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.notes,
    this.documents = const [],
  });

  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? notes;
  final List<String> documents;

  factory AffiliateVerification.fromJson(Map<String, dynamic> j) {
    final docs = j['documents'];
    return AffiliateVerification(
      status: (j['status'] ?? j['verificationStatus'] ?? 'UNVERIFIED').toString().toUpperCase(),
      submittedAt: parseDate(j['submittedAt'] ?? j['createdAt']),
      reviewedAt: parseDate(j['reviewedAt'] ?? j['verifiedAt']),
      notes: j['notes'] ?? j['rejectionReason'] ?? j['verificationNote'],
      documents: docs is List ? docs.map((e) => e.toString()).toList() : const [],
    );
  }

  /// Steps the affiliate walks through, with the reached one marked done.
  List<({String label, bool done})> get steps => [
        (label: 'Create your affiliate profile', done: _reached(1)),
        (label: 'Submit identity documents for verification', done: _reached(2)),
        (label: 'MVEC reviews and approves your account', done: _reached(3)),
        (label: 'Start sharing links and earning commission', done: status == 'VERIFIED'),
      ];

  bool _reached(int step) {
    switch (status) {
      case 'VERIFIED':
        return true;
      case 'PENDING':
      case 'UNDER_REVIEW':
        return step <= 2;
      case 'REJECTED':
        return step <= 1;
      default:
        return step <= 1;
    }
  }
}

/// User-controlled affiliate preferences. Persisted per affiliate so the
/// backend can restore them across devices.
class AffiliateSettings {
  const AffiliateSettings({
    this.defaultPayoutMethod = 'MTN_MOMO',
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.payoutAlerts = true,
    this.marketingEmails = false,
    this.language = 'English',
    this.themeMode,
  });

  final String defaultPayoutMethod;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool payoutAlerts;
  final bool marketingEmails;
  final String language;

  /// `'light'`, `'dark'` or null to follow the app setting.
  final String? themeMode;

  factory AffiliateSettings.fromJson(Map<String, dynamic> j) {
    final prefs = j['preferences'] is Map ? Map<String, dynamic>.from(j['preferences']) : j;
    return AffiliateSettings(
      defaultPayoutMethod: prefs['defaultPayoutMethod'] ?? prefs['paymentMethod'] ?? 'MTN_MOMO',
      emailNotifications: prefs['emailNotifications'] is bool ? prefs['emailNotifications'] as bool : true,
      pushNotifications: prefs['pushNotifications'] is bool ? prefs['pushNotifications'] as bool : true,
      payoutAlerts: prefs['payoutAlerts'] is bool ? prefs['payoutAlerts'] as bool : true,
      marketingEmails: prefs['marketingEmails'] is bool ? prefs['marketingEmails'] as bool : false,
      language: prefs['language'] ?? 'English',
      themeMode: prefs['themeMode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'preferences': {
          'defaultPayoutMethod': defaultPayoutMethod,
          'emailNotifications': emailNotifications,
          'pushNotifications': pushNotifications,
          'payoutAlerts': payoutAlerts,
          'marketingEmails': marketingEmails,
          'language': language,
          if (themeMode != null) 'themeMode': themeMode,
        },
      };

  AffiliateSettings copyWith({
    String? defaultPayoutMethod,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? payoutAlerts,
    bool? marketingEmails,
    String? language,
    String? themeMode,
    bool clearThemeMode = false,
  }) =>
      AffiliateSettings(
        defaultPayoutMethod: defaultPayoutMethod ?? this.defaultPayoutMethod,
        emailNotifications: emailNotifications ?? this.emailNotifications,
        pushNotifications: pushNotifications ?? this.pushNotifications,
        payoutAlerts: payoutAlerts ?? this.payoutAlerts,
        marketingEmails: marketingEmails ?? this.marketingEmails,
        language: language ?? this.language,
        themeMode: clearThemeMode ? null : (themeMode ?? this.themeMode),
      );
}

/// Payment channels offered on the payout form, matching the frontend
/// `/affiliates/payouts/request` payload.
const kAffiliatePayoutMethods = <({String value, String label})>[
  (value: 'MTN_MOMO', label: 'MTN MoMo'),
  (value: 'AIRTEL_MONEY', label: 'Airtel Money'),
  (value: 'BANK_TRANSFER', label: 'Bank account'),
];

/// Minimum withdrawal enforced by the backend (`MINIMUM_PAYOUT_RWF`).
const double kAffiliateMinimumPayout = 10000;

/// Composes the storefront deep link for a referral code.
String affiliateShareUrl(String code) => '$kMarketplaceOrigin/shop?ref=$code';

/// Public web origin used to build shareable affiliate links.
String get kMarketplaceOrigin {
  const configured = String.fromEnvironment('WEB_ORIGIN', defaultValue: 'https://mvec.rw');
  return configured;
}

/// Returns the payout method with a friendly label.
String payoutMethodLabel(String? value) {
  for (final m in kAffiliatePayoutMethods) {
    if (m.value == value) return m.label;
  }
  return '—';
}
