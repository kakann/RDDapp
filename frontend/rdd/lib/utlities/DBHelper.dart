import 'dart:convert';

import 'package:path/path.dart';
import 'package:rdd/objects/capturedImageList.dart';
import 'package:sqflite/sqflite.dart';
import 'package:rdd/objects/CapturedImage.dart';

class DBHelper {
  static Future<Database> database() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'captured_images.db'),
      onCreate: (db, version) {
        db.execute(
            'CREATE TABLE captured_images(id INTEGER PRIMARY KEY, imagePath TEXT, latitude REAL, longitude REAL, speed REAL, bboxes TEXT, imageListId INTEGER)');

        db.execute(
            'CREATE TABLE captured_image_lists(id INTEGER PRIMARY KEY AUTOINCREMENT, created_at TEXT, start_locality TEXT, end_locality TEXT)');
      },
      version: 1,
    );
  }

  static Future<void> setStartLocality(int listId, String locality) async {
    final db = await DBHelper.database();
    await db.update(
      'captured_image_lists',
      {'start_locality': locality},
      where: 'id = ?',
      whereArgs: [listId],
    );
  }

  static Future<void> setEndLocality(int listId, String locality) async {
    final db = await DBHelper.database();
    await db.update(
      'captured_image_lists',
      {'end_locality': locality},
      where: 'id = ?',
      whereArgs: [listId],
    );
  }

  static Future<void> insertCapturedImage(
      CapturedImage image, int listId) async {
    final db = await DBHelper.database();
    await db.insert(
      'captured_images',
      {
        'imagePath': image.imagePath,
        'latitude': image.latitude,
        'longitude': image.longitude,
        'speed': image.speed,
        'bboxes': image.bboxes.map((bbox) => jsonEncode(bbox)).join(';'),
        'imageListId':
            listId, // this is the foreign key linking to the image list
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<int> insertCapturedImageList() async {
    final db = await DBHelper.database();
    return await db.insert(
      'captured_image_lists',
      {'created_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // This method will add a new CapturedImage object to a specific CapturedImageList.
  static Future<void> addImageToCapturedImageList(
      CapturedImage image, int listId) async {
    await insertCapturedImage(image, listId);
  }

  static Future<void> deleteCapturedImageList(int listId) async {
    final db = await DBHelper.database();

    // Delete the images linked to the list.
    await db.delete(
      'captured_images',
      where: 'imageListId = ?',
      whereArgs: [listId],
    );

    // Delete the list.
    await db.delete(
      'captured_image_lists',
      where: 'id = ?',
      whereArgs: [listId],
    );
  }

  static Future<List<CapturedImageList>> getCapturedImageLists() async {
    final db = await DBHelper.database();

    // Get all image lists.
    final List<Map<String, dynamic>> imageListData =
        await db.query('captured_image_lists');

    List<CapturedImageList> imageLists = [];

    for (var list in imageListData) {
      final int listId = list['id'];

      // Get all images associated with this list.
      final List<Map<String, dynamic>> imageData = await db.query(
        'captured_images',
        where: 'imageListId = ?',
        whereArgs: [listId],
      );

      // Convert the Map objects into CapturedImage objects.
      List<CapturedImage> images = imageData.map((img) {
        // Convert string back to List<Map<String, dynamic>>
        var stringBboxes = img['bboxes'].split(";");
        //print(stringBboxes);
        List<Map<String, dynamic>> bboxes = [];

        if (stringBboxes[0] != "") {
          for (var box in stringBboxes) {
            Map<String, dynamic> bbox = json.decode(box);
            bboxes.add(bbox);
          }
        }

        return CapturedImage(
          imagePath: img['imagePath'],
          latitude: img['latitude'],
          longitude: img['longitude'],
          speed: img['speed'],
          bboxes: bboxes,
        );
      }).toList();

      // Add the image list to the list of image lists.
      CapturedImageList imageList = CapturedImageList();
      imageList.images = images;
      imageList.setStartLocality(list['start_locality']);
      imageList.setEndLocality(list['end_locality']);
      imageList.date = DateTime.parse(list['created_at']);
      imageLists.add(imageList);
    }

    return imageLists;
  }
}
