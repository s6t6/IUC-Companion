import 'package:geolocator/geolocator.dart';
import '../models/school_location.dart';
import 'location_service.dart';
import 'sound_service.dart';

class SchoolZoneService {
  final LocationService _locationService = LocationService();
  final SoundService _soundService = SoundService();

  Future<void> checkSchoolZone() async {
    final userPosition =
        await _locationService.getCurrentLocation();

    double distance = Geolocator.distanceBetween(
      SchoolLocation.latitude,
      SchoolLocation.longitude,
      userPosition.latitude,
      userPosition.longitude,
    );

    if (distance <= SchoolLocation.radius) {
      await _soundService.setSilent();
    } else {
      await _soundService.setNormal();
    }
  }
}
