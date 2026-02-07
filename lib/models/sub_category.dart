class SubCategory {
  final int? id;
  final int categoryId;
  final String name;

  SubCategory({this.id, required this.categoryId, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
    };
  }

  factory SubCategory.fromMap(Map<String, dynamic> map) {
    return SubCategory(
      id: map['id'],
      categoryId: map['categoryId'],
      name: map['name'],
    );
  }
}
