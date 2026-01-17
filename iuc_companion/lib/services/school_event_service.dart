import 'dart:async';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local/app_database.dart';
import '../models/school_location.dart';
import '../di/locator.dart';
import 'sound_service.dart';

const String _keyInSchool = 'state_in_school';
const String _keyHasClass = 'state_has_class';
const String _keySilentModePref = 'silent_mode_preference';
const String _keyLastAppliedState = 'last_applied_silent_state';
const String _foregroundChannelId = 'my_foreground';

const int _alarmIdBase = 1000;
const int _alarmIdScheduler = 9999;
const int _maxAlarms = 50;

@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  await setupDependencies();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  print("Arkaplan Servisi başlatıldı.");

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    print("Arkaplan Servisi: Konum izinleri reddedildi.");
  }

  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 20,
  );

  Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
      final double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        SchoolLocation.latitude,
        SchoolLocation.longitude,
      );

      final bool isInside = distanceInMeters <= SchoolLocation.radius;
      print("Arkaplan Servisi: Loc: ${position.latitude},${position.longitude} | Dist: ${distanceInMeters.toStringAsFixed(1)}m | Inside: $isInside");

      SchoolEventService.handleLocationUpdate(isInside);
    },
    onError: (e) {
      print("Arkaplan Servisi: Hata: $e");
    },
  );
}

@pragma('vm:entry-point')
class SchoolEventService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    int mode = prefs.getInt(_keySilentModePref) ?? 0;
    if (mode != 0) {
      await startService();
    }
  }

  static Future<void> startService() async {
    await AndroidAlarmManager.initialize();
    await _ensureServicesInitialized();

    final prefs = await SharedPreferences.getInstance();
    int mode = prefs.getInt(_keySilentModePref) ?? 0;

    await prefs.setBool(_keyInSchool, false);
    await prefs.setBool(_keyHasClass, false);
    await prefs.remove(_keyLastAppliedState);

    final bgService = FlutterBackgroundService();

    if (mode == 1 || mode == 3) {
      await bgService.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onBackgroundServiceStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: _foregroundChannelId,
          initialNotificationTitle: 'IUC Companion',
          initialNotificationContent: 'Konum takibi aktif',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(),
      );
      await bgService.startService();
    } else {
      if (await bgService.isRunning()) {
        bgService.invoke("stopService");
      }
    }

    if (mode == 2 || mode == 3) {
      await _runSchedulerLogic();
    } else {
      await AndroidAlarmManager.cancel(_alarmIdScheduler);
      for (int i = 0; i < _maxAlarms; i++) {
        await AndroidAlarmManager.cancel(_alarmIdBase + (i * 2));
        await AndroidAlarmManager.cancel(_alarmIdBase + (i * 2) + 1);
      }
    }
  }

  static Future<void> stopService() async {
    final bgService = FlutterBackgroundService();
    if (await bgService.isRunning()) {
      bgService.invoke("stopService");
    }

    await AndroidAlarmManager.cancel(_alarmIdScheduler);
    for (int i = 0; i < _maxAlarms; i++) {
      await AndroidAlarmManager.cancel(_alarmIdBase + (i * 2));
      await AndroidAlarmManager.cancel(_alarmIdBase + (i * 2) + 1);
    }

    await SoundService().revertToPrevious();
  }


  static Future<void> handleLocationUpdate(bool isInside) async {
    await _ensureServicesInitialized();

    final prefs = await SharedPreferences.getInstance();
    bool wasInside = prefs.getBool(_keyInSchool) ?? false;

    if (isInside != wasInside) {
      await prefs.setBool(_keyInSchool, isInside);
      await _evaluateSoundMode(trigger: isInside ? "Kampüse Giriş" : "Kampüsten Çıkış");
    }
  }

  @pragma('vm:entry-point')
  static Future<void> scheduleDailyAlarms() async {
    try {
      await setupDependencies();
      await _runSchedulerLogic();
    } catch (e) {
      print("Scheduler Hatası: $e");
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onClassStart(int id) async {
    try {
      await setupDependencies();
      print("ALARM: Ders Başlangıcı");
      await _ensureServicesInitialized();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasClass, true);
      await _evaluateSoundMode(trigger: "Ders Başlangıcı");
    } catch (e) { print("Alarm Hata: $e"); }
  }

  @pragma('vm:entry-point')
  static Future<void> onClassEnd(int id) async {
    try {
      await setupDependencies();
      print("ALARM: Ders Bitişi");
      await _ensureServicesInitialized();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasClass, false);
      await _evaluateSoundMode(trigger: "Ders Bitişi");
    } catch (e) { print("Alarm Hata: $e"); }
  }

  static Future<void> _ensureServicesInitialized() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _foregroundChannelId,
      'IUC Companion Servisi',
      description: 'Arkaplan servis bildirimleri',
      importance: Importance.low,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _evaluateSoundMode({String? trigger}) async {
    final prefs = await SharedPreferences.getInstance();

    bool inSchool = prefs.getBool(_keyInSchool) ?? false;
    bool hasClass = prefs.getBool(_keyHasClass) ?? false;
    int modePref = prefs.getInt(_keySilentModePref) ?? 0;
    bool lastState = prefs.getBool(_keyLastAppliedState) ?? false;

    bool shouldBeSilent = false;

    switch (modePref) {
      case 1: shouldBeSilent = inSchool; break;
      case 2: shouldBeSilent = hasClass; break;
      case 3: shouldBeSilent = inSchool && hasClass; break;
      default: shouldBeSilent = false; break;
    }

    if (shouldBeSilent != lastState) {
      final soundService = SoundService();
      try {
        if (shouldBeSilent) {
          await soundService.setSilent();
          await _sendNotification("Sessiz Mod Aktif", "${trigger ?? 'Otomatik'}: Telefon sessize alındı.");
        } else {
          await soundService.revertToPrevious();
          await _sendNotification("Normal Mod", "${trigger ?? 'Otomatik'}: Ses profili geri yüklendi.");
        }
        await prefs.setBool(_keyLastAppliedState, shouldBeSilent);
      } catch (e) {
        print("Ses Profili Hatası: $e");
      }
    }
  }

  static Future<void> _runSchedulerLogic() async {

    final database = locator<AppDatabase>();

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileId = prefs.getInt('active_profile_id');

      if (profileId != null) {
        await _scheduleForDate(DateTime.now(), database, profileId);
      }

      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 1);

      await AndroidAlarmManager.oneShotAt(
        tomorrow,
        _alarmIdScheduler,
        scheduleDailyAlarms,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    } catch(e) {
      print("Scheduler mantık hatası: $e");
    }
  }

  static Future<void> _scheduleForDate(DateTime date, AppDatabase database, int profileId) async {
    final schedule = await database.scheduleDao.getScheduleForProfile(profileId);
    final activeCourses = await database.activeCourseDao.getActiveCourses(profileId);
    final activeCodes = activeCourses.map((e) => e.courseCode.toUpperCase()).toSet();
    final dayWeekday = _getWeekdayString(date.weekday);

    final daysClasses = schedule.where((item) =>
    item.day.toLowerCase() == dayWeekday &&
        item.courseCode != null &&
        activeCodes.contains(item.courseCode!.toUpperCase())
    ).toList();

    int alarmIndex = 0;
    for (var item in daysClasses) {
      if (alarmIndex >= _maxAlarms) break;
      final range = _parseTime(item.time);
      if (range == null) continue;

      final startDateTime = DateTime(date.year, date.month, date.day, range.startH, range.startM);
      final endDateTime = DateTime(date.year, date.month, date.day, range.endH, range.endM);

      if (startDateTime.isAfter(DateTime.now().subtract(const Duration(seconds: 5)))) {
        await AndroidAlarmManager.oneShotAt(
          startDateTime,
          _alarmIdBase + (alarmIndex * 2),
          onClassStart,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
      }

      if (endDateTime.isAfter(DateTime.now())) {
        await AndroidAlarmManager.oneShotAt(
          endDateTime,
          _alarmIdBase + (alarmIndex * 2) + 1,
          onClassEnd,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
      }
      alarmIndex++;
    }
  }

  static Future<void> _sendNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'silent_mode_channel', 'Sessiz Mod Bildirimleri',
      channelDescription: 'Otomatik sessiz mod durumu değişimleri',
      importance: Importance.high,
      priority: Priority.high,
    );
    int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _notificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(android: androidDetails),
        payload: 'silent_mode_view'
    );
  }

  static String _getWeekdayString(int weekday) {
    const dayMap = { 1: "pazartesi", 2: "salı", 3: "çarşamba", 4: "perşembe", 5: "cuma", 6: "cumartesi", 7: "pazar" };
    return dayMap[weekday] ?? "";
  }

  static ({int startH, int startM, int endH, int endM})? _parseTime(String timeStr) {
    try {
      final regex = RegExp(r'(\d{1,2})[:.](\d{2})');
      final matches = regex.allMatches(timeStr).toList();
      if (matches.length >= 2) {
        return (
        startH: int.parse(matches[0].group(1)!),
        startM: int.parse(matches[0].group(2)!),
        endH: int.parse(matches[1].group(1)!),
        endM: int.parse(matches[1].group(2)!),
        );
      }
    } catch (_) {}
    return null;
  }
}