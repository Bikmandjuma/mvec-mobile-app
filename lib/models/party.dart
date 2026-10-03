import 'user.dart';

class PartyRecord {
  PartyRecord({
    this.id,
    this.name,
    this.slug,
    this.email,
    this.phone,
    this.category,
    this.location,
    this.status,
    this.verificationStatus,
    this.rating,
    this.productCount,
    this.products,
    this.orders,
    this.clicks,
    this.earnings,
    this.raw,
  });

  String? id;
  String? name;
  String? slug;
  String? email;
  String? phone;
  String? category;
  String? location;
  String? status;
  String? verificationStatus;
  double? rating;
  int? productCount;
  int? products;
  int? orders;
  int? clicks;
  num? earnings;
  Map<String, dynamic>? raw;

  factory PartyRecord.fromJson(Map<String, dynamic> j) {
    final owner = j['owner'] is Map ? Map<String, dynamic>.from(j['owner']) : null;
    final user = j['user'] is Map ? Map<String, dynamic>.from(j['user']) : null;
    final cats = j['productCategories'] is List
        ? (j['productCategories'] as List).map((e) => e.toString()).toList()
        : null;
    return PartyRecord(
      id: j['_id'] ?? j['id'],
      name: j['businessName'] ??
          j['companyName'] ??
          j['storeName'] ??
          j['name'] ??
          j['fullname'] ??
          owner?['Fullname'] ??
          user?['Fullname'],
      slug: j['slug'],
      email: j['email'] ?? owner?['email'] ?? user?['email'],
      phone: j['phone'] ?? owner?['phone'] ?? user?['phone'],
      category: j['category'] ?? (cats != null && cats.isNotEmpty ? cats.join(', ') : null) ?? j['primaryCategory'],
      location: _str(j['location']) ??
          _str(j['address']) ??
          _str(j['province']) ??
          _str(j['district']),
      status: j['status'],
      verificationStatus: j['verificationStatus'],
      rating: (j['rating'] ?? j['averageRating'])?.toDouble(),
      productCount: _int(j['productCount'] ?? j['productsCount']),
      products: _int(j['products'] ?? j['productCount']),
      orders: _int(j['orders'] ?? j['totalOrders']),
      clicks: _int(j['clicks']),
      earnings: (j['earnings'] ?? j['totalEarnings'] ?? j['commission']) as num?,
      raw: j,
    );
  }

  static int? _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : (v is String ? int.tryParse(v) : null));

  /// Reads a scalar string field. Object/array payloads (e.g. a structured
  /// `address`) are skipped rather than leaking into a `String?`.
  static String? _str(dynamic v) {
    if (v == null || v is Map || v is List) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  String get display => name ?? email ?? 'Unknown';
  String get effectiveStatus {
    if (verificationStatus == 'VERIFIED') return 'VERIFIED';
    return status ?? verificationStatus ?? 'ACTIVE';
  }
}

class ConversationRecord {
  ConversationRecord({this.id, this.subject, this.participants, this.lastMessage, this.unread, this.updatedAt});
  String? id;
  String? subject;
  String? participants;
  String? lastMessage;
  int? unread;
  DateTime? updatedAt;

  factory ConversationRecord.fromJson(Map<String, dynamic> j) {
    final parts = j['participants'];
    return ConversationRecord(
      id: j['_id'] ?? j['id'],
      subject: j['subject'] ?? j['name'],
      participants: parts is List ? parts.map((e) => e is Map ? (e['Fullname'] ?? e['email'] ?? e['_id']) : e.toString()).join(', ') : null,
      lastMessage: j['lastMessage'] ?? j['preview'],
      unread: j['unreadCount'] is int ? j['unreadCount'] : null,
      updatedAt: parseDate(j['updatedAt'] ?? j['lastMessageAt']),
    );
  }
}

class MessageRecord {
  MessageRecord({this.id, this.sender, this.body, this.createdAt, this.mine});
  String? id;
  String? sender;
  String? body;
  DateTime? createdAt;
  bool? mine;

  factory MessageRecord.fromJson(Map<String, dynamic> j, String? myId) {
    final sid = j['sender'] is Map ? j['sender']['_id']?.toString() : j['sender']?.toString();
    return MessageRecord(
      id: j['_id'] ?? j['id'],
      sender: j['sender'] is Map ? (j['sender']['Fullname'] ?? j['sender']['email'])?.toString() : sid,
      body: j['body'] ?? j['text'] ?? j['message'],
      createdAt: parseDate(j['createdAt']),
      mine: myId != null && sid == myId,
    );
  }
}