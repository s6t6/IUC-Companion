import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/faculty.dart';
import '../data/models/department.dart';
import '../data/models/student_grade.dart';
import '../data/models/schedule_item.dart';
import '../data/models/profile.dart';
import '../data/repositories/university_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../services/transcript_service.dart';
import '../services/schedule_service.dart';

class OnboardingViewModel extends ChangeNotifier {
  final UniversityRepository _universityRepository;
  final ScheduleRepository _scheduleRepository;
  final TranscriptService _transcriptService;
  final ScheduleService _scheduleService;

  // State
  List<Faculty> _faculties = [];
  List<Department> _departments = [];

  Faculty? _selectedFaculty;
  Department? _selectedDepartment;
  String _profileName = "";

  // Temp
  List<StudentGrade> _tempGrades = [];
  List<ScheduleItem> _tempSchedule = [];

  bool _isLoading = false;
  String? _errorMessage;
  int _currentStep = 0;

  String? _uploadedTranscriptName;
  String? _uploadedScheduleName;

  // Getters
  List<Faculty> get faculties => _faculties;
  List<Department> get departments => _departments;
  Faculty? get selectedFaculty => _selectedFaculty;
  Department? get selectedDepartment => _selectedDepartment;
  String get profileName => _profileName;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentStep => _currentStep;

  String? get uploadedTranscriptName => _uploadedTranscriptName;
  int get extractedCourseCount => _tempGrades.length;

  String? get uploadedScheduleName => _uploadedScheduleName;
  bool get hasSchedule => _tempSchedule.isNotEmpty;

  bool get isStep1Valid => _selectedDepartment != null && _profileName.trim().isNotEmpty;

  OnboardingViewModel(
      this._universityRepository,
      this._scheduleRepository,
      this._transcriptService,
      this._scheduleService,
      ) {
    _loadFaculties();
  }

  void reset() {
    _currentStep = 0;
    _profileName = "";
    _selectedFaculty = null;
    _selectedDepartment = null;
    _departments = [];

    _tempGrades = [];
    _tempSchedule = [];
    _uploadedTranscriptName = null;
    _uploadedScheduleName = null;

    _errorMessage = null;
    _isLoading = false;
    notifyListeners();

    if (_faculties.isEmpty) _loadFaculties();
  }

  void setProfileName(String name) {
    _profileName = name;
    notifyListeners();
  }

  Future<void> _loadFaculties() async {
    _setLoading(true);
    try {
      _faculties = await _universityRepository.fetchFaculties();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Fakülteler yüklenirken hata: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> selectFaculty(Faculty? faculty) async {
    if (faculty == null) return;
    _selectedFaculty = faculty;
    _selectedDepartment = null;
    _departments = [];
    notifyListeners();
    await _loadDepartments(faculty.id);
  }

  Future<void> _loadDepartments(int facultyId) async {
    _setLoading(true);
    try {
      _departments = await _universityRepository.fetchDepartments(facultyId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Bölümler yüklenemedi: $e";
    } finally {
      _setLoading(false);
    }
  }

  void selectDepartment(Department? department) {
    _selectedDepartment = department;
    notifyListeners();
  }

  Future<void> pickAndProcessTranscript() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        _uploadedTranscriptName = result.files.single.name;
        _setLoading(true);

        Map<String, String> grades = await _transcriptService.extractGrades(file);

        if (grades.isNotEmpty) {
          _tempGrades = grades.entries
              .map((e) => StudentGrade(
              profileId: 0,
              courseCode: e.key,
              letterGrade: e.value))
              .toList();
        }

        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Dosya işlenirken hata: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pickAndProcessSchedule() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        _uploadedScheduleName = result.files.single.name;
        _setLoading(true);

        try {
          final rawItems = await _scheduleService.extractSchedule(file);

          if (_selectedDepartment != null) {
            final courses = await _universityRepository
                .fetchCoursesByDepartment(_selectedDepartment!.guid);

            _tempSchedule =
                _scheduleService.linkScheduleToCourses(rawItems, courses);
          } else {
            _tempSchedule = rawItems;
          }

          _errorMessage = null;
        } catch (e) {
          _errorMessage = e.toString().replaceAll("Exception:", "").trim();
          _tempSchedule = [];
          _uploadedScheduleName = null;
        }

        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Dosya seçimi sırasında hata: $e";
    } finally {
      _setLoading(false);
    }
  }

  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void prevStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  Future<bool> completeOnboarding() async {
    if (_selectedDepartment == null) return false;

    try {
      final prefs = await SharedPreferences.getInstance();

      final newProfile = Profile(
        profileName: _profileName.trim(),
        departmentGuid: _selectedDepartment!.guid,
        departmentName: _selectedDepartment!.name,
        facultyId: _selectedDepartment!.facultyId,
      );

      int profileId = await _universityRepository.createProfile(newProfile);

      if (_tempGrades.isNotEmpty) {
        final finalGrades = _tempGrades
            .map((g) => StudentGrade(
            profileId: profileId,
            courseCode: g.courseCode,
            letterGrade: g.letterGrade))
            .toList();

        await _universityRepository.saveGrades(finalGrades);
      }

      if (_tempSchedule.isNotEmpty) {
        final finalSchedule = _tempSchedule
            .map((s) => ScheduleItem(
            profileId: profileId,
            courseCode: s.courseCode,
            day: s.day,
            time: s.time,
            courseName: s.courseName,
            instructor: s.instructor,
            location: s.location,
            semester: s.semester))
            .toList();

        await _scheduleRepository.saveSchedule(profileId, finalSchedule);
      }

      await prefs.setInt('active_profile_id', profileId);
      await prefs.setString('user_department_guid', _selectedDepartment!.guid);
      await prefs.setString('user_department_name', _selectedDepartment!.name);

      return true;
    } catch (e) {
      _errorMessage = "Kaydetme hatası: $e";
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}