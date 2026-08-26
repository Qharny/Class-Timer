import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'local_storage_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<void> checkProximityToCampus() async {
    try {
      // Only run if the user has actually set their campus location — we
      // must not request/act on location for a feature that has nothing
      // real to compare against.
      final program = LocalStorageService().getProgram();
      final campusLat = program?.campusLat;
      final campusLng = program?.campusLng;
      if (campusLat == null || campusLng == null) return;

      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        campusLat,
        campusLng,
      );

      // If more than 1.5km away
      if (distance > 1500) {
        _checkScheduleAndNotify();
      }
    } catch (e) {
      debugPrint('LocationService checkProximityToCampus error: $e');
    }
  }

  /// Requests location permission if needed and returns the device's
  /// current position, for an explicit, user-initiated action (e.g. "set my
  /// campus location" while the user is standing on campus). Returns null
  /// if location services/permissions aren't available.
  Future<Position?> captureCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('LocationService captureCurrentPosition error: $e');
      return null;
    }
  }

  Future<void> _checkScheduleAndNotify() async {
    final storage = LocalStorageService();
    final events = storage.getAllClassEvents();
    final now = DateTime.now();

    for (var event in events) {
      if (event.dayOfWeek == now.weekday) {
        final startTime = _parseTimeString(event.startTime);
        final diff = startTime.difference(now).inMinutes;

        if (diff > 0 && diff <= 15) {
          await NotificationService().sendInstantNotification(
            id: 2000,
            title: '🏃 Still far from campus?',
            body:
                'Your ${event.title} class starts in $diff mins. Better hurry!',
          );
        }
      }
    }
  }

  DateTime _parseTimeString(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
