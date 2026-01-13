import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/schedule_item.dart';
import '../data/models/course.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/repositories/university_repository.dart';

class ScheduleCorrectionViewModel extends ChangeNotifier {
  final ScheduleRepository _scheduleRepository;
  final UniversityRepository _universityRepository;

  bool isLoading = true;
  int? _currentProfileId;
  String? _departmentGuid;

  Map<String, List<ScheduleItem>> groupedItems = {};

  List<Course> _allCourses = [];
  List<Course> filteredCourses = [];

  ScheduleCorrectionViewModel(this._scheduleRepository, this._universityRepository) {
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _currentProfileId = prefs.getInt('active_profile_id');
    _departmentGuid = prefs.getString('user_department_guid');

    if (_currentProfileId != null) {
      await _refreshSchedule();

      if (_departmentGuid != null) {
        _allCourses = await _universityRepository.fetchCoursesByDepartment(_departmentGuid!);
        filteredCourses = List.from(_allCourses);
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshSchedule() async {
    final items = await _scheduleRepository.getSchedule(_currentProfileId!);

    groupedItems = {};
    for (var item in items) {
      final code = (item.courseCode == null || item.courseCode!.isEmpty)
          ? "Diğer"
          : item.courseCode!;

      if (!groupedItems.containsKey(code)) {
        groupedItems[code] = [];
      }
      groupedItems[code]!.add(item);
    }
  }

  void searchCourses(String query) {
    if (query.isEmpty) {
      filteredCourses = List.from(_allCourses);
    } else {
      final q = query.toLowerCase();
      filteredCourses = _allCourses.where((c) {
        return c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> saveItem(ScheduleItem item) async {
    if (_currentProfileId == null) return;

    final itemToSave = ScheduleItem(
      id: item.id,
      profileId: _currentProfileId!,
      courseCode: item.courseCode,
      courseName: item.courseName,
      day: item.day,
      time: item.time,
      location: item.location,
      instructor: item.instructor,
      semester: item.semester,
    );

    await _scheduleRepository.saveScheduleItems([itemToSave]);
    await _refreshSchedule();
    notifyListeners();
  }

  Future<void> deleteItem(ScheduleItem item) async {
    await _scheduleRepository.deleteScheduleItem(item);
    await _refreshSchedule();
    notifyListeners();
  }

  Future<void> deleteCourse(String courseCode) async {
    if (_currentProfileId == null) return;
    await _scheduleRepository.deleteCourse(_currentProfileId!, courseCode);
    await _refreshSchedule();
    notifyListeners();
  }
}