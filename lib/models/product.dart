class Product {
  final int? id;
  final String name;
  final double price;
  final String? unit;
  final String? notes;
  final int? categoryId;
  final String? categoryName;
  final DateTime createdAt;
  final bool isActive;

  Product({
    this.id,
    required this.name,
    required this.price,
    this.unit,
    this.notes,
    this.categoryId,
    this.categoryName,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Product to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'unit': unit,
      'notes': notes,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  // Create Product from Map (database query result)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String?,
      notes: map['notes'] as String?,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  // Copy with method for updating fields
  Product copyWith({
    int? id,
    String? name,
    double? price,
    String? unit,
    String? notes,
    int? categoryId,
    String? categoryName,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
