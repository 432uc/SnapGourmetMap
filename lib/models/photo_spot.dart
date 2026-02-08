import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'order_item.dart';

class PhotoSpot {
  final int? id;
  final double latitude;
  final double longitude;
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
    required this.latitude,
    required this.longitude,
    required this.imagePath,
    this.categoryId,
    this.subCategoryId,
    this.shopName,
    this.rating,
    this.visitCount,
    this.notes,
    this.orders = const [],
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
      orders: map['ordersJson'] != null ? OrderItem.decode(map['ordersJson']) : [],
    );
  }
}
