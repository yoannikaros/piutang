class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? notes;
  final DateTime createdAt;
  final bool isActive;
  
  // Computed field - will be set when loading from database with joins
  double totalDebt;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.notes,
    DateTime? createdAt,
    this.isActive = true,
    this.totalDebt = 0.0,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Customer to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  // Create Customer from Map (database query result)
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isActive: (map['is_active'] as int) == 1,
      totalDebt: (map['total_debt'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Copy with method for updating fields
  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? notes,
    DateTime? createdAt,
    bool? isActive,
    double? totalDebt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      totalDebt: totalDebt ?? this.totalDebt,
    );
  }
}
