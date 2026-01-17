import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:sqflite/sqflite.dart';
import '../data/repositories/announcement_repository.dart';
import '../di/locator.dart';

const String announcementTaskKey = "com.iuc_companion.announcement_check";
const String announcementChannelId = "announcement_channel";
const String announcementChannelName = "Duyurular";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == announcementTaskKey) {
      try {
        await setupDependencies();

        final repo = locator<AnnouncementRepository>();

        // Bildirimler
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

        await flutterLocalNotificationsPlugin.initialize(initializationSettings);

        const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          announcementChannelId,
          announcementChannelName,
          channelDescription: 'Yeni üniversite duyuruları',
          importance: Importance.max,
          priority: Priority.high,
        );
        const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

        final sources = await repo.getSources();
        for (var source in sources) {
          final newItem = await repo.checkForNewAnnouncement(source);

          if (newItem != null) {
            await flutterLocalNotificationsPlugin.show(
              source.id!,
              'Yeni Duyuru: ${source.name}',
              newItem.title,
              platformChannelSpecifics,
              payload: 'announcement_view',
            );
          }
        }

        return Future.value(true);

      } on DatabaseException catch (e) {
        // Race Condition olursa
        if (e.isDatabaseClosedError() || e.toString().toLowerCase().contains('locked')) {
          print("Duyuru Worker DB'ye yazamadı. Sonra tekrar denenecek... Hata: $e");
          return Future.value(false);
        }
        print("Duyuru Worker DB Hatası(Tekrar deneme başarısız): $e");
        return Future.value(true);

      } catch (e) {
        print("Duyuru Worker Genel Hata: $e");
        return Future.value(true);
      }
    }
    return Future.value(true);
  });
}

class AnnouncementWorkerService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      "iuc_announcement_check_task",
      announcementTaskKey,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}