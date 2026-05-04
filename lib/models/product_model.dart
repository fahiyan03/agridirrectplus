class ProductModel {
  final String id;
  final String farmerId;
  final String title;
  final String? description;
  final double price;
  final String category;
  final int zone;
  final double quantity;
  final String unit;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final bool isAvailable;
  final DateTime createdAt;

  // Joined data
  final String? farmerName;
  final String? farmerAddress;
  final String? farmerImageUrl;

  ProductModel({
    required this.id,
    required this.farmerId,
    required this.title,
    this.description,
    required this.price,
    required this.category,
    required this.zone,
    required this.quantity,
    required this.unit,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.isAvailable = true,
    required this.createdAt,
    this.farmerName,
    this.farmerAddress,
    this.farmerImageUrl,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    final farmer = map['farmer'] as Map<String, dynamic>?;
    return ProductModel(
      id:             map['id'] ?? '',
      farmerId:       map['farmer_id'] ?? '',
      title:          map['title'] ?? '',
      description:    map['description'],
      price:          (map['price'] as num).toDouble(),
      category:       map['category'] ?? '',
      zone:           map['zone'] ?? 1,
      quantity:       (map['quantity'] as num).toDouble(),
      unit:           map['unit'] ?? 'কেজি',
      imageUrl:       map['image_url'],
      latitude:       map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude:      map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      isAvailable:    map['is_available'] ?? true,
      createdAt:      map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      farmerName:     farmer?['full_name'],
      farmerAddress:  farmer?['address'],
      farmerImageUrl: farmer?['profile_image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmer_id':    farmerId,
      'title':        title,
      'description':  description,
      'price':        price,
      'category':     category,
      'zone':         zone,
      'quantity':     quantity,
      'unit':         unit,
      'image_url':    imageUrl,
      'latitude':     latitude,
      'longitude':    longitude,
      'is_available': isAvailable,
    };
  }

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasImage    => imageUrl != null && imageUrl!.isNotEmpty;
}