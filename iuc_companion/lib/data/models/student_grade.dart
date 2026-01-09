import 'package:floor/floor.dart';

@Entity(primaryKeys: ['profileId', 'courseCode'])
class StudentGrade {
  final int profileId;
  final String courseCode;
  final String letterGrade;

  StudentGrade({
    required this.profileId,
    required this.courseCode,
    required this.letterGrade,
  });

  static const Map<String, double> gradeCoefficients = {
    'AA': 4.0, 'BA': 3.5, 'BB': 3.0, 'CB': 2.5,
    'CC': 2.0, 'DC': 1.5, 'DD': 1.0, 'FF': 0.0,
    'FD': 0.0, 'G': 0.0, 'M': 0.0,
  };

  static const Set<String> passingGrades = {'AA', 'BA', 'BB', 'CB', 'CC'};
  static const Set<String> conditionalGrades = {'DC', 'DD'};
  static const Set<String> failureGrades = {'FF', 'FD', 'NA', 'DZ', 'G', 'M'};

  // Helper
  static bool isPassing(String grade) => passingGrades.contains(grade);
  static bool isConditional(String grade) => conditionalGrades.contains(grade);
  static bool isFailure(String grade) => failureGrades.contains(grade);
  static bool isAttendanceFailure(String grade) => {'FD', 'NA', 'DZ'}.contains(grade);
}