class Budget {
  final String? id;
  final String category;
  final double limit;
  final double spent;
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Budget({
    this.id,
    required this.category,
    required this.limit,
    required this.spent,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  double get remainingBudget => limit - spent;
  double get percentageUsed => spent / limit;
  bool get isExceeded => spent > limit;

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['_id'] ?? json['id'],
      category: json['category'] ?? '',
      limit: (json['limit'] ?? 0.0).toDouble(),
      spent: (json['spent'] ?? 0.0).toDouble(),
      period: json['period'] ?? 'monthly',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'limit': limit,
      'spent': spent,
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
