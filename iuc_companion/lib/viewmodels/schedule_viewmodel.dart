import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/schedule_item.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/repositories/university_repository.dart';
import '../services/schedule_service.dart';

class ScheduleViewModel extends ChangeNotifier {
  final ScheduleRepository _repository;
  final UniversityRepository _uniRepository;
  final ScheduleService _service;

  List<ScheduleItem> _schedule = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _activeProfileId;

  List<ScheduleItem> get schedule => _schedule;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSchedule => _schedule.isNotEmpty;

  ScheduleViewModel(this._repository, this._uniRepository, this._service) {
    loadScheduleForActiveProfile();
  }

  Future<void> loadScheduleForActiveProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _activeProfileId = prefs.getInt('active_profile_id');

      if (_activeProfileId != null) {
        _schedule = await _repository.getSchedule(_activeProfileId!);
        _errorMessage = null;
      } else {
        _schedule = [];
      }
    } catch (e) {
      _errorMessage = "Program yüklenirken hata: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> pickAndUploadSchedule() async {
    if (_activeProfileId == null) {
      _errorMessage = "Aktif profil bulunamadı.";
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final deptGuid = prefs.getString('user_department_guid');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);

        final parsedItems = await _service.extractSchedule(file);

        if (parsedItems.isEmpty) {
          _errorMessage = "PDF'ten ders programı okunamadı.";
          _isLoading = false;
          notifyListeners();
          return false;
        }

        List<ScheduleItem> linkedItems = parsedItems;

        if (deptGuid != null) {
          try {
            final courses = await _uniRepository.fetchCoursesByDepartment(deptGuid);

            linkedItems = _service.linkScheduleToCourses(parsedItems, courses);

          } catch (e) {
            print("Ders eşleştirme hatası (kritik değil, eşleşmeden devam ediliyor): $e");
          }
        }

        final finalItems = linkedItems.map((item) => ScheduleItem(
            profileId: _activeProfileId!,
            courseCode: item.courseCode,
            day: item.day,
            time: item.time,
            courseName: item.courseName,
            instructor: item.instructor,
            location: item.location,
            semester: item.semester
        )).toList();

        await _repository.saveSchedule(_activeProfileId!, finalItems);

        _schedule = finalItems;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Hata oluştu: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  ScheduleItem? getNextClass() {
    if (_schedule.isEmpty) return null;

    final now = DateTime.now();
    final todayWeekday = now.weekday;

    const dayMap = {
      1: "Pazartesi", 2: "Salı", 3: "Çarşamba",
      4: "Perşembe", 5: "Cuma"
    };

    final todayString = dayMap[todayWeekday];
    if (todayString == null) return null;

    final todaysClasses = _schedule.where((s) => s.day == todayString).toList();

    for (var item in todaysClasses) {
      final parts = item.time.split('-');
      if (parts.isEmpty) continue;

      final startPart = parts[0].trim().replaceAll('.', ':');

      try {
        final p = startPart.split(':');
        final classTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));

        final nowTime = TimeOfDay.fromDateTime(now);
        final nowMinutes = nowTime.hour * 60 + nowTime.minute;
        final classMinutes = classTime.hour * 60 + classTime.minute;

        if (classMinutes > nowMinutes - 50) {
          return item;
        }
      } catch (e) {
        continue;
      }
    }

    return null;
  }
}