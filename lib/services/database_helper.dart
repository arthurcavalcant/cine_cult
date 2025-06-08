// filepath: c:\Users\arthu\AndroidStudioProjects\cine_cult\lib\services\database_helper.dart
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // Alias for path package
import '../models/media_item.dart';
import '../models/user_media_item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String _dbName = 'cine_cult.db';
  static const int _dbVersion = 1;

  // Table and Column Names
  static const String tableMediaItems = 'media_items';
  static const String colId = 'id'; // imdbID
  static const String colTitle = 'title';
  static const String colPosterUrl = 'posterUrl';
  static const String colSynopsis = 'synopsis';
  static const String colReleaseYear = 'releaseYear';
  static const String colPublicRating = 'publicRating';
  static const String colType = 'type';
  static const String colGenre = 'genre';
  static const String colRuntime = 'runtime';
  static const String colCast = 'cast'; // Stored as JSON string

  static const String tableUserLists = 'user_lists';
  static const String colUserMediaItemId = 'user_media_item_id'; // Primary key for this table
  static const String colMediaItemId = 'media_item_id'; // Foreign key to media_items table
  static const String colStatus = 'status'; // 'wantToWatch' or 'watched'
  static const String colUserRating = 'userRating'; // 1-5
  static const String colUserComment = 'userComment';
  static const String colDateAdded = 'dateAdded'; // ISO8601 String

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = p.join(documentsDirectory.path, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableMediaItems (
        $colId TEXT PRIMARY KEY,
        $colTitle TEXT NOT NULL,
        $colPosterUrl TEXT,
        $colSynopsis TEXT,
        $colReleaseYear TEXT,
        $colPublicRating REAL,
        $colType TEXT,
        $colGenre TEXT,
        $colRuntime TEXT,
        $colCast TEXT 
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableUserLists (
        $colUserMediaItemId INTEGER PRIMARY KEY AUTOINCREMENT, 
        $colMediaItemId TEXT NOT NULL,
        $colStatus TEXT NOT NULL,
        $colUserRating INTEGER,
        $colUserComment TEXT,
        $colDateAdded TEXT NOT NULL,
        FOREIGN KEY ($colMediaItemId) REFERENCES $tableMediaItems ($colId) ON DELETE CASCADE
      )
    ''');
  }

  // MediaItem CRUD
  Future<int> insertMediaItem(MediaItem item) async {
    final db = await database;
    return await db.insert(
      tableMediaItems,
      item.toMapForDb(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Replace if ID already exists
    );
  }

  Future<MediaItem?> getMediaItem(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableMediaItems,
      where: '$colId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return MediaItem.fromDbMap(maps.first);
    }
    return null;
  }

  // UserMediaItem CRUD
  Future<int> insertUserMediaItem(UserMediaItem item) async {
    final db = await database;
    // Ensure the base MediaItem is in the database first
    await insertMediaItem(item.mediaItem);

    Map<String, dynamic> userMediaMap = item.toMapForDb();

    // Check if an entry for this mediaId and status already exists
    List<Map<String, dynamic>> existing = await db.query(
      tableUserLists,
      where: '$colMediaItemId = ?',
      whereArgs: [item.mediaItem.id],
    );

    if (existing.isNotEmpty) {
      // If it exists, update it
      return await db.update(
        tableUserLists,
        userMediaMap,
        where: '$colMediaItemId = ?',
        whereArgs: [item.mediaItem.id],
      );
    } else {
      // Otherwise, insert new
      return await db.insert(tableUserLists, userMediaMap);
    }
  }

  Future<int> updateUserMediaItem(UserMediaItem item) async {
    final db = await database;
    await insertMediaItem(item.mediaItem); // Ensure media item is up-to-date or inserted
    return await db.update(
      tableUserLists,
      item.toMapForDb(),
      where: '$colMediaItemId = ?', // Assuming media_item_id is unique enough for user lists
      whereArgs: [item.mediaItem.id],
    );
  }

  Future<int> deleteUserMediaItem(String mediaId) async {
    final db = await database;
    return await db.delete(
      tableUserLists,
      where: '$colMediaItemId = ?',
      whereArgs: [mediaId],
    );
  }

  Future<List<UserMediaItem>> getAllUserMediaItems() async {
    final db = await database;
    final List<Map<String, dynamic>> userListMaps = await db.query(tableUserLists);

    List<UserMediaItem> items = [];
    for (Map<String, dynamic> userMap in userListMaps) {
      MediaItem? mediaItem = await getMediaItem(userMap[colMediaItemId]);
      if (mediaItem != null) {
        items.add(UserMediaItem.fromDbMap(userMap, mediaItem));
      }
    }
    return items;
  }

  Future<List<UserMediaItem>> getUserMediaItemsByStatus(MediaStatus status) async {
    final db = await database;
    final List<Map<String, dynamic>> userListMaps = await db.query(
      tableUserLists,
      where: '$colStatus = ?',
      whereArgs: [status.toString().split('.').last], // e.g., "watched"
    );

    List<UserMediaItem> items = [];
    for (Map<String, dynamic> userMap in userListMaps) {
      MediaItem? mediaItem = await getMediaItem(userMap[colMediaItemId]);
      if (mediaItem != null) {
        items.add(UserMediaItem.fromDbMap(userMap, mediaItem));
      }
    }
    return items;
  }

  Future<UserMediaItem?> getUserMediaItem(String mediaId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUserLists,
      where: '$colMediaItemId = ?',
      whereArgs: [mediaId],
    );
    if (maps.isNotEmpty) {
      MediaItem? mediaItem = await getMediaItem(maps.first[colMediaItemId]);
      if (mediaItem != null) {
        return UserMediaItem.fromDbMap(maps.first, mediaItem);
      }
    }
    return null;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null; // Reset database instance so it can be re-initialized if needed
  }
}

