import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineConsultationDb {
  static final OfflineConsultationDb instance = OfflineConsultationDb._init();
  static Database? _database;

  OfflineConsultationDb._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('offline_consultations.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE consultations (
  id TEXT PRIMARY KEY,
  chiefComplaint TEXT NOT NULL,
  symptomsDescription TEXT NOT NULL,
  mediaPath TEXT,
  mediaType TEXT,
  status TEXT NOT NULL,
  createdAt TEXT NOT NULL
)
''');
  }

  Future<void> save(Map<String, dynamic> consultation) async {
    final db = await instance.database;
    await db.insert('consultations', consultation,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPending() async {
    final db = await instance.database;
    return await db.query(
      'consultations',
      where: 'status = ?',
      whereArgs: ['pending'],
    );
  }

  Future<void> updateStatus(String id, String status) async {
    final db = await instance.database;
    await db.update(
      'consultations',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await instance.database;
    await db.delete(
      'consultations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
