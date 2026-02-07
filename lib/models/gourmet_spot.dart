class GourmetSpot {
  final int? id;
  final String name;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final String? imagePath;
  final String? memo;

  GourmetSpot({
    this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.imagePath,
    this.memo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'image_path': imagePath,
      'memo': memo,
    };
  }

  factory GourmetSpot.fromMap(Map<String, dynamic> map) {
    return GourmetSpot(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      imagePath: map['image_path'],
      memo: map['memo'],
    );
  }
}
