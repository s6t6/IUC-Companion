import 'package:floor/floor.dart';

@Entity(primaryKeys: ['profileId', 'courseCode'])
class ActiveCourse {
  final int profileId;
  final String courseCode;
  final int colorValue; // ARGB

  ActiveCourse({
    required this.profileId,
    required this.courseCode,
    required this.colorValue,
  });
}