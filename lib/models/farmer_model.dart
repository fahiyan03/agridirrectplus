// farmer_model.dart
// UserModel extend করে farmer-specific fields যোগ করা হয়েছে

class FarmerModel {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? address;
  final String? profileImageUrl;
  final bool isBanned;

  // Farmer-specific stats (join থেকে আসে)
  final int totalListings;
  final int totalOrders;
  final double avgRating;
  final int totalReviews;

  FarmerModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.address,
    this.profileImageUrl,
    this.isBanned = false,
    this.totalListings = 0,
    this.totalOrders = 0,
    this.avgRating = 0.0,
    this.totalReviews = 0,
  });

  factory FarmerModel.fromMap(Map<String, dynamic> map) {
    return FarmerModel(
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

  String get ratingText => avgRating.toStringAsFixed(1);
}