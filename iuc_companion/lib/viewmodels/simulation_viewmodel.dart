import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/course.dart';
import '../data/models/student_grade.dart';
import '../data/repositories/university_repository.dart';
import '../utils/semester_helper.dart';

class SimulationViewModel extends ChangeNotifier {
  final UniversityRepository _repository;

  List<Course> _allCourses = [];
  Map<String, String> _currentGrades = {};

  // Stats
  double _calculatedGPA = 0.0;
  int _totalCredits = 0;
  double _realGPA = 0.0;
  int _realTotalCredits = 0;

  bool _isLoading = true;
  int? _activeProfileId;

  Map<String, List<Course>> _coursesBySemester = {};

  List<Course> get allCourses => _allCourses;
  Map<String, String> get currentGrades => _currentGrades;

  double get calculatedGPA => _calculatedGPA;
  int get totalCredits => _totalCredits;
  double get realGPA => _realGPA;
  int get realTotalCredits => _realTotalCredits;

  bool get isLoading => _isLoading;
  Map<String, List<Course>> get coursesBySemester => _coursesBySemester;

  List<String> get letterGrades => StudentGrade.gradeCoefficients.keys.toList();


  List<Course> get passedCourses {
    return _allCourses.where((c) {
      final grade = _currentGrades[c.code];
      if (grade == null) return false;
      return StudentGrade.isPassing(grade);
    }).toList();
  }

  List<Course> get retakeCourses {
    return _allCourses.where((c) {
      final grade = _currentGrades[c.code];
      if (grade == null) return false;
      return StudentGrade.isFailure(grade) || StudentGrade.isConditional(grade);
    }).toList();
  }

  List<Course> get futureCourses {
    return _allCourses.where((c) {
      bool hasGrade = _currentGrades.containsKey(c.code);
      bool isAvailable = !c.isRemoved;
      return !hasGrade && isAvailable;
    }).toList();
  }

  List<String> get sortedSemesters => SemesterHelper.sortSemesters(_coursesBySemester.keys);

  SimulationViewModel(this._repository) {
    initialize();
  }

  Future<void> initialize() async {
    _isLoading = true;

    _allCourses = [];
    _currentGrades = {};
    _coursesBySemester = {};
    _calculatedGPA = 0.0;
    _totalCredits = 0;
    _realGPA = 0.0;
    _realTotalCredits = 0;

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      _activeProfileId = prefs.getInt('active_profile_id');
      final deptGuid = prefs.getString('user_department_guid');

      if (_activeProfileId == null || deptGuid == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      _allCourses = await _repository.fetchCoursesByDepartment(deptGuid);
      _groupCoursesBySemester(_allCourses);

      final gradeEntities = await _repository.getGradesForProfile(_activeProfileId!);

      final dbGradesMap = { for (var e in gradeEntities) e.courseCode : e.letterGrade };
      _calculateStats(dbGradesMap, isReal: true);

      _currentGrades = Map.from(dbGradesMap);
      _calculateStats(_currentGrades, isReal: false);

    } catch (e) {
      print("Simülasyon hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateGrade(String courseCode, String? newGrade) {
    if (newGrade == null) {
      _currentGrades.remove(courseCode);
    } else {
      _currentGrades[courseCode] = newGrade;
    }

    _calculateStats(_currentGrades, isReal: false);
    notifyListeners();
  }

  void resetSimulation() {
    initialize();
  }

  void _calculateStats(Map<String, String> gradesMap, {required bool isReal}) {
    double totalPoints = 0;
    double totalCreditAttempted = 0;

    for (var course in _allCourses) {
      if (gradesMap.containsKey(course.code)) {
        String grade = gradesMap[course.code]!;
        double coefficient = StudentGrade.gradeCoefficients[grade] ?? 0.0;

        if (grade == 'G' || grade == 'M') continue;

        double credit = course.credit;

        if (credit > 0) {
          totalPoints += (credit * coefficient);
          totalCreditAttempted += credit;
        }
      }
    }

    double gpa = 0.0;
    int credits = 0;

    if (totalCreditAttempted > 0) {
      gpa = totalPoints / totalCreditAttempted;
      credits = totalCreditAttempted.toInt();
    }

    if (isReal) {
      _realGPA = gpa;
      _realTotalCredits = credits;
    } else {
      _calculatedGPA = gpa;
      _totalCredits = credits;
    }
  }

  void _groupCoursesBySemester(List<Course> courses) {
    _coursesBySemester = {};
    for (var course in courses) {
      if (course.isRemoved) continue;

      final semester = course.semester.isEmpty ? "Diğer" : course.semester;

      if (!_coursesBySemester.containsKey(semester)) {
        _coursesBySemester[semester] = [];
      }
      _coursesBySemester[semester]!.add(course);
    }
  }
}