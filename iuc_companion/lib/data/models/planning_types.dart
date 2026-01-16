import 'course.dart';
import 'schedule_item.dart';

/// Ders listesini filtrelemek için kullanılan seçenekler
enum CourseFilter { all, failed, conditional, current, other }

/// Öğrencinin akademik durumu
enum StudentStatus { successful, probation, failed }

/// Bir dersin öğrenci için statüsü
enum CourseStatus {
  passed,                  // AA, BA, BB, CB, CC - Başarılı
  conditional,             // DD, DC - Şartlı Geçiş
  failedCanSkipAttendance, // FF - Kaldı (Devamsızlık sorunu yok)
  failedMustAttend,        // FD, NA, DZ - Kaldı (Devam zorunlu)
  mandatoryNew,            // Zorunlu (Hiç alınmamış - Açık)
  electiveNew,             // Seçmeli (Hiç alınmamış - Açık)
  available,               // Genel
  unknown                  // Kapalı / Üst dönem
}

class PlanningRule {
  final String title;
  final String value;
  final String reason;
  final bool isWarning;
  final bool isSuccess;

  PlanningRule({
    required this.title,
    required this.value,
    required this.reason,
    this.isWarning = false,
    this.isSuccess = false,
  });
}

class AcademicStatusResult {
  final double currentGPA;
  final double previousGPA;
  final int anchorYear;

  final int targetFallID;
  final int targetSpringID;

  final StudentStatus studentStatus;
  final double calculatedMaxEcts;
  final String limitReason;

  AcademicStatusResult({
    required this.currentGPA,
    required this.previousGPA,
    required this.anchorYear,
    required this.targetFallID,
    required this.targetSpringID,
    required this.studentStatus,
    required this.calculatedMaxEcts,
    required this.limitReason,
  });
}

class CourseOffering {
  final Course course;
  final List<ScheduleItem> schedule;
  final CourseStatus status;

  bool isSelected;
  bool hasConflict;

  CourseOffering({
    required this.course,
    required this.schedule,
    this.status = CourseStatus.available,
    this.isSelected = false,
    this.hasConflict = false,
  });

  double get opacity => isSelected ? 1.0 : 0.4;
}

class VisualTimeSlot {
  final String day;
  final int startMinute;
  final int endMinute;
  final CourseOffering source;

  double layoutLeft = 0.0;
  double layoutWidth = 1.0;

  VisualTimeSlot({
    required this.day,
    required this.startMinute,
    required this.endMinute,
    required this.source,
  });

  int get duration => endMinute - startMinute;
}