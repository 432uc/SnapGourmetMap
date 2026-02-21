import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'order_item.dart';

class PhotoSpot {
  final int? id;
  final double? latitude;
  final double? longitude;
  final String? imagePath;
  final List<String> additionalImages;
  final int? categoryId;
  final int? subCategoryId;
  final String? shopName;
  final int? rating;
  final String? visitCount;
  final String? notes;
  final List<OrderItem> orders;
  final DateTime? visitDate;

  PhotoSpot({
    this.id,
    this.latitude,
    this.longitude,
    this.imagePath,
    this.additionalImages = const [],
    this.categoryId,
    this.subCategoryId,
    this.shopName,
    this.rating,
    this.visitCount,
    this.notes,
    this.orders = const [],
    this.visitDate,
  });

  LatLng get position => LatLng(latitude!, longitude!);

  // Helper to get all images as a unified list
  List<String> get allImages {
    final images = <String>[];
    if (imagePath != null && imagePath!.isNotEmpty) {
      images.add(imagePath!);
    }
    images.addAll(additionalImages);
    return images;
  }

  // Safe getter for the first image path, for previews.
  String? get firstImagePath => allImages.isNotEmpty ? allImages.first : null;

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'imagePath': imagePath,
      'additionalImages': json.encode(additionalImages),
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'shopName': shopName,
      'rating': rating,
      'visitCount': visitCount,
      'notes': notes,
      'ordersJson': OrderItem.encode(orders),
      'visitDate': visitDate?.toIso8601String(),
    };
  }

  factory PhotoSpot.fromMap(Map<String, dynamic> map) {
    List<String> additionalImagesList = [];
    if (map['additionalImages'] != null && map['additionalImages'].isNotEmpty) {
      try {
        additionalImagesList = List<String>.from(json.decode(map['additionalImages']));
      } catch (e) {
        print('Error decoding additionalImages: $e');
      }
    }

    return PhotoSpot(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      imagePath: map['imagePath'],
      additionalImages: additionalImagesList,
      categoryId: map['categoryId'],
      subCategoryId: map['subCategoryId'],
      shopName: map['shopName'],
      rating: map['rating'],
      visitCount: map['visitCount'],
      notes: map['notes'],
      orders: map['ordersJson'] != null && map['ordersJson'].isNotEmpty 
          ? OrderItem.decode(map['ordersJson']) 
          : [],
      visitDate: map['visitDate'] != null ? DateTime.parse(map['visitDate']) : null,
    );
  }
}

