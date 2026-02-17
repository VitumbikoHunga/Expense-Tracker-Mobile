class Receipt {
  final String? id;
  final String vendor;
  final String? title;
  final double amount;
  final String category;
  final DateTime date;
  final String? time;
  final String? budgetId;
  final String? invoiceId;
  final int? installments;
  final String? notes;
  final String? imageUrl;
  final String? location;
  final String? paymentMethod;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Receipt({
    this.id,
    required this.vendor,
    this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.time,
    this.budgetId,
    this.invoiceId,
    this.installments,
    this.notes,
    this.imageUrl,
    this.location,
    this.paymentMethod,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['_id'] ?? json['id'],
      vendor: json['vendor'] ?? '',
      title: json['title'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      time: json['time'],
      budgetId: json['budgetId'],
      invoiceId: json['invoiceId'],
      installments: json['installments'],
      notes: json['notes'],
      imageUrl: json['imageUrl'],
      location: json['location'],
      paymentMethod: json['paymentMethod'],
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor': vendor,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'time': time,
      'budgetId': budgetId,
      'invoiceId': invoiceId,
      'installments': installments,
      'notes': notes,
      'imageUrl': imageUrl,
      'location': location,
      'paymentMethod': paymentMethod,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
