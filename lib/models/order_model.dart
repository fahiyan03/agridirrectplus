class OrderModel {
  final String id;
  final String buyerId;
  final String farmerId;
  final String productId;
  final double quantity;
  final double totalPrice;
  final String status;
  final String? deliveryAddress;
  final String? notes;
  final DateTime createdAt;

  // Joined data
  final String? buyerName;
  final String? buyerPhone;
  final String? farmerName;
  final String? productTitle;
  final String? productUnit;
  final double? productPrice;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.farmerId,
    required this.productId,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    this.deliveryAddress,
    this.notes,
    required this.createdAt,
    this.buyerName,
    this.buyerPhone,
    this.farmerName,
    this.productTitle,
    this.productUnit,
    this.productPrice,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final buyer   = map['buyer']   as Map<String, dynamic>?;
    final farmer  = map['farmer']  as Map<String, dynamic>?;
    final product = map['product'] as Map<String, dynamic>?;

    return OrderModel(
      id:              map['id'] ?? '',
      buyerId:         map['buyer_id'] ?? '',
      farmerId:        map['farmer_id'] ?? '',
      productId:       map['product_id'] ?? '',
      quantity:        (map['quantity'] as num).toDouble(),
      totalPrice:      (map['total_price'] as num).toDouble(),
      status:          map['status'] ?? 'pending',
      deliveryAddress: map['delivery_address'],
      notes:           map['notes'],
      createdAt:       map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      buyerName:       buyer?['full_name'],
      buyerPhone:      buyer?['phone'],
      farmerName:      farmer?['full_name'],
      productTitle:    product?['title'],
      productUnit:     product?['unit'],
      productPrice:    product?['price'] != null
          ? (product!['price'] as num).toDouble()
          : null,
    );
  }

  bool get isPending   => status == 'pending';
  bool get isAccepted  => status == 'accepted';
  bool get isDelivered => status == 'delivered';
  bool get isRejected  => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
}