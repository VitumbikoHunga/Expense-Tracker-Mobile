class Category {
  final String? id;
  final String name;
  final String? icon;
  final String? color;
  final String userId;
  final DateTime? createdAt;

  Category({
    this.id,
    required this.name,
    this.icon,
    this.color,
    required this.userId,
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      userId: json['userId'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
