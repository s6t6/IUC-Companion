import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/course.dart';
import '../data/models/student_grade.dart';
import '../data/repositories/university_repository.dart';
import '../utils/semester_helper.dart';

class TranscriptViewModel extends ChangeNotifier {
  final UniversityRepository _repository;

  Map<String, List<Course>> _coursesBySemester = {};
  List<Course> _removedCourses = [];
  Map<String, String> _savedGrades = {};

  bool _isLoading = false;
  String? _errorMessage;
  int? _activeProfileId;

  final List<String> letterGrades = [
    'AA', 'BA', 'BB', 'CB', 'CC', 'DC', 'DD', 'FD', 'FF', 'G', 'M'
  ];

  Map<String, List<Course>> get coursesBySemester => _coursesBySemester;
  List<Course> get removedCourses => _removedCourses;
  Map<String, String> get savedGrades => _savedGrades;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  TranscriptViewModel(this._repository) {
    loadData();
  }

  List<String> get sortedSemesters => SemesterHelper.sortSemesters(_coursesBySemester.keys);

  ({double credit, double ects}) getSemesterTotals(String semester) {
    final courses = _coursesBySemester[semester] ?? [];

    final activeCourses = courses.where((c) => !c.isRemoved);

    final double totalEcts = activeCourses.fold(0.0, (sum, item) => sum + item.ects);
    final double totalCredit = activeCourses.fold(0.0, (sum, item) => sum + item.credit);

    return (credit: totalCredit, ects: totalEcts);
  }
  // ----------------------------------------------

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _activeProfileId = prefs.getInt('active_profile_id');
      final deptGuid = prefs.getString('user_department_guid');

      if (_activeProfileId == null || deptGuid == null) {
        _errorMessage = "Profil bilgisi bulunamadı.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final courses = await _repository.fetchCoursesByDepartment(deptGuid);
      _groupCoursesBySemester(courses);

      final gradeEntities = await _repository.getGradesForProfile(_activeProfileId!);
      _savedGrades = { for (var e in gradeEntities) e.courseCode : e.letterGrade };

    } catch (e) {
      _errorMessage = "Veriler yüklenirken hata: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _groupCoursesBySemester(List<Course> courses) {
    _coursesBySemester = {};
    _removedCourses = [];

    for (var course in courses) {

      final semester = course.semester.isEmpty ? "Diğer" : course.semester;
      if (!_coursesBySemester.containsKey(semester)) {
        _coursesBySemester[semester] = [];
      }
      _coursesBySemester[semester]!.add(course);
    }
  }

  Future<void> saveGrade(String courseCode, String? newGrade) async {
    if (_activeProfileId == null) return;

    if (newGrade == null) {
      _savedGrades.remove(courseCode);
      await _repository.removeGrade(_activeProfileId!, courseCode);
    } else {
      _savedGrades[courseCode] = newGrade;
      await _repository.saveGrade(
          StudentGrade(
            profileId: _activeProfileId!,
            courseCode: courseCode,
            letterGrade: newGrade,
          )
      );
    }
    notifyListeners();
  }
}