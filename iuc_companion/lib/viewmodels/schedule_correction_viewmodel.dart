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

  ({TimeOfDay start, TimeOfDay end}) getTimesFromItem(ScheduleItem? item) {
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 50);

    if (item != null) {
      try {
        final regex = RegExp(r'(\d{1,2})[:.](\d{2})');
        final matches = regex.allMatches(item.time).toList();

        if (matches.length >= 2) {
          startTime = TimeOfDay(
              hour: int.parse(matches[0].group(1)!),
              minute: int.parse(matches[0].group(2)!));
          endTime = TimeOfDay(
              hour: int.parse(matches[1].group(1)!),
              minute: int.parse(matches[1].group(2)!));
        }
      } catch (e) {
        print("Zaman ayıklama hatasu: $e");
      }
    }
    return (start: startTime, end: endTime);
  }

  Future<void> saveCourse({
    required int? id,
    required String courseCode,
    required String courseName,
    required String day,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String location,
    required String instructor,
  }) async {
    if (_currentProfileId == null) return;

    final timeString = "${_formatTime(startTime)}-${_formatTime(endTime)}";

    final itemToSave = ScheduleItem(
      id: id,
      profileId: _currentProfileId!,
      courseCode: courseCode,
      courseName: courseName,
      day: day,
      time: timeString,
      location: location,
      instructor: instructor,
      semester: "Manuel",
    );

    await _scheduleRepository.saveScheduleItems([itemToSave]);
    await _refreshSchedule();
    notifyListeners();
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h.$m";
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