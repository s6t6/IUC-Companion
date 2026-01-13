import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../data/models/faculty.dart';
import '../data/models/department.dart';
import '../data/models/course.dart';
import '../data/models/course_detail.dart';

class ApiService {
  static const String baseUrl = AppConfig.apiBaseUrl;

  Future<List<Faculty>> getFaculties() async {
    final response = await http.get(Uri.parse('$baseUrl/faculties'))
    .timeout(AppConfig.apiTimeout);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Faculty.fromJson(item)).toList();
    } else {
      throw Exception('Fakülteler yüklenemedi: ${response.statusCode}');
    }
  }

  Future<CourseDetail> getCourseDetail(String courseCode) async {
    final response = await http.get(Uri.parse('$baseUrl/course-detail?code=$courseCode'))
        .timeout(AppConfig.apiTimeout);

    if (response.statusCode == 200) {
      return CourseDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ders detayı bulunamadı');
    }
  }
  Future<List<Department>> getDepartments({int? facultyId}) async {
    String url = '$baseUrl/departments';
    if (facultyId != null) {
      url += '?faculty_id=$facultyId';
    }

    final response = await http.get(Uri.parse(url))
        .timeout(AppConfig.apiTimeout);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Department.fromJson(item)).toList();
    } else {
      throw Exception('Bölümler yüklenemedi');
    }
  }

  Future<List<Course>> getCourses(String departmentGuid) async {
    final response = await http.get(Uri.parse('$baseUrl/courses?id=$departmentGuid'))
        .timeout(AppConfig.apiTimeout);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Course.fromJson(item)).toList();
    } else {
      throw Exception('Dersler yüklenemedi');
    }
  }

  Future<List<dynamic>> getAnnouncements(String siteKey, int categoryId) async {
    final url = 'https://service-cms.iuc.edu.tr/api/webclient/f_getNotices?siteKey=$siteKey&Categoryid=$categoryId&Page=1';

    try {
      final response = await http.get(Uri.parse(url)).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // API yapısına göre data > Data > Data şeklinde liste dönüyor
        return json['Data']['Data'] ?? [];
      }
    } catch (e) {
      print("Duyuru çekme hatası ($siteKey): $e");
    }
    return [];
  }
}