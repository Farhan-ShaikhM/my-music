import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_migrations.dart';

class DatabaseService {
  static const String _databaseName = 'my_music.db';
  static const int _databaseVersion = 3;

  final String? databasePath;

  Database? _database;

  DatabaseService({this.databasePath});

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final path = databasePath ?? join(
      await getDatabasesPath(),
      _databaseName,
    );

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: DatabaseMigrations.onCreate,
      onUpgrade: DatabaseMigrations.onUpgrade,
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}