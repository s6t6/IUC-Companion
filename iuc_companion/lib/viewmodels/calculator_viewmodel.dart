import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/api_service.dart';

class CalculatorViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  final List<CourseModel> _courses = [];
  double _currentGpa = 0.0;
  bool _isLoading = false;

  List<CourseModel> get courses => _courses;
  double get currentGpa => _currentGpa;
  bool get isLoading => _isLoading;

  // Manuel Ders Ekleme
  void addCourse(String name, int credit, String grade) {
    _courses.add(CourseModel(name: name, credit: credit, grade: grade));
    calculateGpa();
  }

  // Listeden Silme
  void removeCourse(int index) {
    _courses.removeAt(index);
    calculateGpa();
  }

  // Transkriptten Çekme
  Future<void> loadFromTranscript(String fileId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Backend'e dosyayı gönder ve analiz edilmiş dersleri al
      List<CourseModel> fetchedCourses = await _apiService.parseTranscript(fileId);
      _courses.addAll(fetchedCourses);
      calculateGpa();
    } catch (e) {
      print("Hata: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  void calculateGpa() {
    if (_courses.isEmpty) {
      _currentGpa = 0.0;
    } else {
      double totalPoints = 0;
      int totalCredits = 0;
      for (var course in _courses) {
        totalPoints += course.numericGrade * course.credit;
        totalCredits += course.credit;
      }
      _currentGpa = totalCredits == 0 ? 0 : totalPoints / totalCredits;
    }
    notifyListeners();
  }
}