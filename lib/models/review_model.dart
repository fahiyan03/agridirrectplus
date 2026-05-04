class ReviewModel {
  final String id;
  final String buyerId;
  final String farmerId;
  final String orderId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  // Joined data
  final String? buyerName;
  final String? buyerImageUrl;

  ReviewModel({
    required this.id,
    required this.buyerId,
    required this.farmerId,
    required this.orderId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.buyerName,
    this.buyerImageUrl,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    final buyer = map['buyer'] as Map<String, dynamic>?;
    return ReviewModel(
      id:           map['id'] ?? '',
      buyerId:      map['buyer_id'] ?? '',
      farmerId:     map['farmer_id'] ?? '',
      orderId:      map['order_id'] ?? '',
      rating:       map['rating'] ?? 0,
      comment:      map['comment'],
      createdAt:    map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      buyerName:    buyer?['full_name'],
      buyerImageUrl: buyer?['profile_image_url'],
    );
  }

  bool get hasComment => comment != null && comment!.isNotEmpty;
}
