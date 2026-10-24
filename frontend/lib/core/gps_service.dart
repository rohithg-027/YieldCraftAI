import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class GpsLocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String? district;
  final String? state;
  final String? village;
  final bool isGpsHardware;

  GpsLocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.district,
    this.state,
    this.village,
    required this.isGpsHardware,
  });
}

class GpsService {
  static Future<GpsLocationResult?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (serviceEnabled &&
          (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse)) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        final address = await _reverseGeocode(position.latitude, position.longitude);

        return GpsLocationResult(
          latitude: double.parse(position.latitude.toStringAsFixed(5)),
          longitude: double.parse(position.longitude.toStringAsFixed(5)),
          accuracy: position.accuracy,
          district: address['district'],
          state: address['state'],
          village: address['village'],
          isGpsHardware: true,
        );
      }
    } catch (e) {
      debugPrint("GpsService hardware lookup failed: $e. Falling back to IP-location.");
    }

    // IP Geolocation fallback (useful for emulators, desktop, or when GPS is unavailable)
    return await _fallbackIpLocation();
  }

  static Future<Map<String, String?>> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=14&addressdetails=1',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'YieldCraftAI-MobileApp/1.0',
      }).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final village = addr['village'] ?? addr['suburb'] ?? addr['neighbourhood'] ?? addr['town'];
          final district = addr['state_district'] ?? addr['county'] ?? addr['district'] ?? addr['city'];
          final state = addr['state'];
          return {
            'village': village?.toString(),
            'district': district?.toString(),
            'state': state?.toString(),
          };
        }
      }
    } catch (_) {}
    return {'village': null, 'district': null, 'state': null};
  }

  static Future<GpsLocationResult?> _fallbackIpLocation() async {
    try {
      final resp = await http.get(
        Uri.parse('http://ip-api.com/json/?fields=status,lat,lon,regionName,city,district'),
      ).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['status'] == 'success') {
          return GpsLocationResult(
            latitude: (data['lat'] as num).toDouble(),
            longitude: (data['lon'] as num).toDouble(),
            accuracy: 50.0,
            district: data['city'] ?? data['district'],
            state: data['regionName'],
            village: data['city'],
            isGpsHardware: false,
          );
        }
      }
    } catch (_) {}

    // If GPS hardware and IP lookup both fail, return general location without forcing a fake district
    return GpsLocationResult(
      latitude: 12.9716,
      longitude: 77.5946,
      accuracy: 100.0,
      district: null, // Let user specify their real district
      state: "Karnataka",
      village: null,
      isGpsHardware: false,
    );
  }
}
