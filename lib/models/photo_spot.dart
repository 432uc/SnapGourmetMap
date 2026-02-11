import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'order_item.dart';

class PhotoSpot {
  final int? id;
  final double? latitude;
  final double? longitude;
  final String imagePath; // The primary/first image
  final List<String> additionalImages; // Sub-images (2nd, 3rd, etc.)
  final int? categoryId;
  final int? subCategoryId;
  final String? shopName;
  final int? rating;
  final String? visitCount;
  final String? notes;
  final List<OrderItem> orders;
  final DateTime visitDate; // Added for filtering and export

  PhotoSpot({
    this.id,
    this.latitude,
    this.longitude,
    required this.imagePath,
    this.additionalImages = const [],
    this.categoryId,
    this.subCategoryId,
    this.shopName,
    this.rating,
    this.visitCount,
    this.notes,
    this.orders = const [],
    DateTime? visitDate,
  }) : visitDate = visitDate ?? DateTime.now();

  // Getter for all images combined
  List<String> get allImages => [imagePath, ...additionalImages];

  // A getter that can fail if lat/lng are null.
  LatLng get position => LatLng(latitude!, longitude!);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'imagePath': imagePath,
      'additionalImages': jsonEncode(additionalImages),
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'shopName': shopName,
      'rating': rating,
      'visitCount': visitCount,
      'notes': notes,
      'ordersJson': OrderItem.encode(orders),
      'visitDate': visitDate.toIso8601String(), // Store as ISO string
    };
  }

  factory PhotoSpot.fromMap(Map<String, dynamic> map) {
    List<String> others = [];
    if (map['additionalImages'] != null) {
      try {
        others = List<String>.from(jsonDecode(map['additionalImages']));
      } catch (_) {
        others = [];
      }
    }
    
    return PhotoSpot(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      imagePath: map['imagePath'],
      additionalImages: others,
      categoryId: map['categoryId'],
      subCategoryId: map['subCategoryId'],
      shopName: map['shopName'],
      rating: map['rating'],
      visitCount: map['visitCount'],
      notes: map['notes'],
      orders: map['ordersJson'] != null && map['ordersJson'].isNotEmpty 
          ? OrderItem.decode(map['ordersJson']) 
          : [],
      visitDate: _parseDate(map['visitDate']),
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null || date is! String || date.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }
  
  // Create a copy with some fields replaced
  PhotoSpot copyWith({
    int? id,
    double? latitude,
    double? longitude,
    String? imagePath,
    List<String>? additionalImages,
    int? categoryId,
    int? subCategoryId,
    String? shopName,
    int? rating,
    String? visitCount,
    String? notes,
    List<OrderItem>? orders,
    DateTime? visitDate,
  }) {
    return PhotoSpot(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imagePath: imagePath ?? this.imagePath,
      additionalImages: additionalImages ?? this.additionalImages,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      shopName: shopName ?? this.shopName,
      rating: rating ?? this.rating,
      visitCount: visitCount ?? this.visitCount,
      notes: notes ?? this.notes,
      orders: orders ?? this.orders,
      visitDate: visitDate ?? this.visitDate,
    );
  }
}
