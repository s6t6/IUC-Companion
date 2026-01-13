import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/school_location.dart';
import '../data/local/app_database.dart';
import '../data/models/schedule_item.dart';
import 'location_service.dart';
import 'sound_service.dart';

enum SilentModeOption {
  none,
  locationOnly,
  scheduleOnly,
  locationAndSchedule
}

class SchoolZoneService {
  final LocationService _locationService = LocationService();
  final SoundService _soundService = SoundService();

  final AppDatabase database;

  SchoolZoneService(this.database);

  static const String prefModeKey = 'silent_mode_preference';

  Future<void> checkUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    int modeIndex = prefs.getInt(prefModeKey) ?? 3;
    SilentModeOption mode = SilentModeOption.values[modeIndex];

    if (mode == SilentModeOption.none) {
      await _soundService.revertToPrevious();
      return;
    }

    bool shouldBeSilent = false;
    try {
      if (mode == SilentModeOption.locationOnly) {
        shouldBeSilent = await _isInsideCampus();
      }
      else if (mode == SilentModeOption.scheduleOnly) {
        shouldBeSilent = await _hasActiveCourseNow();
      }
      else if (mode == SilentModeOption.locationAndSchedule) {
        bool inside = await _isInsideCampus();
        if (inside) {
          shouldBeSilent = await _hasActiveCourseNow();
        } else {
          shouldBeSilent = false;
        }
      }

      if (shouldBeSilent) {
        await _soundService.setSilent();
      } else {
        await _soundService.revertToPrevious();
      }
    } catch (e) {
      print("Error in SchoolZoneService: $e");
      await _soundService.revertToPrevious();
    }
  }

  Future<bool> _isInsideCampus() async {
    try {
      final userPosition = await _locationService.getCurrentLocation();
      double distance = Geolocator.distanceBetween(
        SchoolLocation.latitude,
        SchoolLocation.longitude,
        userPosition.latitude,
        userPosition.longitude,
      );
      return distance <= SchoolLocation.radius;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _hasActiveCourseNow() async {

    final prefs = await SharedPreferences.getInstance();
    final activeProfileId = prefs.getInt('active_profile_id');

    if (activeProfileId == null) return false;

    final activeCoursesList = await database.activeCourseDao.getActiveCourses(activeProfileId);
    if (activeCoursesList.isEmpty) return false;

    final activeCourseCodes = activeCoursesList.map((e) => e.courseCode).toSet();
    final fullSchedule = await database.scheduleDao.getScheduleForProfile(activeProfileId);

    final effectiveSchedule = fullSchedule.where((item) {
      return item.courseCode != null && activeCourseCodes.contains(item.courseCode);
    }).toList();

    if (effectiveSchedule.isEmpty) return false;

    return _isTimeMatchingClass(effectiveSchedule);
  }

  bool _isTimeMatchingClass(List<ScheduleItem> items) {
    final now = DateTime.now();
    const dayMap = {
      1: "Pazartesi", 2: "Salı", 3: "Çarşamba",
      4: "Perşembe", 5: "Cuma", 6: "Cumartesi", 7: "Pazar"
    };

    final todayString = dayMap[now.weekday];
    if (todayString == null) return false;

    final todaysClasses = items.where((s) =>
    s.day.toLowerCase() == todayString.toLowerCase()
    ).toList();

    if (todaysClasses.isEmpty) return false;

    final nowMinutes = now.hour * 60 + now.minute;

    for (var item in todaysClasses) {
      try {
        final times = item.time.split('-');
        if (times.length < 2) continue;

        final start = _parseToMinutes(times[0]);
        final end = _parseToMinutes(times[1]);

        if (nowMinutes >= (start - 5) && nowMinutes < end) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  int _parseToMinutes(String timeStr) {
    final clean = timeStr.trim().replaceAll('.', ':');
    final parts = clean.split(':');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}