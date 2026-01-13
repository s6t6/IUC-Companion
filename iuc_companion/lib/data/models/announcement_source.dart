import 'package:floor/floor.dart';

@entity
class AnnouncementSource {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String name;
  final String siteKey;
  final int categoryId;
  final String? lastAnnouncementId;
  final String? lastCheckDate;

  AnnouncementSource({
    this.id,
    required this.name,
    required this.siteKey,
    required this.categoryId,
    this.lastAnnouncementId,
    this.lastCheckDate,
  });
}