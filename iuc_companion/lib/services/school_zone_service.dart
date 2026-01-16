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
    s.day.trim().toLowerCase() == todayString.toLowerCase()
    ).toList();

    if (todaysClasses.isEmpty) return false;

    final nowMinutes = now.hour * 60 + now.minute;

    final regex = RegExp(r'(\d{1,2})[:.](\d{2})');

    for (var item in todaysClasses) {
      try {
        final matches = regex.allMatches(item.time).toList();
        if (matches.length < 2) continue;

        final startH = int.parse(matches[0].group(1)!);
        final startM = int.parse(matches[0].group(2)!);
        final endH = int.parse(matches[1].group(1)!);
        final endM = int.parse(matches[1].group(2)!);

        final start = startH * 60 + startM;
        final end = endH * 60 + endM;

        if (nowMinutes >= (start - 5) && nowMinutes < end) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }
}