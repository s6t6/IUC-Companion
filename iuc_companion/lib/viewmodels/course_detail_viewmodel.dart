import 'package:flutter/material.dart';
import '../data/models/course_detail.dart';
import '../data/repositories/university_repository.dart';

class CourseDetailViewModel extends ChangeNotifier {
  final UniversityRepository _repository;

  CourseDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  CourseDetail? get detail => _detail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CourseDetailViewModel(this._repository);

  Future<void> loadCourseDetail(String courseCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _detail = await _repository.fetchCourseDetail(courseCode);
    } catch (e) {
      _errorMessage = "Detaylar yüklenemedi: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}