import 'package:geolocator/geolocator.dart';

class LocationRiskAnalyzer {
  Future<Map<String, String>> analyze() async {
    final pos = await Geolocator.getCurrentPosition();
    return {
      "lat": pos.latitude.toString(),
      "lon": pos.longitude.toString(),
      "risk": "LOW"
    };
  }
}
