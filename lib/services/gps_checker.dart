import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/gps_status.dart';

class GpsChecker {
  Future<GpsStatus> check({String accuracy = 'high'}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return GpsStatus.empty();
    }

    LocationAccuracy acc;
    switch (accuracy) {
      case 'low':
        acc = LocationAccuracy.low;
        break;
      case 'high':
        acc = LocationAccuracy.high;
        break;
      case 'max':
        acc = LocationAccuracy.bestForNavigation;
        break;
      default:
        acc = LocationAccuracy.high;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: acc,
        timeLimit: const Duration(seconds: 3),
      );
      return GpsStatus(
        isFixed: true,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        bearing: position.heading,
        altitude: position.altitude,
      );
    } catch (_) {
      return GpsStatus.empty();
    }
  }
}