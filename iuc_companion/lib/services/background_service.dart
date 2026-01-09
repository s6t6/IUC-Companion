import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'school_zone_service.dart';

@pragma('vm:entry-point')
void backgroundServiceStart(ServiceInstance service) {

  // Her 2 dakikada bir kontrol
  Timer.periodic(const Duration(minutes: 2), (timer) async {
    await SchoolZoneService().checkSchoolZone();
  });
}
