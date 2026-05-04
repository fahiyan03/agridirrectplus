// buyer_model.dart

class BuyerModel {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? address;
  final String? profileImageUrl;
  final bool isBanned;

  // Buyer-specific stats
  final int totalOrders;

  BuyerModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.address,
    this.profileImageUrl,
    this.isBanned = false,
    this.totalOrders = 0,
  });

  factory BuyerModel.fromMap(Map<String, dynamic> map) {
    return BuyerModel(
      id:              map['id'] ?? '',
      fullName:        map['full_name'] ?? '',
      email:           map['email'],
      phone:           map['phone'],
      address:         map['address'],
      profileImageUrl: map['profile_image_url'],
      isBanned:        map['is_banned'] ?? false,
    );
  }

  String get initials =>
      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'ক';
}