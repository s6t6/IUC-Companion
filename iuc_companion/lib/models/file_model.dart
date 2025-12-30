class FileModel {
  final String id;
  final String name;
  final String type; // TRANSCRIPT, PROGRAM, SYLLABUS
  final DateTime uploadDate;
  final String url;

  FileModel({required this.id, required this.name, required this.type, required this.uploadDate, required this.url});
}