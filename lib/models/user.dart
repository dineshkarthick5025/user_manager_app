class User {
  final int? id;
  final String name;
  final String email;
  final String? phone;
  final String? role;

  User({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
    );
  }
}
