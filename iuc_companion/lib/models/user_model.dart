class UserModel {
  final String id;
  final String name;
  final String studentNo;
  final String department;
  final String token; // API yetkilendirme anahtarı

  UserModel({required this.id, required this.name, required this.studentNo, required this.department, required this.token});
}