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
  bool _isDayEmpty = false;

  // Getters
  Map<String, List<Course>> get coursesBySemester => _coursesBySemester;
  List<Course> get removedCourses => _removedCourses;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get departmentName => _departmentName;
  List<Profile> get savedProfiles => _savedProfiles;
  int? get activeProfileId => _activeProfileId;

  ScheduleItem? get nextClass => _nextClass;
  bool get hasRawSchedule => _hasRawSchedule;
  bool get isDayEmpty => _isDayEmpty;

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
      _isDayEmpty = true;
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
    _isDayEmpty = false;
    if (scheduleList.isEmpty) {
      _isDayEmpty = true;
      return null;
    }

    final now = DateTime.now();
    const dayMap = {
      1: "Pazartesi", 2: "Salı", 3: "Çarşamba",
      4: "Perşembe", 5: "Cuma", 6: "Cumartesi", 7: "Pazar"
    };

    final todayString = dayMap[now.weekday];
    if (todayString == null) return null;

    final todaysClasses = scheduleList.where((s) =>
    s.day.trim().toLowerCase() == todayString.toLowerCase()
    ).toList();

    if (todaysClasses.isEmpty) {
      _isDayEmpty = true;
      return null;
    }

    todaysClasses.sort((a, b) {
      final t1 = _parseTimeRange(a.time);
      final t2 = _parseTimeRange(b.time);
      return (t1?.start ?? 0).compareTo(t2?.start ?? 0);
    });

    final nowMinutes = now.hour * 60 + now.minute;

    for (var item in todaysClasses) {
      final range = _parseTimeRange(item.time);
      if (range == null) continue;

      if (range.end > nowMinutes) {
        return item;
      }
    }

    return null;
  }

  ({int start, int end})? _parseTimeRange(String timeStr) {
    try {
      final regex = RegExp(r'(\d{1,2})[:.](\d{2})');
      final matches = regex.allMatches(timeStr).toList();

      if (matches.length >= 2) {
        final startH = int.parse(matches[0].group(1)!);
        final startM = int.parse(matches[0].group(2)!);

        final endH = int.parse(matches[1].group(1)!);
        final endM = int.parse(matches[1].group(2)!);

        return (start: startH * 60 + startM, end: endH * 60 + endM);
      }
    } catch (_) {}
    return null;
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