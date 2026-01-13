import 'package:floor/floor.dart';

// Changed: Added primaryKeys list to include departmentGuid
@Entity(primaryKeys: ['code', 'departmentGuid'])
class Course {
  // Removed @primaryKey annotation from here
  final String code;
  final int departmentId;
  final String departmentGuid; // Changed: Made non-nullable
  final String name;
  final double credit;
  final double ects;
  final bool isMandatory;
  final int theory;
  final int practice;
  final int lab;
  final String semester;
  final String linkId;
  final String unitId;
  final int? year;
  final bool isRemoved;

  Course({
    required this.code,
    required this.departmentId,
    required this.departmentGuid, // Required now
    required this.name,
    required this.credit,
    required this.ects,
    required this.isMandatory,
    required this.theory,
    required this.practice,
    required this.lab,
    required this.semester,
    required this.linkId,
    required this.unitId,
    this.year,
    required this.isRemoved,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      code: json['code'] ?? '',
      departmentId: json['department_id'] ?? 0,
      departmentGuid: json['department_guid'] ?? '',
      name: json['name'] ?? '',
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      ects: (json['ects'] as num?)?.toDouble() ?? 0.0,
      isMandatory: json['is_mandatory'] ?? false,
      theory: json['theory'] ?? 0,
      practice: json['practice'] ?? 0,
      lab: json['lab'] ?? 0,
      semester: json['semester'] ?? '',
      linkId: json['link_id'] ?? '',
      unitId: json['unit_id'] ?? '',
      year: json['year'],
      isRemoved: json['is_removed'] ?? false,
    );
  }
}