import 'package:volume_controller/volume_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {

  static const String _keyIsSilencedByApp = 'is_silenced_by_app';
  static const String _keyPreviousVolume = 'previous_volume';

  Future<void> setSilent() async {
    final prefs = await SharedPreferences.getInstance();
    bool isSilencedByApp = prefs.getBool(_keyIsSilencedByApp) ?? false;

    if (!isSilencedByApp) {
      double currentVol = await VolumeController.instance.getVolume();

      await prefs.setDouble(_keyPreviousVolume, currentVol);
      await prefs.setBool(_keyIsSilencedByApp, true);

      await VolumeController.instance.setVolume(0.0);
      print("SoundService: Volume saved ($currentVol) and muted.");
    }
  }

  Future<void> revertToPrevious() async {
    final prefs = await SharedPreferences.getInstance();
    bool isSilencedByApp = prefs.getBool(_keyIsSilencedByApp) ?? false;

    if (isSilencedByApp) {
      double prevVolume = prefs.getDouble(_keyPreviousVolume) ?? 0.5;

      await VolumeController.instance.setVolume(prevVolume);

      await prefs.remove(_keyIsSilencedByApp);
      await prefs.remove(_keyPreviousVolume);
      print("SoundService: Volume reverted to $prevVolume.");
    }
  }
}