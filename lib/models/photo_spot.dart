import 'package:google_maps_flutter/google_maps_flutter.dart';

class PhotoSpot {
  final int? id;
  final double latitude;
  final double longitude;
  final String imagePath;
  final int? categoryId;
  final int? subCategoryId;

  PhotoSpot({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
    this.categoryId,
    this.subCategoryId,
  });

  LatLng get position => LatLng(latitude, longitude);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'imagePath': imagePath,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
    };
  }

  factory PhotoSpot.fromMap(Map<String, dynamic> map) {
    return PhotoSpot(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      imagePath: map['imagePath'],
      categoryId: map['categoryId'],
      subCategoryId: map['subCategoryId'],
    );
  }
}
