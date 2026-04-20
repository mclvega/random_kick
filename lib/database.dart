import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class Penalty {
  final int? id;
  final DateTime date;
  final String direction;
  final String shotType;
  final String result;

  Penalty({this.id, required this.date, required this.direction, required this.shotType, required this.result});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'direction': direction,
      'shotType': shotType,
      'result': result,
    };
  }

  factory Penalty.fromMap(Map<String, dynamic> map) {
    return Penalty(
      id: map['id'],
      date: DateTime.parse(map['date']),
      direction: map['direction'],
      shotType: map['shotType'] ?? '',
      result: map['result'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'penalties.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE penalties(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        direction TEXT NOT NULL,
        shotType TEXT NOT NULL DEFAULT '',
        result TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertPenalty(Penalty penalty) async {
    final db = await database;
    return await db.insert('penalties', penalty.toMap());
  }

  Future<List<Penalty>> getPenalties() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('penalties');
    return List.generate(maps.length, (i) => Penalty.fromMap(maps[i]));
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('penalties');
  }

  Future<void> deletePenalty(int id) async {
    final db = await database;
    await db.delete('penalties', where: 'id = ?', whereArgs: [id]);
  }
}