class Address {
  final String id;
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String region;
  final bool isDefault;

  Address({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.region,
    this.isDefault = false,
  });
}