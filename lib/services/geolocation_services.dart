import 'package:geolocator/geolocator.dart';

class GeolocationServices {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) {
        throw Exception("you have to able location service");
      }
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
            "need permission to continue using the app sorry for the disturb");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition(
      locationSettings:
          LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 20),
    );
  }
}
