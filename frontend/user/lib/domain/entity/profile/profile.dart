class Profile {
  final int id;
  final int userId;
  final String? name;
  final String? phone;
  final String? gender;
  final DateTime? birthday;
  final String? avatar;

  const Profile({
    required this.id,
    required this.userId,
    this.name,
    this.phone,
    this.gender,
    this.birthday,
    this.avatar,
  });
}
