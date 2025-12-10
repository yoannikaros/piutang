import 'transaction_line.dart';

class Transaction {
  final int? id;
  final int customerId;
  final DateTime takenAt;
  final String? notes;
  final bool isReset;
  final DateTime? resetAt;
  
  // Related data
  final List<TransactionLine> lines;

  Transaction({
    this.id,
    required this.customerId,
    DateTime? takenAt,
    this.notes,
    this.isReset = false,
    this.resetAt,
    this.lines = const [],
  }) : takenAt = takenAt ?? DateTime.now();

  // Calculate total from all lines
  double get total {
    return lines.fold(0.0, (sum, line) => sum + line.lineTotal);
  }

  // Convert Transaction to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'taken_at': takenAt.toIso8601String(),
      'notes': notes,
      'is_reset': isReset ? 1 : 0,
      'reset_at': resetAt?.toIso8601String(),
    };
  }

  // Create Transaction from Map (database query result)
  factory Transaction.fromMap(Map<String, dynamic> map, {List<TransactionLine>? lines}) {
    return Transaction(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      takenAt: DateTime.parse(map['taken_at'] as String),
      notes: map['notes'] as String?,
      isReset: (map['is_reset'] as int) == 1,
      resetAt: map['reset_at'] != null ? DateTime.parse(map['reset_at'] as String) : null,
      lines: lines ?? [],
    );
  }

  // Copy with method for updating fields
  Transaction copyWith({
    int? id,
    int? customerId,
    DateTime? takenAt,
    String? notes,
    bool? isReset,
    DateTime? resetAt,
    List<TransactionLine>? lines,
  }) {
    return Transaction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      takenAt: takenAt ?? this.takenAt,
      notes: notes ?? this.notes,
      isReset: isReset ?? this.isReset,
      resetAt: resetAt ?? this.resetAt,
      lines: lines ?? this.lines,
    );
  }
}
