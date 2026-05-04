class CategoryModel {
  final String id;
  final String name;
  final String nameBn;
  final int? zone;
  final bool isActive;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.nameBn,
    this.zone,
    required this.isActive,
    required this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id:        map['id'] ?? '',
      name:      map['name'] ?? '',
      nameBn:    map['name_bn'] ?? '',
      zone:      map['zone'],
      isActive:  map['is_active'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name':      name,
      'name_bn':   nameBn,
      'zone':      zone,
      'is_active': isActive,
    };
  }
}