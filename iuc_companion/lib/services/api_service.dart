import '../models/user_model.dart';
import '../models/file_model.dart';
import '../models/course_model.dart';
import '../models/schedule_model.dart';
import 'package:flutter/material.dart';

class ApiService {
  // Base URL (Gerçek sunucun olunca burayı değiştir)
  final String baseUrl = "https://api.companionapp.com";

  // --- AUTH ---
  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Ağ gecikmesi simülasyonu
    
    // Gerçek API Kodu:
    // var response = await http.post(Uri.parse('$baseUrl/login'), body: {'email': email, 'password': password});
    // if (response.statusCode == 200) return UserModel.fromJson(jsonDecode(response.body));

    if (password == '123456') {
      return UserModel(
        id: "user_123",
        name: "Kubilay Özkan",
        studentNo: "1316230077",
        department: "Bilgisayar Müh.",
        token: "fake_jwt_token_123456",
      );
    }
    return null;
  }

  // --- DOSYALAR ---
  Future<List<FileModel>> getUserFiles(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      FileModel(id: "1", name: "Transkript_Guz_2024.pdf", type: "TRANSCRIPT", uploadDate: DateTime.now().subtract(const Duration(days: 5)), url: "link"),
      FileModel(id: "2", name: "Ders_Plani.pdf", type: "SYLLABUS", uploadDate: DateTime.now().subtract(const Duration(days: 20)), url: "link"),
    ];
  }

  // --- TRANSKRİPT ANALİZİ (OCR Simülasyonu) ---
  Future<List<CourseModel>> parseTranscript(String fileId) async {
    await Future.delayed(const Duration(seconds: 2)); // Sunucuda PDF işleniyor...
    return [
      CourseModel(name: "Matematik I", credit: 4, grade: "AA"),
      CourseModel(name: "Fizik I", credit: 3, grade: "BA"),
      CourseModel(name: "Programlamaya Giriş", credit: 5, grade: "AA"),
      CourseModel(name: "Türk Dili", credit: 2, grade: "BB"),
    ];
  }

  // --- DERS PROGRAMI ÇEKME ---
  Future<List<ScheduleModel>> getSchedule(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ScheduleModel(id: "1", day: "Çarşamba", startTime: const TimeOfDay(hour: 09, minute: 00), endTime: const TimeOfDay(hour: 11, minute: 50), courseName: "Kriptoloji", location: "D-526"),
      ScheduleModel(id: "2", day: "Çarşamba", startTime: const TimeOfDay(hour: 13, minute: 00), endTime: const TimeOfDay(hour: 14, minute: 50), courseName: "Bilgisayar Aritmetiği", location: "D-523"),
       // Test için şu anki saate yakın bir ders ekleyelim:
      ScheduleModel(id: "3", day: DateTime.now().weekday == 3 ? "Çarşamba" : _getDayName(DateTime.now().weekday), startTime: TimeOfDay(hour: DateTime.now().hour, minute: DateTime.now().minute), endTime: TimeOfDay(hour: DateTime.now().hour + 1, minute: 0), courseName: "Test Dersi", location: "Lab"),
    ];
  }
  
  String _getDayName(int weekday) {
    const days = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
    return days[weekday - 1];
  }
}