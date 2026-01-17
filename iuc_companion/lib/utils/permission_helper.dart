import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {

  static Future<bool> ensureNotificationPermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;
    if (await Permission.notification.isGranted) return true;
    return await _requestPermission(
        context, Permission.notification, "Bildirim İzni",
        "Duyurular ve sessiz mod durumu hakkında bilgi alabilmeniz için bildirim izni gereklidir."
    );
  }

  static Future<bool> ensureActivityRecognition(BuildContext context) async {
    if (!Platform.isAndroid) return true;
    if (await Permission.activityRecognition.isGranted) return true;
    return await _requestPermission(
        context, Permission.activityRecognition, "Fiziksel Aktivite İzni",
        "Okul bölgesine giriş/çıkış hareketlerini algılayabilmek için bu izin gereklidir."
    );
  }

  static Future<bool> ensureDndAccess(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    var status = await Permission.accessNotificationPolicy.status;
    if (status.isGranted) return true;

    if (context.mounted) {
      bool goSettings = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Rahatsız Etme İzni"),
          content: const Text(
              "Telefonun sesini otomatik olarak kapatıp açabilmek için 'Rahatsız Etme' (Do Not Disturb) erişimi vermelisiniz."
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Ayarlara Git")),
          ],
        ),
      ) ?? false;

      if (goSettings) {
        await Permission.accessNotificationPolicy.request();
        await Future.delayed(const Duration(seconds: 1));
        return await Permission.accessNotificationPolicy.isGranted;
      }
    }
    return false;
  }

  static Future<bool> ensureSchedulePermissions(BuildContext context) async {
    if (!await ensureNotificationPermission(context)) return false;

    if (!await ensureDndAccess(context)) return false;

    if (Platform.isAndroid) {
      var status = await Permission.scheduleExactAlarm.status;
      if (status.isGranted) return true;
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.scheduleExactAlarm.request();
        if (status.isGranted) return true;
        if (context.mounted) {
          _showSettingsDialog(context, "Alarm İzni",
              "Ders saatlerinde telefonun tam zamanında sessize alınabilmesi için 'Tam Zamanlı Alarm' izni gereklidir.");
        }
        return false;
      }
    }
    return true;
  }

  static Future<bool> ensureLocationPermissions(BuildContext context) async {
    if (!await ensureDndAccess(context)) return false;

    if (!await ensureActivityRecognition(context)) return false;

    bool foregroundOk = await _requestPermission(
        context, Permission.locationWhenInUse, "Konum İzni",
        "Okul bölgesine girdiğinizi algılamak için konum izni gereklidir."
    );
    if (!foregroundOk) return false;

    var bgStatus = await Permission.locationAlways.status;
    if (bgStatus.isGranted) return true;

    if (context.mounted) {
      bool userAgreed = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Her Zaman Konum İzni"),
          content: const Text("Uygulama kapalıyken bile okula girdiğinizi algılayıp telefonu sessize alabilmek için konum iznini 'Her Zaman İzin Ver' olarak ayarlamanız gerekmektedir."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Tamam")),
          ],
        ),
      ) ?? false;

      if (!userAgreed) return false;
      bgStatus = await Permission.locationAlways.request();
      if (bgStatus.isGranted) return true;
      if (context.mounted) {
        _showSettingsDialog(context, "Arkaplan Konum İzni", "Otomatik sessiz modun çalışması için ayarlardan konum iznini 'Her Zaman' olarak seçmelisiniz.");
      }
      return false;
    }
    return false;
  }

  static Future<bool> _requestPermission(BuildContext context, Permission permission, String title, String rationale) async {
    if (await permission.isGranted) return true;
    final status = await permission.request();
    if (status.isGranted) return true;
    if ((status.isPermanentlyDenied || status.isDenied) && context.mounted) {
      _showSettingsDialog(context, title, rationale);
    }
    return false;
  }

  static void _showSettingsDialog(BuildContext context, String title, String rationale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("$title Gerekli"),
        content: Text(rationale),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          TextButton(onPressed: () { Navigator.pop(ctx); openAppSettings(); }, child: const Text("Ayarlara Git")),
        ],
      ),
    );
  }
}