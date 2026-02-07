import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/gourmet_spot.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gourmet_log.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const textNullableType = 'TEXT';

    await db.execute('''
CREATE TABLE gourmet_spots ( 
  id $idType, 
  name $textType,
  category $textType,
  address $textType,
  latitude $doubleType,
  longitude $doubleType,
  image_path $textNullableType,
  memo $textNullableType
  )
''');
  }

  Future<int> create(GourmetSpot spot) async {
    final db = await instance.database;
    return await db.insert('gourmet_spots', spot.toMap());
  }

  Future<List<GourmetSpot>> readAllSpots() async {
    final db = await instance.database;
    final result = await db.query('gourmet_spots');
    return result.map((json) => GourmetSpot.fromMap(json)).toList();
  }
  
  Future<int> update(GourmetSpot spot) async {
    final db = await instance.database;
    return db.update(
      'gourmet_spots',
      spot.toMap(),
      where: 'id = ?',
      whereArgs: [spot.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'gourmet_spots',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
