import 'package:google_maps_flutter/google_maps_flutter.dart';

class PhotoSpot {
  final int? id;
  final double latitude;
  final double longitude;
  final String imagePath;

  PhotoSpot({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
  });

  LatLng get position => LatLng(latitude, longitude);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'imagePath': imagePath,
    };
  }
}
