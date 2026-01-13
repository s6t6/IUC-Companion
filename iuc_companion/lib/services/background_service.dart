import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/local/app_database.dart';
import '../data/repositories/announcement_repository.dart';
import 'api_service.dart';
import 'school_zone_service.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'IUC Companion Servisi',
    description: 'Arkaplan servis bildirimleri',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'IUC Companion',
      initialNotificationContent: 'Otomatik sessize alma servisi çalışıyor',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final database = await AppDatabase.init();

  final announcementRepo = AnnouncementRepository(database, ApiService());
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });


  await SchoolZoneService(database).checkUserStatus();

  Timer.periodic(const Duration(minutes: 2), (timer) async {
    await SchoolZoneService(database).checkUserStatus();
    await _checkAnnouncementsIfNeeded(announcementRepo, flutterLocalNotificationsPlugin);
  });
}

Future<void> _checkAnnouncementsIfNeeded(
    AnnouncementRepository repo,
    FlutterLocalNotificationsPlugin notifPlugin
    ) async {
  try {
    final sources = await repo.getSources();
    final now = DateTime.now();

    for (var source in sources) {
      bool shouldCheck = false;

      if (source.lastCheckDate == null) {
        shouldCheck = true;
      } else {
        final lastCheck = DateTime.parse(source.lastCheckDate!);
        final difference = now.difference(lastCheck);
        if (difference.inHours >= 5) {
          shouldCheck = true;
        }
      }

      if (shouldCheck) {
        print("Checking announcements for: ${source.name}");
        final newItem = await repo.checkForNewAnnouncement(source);

        if (newItem != null) {
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'announcement_channel',
            'Duyurular',
            channelDescription: 'Yeni üniversite duyuruları',
            importance: Importance.max,
            priority: Priority.high,
          );
          const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

          await notifPlugin.show(
            source.id!,
            'Yeni Duyuru: ${source.name}',
            newItem.title,
            platformChannelSpecifics,
          );
        }
      }
    }
  } catch (e) {
    print("Duyuru kontrolünde hata oluştu: $e");
  }
}