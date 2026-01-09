import 'package:floor/floor.dart';

@entity
class ScheduleItem {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final int profileId;
  final String? courseCode;

  final String day;
  final String time;
  final String courseName;
  final String instructor;
  final String location;
  final String semester;

  ScheduleItem({
    this.id,
    required this.profileId,
    this.courseCode,
    required this.day,
    required this.time,
    required this.courseName,
    required this.instructor,
    required this.location,
    required this.semester,
  });

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'courseCode': courseCode,
    'day': day,
    'time': time,
    'courseName': courseName,
    'instructor': instructor,
    'location': location,
    'semester': semester,
  };

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      profileId: json['profileId'] ?? 0,
      courseCode: json['courseCode'],
      day: json['day'],
      time: json['time'],
      courseName: json['courseName'],
      instructor: json['instructor'],
      location: json['location'],
      semester: json['semester'],
    );
  }
}