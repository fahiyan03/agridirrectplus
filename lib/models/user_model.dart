class UserModel {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final String? profileImageUrl;
  final String? address;
  final bool isBanned;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.profileImageUrl,
    this.address,
    this.isBanned = false,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id:               map['id'] ?? '',
      fullName:         map['full_name'] ?? '',
      email:            map['email'],
      phone:            map['phone'],
      role:             map['role'] ?? 'buyer',
      profileImageUrl:  map['profile_image_url'],
      address:          map['address'],
      isBanned:         map['is_banned'] ?? false,
      createdAt:        map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id':                 id,
      'full_name':          fullName,
      'email':              email,
      'phone':              phone,
      'role':               role,
      'profile_image_url':  profileImageUrl,
      'address':            address,
      'is_banned':          isBanned,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? profileImageUrl,
    String? address,
    bool? isBanned,
  }) {
    return UserModel(
      id:               id,
      fullName:         fullName ?? this.fullName,
      email:            email,
      phone:            phone ?? this.phone,
      role:             role,
      profileImageUrl:  profileImageUrl ?? this.profileImageUrl,
      address:          address ?? this.address,
      isBanned:         isBanned ?? this.isBanned,
      createdAt:        createdAt,
    );
  }

  bool get isFarmer => role == 'farmer';
  bool get isBuyer  => role == 'buyer';
  bool get isAdmin  => role == 'admin';
}