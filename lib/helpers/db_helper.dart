import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import '../models/photo_spot.dart';
import '../models/order_item.dart';

class DBHelper {
  static const String _databaseName = 'spots.db';
  static const int _databaseVersion = 3;

  static Future<sql.Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return sql.openDatabase(
      path.join(dbPath, _databaseName),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      version: _databaseVersion,
    );
  }

  static Future _onCreate(sql.Database db, int version) async {
    await db.execute(
        'CREATE TABLE photo_spots(id INTEGER PRIMARY KEY AUTOINCREMENT, latitude REAL, longitude REAL, imagePath TEXT, categoryId INTEGER, subCategoryId INTEGER, shopName TEXT, rating INTEGER, visitCount TEXT, notes TEXT, ordersJson TEXT)');
    await db.execute(
        'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
    await db.execute(
        'CREATE TABLE sub_categories(id INTEGER PRIMARY KEY AUTOINCREMENT, categoryId INTEGER, name TEXT, FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE)');
  }

  static Future _onUpgrade(sql.Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE photo_spots ADD COLUMN categoryId INTEGER');
      await db.execute('ALTER TABLE photo_spots ADD COLUMN subCategoryId INTEGER');
      await db.execute(
          'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
      await db.execute(
          'CREATE TABLE sub_categories(id INTEGER PRIMARY KEY AUTOINCREMENT, categoryId INTEGER, name TEXT, FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE)');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE photo_spots ADD COLUMN shopName TEXT');
      await db.execute('ALTER TABLE photo_spots ADD COLUMN rating INTEGER');
      await db.execute('ALTER TABLE photo_spots ADD COLUMN visitCount TEXT');
      await db.execute('ALTER TABLE photo_spots ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE photo_spots ADD COLUMN ordersJson TEXT');
    }
  }

  static Future<int> insert(String table, Map<String, Object?> data) async {
    final db = await DBHelper.database();
    return db.insert(table, data, conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getData(String table) async {
    final db = await DBHelper.database();
    return db.query(table);
  }

  static Future<List<Map<String, dynamic>>> getDataWhere(String table, String where, List<dynamic> whereArgs) async {
    final db = await DBHelper.database();
    return db.query(table, where: where, whereArgs: whereArgs);
  }

  static Future<int> update(String table, Map<String, Object?> data, int id) async {
    final db = await DBHelper.database();
    return db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> delete(String table, int id) async {
    final db = await DBHelper.database();
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<PhotoSpot>> searchSpots({
    String? keyword,
    int? categoryId,
    int? rating,
    String? visitCount,
    int? minPrice,
    int? maxPrice,
    PriceSearchMode priceMode = PriceSearchMode.firstItem, // Default mode
  }) async {
    final db = await DBHelper.database();
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (keyword != null && keyword.isNotEmpty) {
      whereClauses.add('(shopName LIKE ? OR ordersJson LIKE ?)');
      whereArgs.addAll(['%$keyword%', '%$keyword%']);
    }
    if (categoryId != null) {
      whereClauses.add('categoryId = ?');
      whereArgs.add(categoryId);
    }
    if (rating != null) {
      whereClauses.add('rating >= ?');
      whereArgs.add(rating);
    }
    if (visitCount != null) {
      whereClauses.add('visitCount = ?');
      whereArgs.add(visitCount);
    }

    String? whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'photo_spots',
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );

    List<PhotoSpot> spots = maps.map((map) => PhotoSpot.fromMap(map)).toList();

    // Dart-side filtering for price range based on the selected mode
    if (minPrice != null || maxPrice != null) {
      spots.retainWhere((spot) {
        if (spot.orders.isEmpty) return false;

        if (priceMode == PriceSearchMode.total) {
          // Sum of all item prices
          int total = spot.orders.fold(0, (sum, item) => sum + (item.price ?? 0));
          bool minOk = minPrice == null || total >= minPrice;
          bool maxOk = maxPrice == null || total <= maxPrice;
          return minOk && maxOk;
        } else {
          // Price of the first item
          final firstPrice = spot.orders.first.price;
          if (firstPrice == null) return false;
          bool minOk = minPrice == null || firstPrice >= minPrice;
          bool maxOk = maxPrice == null || firstPrice <= maxPrice;
          return minOk && maxOk;
        }
      });
    }

    return spots;
  }
}
