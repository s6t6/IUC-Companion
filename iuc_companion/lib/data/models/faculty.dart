class Faculty {
  final int id;
  final String guid;
  final String name;
  final String nameEn;

  Faculty({
    required this.id,
    required this.guid,
    required this.name,
    required this.nameEn,
  });

  // JSON'dan nesne oluşturma
  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      id: json['id'] ?? 0,
      guid: json['guid'] ?? '',
      name: json['text'] ?? '', // Go tarafında json tag: "text"
      nameEn: json['textEn'] ?? '',
    );
  }
}