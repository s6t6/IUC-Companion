import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_mode/permission_handler.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';

class SoundService {
  static const String _prefLastModeKey = 'last_known_ringer_mode';

  Future<void> setSilent() async {
    bool? granted = await PermissionHandler.permissionsGranted;
    if (!granted!) {
      print("SoundService: Rahatsız Etme izinleri verilmedi.");
      return;
    }

    try {
      final currentStatus = await SoundMode.ringerModeStatus;

      if (currentStatus != RingerModeStatus.silent) {
        await _saveLastMode(currentStatus);

        await SoundMode.setSoundMode(RingerModeStatus.silent);
      }
    } catch (e) {
      print("SoundService Error (setSilent): $e");
    }
  }

  Future<void> revertToPrevious() async {
    bool? granted = await PermissionHandler.permissionsGranted;
    if (!granted!) return;

    try {
      final currentStatus = await SoundMode.ringerModeStatus;
      if (currentStatus == RingerModeStatus.silent) {

        final lastModeStr = await _getLastMode();
        RingerModeStatus targetMode = RingerModeStatus.normal;

        if (lastModeStr == 'vibrate') {
          targetMode = RingerModeStatus.vibrate;
        } else if (lastModeStr == 'normal') {
          targetMode = RingerModeStatus.normal;
        }

        await SoundMode.setSoundMode(targetMode);
      }
    } catch (e) {
      print("SoundService Error (revertToPrevious): $e");
    }
  }

  Future<void> _saveLastMode(RingerModeStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    String statusStr = 'normal';
    if (status == RingerModeStatus.vibrate) statusStr = 'vibrate';
    if (status == RingerModeStatus.silent) statusStr = 'silent';
    await prefs.setString(_prefLastModeKey, statusStr);
  }

  Future<String?> _getLastMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefLastModeKey);
  }

  Future<bool?> checkAndRequestPermission() async {
    bool? isGranted = await PermissionHandler.permissionsGranted;
    if (!isGranted!) {
      await PermissionHandler.openDoNotDisturbSetting();
      isGranted = await PermissionHandler.permissionsGranted;
    }
    return isGranted;
  }
}