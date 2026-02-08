import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'order_item.dart';

class PhotoSpot {
  final int? id;
  final double? latitude;   // Made nullable
  final double? longitude;  // Made nullable
  final String imagePath;
  final int? categoryId;
  final int? subCategoryId;
  final String? shopName;
  final int? rating;
  final String? visitCount;
  final String? notes;
  final List<OrderItem> orders;

  PhotoSpot({
    this.id,
    this.latitude,         // No longer required
    this.longitude,        // No longer required
    required this.imagePath,
    this.categoryId,
    this.subCategoryId,
    this.shopName,
    this.rating,
    this.visitCount,
    this.notes,
    this.orders = const [],
  });

  // A getter that can fail if lat/lng are null.
  LatLng get position => LatLng(latitude!, longitude!);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'imagePath': imagePath,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'shopName': shopName,
      'rating': rating,
      'visitCount': visitCount,
      'notes': notes,
      'ordersJson': OrderItem.encode(orders),
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
      shopName: map['shopName'],
      rating: map['rating'],
      visitCount: map['visitCount'],
      notes: map['notes'],
      orders: map['ordersJson'] != null && map['ordersJson'].isNotEmpty ? OrderItem.decode(map['ordersJson']) : [],
    );
  }
}
