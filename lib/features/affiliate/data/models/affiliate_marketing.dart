import 'affiliate_earnings.dart';
import 'affiliate_profile.dart';
import '../../../../models/user.dart';

/// A referral link: the unit the affiliate shares and the unit the backend
/// attributes clicks, registrations and conversions to.
class AffiliateLink {
  const AffiliateLink({
    this.id,
    this.code,
    this.label,
    this.productId,
    this.productName,
    this.campaignId,
    this.campaignName,
    this.clicks = 0,
    this.registrations = 0,
    this.conversions = 0,
    this.commission = 0,
    this.revenue = 0,
    this.isActive = true,
    this.createdAt,
    this.lastClickedAt,
  });

  final String? id;

  /// The referral code embedded in the shared URL.
  final String? code;

  /// Human label the affiliate gave the link ("TikTok bio", ...).
  final String? label;
  final String? productId;
  final String? productName;
  final String? campaignId;
  final String? campaignName;
  final int clicks;
  final int registrations;
  final int conversions;
  final num commission;
  final num revenue;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastClickedAt;

  factory AffiliateLink.fromJson(Map<String, dynamic> j) {
    final product = j['targetProduct'] ?? j['product'];
    final campaign = j['campaign'];
    return AffiliateLink(
      id: j['_id'] ?? j['id'] ?? j['linkId'],
      code: j['affiliateCode'] ?? j['code'] ?? j['referralCode'],
      label: j['label'] ?? j['name'] ?? j['title'],
      productId: product is Map ? (product['_id'] ?? product['id'])?.toString() : product?.toString() ?? j['targetProductId']?.toString(),
      productName: product is Map ? (product['name'] ?? product['title'])?.toString() : null,
      campaignId: campaign is Map ? (campaign['_id'] ?? campaign['id'])?.toString() : campaign?.toString() ?? j['campaignId']?.toString(),
      campaignName: campaign is Map ? (campaign['name'] ?? campaign['title'])?.toString() : null,
      clicks: j['clickCount'] is num ? (j['clickCount'] as num).toInt() : int.tryParse('${j['clickCount'] ?? 0}') ?? 0,
      registrations: j['registrationCount'] is num ? (j['registrationCount'] as num).toInt() : int.tryParse('${j['registrationCount'] ?? 0}') ?? 0,
      conversions: j['conversionCount'] is num ? (j['conversionCount'] as num).toInt() : int.tryParse('${j['conversionCount'] ?? 0}') ?? 0,
      commission: numOrNull(j['commissionEarned'] ?? j['commission'] ?? j['earnings']) ?? 0,
      revenue: numOrNull(j['revenue'] ?? j['orderVolume']) ?? 0,
      isActive: j['isActive'] is bool ? j['isActive'] as bool : (j['status']?.toString().toUpperCase() ?? 'ACTIVE') != 'INACTIVE',
      createdAt: parseDate(j['createdAt']),
      lastClickedAt: parseDate(j['lastClickedAt']),
    );
  }

  /// What the link points at, in the wording the frontend uses.
  String get target => productName ?? campaignName ?? label ?? 'General link';

  String get shareUrl => affiliateLinkUrl(code ?? '');

  double get conversionRate => clicks == 0 ? 0 : (conversions / clicks) * 100;

  num get averageCommission => conversions == 0 ? 0 : commission / conversions;

  AffiliateLink copyWith({String? label, bool? isActive, int? clicks, int? registrations, int? conversions, num? commission, num? revenue, DateTime? lastClickedAt}) =>
      AffiliateLink(
        id: id,
        code: code,
        label: label ?? this.label,
        productId: productId,
        productName: productName,
        campaignId: campaignId,
        campaignName: campaignName,
        clicks: clicks ?? this.clicks,
        registrations: registrations ?? this.registrations,
        conversions: conversions ?? this.conversions,
        commission: commission ?? this.commission,
        revenue: revenue ?? this.revenue,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        lastClickedAt: lastClickedAt ?? this.lastClickedAt,
      );
}

/// Builds the shareable storefront deep link for a referral code.
String affiliateLinkUrl(String code) => affiliateShareUrl(code);

/// A promotional campaign the affiliate can join and share.
class AffiliateCampaign {
  const AffiliateCampaign({
    this.id,
    this.code,
    this.name,
    this.description,
    this.banner,
    this.commissionRate,
    this.status,
    this.startsAt,
    this.endsAt,
    this.productCount = 0,
    this.joined = false,
    this.clicks = 0,
    this.conversions = 0,
    this.earnings = 0,
  });

  final String? id;
  final String? code;
  final String? name;
  final String? description;
  final String? banner;
  final num? commissionRate;
  final String? status;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int productCount;
  final bool joined;
  final int clicks;
  final int conversions;
  final num earnings;

  factory AffiliateCampaign.fromJson(Map<String, dynamic> j) => AffiliateCampaign(
        id: j['_id'] ?? j['id'] ?? j['campaignId'],
        code: j['campaignCode'] ?? j['code'],
        name: j['name'] ?? j['title'],
        description: j['description'] ?? j['summary'],
        banner: j['banner'] ?? j['image'],
        commissionRate: (j['commissionRate'] ?? j['rate'] ?? j['commission']) as num?,
        status: (j['status'] ?? 'ACTIVE').toString().toUpperCase(),
        startsAt: parseDate(j['startsAt'] ?? j['startDate']),
        endsAt: parseDate(j['endsAt'] ?? j['endDate']),
        productCount: j['productCount'] is num ? (j['productCount'] as num).toInt() : int.tryParse('${j['productCount'] ?? 0}') ?? 0,
        joined: j['joined'] == true || j['isJoined'] == true || j['affiliateJoined'] == true,
        clicks: j['clickCount'] is num ? (j['clickCount'] as num).toInt() : int.tryParse('${j['clickCount'] ?? 0}') ?? 0,
        conversions: j['conversionCount'] is num ? (j['conversionCount'] as num).toInt() : int.tryParse('${j['conversionCount'] ?? 0}') ?? 0,
        earnings: numOrNull(j['earnings'] ?? j['commissionEarned']) ?? 0,
      );

  bool get isLive {
    final now = DateTime.now();
    if (status == 'PAUSED' || status == 'EXPIRED' || status == 'ENDED') return false;
    if (startsAt != null && startsAt!.isAfter(now)) return false;
    if (endsAt != null && endsAt!.isBefore(now)) return false;
    return true;
  }

  int get daysLeft {
    final end = endsAt;
    if (end == null) return 0;
    return end.difference(DateTime.now()).inDays.clamp(0, 9999);
  }
}

/// A product the affiliate can promote. Uses the marketplace product model so
/// images, price and vendor render exactly like the storefront.
class PromotableProduct {
  const PromotableProduct({
    this.id,
    this.name,
    this.price,
    this.stock,
    this.vendor,
    this.category,
    this.image,
    this.rating,
    this.referralCode,
    this.campaignId,
  });

  final String? id;
  final String? name;
  final num? price;
  final int? stock;
  final String? vendor;
  final String? category;
  final String? image;
  final double? rating;

  /// Non-null when a link already exists for this product.
  final String? referralCode;
  final String? campaignId;

  factory PromotableProduct.fromJson(Map<String, dynamic> j) {
    final vendor = j['vendor'];
    final category = j['category'];
    final media = j['media'];
    final image = media is Map ? media['mainImage']?.toString() : (j['image'] ?? j['thumbnail'])?.toString();
    return PromotableProduct(
      id: j['_id'] ?? j['id'],
      name: j['name'] ?? j['title'],
      price: (j['price'] ?? j['salePrice'] ?? j['basePrice']) as num?,
      stock: j['stockQuantity'] is int ? j['stockQuantity'] : (j['stock'] is int ? j['stock'] : null),
      vendor: vendor is Map ? (vendor['name'] ?? vendor['businessName'] ?? vendor['_id'])?.toString() : vendor?.toString(),
      category: category is Map ? (category['name'] ?? category['_id'])?.toString() : category?.toString(),
      image: image,
      rating: ((j['rating'] ?? j['averageRating']) as num?)?.toDouble(),
      referralCode: j['affiliateCode'] ?? j['referralCode'],
      campaignId: j['campaignId']?.toString(),
    );
  }

  bool get hasLink => referralCode != null && referralCode!.isNotEmpty;

  String get display => name ?? 'Unnamed product';
}

/// Affiliate-scoped notification (commission released, payout paid, campaign
/// starting, verification decision...).
class AffiliateNotification {
  const AffiliateNotification({
    this.id,
    this.type,
    this.title,
    this.message,
    this.isRead = false,
    this.amount,
    this.link,
    this.createdAt,
  });

  final String? id;

  /// `COMMISSION`, `PAYOUT`, `CAMPAIGN`, `VERIFICATION` or `SYSTEM`.
  final String? type;
  final String? title;
  final String? message;
  final bool isRead;
  final num? amount;
  final String? link;
  final DateTime? createdAt;

  factory AffiliateNotification.fromJson(Map<String, dynamic> j) => AffiliateNotification(
        id: j['_id'] ?? j['id'],
        type: (j['type'] ?? j['category'] ?? 'SYSTEM').toString().toUpperCase(),
        title: j['title'] ?? j['subject'] ?? j['type'] ?? 'Update',
        message: j['message'] ?? j['body'] ?? j['description'],
        isRead: j['read'] == true || (j['status']?.toString().toUpperCase() ?? 'UNREAD') == 'READ',
        amount: (j['amount']) as num?,
        link: j['link'] ?? j['actionUrl'],
        createdAt: parseDate(j['createdAt'] ?? j['created_at']),
      );

  AffiliateNotification copyWith({bool? isRead}) => AffiliateNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        isRead: isRead ?? this.isRead,
        amount: amount,
        link: link,
        createdAt: createdAt,
      );
}

/// Everything the affiliate dashboard shows in one payload, so the overview
/// renders from a single request (and a single mock map in demo mode).
class AffiliateOverview {
  const AffiliateOverview({
    this.clicks = 0,
    this.registrations = 0,
    this.conversions = 0,
    this.wallet = const AffiliateWallet(),
    this.stats = const AffiliateStats(),
    this.activeLinks = 0,
  });

  final int clicks;
  final int registrations;
  final int conversions;
  final AffiliateWallet wallet;
  final AffiliateStats stats;
  final int activeLinks;

  factory AffiliateOverview.fromJson(Map<String, dynamic> j) {
    final wallet = j['wallet'];
    final stats = j['stats'];
    return AffiliateOverview(
      clicks: j['clicks'] is num ? (j['clicks'] as num).toInt() : int.tryParse('${j['clicks'] ?? 0}') ?? 0,
      registrations: j['registrations'] is num ? (j['registrations'] as num).toInt() : int.tryParse('${j['registrations'] ?? 0}') ?? 0,
      conversions: j['conversions'] is num ? (j['conversions'] as num).toInt() : int.tryParse('${j['conversions'] ?? 0}') ?? 0,
      wallet: AffiliateWallet.fromJson(wallet is Map ? Map<String, dynamic>.from(wallet) : const {}),
      stats: AffiliateStats.fromJson(stats is Map ? Map<String, dynamic>.from(stats) : const {}),
      activeLinks: j['activeLinks'] is num ? (j['activeLinks'] as num).toInt() : int.tryParse('${j['activeLinks'] ?? 0}') ?? 0,
    );
  }
}
