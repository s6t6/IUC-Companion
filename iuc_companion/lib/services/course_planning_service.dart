import '../data/models/student_grade.dart';
import '../data/models/course.dart';
import '../data/models/schedule_item.dart';
import '../data/models/planning_types.dart';

class CoursePlanningService {
  CoursePlanningService();

  AcademicStatusResult analyzeStudentStatus(
      List<Course> allCourses, Map<String, String> gradeMap) {

    print("\n=== AKADEMİK DURUM ANALİZİ (KÜMÜLATİF + ÇİFT HEDEF + AKTS) BAŞLIYOR ===");

    final Map<int, List<Course>> coursesBySemester = {};
    int maxSemester = 0;

    for (var course in allCourses) {
      int semId = _parseSemester(course.semester);

      if (semId == 0 && course.year != null && course.year! > 0) {
        semId = course.year! * 2;
      }

      if (semId == 0) semId = 99;

      if (!coursesBySemester.containsKey(semId)) {
        coursesBySemester[semId] = [];
      }
      coursesBySemester[semId]!.add(course);

      if (semId > maxSemester && semId <= 12) maxSemester = semId;
    }

    StudentStatus currentStatus = StudentStatus.successful;
    int consecutiveFailures = 0;

    // Seviye Takibi (Güz ve Bahar ayrı ayrı)
    int lastZorunluGuzID = -1;
    int lastZorunluBaharID = 0;

    for (int i = 1; i <= maxSemester; i++) {
      if (!coursesBySemester.containsKey(i)) continue;

      final semesterCourses = coursesBySemester[i]!;
      bool hasGrades = semesterCourses.any((c) => gradeMap.containsKey(c.code));
      if (!hasGrades) continue;

      double gpa = _calculateCumulativeGPA(coursesBySemester, i, gradeMap);

      bool hasZorunlu = semesterCourses.any((c) => c.isMandatory && gradeMap.containsKey(c.code));

      if (hasZorunlu) {
        if (i % 2 != 0) {
          lastZorunluGuzID = i;
        } else {
          lastZorunluBaharID = i;
        }
      }

      if (gpa >= 1.80) {
        currentStatus = StudentStatus.successful;
        consecutiveFailures = 0;
      } else {
        consecutiveFailures++;
        if (consecutiveFailures == 1) {
          currentStatus = StudentStatus.probation;
        } else {
          currentStatus = StudentStatus.failed;
        }
      }
    }

    int targetFallID = lastZorunluGuzID + 2;
    if (targetFallID < 1) targetFallID = 1;

    int targetSpringID = lastZorunluBaharID + 2;
    if (targetSpringID < 2) targetSpringID = 2;

    // --- AKTS LİMİTİ HESAPLAMA ---

    double maxEcts = 30.0;

    bool isSenior = (lastZorunluGuzID >= 7 || lastZorunluBaharID >= 8) ||
        (targetFallID >= 7 || targetSpringID >= 8);

    bool hasDebt = gradeMap.values.any((g) =>
    StudentGrade.isFailure(g) ||
        StudentGrade.isAttendanceFailure(g) ||
        StudentGrade.isConditional(g)
    );

    if (isSenior) {
      maxEcts = 66.0;
      print("   ➤ Limit: 66 AKTS (4. Sınıf Statüsü)");
    } else if (hasDebt) {
      maxEcts = 45.0;
      print("   ➤ Limit: 45 AKTS (Alttan/Kaldığı/Şartlı Ders Var)");
    } else {
      maxEcts = 30.0;
      print("   ➤ Limit: 30 AKTS (Başarılı & Temiz)");
    }

    print("--- Analiz Tamamlandı ---");
    print("   * Hedef Güz: $targetFallID | Hedef Bahar: $targetSpringID");
    print("   * Statü: $currentStatus | AKTS Limiti: $maxEcts");

    String limitReason = "";
    if (currentStatus == StudentStatus.successful) {
      limitReason = "Başarılı. Tüm dersleri alabilirsiniz.";
    } else if (currentStatus == StudentStatus.probation) {
      limitReason = "Sınamalı. Yeni dönem derslerini alabilirsiniz.";
    } else {
      limitReason = "Başarısız. Yeni ZORUNLU ders alamazsınız.";
    }

    return AcademicStatusResult(
      currentGPA: 0.0,
      previousGPA: 0.0,
      anchorYear: (maxSemester + 1) ~/ 2,
      targetFallID: targetFallID,
      targetSpringID: targetSpringID,
      studentStatus: currentStatus,
      calculatedMaxEcts: maxEcts,
      limitReason: limitReason,
    );
  }

  // Kümülatif GPA
  double _calculateCumulativeGPA(
      Map<int, List<Course>> allSemesters,
      int currentSemID,
      Map<String, String> gradeMap
      ) {
    double totalPoints = 0;
    double totalCredits = 0;

    for (int i = 1; i <= currentSemID; i++) {
      if (!allSemesters.containsKey(i)) continue;

      for (var c in allSemesters[i]!) {
        if (gradeMap.containsKey(c.code)) {
          String g = gradeMap[c.code]!;
          double? coeff = StudentGrade.gradeCoefficients[g];
          if (coeff != null && g != 'G' && g != 'M') {
            totalPoints += (coeff * c.credit);
            totalCredits += c.credit;
          }
        }
      }
    }
    return totalCredits > 0 ? totalPoints / totalCredits : 0.0;
  }

  // --- DERS STATÜSÜ ---
  CourseStatus determineCourseStatus(
      Course course,
      String? grade,
      AcademicStatusResult statusResult
      ) {
    if (grade != null) {
      if (StudentGrade.isPassing(grade)) return CourseStatus.passed;
      if (StudentGrade.isConditional(grade)) return CourseStatus.conditional;
      if (StudentGrade.isAttendanceFailure(grade)) return CourseStatus.failedMustAttend;
      if (StudentGrade.isFailure(grade)) return CourseStatus.failedCanSkipAttendance;
    }

    int courseSemID = _parseSemester(course.semester);
    if (courseSemID == 0) courseSemID = 99;

    int targetID;
    if (courseSemID % 2 != 0) {
      targetID = statusResult.targetFallID;
    } else {
      targetID = statusResult.targetSpringID;
    }

    if (courseSemID < targetID) {
      return course.isMandatory ? CourseStatus.mandatoryNew : CourseStatus.electiveNew;
    }

    if (courseSemID == targetID) {
      if (statusResult.studentStatus == StudentStatus.failed) {
        if (course.isMandatory) {
          return CourseStatus.unknown;
        } else {
          return CourseStatus.electiveNew;
        }
      } else {
        return course.isMandatory ? CourseStatus.mandatoryNew : CourseStatus.electiveNew;
      }
    }

    return CourseStatus.unknown;
  }

  // --- PARSER ---
  int _parseSemester(String sem) {
    if (sem.isEmpty) return 0;
    String lower = sem.toLowerCase().trim();

    final sinifMatch = RegExp(r'(\d+)\s*\.\s*sınıf.*?(güz|bahar)').firstMatch(lower);
    if (sinifMatch != null) {
      int sinif = int.parse(sinifMatch.group(1)!);
      String mevsim = sinifMatch.group(2)!;
      return (mevsim == 'güz') ? (sinif * 2) - 1 : (sinif * 2);
    }

    final yariyilMatch = RegExp(r'(\d+)\s*\.\s*yarıyıl').firstMatch(lower);
    if (yariyilMatch != null) return int.parse(yariyilMatch.group(1)!);

    final digitMatch = RegExp(r'^(\d+)$').firstMatch(lower);
    if (digitMatch != null) return int.parse(digitMatch.group(1)!);

    return 0;
  }

  // --- ÇAKIŞMA KONTROL & YERLEŞTİRME ---
  List<String> checkConflicts(List<CourseOffering> selectedCourses) {
    List<String> conflicts = [];
    for (int i = 0; i < selectedCourses.length; i++) {
      for (int j = i + 1; j < selectedCourses.length; j++) {
        final c1 = selectedCourses[i];
        final c2 = selectedCourses[j];
        for (var s1 in c1.schedule) {
          for (var s2 in c2.schedule) {
            if (_isOverlapping(s1, s2)) {
              conflicts.add("${c1.course.name} ⚡ ${c2.course.name}");
              c1.hasConflict = true;
              c2.hasConflict = true;
            }
          }
        }
      }
    }
    return conflicts;
  }

  bool _isOverlapping(ScheduleItem item1, ScheduleItem item2) {
    if (item1.day.toLowerCase() != item2.day.toLowerCase()) return false;
    final t1 = _parseTimeRange(item1.time);
    final t2 = _parseTimeRange(item2.time);
    if (t1 == null || t2 == null) return false;
    return (t1.start < t2.end) && (t2.start < t1.end);
  }

  ({int start, int end})? _parseTimeRange(String timeStr) {
    try {
      final regex = RegExp(r'(\d{1,2})[:.](\d{2})');
      final matches = regex.allMatches(timeStr).toList();
      if (matches.length >= 2) {
        return (
        start: int.parse(matches[0].group(1)!)*60 + int.parse(matches[0].group(2)!),
        end: int.parse(matches[1].group(1)!)*60 + int.parse(matches[1].group(2)!)
        );
      }
    } catch (_) {}
    return null;
  }

  List<VisualTimeSlot> computeVisualLayout(String dayName, List<CourseOffering> allCourses) {
    List<VisualTimeSlot> slots = [];
    for (var course in allCourses) {
      for (var item in course.schedule) {
        if (item.day.toLowerCase() == dayName.toLowerCase()) {
          final range = _parseTimeRange(item.time);
          if (range != null) {
            slots.add(VisualTimeSlot(day: dayName, startMinute: range.start, endMinute: range.end, source: course));
          }
        }
      }
    }
    if (slots.isEmpty) return [];
    slots.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    List<List<VisualTimeSlot>> columns = [];
    for(var slot in slots) {
      bool placed = false;
      for(int i=0; i<columns.length; i++) {
        bool fits = true;
        for(var existing in columns[i]) {
          if (slot.startMinute < existing.endMinute && slot.endMinute > existing.startMinute) {
            fits = false; break;
          }
        }
        if(fits) { columns[i].add(slot); slot.layoutLeft = i.toDouble(); placed = true; break; }
      }
      if(!placed) { columns.add([slot]); slot.layoutLeft = (columns.length - 1).toDouble(); }
    }
    int totalCols = columns.length;
    for(var slot in slots) {
      slot.layoutWidth = 1.0 / totalCols;
      slot.layoutLeft = slot.layoutLeft / totalCols;
    }
    return slots;
  }

  int getSanitizedYear(Course c) => (_parseSemester(c.semester) + 1) ~/ 2;
}