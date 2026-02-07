import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class DBHelper {
  static const String _databaseName = 'spots.db';
  static const int _databaseVersion = 2;

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
        'CREATE TABLE photo_spots(id INTEGER PRIMARY KEY AUTOINCREMENT, latitude REAL, longitude REAL, imagePath TEXT, categoryId INTEGER, subCategoryId INTEGER)');
    await db.execute(
        'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
    await db.execute(
        'CREATE TABLE sub_categories(id INTEGER PRIMARY KEY AUTOINCREMENT, categoryId INTEGER, name TEXT, FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE)');
  }

  static Future _onUpgrade(sql.Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // In a real app, you would likely migrate data. Here we are just adding columns.
      await db.execute('ALTER TABLE photo_spots ADD COLUMN categoryId INTEGER');
      await db.execute('ALTER TABLE photo_spots ADD COLUMN subCategoryId INTEGER');
      await db.execute(
          'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
      await db.execute(
          'CREATE TABLE sub_categories(id INTEGER PRIMARY KEY AUTOINCREMENT, categoryId INTEGER, name TEXT, FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE)');
    }
  }

  static Future<int> insert(String table, Map<String, Object?> data) async {
    final db = await DBHelper.database();
    return db.insert(
      table,
      data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
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
}
