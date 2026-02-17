class Quotation {
  final String? id;
  final String quotationNumber;
  final String clientName;
  final String? clientEmail;
  final double amount;
  final String status;
  final DateTime validUntil;
  final String? description;
  final List<QuotationItem>? items;
  final String? location;
  final String? notes;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Quotation({
    this.id,
    required this.quotationNumber,
    required this.clientName,
    this.clientEmail,
    required this.amount,
    required this.status,
    required this.validUntil,
    this.description,
    this.items,
    this.location,
    this.notes,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isExpired => validUntil.isBefore(DateTime.now());

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['_id'] ?? json['id'],
      quotationNumber: json['quotationNumber'] ?? '',
      clientName: json['clientName'] ?? '',
      clientEmail: json['clientEmail'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'draft',
      validUntil: DateTime.parse(json['validUntil'] ?? DateTime.now().toIso8601String()),
      description: json['description'],
      items: json['items'] != null
          ? List<QuotationItem>.from((json['items'] as List).map((x) => QuotationItem.fromJson(x)))
          : null,
      location: json['location'],
      notes: json['notes'],
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quotationNumber': quotationNumber,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'amount': amount,
      'status': status,
      'validUntil': validUntil.toIso8601String(),
      'description': description,
      'items': items?.map((x) => x.toJson()).toList(),
      'location': location,
      'notes': notes,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class QuotationItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  QuotationItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      description: json['description'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }
}
