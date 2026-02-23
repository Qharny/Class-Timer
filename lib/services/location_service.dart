import 'package:geolocator/geolocator.dart';
import 'notification_service.dart';
import 'local_storage_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Mock Campus Coordinates (e.g. University of Ghana)
  static const double campusLat = 5.6506;
  static const double campusLng = -0.1962;

  Future<void> checkProximityToCampus() async {
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
            body: 'Your ${event.title} class starts in $diff mins. Better hurry!',
          );
        }
      }
    }
  }

  DateTime _parseTimeString(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }
}
