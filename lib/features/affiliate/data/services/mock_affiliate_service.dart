import 'dart:math';

import '../models/affiliate_earnings.dart';
import '../models/affiliate_marketing.dart';
import '../models/affiliate_profile.dart';
import 'affiliate_service.dart';

/// Local demo implementation of [AffiliateService].
///
/// Every method builds the *same* JSON shape the backend returns and then
/// parses it with the production `fromJson` factories. That keeps the demo
/// path honest: the widgets, parsers and validation rules exercised in demo
/// mode are byte-for-byte the ones that will run against the live API, so
/// switching backends changes nothing above the data layer.
///
/// State is held in memory for the session, so creating links, joining
/// campaigns and requesting payouts all behave like the real thing.
class MockAffiliateService implements AffiliateService {
  MockAffiliateService({this.delay = const Duration(milliseconds: 350)}) {
    _seed();
  }

  /// Simulated latency so loading states behave like production.
  final Duration delay;

  final _rand = Random(20260929);
  final _now = DateTime.now();

  late Map<String, dynamic> _profile;
  late Map<String, dynamic> _wallet;
  late List<Map<String, dynamic>> _links;
  late List<Map<String, dynamic>> _campaigns;
  late List<Map<String, dynamic>> _commissions;
  late List<Map<String, dynamic>> _payouts;
  late List<Map<String, dynamic>> _notifications;
  late Map<String, dynamic> _settings;
  late List<Map<String, dynamic>> _products;

  int _codeCounter = 0;

  @override
  bool get isDemo => true;

  Future<void> _latency() => Future<void>.delayed(delay);

  // ------------------------------------------------------------------
  // Seeding
  // ------------------------------------------------------------------

  void _seed() {
    _profile = {
      '_id': 'aff-1042',
      'affiliateUserId': 'usr-1042',
      'Fullname': 'Aline Uwase',
      'email': 'aline.uwase@mvec.rw',
      'phone': '+250 788 100 005',
      'displayName': 'Aline Deals',
      'bio': 'Kigali lifestyle creator sharing honest finds from the MVEC marketplace.',
      'website': 'https://aline-deals.rw',
      'country': 'Rwanda',
      'affiliateCode': 'AFF-1042-9F3C1A',
      'referralUrl': affiliateShareUrl('AFF-1042-9F3C1A'),
      'status': 'ACTIVE',
      'verificationStatus': 'VERIFIED',
      'commissionRate': 8,
      'paymentMethod': 'MTN_MOMO',
      'accountName': 'Aline Uwase',
      'createdAt': _iso(_now.subtract(const Duration(days: 214))),
      'verifiedAt': _iso(_now.subtract(const Duration(days: 209))),
    };

    _products = _seedProducts();
    _links = _seedLinks();
    _campaigns = _seedCampaigns();
    _wallet = _seedWallet();
    _commissions = _seedCommissions();
    _payouts = _seedPayouts();
    _notifications = _seedNotifications();
    _settings = const {
      'preferences': {
        'defaultPayoutMethod': 'MTN_MOMO',
        'emailNotifications': true,
        'pushNotifications': true,
        'payoutAlerts': true,
        'marketingEmails': false,
        'language': 'English',
      },
    };
  }

  List<Map<String, dynamic>> _seedProducts() => [
        {
          '_id': 'prd-101',
          'name': 'Wireless Over-Ear Headphones',
          'price': 189000,
          'stockQuantity': 42,
          'rating': 4.8,
          'media': {'mainImage': 'https://picsum.photos/seed/aff-headphones/400'},
          'vendor': {'name': 'TechZone'},
          'category': {'name': 'Electronics'},
        },
        {
          '_id': 'prd-102',
          'name': 'Slim Fit Denim Jacket',
          'price': 79000,
          'stockQuantity': 120,
          'rating': 4.6,
          'media': {'mainImage': 'https://picsum.photos/seed/aff-denim/400'},
          'vendor': {'name': 'UrbanWear'},
          'category': {'name': 'Fashion'},
        },
        {
          '_id': 'prd-103',
          'name': 'Ceramic Planter Set',
          'price': 34500,
          'stockQuantity': 8,
          'rating': 4.9,
          'media': {'mainImage': 'https://picsum.photos/seed/aff-planter/400'},
          'vendor': {'name': 'GreenThumb'},
          'category': {'name': 'Home & Garden'},
        },
        {
          '_id': 'prd-104',
          'name': 'Smart Watch Series 5',
          'price': 149000,
          'stockQuantity': 3,
          'rating': 4.7,
          'media': {'mainImage': 'https://picsum.photos/seed/aff-watch/400'},
          'vendor': {'name': 'Chrono'},
          'category': {'name': 'Electronics'},
        },
        {
          '_id': 'prd-105',
          'name': 'Vitamin C Brightening Serum',
          'price': 24900,
          'stockQuantity': 75,
          'rating': 4.5,
          'media': {'mainImage': 'https://picsum.photos/seed/aff-serum/400'},
          'vendor': {'name': 'GlowNest'},
          'category': {'name': 'Beauty'},
        },
        {
          '_id': 'prd-106',
          'name': 'Cloudstep Running Shoes',
          'price': 95000,
          'stockQuantity': 210,
          'rating': 4.4,
          'media': {'mainImage': 'https://picsum.photos/seed/aff-shoes/400'},
          'vendor': {'name': 'StrideX'},
          'category': {'name': 'Sports'},
        },
        {
          '_id': 'prd-107',
          'name': 'Stainless Steel Water Bottle',
          'price': 22500,
          'stockQuantity': 300,
          'rating': 4.7,
          'media': {'mainImage': 'https://picsum.photos/seed/aff-bottle/400'},
          'vendor': {'name': 'Hydra'},
          'category': {'name': 'Sports'},
        },
        {
          '_id': 'prd-108',
          'name': 'Linen Summer Dress',
          'price': 64000,
          'stockQuantity': 45,
          'rating': 4.5,
          'media': {'mainImage': 'https://picsum.photos/seed/aff-dress/400'},
          'vendor': {'name': 'UrbanWear'},
          'category': {'name': 'Fashion'},
        },
        {
          '_id': 'prd-109',
          'name': 'Gaming Mechanical Keyboard',
          'price': 119000,
          'stockQuantity': 30,
          'rating': 4.8,
          'media': {'mainImage': 'https://picsum.photos/seed/aff-keyboard/400'},
          'vendor': {'name': 'TechZone'},
          'category': {'name': 'Electronics'},
        },
        {
          '_id': 'prd-110',
          'name': 'Organic Cotton Throw Blanket',
          'price': 29000,
          'stockQuantity': 95,
          'rating': 4.7,
          'media': {'mainImage': 'https://picsum.photos/seed/aff-blanket/400'},
          'vendor': {'name': 'Nestora'},
          'category': {'name': 'Home & Garden'},
        },
      ];

  List<Map<String, dynamic>> _seedLinks() => [
        {
          '_id': 'lnk-1',
          'affiliateCode': 'AFF-1042-9F3C1A',
          'label': 'Instagram bio',
          'targetProduct': {'_id': 'prd-101', 'name': 'Wireless Over-Ear Headphones'},
          'clickCount': 1284,
          'registrationCount': 96,
          'conversionCount': 74,
          'commissionEarned': 1122400,
          'revenue': 14026000,
          'isActive': true,
          'createdAt': _iso(_now.subtract(const Duration(days: 210))),
          'lastClickedAt': _iso(_now.subtract(const Duration(hours: 3))),
        },
        {
          '_id': 'lnk-2',
          'affiliateCode': 'AFF-1042-77B2E0',
          'label': 'TikTok weekly',
          'targetProduct': {'_id': 'prd-104', 'name': 'Smart Watch Series 5'},
          'campaignId': 'cmp-1',
          'clickCount': 862,
          'registrationCount': 61,
          'conversionCount': 38,
          'commissionEarned': 452640,
          'revenue': 5662000,
          'isActive': true,
          'createdAt': _iso(_now.subtract(const Duration(days: 96))),
          'lastClickedAt': _iso(_now.subtract(const Duration(hours: 9))),
        },
        {
          '_id': 'lnk-3',
          'affiliateCode': 'AFF-1042-4D5A11',
          'label': 'WhatsApp broadcast',
          'targetProduct': {'_id': 'prd-109', 'name': 'Gaming Mechanical Keyboard'},
          'clickCount': 417,
          'registrationCount': 34,
          'conversionCount': 19,
          'commissionEarned': 226130,
          'revenue': 2261000,
          'isActive': true,
          'createdAt': _iso(_now.subtract(const Duration(days: 61))),
          'lastClickedAt': _iso(_now.subtract(const Duration(days: 1, hours: 4))),
        },
        {
          '_id': 'lnk-4',
          'affiliateCode': 'AFF-1042-C0FFEE',
          'label': 'Blog review — home',
          'targetProduct': {'_id': 'prd-103', 'name': 'Ceramic Planter Set'},
          'clickCount': 233,
          'registrationCount': 12,
          'conversionCount': 7,
          'commissionEarned': 24045,
          'revenue': 241500,
          'isActive': true,
          'createdAt': _iso(_now.subtract(const Duration(days: 40))),
          'lastClickedAt': _iso(_now.subtract(const Duration(days: 2))),
        },
        {
          '_id': 'lnk-5',
          'affiliateCode': 'AFF-1042-11AA22',
          'label': 'Old giveaway link',
          'targetProduct': {'_id': 'prd-106', 'name': 'Cloudstep Running Shoes'},
          'clickCount': 76,
          'registrationCount': 3,
          'conversionCount': 1,
          'commissionEarned': 7600,
          'revenue': 95000,
          'isActive': false,
          'createdAt': _iso(_now.subtract(const Duration(days: 150))),
          'lastClickedAt': _iso(_now.subtract(const Duration(days: 68))),
        },
      ];

  List<Map<String, dynamic>> _seedCampaigns() => [
        {
          '_id': 'cmp-1',
          'campaignCode': 'CAMP-BACK2SCHOOL',
          'name': 'Back to School 2026',
          'description': 'Boost stationery, bags and electronics ahead of the new term. 10% commission on every completed order.',
          'banner': 'https://picsum.photos/seed/camp-school/720/300',
          'commissionRate': 10,
          'status': 'ACTIVE',
          'startsAt': _iso(_now.subtract(const Duration(days: 12))),
          'endsAt': _iso(_now.add(const Duration(days: 26))),
          'productCount': 48,
          'affiliateJoined': true,
          'clickCount': 862,
          'conversionCount': 38,
          'earnings': 452640,
        },
        {
          '_id': 'cmp-2',
          'campaignCode': 'CAMP-HOMEDESK',
          'name': 'Home Office Setup',
          'description': 'Everything needed for a productive workspace: chairs, lighting, storage and desk accessories.',
          'banner': 'https://picsum.photos/seed/camp-desk/720/300',
          'commissionRate': 9,
          'status': 'ACTIVE',
          'startsAt': _iso(_now.subtract(const Duration(days: 5))),
          'endsAt': _iso(_now.add(const Duration(days: 55))),
          'productCount': 26,
          'affiliateJoined': false,
        },
        {
          '_id': 'cmp-3',
          'campaignCode': 'CAMP-RAMADAN',
          'name': 'Festive Table Edit',
          'description': 'Cookware, serveware and hosting essentials for the festive season. Ends once stock clears.',
          'banner': 'https://picsum.photos/seed/camp-table/720/300',
          'commissionRate': 12,
          'status': 'ACTIVE',
          'startsAt': _iso(_now.add(const Duration(days: 9))),
          'endsAt': _iso(_now.add(const Duration(days: 70))),
          'productCount': 34,
          'affiliateJoined': false,
        },
        {
          '_id': 'cmp-4',
          'campaignCode': 'CAMP-SUMMER24',
          'name': 'Summer Flash Sale',
          'description': 'Closed — this campaign has ended and no longer accepts new affiliates.',
          'banner': 'https://picsum.photos/seed/camp-summer/720/300',
          'commissionRate': 7,
          'status': 'EXPIRED',
          'startsAt': _iso(_now.subtract(const Duration(days: 190))),
          'endsAt': _iso(_now.subtract(const Duration(days: 150))),
          'productCount': 61,
          'affiliateJoined': true,
        },
      ];

  Map<String, dynamic> _seedWallet() {
    final earned = _sum('commissionEarned');
    final withdrawn = 3200000;
    return {
      'totalEarned': earned,
      'availableBalance': 4820000,
      'pendingBalance': 1185000,
      'totalWithdrawn': withdrawn,
      'currency': 'RWF',
      'minimumPayout': 10000,
      'lastWithdrawal': _iso(_now.subtract(const Duration(days: 19))),
    };
  }

  List<Map<String, dynamic>> _seedCommissions() {
    final rows = <Map<String, dynamic>>[];
    const products = [
      ['prd-101', 'Wireless Over-Ear Headphones', 189000],
      ['prd-104', 'Smart Watch Series 5', 149000],
      ['prd-109', 'Gaming Mechanical Keyboard', 119000],
      ['prd-103', 'Ceramic Planter Set', 34500],
      ['prd-105', 'Vitamin C Brightening Serum', 24900],
      ['prd-106', 'Cloudstep Running Shoes', 95000],
      ['prd-102', 'Slim Fit Denim Jacket', 79000],
      ['prd-107', 'Stainless Steel Water Bottle', 22500],
    ];
    for (var i = 0; i < 26; i++) {
      final p = products[i % products.length];
      final orderTotal = (p[2] as int) * (1 + (i % 3));
      final rate = i % 4 == 0 ? 10 : 8;
      final daysAgo = i * 4 + 1;
      final released = daysAgo > 12;
      final reversed = i == 17;
      rows.add({
        '_id': 'cms-$i',
        'type': 'CONVERSION',
        'status': reversed ? 'REVERSED' : (released ? 'AVAILABLE' : 'PENDING'),
        'product': {'_id': p[0], 'name': p[1]},
        'order': {'orderNumber': 'MVEC-${(4100 + i * 7).toString()}'},
        'affiliateCode': _links[i % 4]['affiliateCode'],
        'orderTotal': orderTotal,
        'commission': reversed ? 0 : (orderTotal * rate / 100).round(),
        'rate': rate,
        'notes': reversed ? 'Buyer returned the item inside the refund window.' : null,
        'createdAt': _iso(_now.subtract(Duration(days: daysAgo))),
        'releasedAt': released && !reversed ? _iso(_now.subtract(Duration(days: daysAgo - 10))) : null,
      });
    }
    return rows;
  }

  List<Map<String, dynamic>> _seedPayouts() => [
        {
          '_id': 'pay-1',
          'payoutNumber': 'PAY-1753000000-4821',
          'amount': 1500000,
          'status': 'COMPLETED',
          'paymentMethod': 'MTN_MOMO',
          'accountName': 'Aline Uwase',
          'phoneNumber': '+250 788 100 005',
          'transactionReference': 'MOMO-TX-99318422',
          'createdAt': _iso(_now.subtract(const Duration(days: 19))),
          'processedAt': _iso(_now.subtract(const Duration(days: 18))),
        },
        {
          '_id': 'pay-2',
          'payoutNumber': 'PAY-1751000000-1190',
          'amount': 1700000,
          'status': 'COMPLETED',
          'paymentMethod': 'MTN_MOMO',
          'accountName': 'Aline Uwase',
          'phoneNumber': '+250 788 100 005',
          'transactionReference': 'MOMO-TX-99201455',
          'createdAt': _iso(_now.subtract(const Duration(days: 47))),
          'processedAt': _iso(_now.subtract(const Duration(days: 46))),
        },
        {
          '_id': 'pay-3',
          'payoutNumber': 'PAY-1755000000-7732',
          'amount': 900000,
          'status': 'PROCESSING',
          'paymentMethod': 'AIRTEL_MONEY',
          'accountName': 'Aline Uwase',
          'phoneNumber': '+250 782 400 118',
          'createdAt': _iso(_now.subtract(const Duration(days: 3))),
        },
        {
          '_id': 'pay-4',
          'payoutNumber': 'PAY-1748000000-5514',
          'amount': 600000,
          'status': 'REJECTED',
          'paymentMethod': 'BANK_TRANSFER',
          'accountName': 'Aline Uwase',
          'accountNumber': '0001234567',
          'bankName': 'Bank of Kigali',
          'rejectionReason': 'Account name does not match the verified affiliate profile.',
          'createdAt': _iso(_now.subtract(const Duration(days: 88))),
          'processedAt': _iso(_now.subtract(const Duration(days: 86))),
        },
      ];

  List<Map<String, dynamic>> _seedNotifications() => [
        {
          '_id': 'ntf-1',
          'type': 'COMMISSION',
          'title': 'Commission released',
          'message': 'RWF 151,200 from order MVEC-4176 moved into your available balance.',
          'amount': 151200,
          'read': false,
          'link': '/affiliate/earnings',
          'createdAt': _iso(_now.subtract(const Duration(hours: 2))),
        },
        {
          '_id': 'ntf-2',
          'type': 'CAMPAIGN',
          'title': 'Back to School is live',
          'message': 'Commission for the campaign increased to 10%. Your existing links now earn more.',
          'read': false,
          'link': '/affiliate/campaigns',
          'createdAt': _iso(_now.subtract(const Duration(hours: 20))),
        },
        {
          '_id': 'ntf-3',
          'type': 'PAYOUT',
          'title': 'Withdrawal processing',
          'message': 'Your RWF 900,000 Airtel Money withdrawal is being processed.',
          'amount': 900000,
          'read': false,
          'link': '/affiliate/payouts',
          'createdAt': _now.subtract(const Duration(days: 3)),
        },
        {
          '_id': 'ntf-4',
          'type': 'VERIFICATION',
          'title': 'Account verified',
          'message': 'Your identity documents were approved. Payouts are now enabled.',
          'read': true,
          'link': '/affiliate/profile',
          'createdAt': _iso(_now.subtract(const Duration(days: 209))),
        },
        {
          '_id': 'ntf-5',
          'type': 'SYSTEM',
          'title': 'Commission window update',
          'message': 'Pending commission is released 10 days after delivery, once the refund window closes.',
          'read': true,
          'createdAt': _iso(_now.subtract(const Duration(days: 26))),
        },
      ];

  int _sum(String key) {
    var total = 0;
    for (final l in _links) {
      total += (l[key] as num).toInt();
    }
    return total;
  }

  String _iso(DateTime d) => d.toUtc().toIso8601String();

  String _nextCode() {
    _codeCounter++;
    const hex = '0123456789ABCDEF';
    final tail = List.generate(6, (i) => hex[(_rand.nextInt(16) + i * 3) % 16]).join();
    return 'AFF-1042-$tail${_codeCounter % 10}';
  }

  String _payoutNumber() {
    final stamp = _now.millisecondsSinceEpoch + _codeCounter * 1000;
    return 'PAY-$stamp-${1000 + _rand.nextInt(9000)}';
  }

  // ------------------------------------------------------------------
  // Profile & verification
  // ------------------------------------------------------------------

  @override
  Future<AffiliateProfile> fetchProfile() async {
    await _latency();
    return AffiliateProfile.fromJson(_profile);
  }

  @override
  Future<AffiliateProfile> updateProfile(AffiliateProfile draft) async {
    await _latency();
    final patch = draft.toUpdateJson();
    _profile['displayName'] = patch['displayName'] ?? _profile['displayName'];
    _profile['phone'] = patch['phone'] ?? _profile['phone'];
    _profile['bio'] = patch['bio'] ?? _profile['bio'];
    _profile['website'] = patch['website'] ?? _profile['website'];
    _profile['country'] = patch['country'] ?? _profile['country'];
    _profile['paymentMethod'] = patch['paymentMethod'] ?? _profile['paymentMethod'];
    if (patch['accountName'] != null) _profile['accountName'] = patch['accountName'];
    final details = patch['accountDetails'];
    if (details is Map && details['phoneNumber'] != null) {
      _profile['payoutAccountNumber'] = details['phoneNumber'];
    }
    return AffiliateProfile.fromJson(_profile);
  }

  @override
  Future<AffiliateVerification> fetchVerification() async {
    await _latency();
    return AffiliateVerification.fromJson({
      'status': _profile['verificationStatus'],
      'submittedAt': _iso(_now.subtract(const Duration(days: 212))),
      'reviewedAt': _profile['verifiedAt'],
      'notes': 'National ID and business permit verified.',
      'documents': ['National ID', 'Business permit'],
    });
  }

  // ------------------------------------------------------------------
  // Dashboard
  // ------------------------------------------------------------------

  @override
  Future<AffiliateOverview> fetchOverview() async {
    await _latency();
    final stats = _statsPayload('30d');
    return AffiliateOverview.fromJson({
      'clicks': _sum('clickCount'),
      'registrations': _sum('registrationCount'),
      'conversions': _sum('conversionCount'),
      'activeLinks': _links.where((l) => l['isActive'] == true).length,
      'wallet': _wallet,
      'stats': stats,
    });
  }

  // ------------------------------------------------------------------
  // Links
  // ------------------------------------------------------------------

  @override
  Future<List<AffiliateLink>> fetchLinks() async {
    await _latency();
    return _links.map(AffiliateLink.fromJson).toList();
  }

  @override
  Future<AffiliateLink> generateLink({String? productId, String? campaignId, String? label}) async {
    await _latency();
    final product = productId == null
        ? null
        : _products.where((p) => p['_id'] == productId).cast<Map<String, dynamic>?>().firstWhere((_) => true, orElse: () => null);
    final campaign = campaignId == null
        ? null
        : _campaigns.where((c) => c['_id'] == campaignId).cast<Map<String, dynamic>?>().firstWhere((_) => true, orElse: () => null);
    final link = <String, dynamic>{
      '_id': 'lnk-${_links.length + 1}',
      'affiliateCode': _nextCode(),
      'label': label ?? (product?['name'] as String? ?? campaign?['name'] as String? ?? 'General link'),
      if (product != null)
        'targetProduct': {
          '_id': product['_id'],
          'name': product['name'],
        },
      if (campaign != null) 'campaignId': campaign['_id'],
      'clickCount': 0,
      'registrationCount': 0,
      'conversionCount': 0,
      'commissionEarned': 0,
      'revenue': 0,
      'isActive': true,
      'createdAt': _iso(DateTime.now()),
    };
    _links = [link, ..._links];
    if (product != null) product['affiliateCode'] = link['affiliateCode'];
    return AffiliateLink.fromJson(link);
  }

  @override
  Future<AffiliateLink> setLinkActive(String id, bool active) async {
    await _latency();
    final index = _links.indexWhere((l) => l['_id'] == id);
    if (index == -1) throw StateError('Affiliate link not found.');
    _links[index]['isActive'] = active;
    return AffiliateLink.fromJson(_links[index]);
  }

  @override
  Future<void> deleteLink(String id) async {
    await _latency();
    _links.removeWhere((l) => l['_id'] == id);
  }

  // ------------------------------------------------------------------
  // Sharing
  // ------------------------------------------------------------------

  @override
  Future<List<PromotableProduct>> fetchPromotableProducts({String? search, String? campaignId}) async {
    await _latency();
    final codesByProduct = <String, String>{};
    for (final l in _links) {
      final product = l['targetProduct'];
      if (product is Map && product['_id'] != null) {
        codesByProduct[product['_id'].toString()] = l['affiliateCode'] as String;
      }
    }
    var items = _products;
    final term = (search ?? '').trim().toLowerCase();
    if (term.isNotEmpty) {
      items = items.where((p) {
        final haystack = '${p['name']} ${(p['vendor'] as Map)['name']} ${(p['category'] as Map)['name']}'.toLowerCase();
        return haystack.contains(term);
      }).toList();
    }
    return items
        .map((p) => PromotableProduct.fromJson({
              ...p,
              if (codesByProduct[p['_id']] != null) 'affiliateCode': codesByProduct[p['_id']],
              if (campaignId != null) 'campaignId': campaignId,
            }))
        .toList();
  }

  @override
  Future<List<AffiliateCampaign>> fetchCampaigns() async {
    await _latency();
    return _campaigns.map(AffiliateCampaign.fromJson).toList();
  }

  @override
  Future<AffiliateCampaign> joinCampaign(String id) async {
    await _latency();
    final index = _campaigns.indexWhere((c) => c['_id'] == id);
    if (index == -1) throw StateError('Campaign not found.');
    _campaigns[index]['affiliateJoined'] = true;
    return AffiliateCampaign.fromJson(_campaigns[index]);
  }

  // ------------------------------------------------------------------
  // Statistics
  // ------------------------------------------------------------------

  @override
  Future<AffiliateStats> fetchStats({String range = '30d'}) async {
    await _latency();
    return AffiliateStats.fromJson(_statsPayload(range));
  }

  /// Builds a stats payload shaped like `GET /affiliates/stats`.
  Map<String, dynamic> _statsPayload(String range) {
    final days = switch (range) {
      '7d' => 7,
      '90d' => 12,
      '12m' => 12,
      _ => 10,
    };
    final labels = <String>[];
    final clicks = <num>[];
    final registrations = <num>[];
    final conversions = <num>[];
    for (var i = days - 1; i >= 0; i--) {
      final d = _now.subtract(Duration(days: i));
      labels.add('${d.day}/${d.month}');
      final c = 40 + _rand.nextInt(160);
      clicks.add(c);
      registrations.add((c * (0.05 + _rand.nextInt(40) / 1000)).round());
      conversions.add((c * (0.02 + _rand.nextInt(35) / 1000)).round());
    }
    final totals = <String, dynamic>{
      'clicks': _sum('clickCount'),
      'registrations': _sum('registrationCount'),
      'conversions': _sum('conversionCount'),
      'revenue': _links.fold<num>(0, (s, l) => s + (l['revenue'] as num)),
      'commission': _links.fold<num>(0, (s, l) => s + (l['commissionEarned'] as num)),
      'activeLinks': _links.where((l) => l['isActive'] == true).length,
      'labels': labels,
      'clicksSeries': clicks,
      'registrationsSeries': registrations,
      'conversionsSeries': conversions,
      'topLinks': _links.where((l) => l['isActive'] == true).toList()
        ..sort((a, b) => (b['commissionEarned'] as num).compareTo(a['commissionEarned'] as num)),
    };
    return totals;
  }

  // ------------------------------------------------------------------
  // Earnings
  // ------------------------------------------------------------------

  @override
  Future<AffiliateWallet> fetchWallet() async {
    await _latency();
    return AffiliateWallet.fromJson(_wallet);
  }

  @override
  Future<List<AffiliateCommission>> fetchCommissions({String? status}) async {
    await _latency();
    final rows = status == null ? _commissions : _commissions.where((c) => c['status'] == status).toList();
    return rows.map(AffiliateCommission.fromJson).toList();
  }

  // ------------------------------------------------------------------
  // Payouts
  // ------------------------------------------------------------------

  @override
  Future<List<AffiliatePayout>> fetchPayouts() async {
    await _latency();
    return _payouts.map(AffiliatePayout.fromJson).toList();
  }

  @override
  Future<AffiliatePayout> requestPayout({
    required num amount,
    required String paymentMethod,
    required String accountName,
    required String phoneNumber,
    String? bankName,
  }) async {
    await _latency();
    if (amount < 10000) {
      throw StateError('Minimum withdrawal threshold is RWF 10,000.');
    }
    final available = (_wallet['availableBalance'] as num).toDouble();
    if (available < amount) {
      throw StateError('Insufficient available balance for withdrawal.');
    }
    final payout = <String, dynamic>{
      '_id': 'pay-${_payouts.length + 1}',
      'payoutNumber': _payoutNumber(),
      'amount': amount.round(),
      'status': 'PENDING',
      'paymentMethod': paymentMethod,
      'accountName': accountName,
      'phoneNumber': phoneNumber,
      if (bankName != null && bankName.isNotEmpty) 'bankName': bankName,
      'createdAt': _iso(DateTime.now()),
    };
    _wallet['availableBalance'] = (available - amount).round();
    _payouts = [payout, ..._payouts];
    return AffiliatePayout.fromJson(payout);
  }

  // ------------------------------------------------------------------
  // Notifications
  // ------------------------------------------------------------------

  @override
  Future<List<AffiliateNotification>> fetchNotifications() async {
    await _latency();
    return _notifications.map(AffiliateNotification.fromJson).toList();
  }

  @override
  Future<void> markNotificationsRead([String? id]) async {
    await _latency();
    if (id == null) {
      for (final n in _notifications) {
        n['read'] = true;
      }
    } else {
      for (final n in _notifications) {
        if (n['_id'] == id) n['read'] = true;
      }
    }
  }

  // ------------------------------------------------------------------
  // Settings
  // ------------------------------------------------------------------

  @override
  Future<AffiliateSettings> fetchSettings() async {
    await _latency();
    return AffiliateSettings.fromJson(_settings);
  }

  @override
  Future<AffiliateSettings> updateSettings(AffiliateSettings settings) async {
    await _latency();
    _settings = settings.toJson();
    return AffiliateSettings.fromJson(_settings);
  }
}
