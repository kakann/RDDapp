import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "MyDatabase.db";
  static final _databaseVersion = 1;

  static final globalMapTable = "global_map";
  static final myMapTable = "my_map";

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE $globalMapTable (
          id INTEGER PRIMARY KEY,
          road_id TEXT NOT NULL,
          status TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL
        )
        ''');

    await db.execute('''
        CREATE TABLE $myMapTable (
          id INTEGER PRIMARY KEY,
          drive_id TEXT NOT NULL,
          image_path TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          timestamp TEXT NOT NULL
        )
        ''');
  }

  Future<int> insertGlobalMap(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(globalMapTable, row);
  }

  Future<int> insertMyMap(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(myMapTable, row);
  }

  Future<List<Map<String, dynamic>>> queryGlobalMap() async {
    Database db = await instance.database;
    return await db.query(globalMapTable);
  }

  Future<List<Map<String, dynamic>>> queryMyMap() async {
    Database db = await instance.database;
    return await db.query(myMapTable);
  }

  Future<int> updateGlobalMap(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db
        .update(globalMapTable, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateMyMap(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(myMapTable, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteGlobalMap(int id) async {
    Database db = await instance.database;
    return await db.delete(globalMapTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteMyMap(int id) async {
    Database db = await instance.database;
    return await db.delete(myMapTable, where: 'id = ?', whereArgs: [id]);
  }
}
