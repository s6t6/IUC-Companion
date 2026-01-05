import 'dart:io'; // Platform kontrolü için (Windows mu Android mi?)
import 'package:sound_mode/sound_mode.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
class NativeService {
  Future<void> setSilentMode(bool silent) async {
    // 1. KONTROL: Eğer Mobil değilse (Windows/Test) hiç çalıştırma, geri dön.
    if (!Platform.isAndroid && !Platform.isIOS) {
      print("BİLGİSAYAR/TEST MODU: Sessize alma işlemi atlandı.");
      return;
    }

    try {
      // 2. KONTROL: İzinler (Sadece mobilde çalışır)
      bool isGranted = await Permission.accessNotificationPolicy.isGranted;
      if (!isGranted) {
        await Permission.accessNotificationPolicy.request();
      }

      // 3. İŞLEM: Sessize al veya Sesi aç
      if (silent) {
        await SoundMode.setSoundMode(RingerModeStatus.vibrate);
        print("Telefon Titreşim Moduna Alındı");
      } else {
        await SoundMode.setSoundMode(RingerModeStatus.normal);
        print("Telefon Sesi Açıldı");
      }
    } catch (e) {
      // Hata olsa bile uygulama çökmesin, sadece konsola yazsın.
      print("Sessize alma sırasında hata oluştu (Önemli değil): $e");
    }
  }
}