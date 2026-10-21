/// Вошедший пользователь — как его отдаёт сервер в ответе login/register.
class AppUser {
  final int id;
  final String email;
  final String name;

  const AppUser({required this.id, required this.email, required this.name});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] as int,
    email: j['email'] as String,
    name: j['name'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};
}
