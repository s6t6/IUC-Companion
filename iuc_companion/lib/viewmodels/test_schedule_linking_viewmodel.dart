import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/course.dart';
import '../data/models/schedule_item.dart';
import '../data/repositories/university_repository.dart';
import '../data/repositories/schedule_repository.dart';

class TestScheduleLinkingViewModel extends ChangeNotifier {
  final UniversityRepository _uniRepo;
  final ScheduleRepository _schedRepo;

  bool _isLoading = true;
  String? _errorMessage;

  Map<Course, List<ScheduleItem>> _matchedCourses = {};
  List<ScheduleItem> _unmatchedItems = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<Course, List<ScheduleItem>> get matchedCourses => _matchedCourses;
  List<ScheduleItem> get unmatchedItems => _unmatchedItems;

  TestScheduleLinkingViewModel(this._uniRepo, this._schedRepo) {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileId = prefs.getInt('active_profile_id');
      final deptGuid = prefs.getString('user_department_guid');

      if (profileId == null || deptGuid == null) {
        _errorMessage = "Profil bilgisi eksik.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final schedule = await _schedRepo.getSchedule(profileId);
      final allCourses = await _uniRepo.fetchCoursesByDepartment(deptGuid);

      final courseMap = {for (var c in allCourses) c.code: c};

      _matchedCourses = {};
      _unmatchedItems = [];

      for (var item in schedule) {
        if (item.courseCode != null && courseMap.containsKey(item.courseCode)) {
          final course = courseMap[item.courseCode]!;
          if (!_matchedCourses.containsKey(course)) {
            _matchedCourses[course] = [];
          }
          _matchedCourses[course]!.add(item);
        } else {
          _unmatchedItems.add(item);
        }
      }

      _errorMessage = null;

    } catch (e) {
      _errorMessage = "Hata: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}