class Category {
  final int? id;
  final String name;
  final String? description;
  final int? iconCode;
  final String? color;
  final DateTime createdAt;
  final bool isActive;

  Category({
    this.id,
    required this.name,
    this.description,
    this.iconCode,
    this.color,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Category to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_code': iconCode,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  // Create Category from Map (database query result)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      iconCode: map['icon_code'] as int?,
      color: map['color'] as String?,
      createdAt:
          map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : DateTime.now(),
      isActive:
          map['is_active'] != null ? (map['is_active'] as int) == 1 : true,
    );
  }

  // Copy with method for updating fields
  Category copyWith({
    int? id,
    String? name,
    String? description,
    int? iconCode,
    String? color,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCode: iconCode ?? this.iconCode,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
