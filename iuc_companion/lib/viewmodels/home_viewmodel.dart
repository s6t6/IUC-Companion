import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/course.dart';
import '../data/models/profile.dart';
import '../data/models/schedule_item.dart';
import '../data/repositories/university_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../utils/semester_helper.dart';

class HomeViewModel extends ChangeNotifier {
  final UniversityRepository _repository;
  final ScheduleRepository _scheduleRepository;

  // State
  Map<String, List<Course>> _coursesBySemester = {};
  List<Course> _removedCourses = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _departmentName = "";

  // Profil
  List<Profile> _savedProfiles = [];
  int? _activeProfileId;

  // Dashboard
  ScheduleItem? _nextClass;
  bool _hasRawSchedule = false;

  // Getters
  Map<String, List<Course>> get coursesBySemester => _coursesBySemester;
  List<Course> get removedCourses => _removedCourses; // Expose removed courses

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get departmentName => _departmentName;
  List<Profile> get savedProfiles => _savedProfiles;
  int? get activeProfileId => _activeProfileId;

  ScheduleItem? get nextClass => _nextClass;
  bool get hasRawSchedule => _hasRawSchedule;

  List<String> get sortedSemesters => SemesterHelper.sortSemesters(_coursesBySemester.keys);

  HomeViewModel(this._repository, this._scheduleRepository) {
    loadCourses();
  }

  Future<void> loadCourses() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();

      _activeProfileId = prefs.getInt('active_profile_id');
      final deptGuid = prefs.getString('user_department_guid');
      _departmentName = prefs.getString('user_department_name') ?? "Bölüm";

      if (deptGuid == null || _activeProfileId == null) {
        _errorMessage = "Profil bulunamadı. Lütfen tekrar giriş yapın.";
        return;
      }

      final courses = await _repository.fetchCoursesByDepartment(deptGuid);
      _groupCoursesBySemester(courses);
      _savedProfiles = await _repository.getProfiles();

      await _calculateDashboardData();

      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Veriler yüklenirken hata: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _calculateDashboardData() async {
    if (_activeProfileId == null) return;

    final allSchedule = await _scheduleRepository.getSchedule(_activeProfileId!);
    _hasRawSchedule = allSchedule.isNotEmpty;

    if (!_hasRawSchedule) {
      _nextClass = null;
      return;
    }

    final activeCourses = await _repository.getActiveCourses(_activeProfileId!);
    List<ScheduleItem> filteredSchedule;

    if (activeCourses.isEmpty) {
      filteredSchedule = allSchedule;
    } else {
      final activeCodes = activeCourses.map((e) => e.courseCode).toSet();
      filteredSchedule = allSchedule.where((item) {
        return item.courseCode == null || activeCodes.contains(item.courseCode);
      }).toList();
    }

    _nextClass = _findNextClass(filteredSchedule);
  }

  ScheduleItem? _findNextClass(List<ScheduleItem> scheduleList) {
    if (scheduleList.isEmpty) return null;

    final now = DateTime.now();
    const dayMap = {
      1: "Pazartesi", 2: "Salı", 3: "Çarşamba",
      4: "Perşembe", 5: "Cuma", 6: "Cumartesi", 7: "Pazar"
    };

    final todayString = dayMap[now.weekday];
    if (todayString == null) return null;

    final todaysClasses = scheduleList.where((s) =>
    s.day.toLowerCase() == todayString.toLowerCase()
    ).toList();

    if (todaysClasses.isEmpty) return null;

    todaysClasses.sort((a, b) => _parseToMinutes(a.time).compareTo(_parseToMinutes(b.time)));

    final nowMinutes = now.hour * 60 + now.minute;

    for (var item in todaysClasses) {
      final startMinutes = _parseToMinutes(item.time);
      if (startMinutes > nowMinutes - 50) {
        return item;
      }
    }
    return null;
  }

  int _parseToMinutes(String timeStr) {
    try {
      final cleanTime = timeStr.split('-')[0].trim().replaceAll('.', ':');
      final parts = cleanTime.split(':');
      if (parts.length >= 2) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    } catch (_) {}
    return 9999;
  }

  Future<void> switchProfile(Profile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('active_profile_id', profile.id!);
      await prefs.setString('user_department_guid', profile.departmentGuid);
      await prefs.setString('user_department_name', profile.departmentName);

      _departmentName = profile.departmentName;
      _activeProfileId = profile.id;

      _coursesBySemester = {};
      _removedCourses = [];
      notifyListeners();

      await loadCourses();
    } catch (e) {
      _errorMessage = "Profil değiştirilirken hata: $e";
      notifyListeners();
    }
  }

  void _groupCoursesBySemester(List<Course> courses) {
    _coursesBySemester = {};
    _removedCourses = [];

    for (var course in courses) {
      if (course.isRemoved) {
        _removedCourses.add(course);
        continue;
      }

      final semester = course.semester.isEmpty ? "Diğer" : course.semester;

      if (!_coursesBySemester.containsKey(semester)) {
        _coursesBySemester[semester] = [];
      }
      _coursesBySemester[semester]!.add(course);
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}