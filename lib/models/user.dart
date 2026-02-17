class User {
  final String? id;
  final String name;
  final String email;
  final String? role;
  final String? profilePicture;
  final bool isActive;
  final DateTime? createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    this.role,
    this.profilePicture,
    required this.isActive,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
      profilePicture: json['profilePicture'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'profilePicture': profilePicture,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
