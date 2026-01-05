import 'package:volume_controller/volume_controller.dart';

class SoundService {

  SoundService() {
    VolumeController().listener((volume) {});
  }

  Future<void> setSilent() async {
    VolumeController().setVolume(0);
  }

  Future<void> setNormal() async {
    VolumeController().setVolume(0.5);
  }
}
