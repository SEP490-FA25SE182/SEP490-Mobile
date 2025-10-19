class User {
  final String id;
  final String email;
  final String name;

  const User({required this.id, required this.email, required this.name});

  factory User.fromJson(Map<String, dynamic> j) =>
      User(id: j['id'] ?? '', email: j['email'] ?? '', name: j['name'] ?? '');
}
