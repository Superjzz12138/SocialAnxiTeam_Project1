
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/workout_plan.dart';

class DatabaseHelper {
  // Create one instance to avoid duplicates
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Only initialize when first use
  static Database? _database;

  // private function, prevents const from outside
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fitness_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async{
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

    Future<void> _createDB(Database db, int version) async {
      // Create Workout Plans Table(to save workout plans)
      await db.execute(
        '''CREATE TABLE workout_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          exercises TEXT NOT NULL,
          sets INTEGER NOT NULL,
          reps INTEGER NOT NULL,
          restTime INTEGER NOT NULL,
          notes TEXT,
          createdAt TEXT NOT NULL
        )'''
      );

      // Create Dailt Check-ins Table (to save daily check-in records)
      await db.execute(
        '''CREATE TABLE daily_checkins(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          checkDate TEXT NOT NULL UNIQUE,
          createdAt TEXT NOT NULL
        )
        
        
        
        '''
      );
    }

    Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
          '''
          CREATE TABLE daily_checkins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            checkDate TEXT NOT NULL UNIQUE,
            createdAT TEXT NOT NULL
          )
          '''
        );
      }
    
    }
  Future<bool> chekcInToday() async {
    final db = await instance.database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    try {
      await db.insert('daily_checkins', {
        'checkDate': today,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> getCurrentStreak() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT checkDate FROM daily_checkins
      ORDER BY checkDate DESC
      ''');

      if (result.isEmpty) return 0;

      int streak = 1;
      DateTime current = DateTime.parse(result[0]['checkDate'] as String);

      for (int i = 1; i < result.length; i++) {
        DateTime prev = DateTime.parse(result[i]['checkDate'] as String);
        if (current.difference(prev).inDays == 1) {
          streak++;
          current = prev;
        } else{
          break;
        }
      }
      return streak;
  }

  Future<List<String>> getCheckInHistory() async {
    final db = await instance.database;
    final result = await db.query(
      'daily_checkins',
      orderBy: 'checkDate DESC',
      limit: 30,
    );
    return result.map((e) => e['checkDate'] as String).toList();
  }

  Future<int> insertWorkout(WorkoutPlan plan) async {
    final db = await instance.database;
    return await db.insert('workout_plans', plan.toMap());
  }

  Future<List<WorkoutPlan>> getAllWorkouts() async {
    final db = await instance.database;
    final result = await db.query(
      'workout_plans',
      orderBy: 'createdAt DESC'
    );
    return result.map((json) => WorkoutPlan.fromMap(json)).toList();
  }
  Future<int> deleteWorkout(int id) async {
    final db = await instance.database;
    return await db.delete('workout_plans',
    where: 'id = ?',
    whereArgs: [id]);
  }
}

