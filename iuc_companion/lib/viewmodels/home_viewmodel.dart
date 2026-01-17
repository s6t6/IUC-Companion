import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/course.dart';
import '../data/models/profile.dart';
import '../data/models/schedule_item.dart';
import '../data/repositories/university_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../utils/semester_helper.dart';
import 'schedule_viewmodel.dart';
import 'transcript_viewmodel.dart';
import 'simulation_viewmodel.dart';

class HomeViewModel extends ChangeNotifier {
  final UniversityRepository _repository;
  final ScheduleRepository _scheduleRepository;

  // State
  Map<String, List<Course>> _coursesBySemester = {};
  List<Course> _removedCourses = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _departmentName = "";

  // Search State
  String _searchQuery = "";

  // Profil
  List<Profile> _savedProfiles = [];
  int? _activeProfileId;

  // Dashboard State
  ScheduleItem? _nextClass;
  List<ScheduleItem> _todaysClasses = [];
  List<ScheduleItem> _activeSchedule = [];
  bool _hasRawSchedule = false;
  bool _isDayEmpty = false;
  bool _hasActiveCourses = false;

  // Getters
  Map<String, List<Course>> get coursesBySemester => _coursesBySemester;
  List<Course> get removedCourses => _removedCourses;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get departmentName => _departmentName;
  List<Profile> get savedProfiles => _savedProfiles;
  int? get activeProfileId => _activeProfileId;
  String get searchQuery => _searchQuery;

  ScheduleItem? get nextClass => _nextClass;
  List<ScheduleItem> get todaysClasses => _todaysClasses;
  bool get hasRawSchedule => _hasRawSchedule;
  bool get isDayEmpty => _isDayEmpty;
  bool get hasActiveCourses => _hasActiveCourses;

  List<String> get sortedSemesters => SemesterHelper.sortSemesters(_coursesBySemester.keys);

  List<Course> get searchResults {
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    final allCourses = [
      ..._coursesBySemester.values.expand((e) => e),
      ..._removedCourses
    ];

    return allCourses.where((course) =>
    course.name.toLowerCase().contains(query) ||
        course.code.toLowerCase().contains(query)
    ).toList();
  }

  String get nextClassStatusText {
    if (_nextClass == null) return "";
    try {
      final now = TimeOfDay.now();
      final nowMin = now.hour * 60 + now.minute;

      final parts = _nextClass!.time.split('-')[0].replaceAll('.', ':').split(':');
      final startMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final diff = startMin - nowMin;

      if (diff <= 0) {
        return "Şu an İşleniyor";
      } else if (diff < 60) {
        return "$diff dk sonra başlıyor";
      } else {
        return "Bugün ${_nextClass!.time}";
      }
    } catch (_) {
      return "Bugün ${_nextClass!.time}";
    }
  }

  Color get nextClassStatusColor {
    if (_nextClass == null) return Colors.white;
    try {
      final now = TimeOfDay.now();
      final nowMin = now.hour * 60 + now.minute;

      final parts = _nextClass!.time.split('-')[0].replaceAll('.', ':').split(':');
      final startMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final diff = startMin - nowMin;

      if (diff <= 0) {
        return const Color(0xFF81C784);
      } else if (diff < 60) {
        return const Color(0xFFFFB74D);
      } else {
        return Colors.white.withOpacity(0.9);
      }
    } catch (_) {
      return Colors.white.withOpacity(0.9);
    }
  }

  String get nextClassEndTimeStr {
    if (_nextClass == null) return "";
    try {
      final endParts = _nextClass!.time.split('-')[1].replaceAll('.', ':');
      return "Bitiş: $endParts";
    } catch (_) {
      return "";
    }
  }

  HomeViewModel(this._repository, this._scheduleRepository) {
    loadCourses();
  }

  ({double credit, double ects}) getSemesterTotals(List<Course> courses) {
    final double totalEcts = courses.fold(0.0, (sum, item) => sum + item.ects);
    final double totalCredit = courses.fold(0.0, (sum, item) => sum + item.credit);
    return (credit: totalCredit, ects: totalEcts);
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = "";
    notifyListeners();
  }

  Course? getCourseByCode(String code) {
    try {
      final allCourses = _coursesBySemester.values.expand((e) => e);
      return allCourses.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  List<ScheduleItem> getScheduleForCode(String code) {
    return _activeSchedule.where((item) => item.courseCode == code).toList();
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

    _todaysClasses = [];
    _activeSchedule = [];
    _nextClass = null;
    _isDayEmpty = false;
    _hasActiveCourses = false;

    if (!_hasRawSchedule) {
      return;
    }

    final activeCourses = await _repository.getActiveCourses(_activeProfileId!);

    if (activeCourses.isEmpty) {
      _hasActiveCourses = false;
      return;
    } else {
      _hasActiveCourses = true;
    }

    final activeCodes = activeCourses.map((e) => e.courseCode).toSet();
    final filteredSchedule = allSchedule.where((item) {
      return item.courseCode == null || activeCodes.contains(item.courseCode);
    }).toList();

    _activeSchedule = filteredSchedule;

    _calculateTodaysClasses(filteredSchedule);
    _nextClass = _findNextClass(filteredSchedule);
  }

  void _calculateTodaysClasses(List<ScheduleItem> filteredSchedule) {
    final now = DateTime.now();
    const dayMap = {
      1: "Pazartesi", 2: "Salı", 3: "Çarşamba",
      4: "Perşembe", 5: "Cuma", 6: "Cumartesi", 7: "Pazar"
    };
    final todayString = dayMap[now.weekday];
    if (todayString == null) {
      _todaysClasses = [];
      return;
    }

    final todays = filteredSchedule.where((s) =>
    s.day.trim().toLowerCase() == todayString.toLowerCase()
    ).toList();

    todays.sort((a, b) {
      final t1 = _parseTimeRange(a.time);
      final t2 = _parseTimeRange(b.time);
      return (t1?.start ?? 0).compareTo(t2?.start ?? 0);
    });

    _todaysClasses = todays;
  }

  ScheduleItem? _findNextClass(List<ScheduleItem> filteredSchedule) {
    if (_todaysClasses.isEmpty) {
      _isDayEmpty = true;
      return null;
    }

    _isDayEmpty = false;

    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    for (var item in _todaysClasses) {
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

  Future<void> switchProfileAndRefresh({
    required Profile profile,
    required ScheduleViewModel scheduleVM,
    required TranscriptViewModel transcriptVM,
    required SimulationViewModel simulationVM,
  }) async {
    await switchProfile(profile);

    await Future.wait([
      scheduleVM.loadScheduleForActiveProfile(),
      transcriptVM.loadData(),
      simulationVM.initialize(),
    ]);
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
      _searchQuery = "";
      _errorMessage = null;

      _nextClass = null;
      _todaysClasses = [];
      _activeSchedule = [];
      _hasRawSchedule = false;
      _isDayEmpty = false;
      _hasActiveCourses = false;

      notifyListeners();

      await loadCourses();
    } catch (e) {
      _errorMessage = "Profil değiştirilirken hata: $e";
      notifyListeners();
    }
  }

  Future<void> deleteProfileAndRefresh({
    required Profile profile,
    required ScheduleViewModel scheduleVM,
    required TranscriptViewModel transcriptVM,
    required SimulationViewModel simulationVM,
  }) async {
    try {
      if (profile.id == null) return;

      await _repository.deleteProfile(profile.id!);
      _savedProfiles = await _repository.getProfiles();

      if (_activeProfileId == profile.id) {
        if (_savedProfiles.isNotEmpty) {
          await switchProfileAndRefresh(
            profile: _savedProfiles.first,
            scheduleVM: scheduleVM,
            transcriptVM: transcriptVM,
            simulationVM: simulationVM,
          );
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('active_profile_id');
          await prefs.remove('user_department_guid');

          _activeProfileId = null;
          _coursesBySemester = {};
          _departmentName = "";
          _nextClass = null;
          _todaysClasses = [];
          _activeSchedule = [];

          notifyListeners();
        }
      } else {
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Profil silinirken hata: $e";
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