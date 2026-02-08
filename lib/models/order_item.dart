import 'dart:convert';

// Defines the search behavior for price filtering.
enum PriceSearchMode { firstItem, total }

class OrderItem {
  String itemName;
  int? price;

  OrderItem({this.itemName = '', this.price});

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'price': price,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      itemName: map['itemName'] as String,
      price: map['price'] as int?,
    );
  }

  static String encode(List<OrderItem> items) => json.encode(
        items.map<Map<String, dynamic>>((item) => item.toMap()).toList(),
      );

  static List<OrderItem> decode(String items) =>
      (json.decode(items) as List<dynamic>)
          .map<OrderItem>((item) => OrderItem.fromMap(item))
          .toList();
}
