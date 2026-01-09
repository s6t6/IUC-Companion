import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../data/models/course.dart';
import '../data/models/schedule_item.dart';
import '../data/models/student_grade.dart';
import '../data/models/planning_types.dart';
import '../data/models/active_course.dart';
import '../data/repositories/university_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/local/app_database.dart';
import '../services/course_planning_service.dart';

class AcademicCalendarViewModel extends ChangeNotifier {
  final UniversityRepository _uniRepo;
  final ScheduleRepository _schedRepo;
  final AppDatabase _database;
  final CoursePlanningService _planningService = CoursePlanningService();

  bool _isLoading = true;

  List<CourseOffering> _calendarOfferings = [];
  List<Course> _availableCourses = [];
  Map<String, int> _activeCoursesMap = {};

  final Map<String, List<VisualTimeSlot>> _dailyLayouts = {};

  bool get isLoading => _isLoading;
  List<CourseOffering> get calendarOfferings => _calendarOfferings;
  List<Course> get availableCourses => _availableCourses;

  int? _currentProfileId;

  AcademicCalendarViewModel(this._uniRepo, this._schedRepo, this._database) {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentProfileId = prefs.getInt('active_profile_id');
      final deptGuid = prefs.getString('user_department_guid');

      if (_currentProfileId == null || deptGuid == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 1. Verileri Çek
      final schedule = await _schedRepo.getSchedule(_currentProfileId!);
      final allCourses = await _uniRepo.fetchCoursesByDepartment(deptGuid);
      final grades = await _uniRepo.getGradesForProfile(_currentProfileId!);

      // DB'den aktif dersleri çek
      final activeCourses = await _database.activeCourseDao.getActiveCourses(_currentProfileId!);
      _activeCoursesMap = {for (var ac in activeCourses) ac.courseCode: ac.colorValue};

      // 2. İşleme
      final gradeMap = {for (var g in grades) g.courseCode: g.letterGrade};
      final courseMap = {for (var c in allCourses) c.code: c};
      final scheduleCourseCodes = schedule.map((s) => s.courseCode).whereType<String>().toSet();

      _availableCourses = [];
      _calendarOfferings = [];

      for (var code in scheduleCourseCodes) {
        if (!courseMap.containsKey(code)) continue;
        final course = courseMap[code]!;
        final grade = gradeMap[code];

        // Geçilen dersleri hariç tut
        if (grade != null && StudentGrade.isPassing(grade)) continue;

        _availableCourses.add(course);

        // Eğer ders aktifse takvime ekle
        if (_activeCoursesMap.containsKey(code)) {
          final courseSchedule = schedule.where((s) => s.courseCode == code).toList();

          final offering = CourseOffering(
            course: course,
            schedule: courseSchedule,
            status: CourseStatus.available,
            isSelected: true,
          );

          _calendarOfferings.add(offering);
        }
      }

      _updateLayouts();

    } catch (e) {
      print("Takvim yükleme hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleCourse(Course course) async {
    if (_currentProfileId == null) return;

    final isAlreadyActive = _activeCoursesMap.containsKey(course.code);

    if (isAlreadyActive) {
      // Sil
      await _database.activeCourseDao.deleteActiveCourse(_currentProfileId!, course.code);
      _activeCoursesMap.remove(course.code);
    } else {
      // Ekle (Rastgele Renk)
      final color = _generateRandomColor().value;
      final activeCourse = ActiveCourse(
          profileId: _currentProfileId!,
          courseCode: course.code,
          colorValue: color
      );

      await _database.activeCourseDao.insertActiveCourse(activeCourse);
      _activeCoursesMap[course.code] = color;
    }

    // Ekranı yenile
    await _loadData();
  }

  Color getCourseColor(String code) {
    if (_activeCoursesMap.containsKey(code)) {
      return Color(_activeCoursesMap[code]!);
    }
    return Colors.grey;
  }

  bool isCourseActive(String code) => _activeCoursesMap.containsKey(code);

  void _updateLayouts() {
    final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'];
    _dailyLayouts.clear();
    for (var day in days) {
      _dailyLayouts[day] = _planningService.computeVisualLayout(day, _calendarOfferings);
    }
  }

  List<VisualTimeSlot> getLayoutForDay(String day) => _dailyLayouts[day] ?? [];

  Color _generateRandomColor() {
    // Canlı renkler listesi
    final colors = [
      Colors.red.shade400, Colors.pink.shade400, Colors.purple.shade400,
      Colors.deepPurple.shade400, Colors.indigo.shade400, Colors.blue.shade400,
      Colors.lightBlue.shade400, Colors.cyan.shade400, Colors.teal.shade400,
      Colors.green.shade400, Colors.lightGreen.shade400, Colors.orange.shade400,
      Colors.deepOrange.shade400, Colors.brown.shade400, Colors.blueGrey.shade400
    ];
    return colors[Random().nextInt(colors.length)];
  }
}