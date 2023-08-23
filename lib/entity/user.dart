class User {
  final int id;
  final String username;
  final String nama;

  User({required this.id, required this.username, required this.nama});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user']['id'],
      username: json['user']['username'],
      nama: json['user']['nama'],
    );
  }
}
