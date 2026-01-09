import 'course.dart';

class CourseDetail {
  final Course baseInfo;
  final String instructor;
  final String language;
  final String aim;
  final String content;
  final String resources;
  final List<String> outcomes;

  CourseDetail({
    required this.baseInfo,
    required this.instructor,
    required this.language,
    required this.aim,
    required this.content,
    required this.resources,
    required this.outcomes,
  });

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    return CourseDetail(
      baseInfo: Course.fromJson(json['base_info'] ?? {}),
      instructor: json['instructor'] ?? 'Belirtilmemiş',
      language: json['language'] ?? '',
      aim: json['aim'] ?? '',
      content: json['content'] ?? '',
      resources: json['resources'] ?? '',
      // Outcomes bir string listesi olarak geliyor
      outcomes: (json['outcomes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }
}