class Department {
  final int id;
  final int facultyId;
  final String guid;
  final String name;
  final String nameEn;

  Department({
    required this.id,
    required this.facultyId,
    required this.guid,
    required this.name,
    required this.nameEn,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      facultyId: json['ustbirimid'] ?? 0, // Go tarafında json tag: "ustbirimid"
      guid: json['guid'] ?? '',
      name: json['text'] ?? '',
      nameEn: json['textEn'] ?? '',
    );
  }
}