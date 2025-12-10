class TransactionLine {
  final int? id;
  final int transactionId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? notes;
  final DateTime? createdAt;

  // For display purposes - not stored in database
  final String? productName;
  final String? productUnit;

  TransactionLine({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.notes,
    DateTime? createdAt,
    this.productName,
    this.productUnit,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert TransactionLine to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Create TransactionLine from Map (database query result)
  factory TransactionLine.fromMap(Map<String, dynamic> map) {
    return TransactionLine(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      lineTotal: (map['line_total'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt:
          map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : null,
      productName: map['product_name'] as String?,
      productUnit: map['product_unit'] as String?,
    );
  }

  // Copy with method for updating fields
  TransactionLine copyWith({
    int? id,
    int? transactionId,
    int? productId,
    int? quantity,
    double? unitPrice,
    double? lineTotal,
    String? notes,
    DateTime? createdAt,
    String? productName,
    String? productUnit,
  }) {
    return TransactionLine(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      productName: productName ?? this.productName,
      productUnit: productUnit ?? this.productUnit,
    );
  }
}
