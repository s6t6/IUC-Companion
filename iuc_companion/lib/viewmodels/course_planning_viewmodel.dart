import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/planning_types.dart';
import '../data/repositories/university_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../services/course_planning_service.dart';

class CoursePlanningViewModel extends ChangeNotifier {
  final UniversityRepository _universityRepository;
  final ScheduleRepository _scheduleRepository;
  late final CoursePlanningService _planningService;

  bool _isLoading = true;
  bool _isScheduleEmpty = false;
  String? _errorMessage;

  final Set<CourseFilter> _activeFilters = {CourseFilter.current};

  final List<CourseOffering> _allOfferings = [];
  List<String> _conflictMessages = [];

  // Analiz Sonuçları
  double _currentGPA = 0.0;
  int _targetFallID = 1;
  int _targetSpringID = 2;
  StudentStatus _studentStatus = StudentStatus.successful;
  String _limitReason = "";
  double _calculatedMaxEcts = 45.0;

  final Map<String, List<VisualTimeSlot>> _dailyLayouts = {
    'Pazartesi': [], 'Salı': [], 'Çarşamba': [], 'Perşembe': [], 'Cuma': []
  };

  // Getters
  bool get isLoading => _isLoading;
  bool get isScheduleEmpty => _isScheduleEmpty;
  String? get errorMessage => _errorMessage;
  List<String> get conflictMessages => _conflictMessages;
  StudentStatus get studentStatus => _studentStatus;

  int get targetYear => (_targetFallID + 1) ~/ 2;

  double get totalEcts => selectedCourses.fold(0.0, (sum, c) => sum + c.course.ects);
  int get totalCredits => selectedCourses.fold(0, (sum, c) => sum + c.course.credit.toInt());
  bool get isLimitExceeded => totalEcts > _calculatedMaxEcts;

  CoursePlanningViewModel(this._universityRepository, this._scheduleRepository) {
    _planningService = CoursePlanningService();
    initialize();
  }

  bool isFilterActive(CourseFilter filter) => _activeFilters.contains(filter);

  bool _matchesFilter(CourseOffering c, CourseFilter filter) {
    if (filter == CourseFilter.all) return true;

    if (filter == CourseFilter.failed) {
      return c.status == CourseStatus.failedMustAttend ||
          c.status == CourseStatus.failedCanSkipAttendance;
    }

    if (filter == CourseFilter.conditional) {
      return c.status == CourseStatus.conditional;
    }

    if (filter == CourseFilter.current) {
      if (c.status == CourseStatus.passed) return false;
      if (c.status == CourseStatus.unknown) return false;
      return true;
    }

    if (filter == CourseFilter.other) {
      return c.status == CourseStatus.unknown;
    }

    return false;
  }

  Future<void> initialize() async {
    _isLoading = true;
    _isScheduleEmpty = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final activeProfileId = prefs.getInt('active_profile_id');
      final deptGuid = prefs.getString('user_department_guid');

      if (activeProfileId == null || deptGuid == null) {
        _errorMessage = "Profil bilgisi bulunamadı.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final scheduleItems = await _scheduleRepository.getSchedule(activeProfileId);
      if (scheduleItems.isEmpty) {
        _isScheduleEmpty = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final allCourses = await _universityRepository.fetchCoursesByDepartment(deptGuid);
      final grades = await _universityRepository.getGradesForProfile(activeProfileId);
      final gradeMap = {for (var g in grades) g.courseCode: g.letterGrade};

      _allOfferings.clear();

      final result = _planningService.analyzeStudentStatus(allCourses, gradeMap);

      _currentGPA = result.currentGPA;

      // Çift hedefi al
      _targetFallID = result.targetFallID;
      _targetSpringID = result.targetSpringID;

      _studentStatus = result.studentStatus;
      _limitReason = result.limitReason;
      _calculatedMaxEcts = result.calculatedMaxEcts;

      for (var course in allCourses) {
        if (course.isRemoved) continue;

        final courseSchedule = scheduleItems.where((item) {
          return item.courseCode == course.code;
        }).toList();

        if (courseSchedule.isEmpty) continue;

        final status = _planningService.determineCourseStatus(
            course,
            gradeMap[course.code],
            result
        );

        final offering = CourseOffering(
          course: course,
          schedule: courseSchedule,
          status: status,
        );

        // Otomatik Seçim
        if (status == CourseStatus.failedMustAttend || status == CourseStatus.failedCanSkipAttendance) {
          offering.isSelected = true;
        }

        if (status == CourseStatus.mandatoryNew) {
          if (_studentStatus != StudentStatus.failed) {
            offering.isSelected = true;
          }
        }

        _allOfferings.add(offering);
      }

      _updateConflicts();
      _updateLayout();

    } catch (e) {
      _errorMessage = "Veri hatası: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleCourseSelection(CourseOffering offering) {
    // Başarısız Öğrenci Engeli
    if (_studentStatus == StudentStatus.failed &&
        !offering.isSelected &&
        offering.status == CourseStatus.mandatoryNew) {
    }

    offering.isSelected = !offering.isSelected;
    _updateConflicts();
  }

  void _updateConflicts() {
    final selected = selectedCourses;
    _conflictMessages = _planningService.checkConflicts(selected);

    for (var c in _allOfferings) { c.hasConflict = false; }

    for (var msg in _conflictMessages) {
      for (var c in selected) {
        if (msg.contains(c.course.name)) c.hasConflict = true;
      }
    }

    notifyListeners();
  }

  void toggleFilter(CourseFilter filter) {
    if (filter == CourseFilter.all) {
      _activeFilters.clear();
      _activeFilters.add(CourseFilter.all);
    } else {
      _activeFilters.remove(CourseFilter.all);
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
      if (_activeFilters.isEmpty) _activeFilters.add(CourseFilter.current);
    }
    _updateLayout();
  }

  int getFilterCount(CourseFilter filter) => _allOfferings.where((c) => _matchesFilter(c, filter)).length;

  List<CourseOffering> get filteredOfferings {
    if (_activeFilters.contains(CourseFilter.all)) {
      return _allOfferings.where((c) => c.status != CourseStatus.unknown).toList();
    }
    return _allOfferings.where((c) {
      for (var filter in _activeFilters) {
        if (_matchesFilter(c, filter)) return true;
      }
      return false;
    }).toList();
  }

  List<CourseOffering> get selectedCourses => _allOfferings.where((c) => c.isSelected).toList();

  void _updateLayout() {
    final visibleCourses = filteredOfferings;
    final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'];
    for (var day in days) {
      _dailyLayouts[day] = _planningService.computeVisualLayout(day, visibleCourses);
    }
    notifyListeners();
  }

  List<VisualTimeSlot> getLayoutForDay(String day) => _dailyLayouts[day] ?? [];

  List<PlanningRule> get appliedRules {
    List<PlanningRule> rules = [];
    String title = "Başarılı";
    bool warn = false;
    bool success = true;

    if (_studentStatus == StudentStatus.probation) {
      title = "Sınamalı";
      warn = true; success = false;
    } else if (_studentStatus == StudentStatus.failed) {
      title = "Başarısız";
      warn = true; success = false;
    }

    // Hedef bilgisi Güz/Bahar
    rules.add(PlanningRule(
        title: title,
        value: "Güz: $_targetFallID / Bahar: $_targetSpringID",
        reason: _limitReason,
        isWarning: warn,
        isSuccess: success
    ));

    rules.add(PlanningRule(
      title: "AKTS Limiti",
      value: "${totalEcts.toInt()} / ${_calculatedMaxEcts.toInt()}",
      reason: isLimitExceeded ? "Limit aşıldı!" : "Kalan: ${(_calculatedMaxEcts - totalEcts).toStringAsFixed(1)}",
      isWarning: isLimitExceeded,
    ));

    if (conflictMessages.isNotEmpty) {
      rules.add(PlanningRule(
          title: "Uyarı",
          value: "${conflictMessages.length} Sorun",
          reason: "Çakışma tespit edildi.",
          isWarning: true
      ));
    }
    return rules;
  }
}