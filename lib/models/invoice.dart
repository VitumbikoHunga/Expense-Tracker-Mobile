class Invoice {
  final String? id;
  final String invoiceNumber;
  final String clientName;
  final String? clientEmail;
  final String? budgetId;
  final double amount;
  final String status;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final String? description;
  final List<InvoiceItem>? items;
  final String? imageUrl;
  final String? location;
  final String? notes;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.clientName,
    this.clientEmail,
    this.budgetId,
    required this.amount,
    required this.status,
    required this.invoiceDate,
    required this.dueDate,
    this.description,
    this.items,
    this.imageUrl,
    this.location,
    this.notes,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['_id'] ?? json['id'],
      invoiceNumber: json['invoiceNumber'] ?? '',
      clientName: json['clientName'] ?? '',
      clientEmail: json['clientEmail'],
      budgetId: json['budgetId'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'draft',
      invoiceDate: DateTime.parse(json['invoiceDate'] ?? DateTime.now().toIso8601String()),
      dueDate: DateTime.parse(json['dueDate'] ?? DateTime.now().toIso8601String()),
      description: json['description'],
      items: json['items'] != null
          ? List<InvoiceItem>.from((json['items'] as List).map((x) => InvoiceItem.fromJson(x)))
          : null,
      imageUrl: json['imageUrl'],
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
      'invoiceNumber': invoiceNumber,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'budgetId': budgetId,
      'amount': amount,
      'status': status,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'description': description,
      'items': items?.map((x) => x.toJson()).toList(),
      'imageUrl': imageUrl,
      'location': location,
      'notes': notes,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class InvoiceItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
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
