import 'dart:async';
import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/api_service.dart';
import '../services/native_service.dart';

class ScheduleViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final NativeService _nativeService = NativeService();
  
  List<ScheduleModel> _schedule = [];
  Timer? _timer;
  
  List<ScheduleModel> get schedule => _schedule;

  // Başlatıcı
  void init(String userId) {
    _fetchSchedule(userId);
    // Her dakika kontrol et: Ders var mı?
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _checkAndSilencePhone());
  }

  Future<void> _fetchSchedule(String userId) async {
    _schedule = await _apiService.getSchedule(userId);
    notifyListeners();
    _checkAndSilencePhone(); // Veri gelince hemen kontrol et
  }

  void _checkAndSilencePhone() {
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
    
    // Günün ismini bul (Pazartesi, Salı...)
    String today = _getDayName(now.weekday);
    
    bool isClassTime = false;

    for (var lesson in _schedule) {
      if (lesson.day == today) {
        if (_isTimeBetween(currentTime, lesson.startTime, lesson.endTime)) {
          isClassTime = true;
          break;
        }
      }
    }

    // Duruma göre telefonu yönet
    _nativeService.setSilentMode(isClassTime);
  }

  bool _isTimeBetween(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    double nowMinutes = now.hour * 60.0 + now.minute;
    double startMinutes = start.hour * 60.0 + start.minute;
    double endMinutes = end.hour * 60.0 + end.minute;
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  String _getDayName(int weekday) {
    const days = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
    return days[weekday - 1];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}