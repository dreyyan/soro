// [IMPORT] Hive
// Lightweight local NoSQL (key-value) database for offline storage.
// Used for: notes, quiz settings, and user progress.
// Pros: fast, offline-first, simple API, no backend required.
// Cons: no relations/joins, limited querying, requires adapters for models, no built-in sync.
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseHelper {
  // [SINGLETON]
  // Ensures a single shared DB instance across the app.
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // [BOX NAMES]
  // Logical containers (like tables in SQL)
  static const String notesBox = 'notes';
  static const String quizSettingsBox = 'quiz_settings';

  // [INIT]
  // Initialize Hive (must be called before any DB operation)
  static Future<void> init() async {
    await Hive.initFlutter(); // Handles path setup for all platforms
  }

  // [CREATE] Add a new note
  // Returns generated key (auto-incremented by Hive)
  Future<int> insertNote(Map<String, dynamic> row) async {
    var box = await Hive.openBox(notesBox);
    return await box.add(row);
  }

  // [READ] Fetch all notes (latest first)
  Future<List<Map<String, dynamic>>> getNotes() async {
    var box = await Hive.openBox(notesBox);
    return box.values
        .cast<Map<String, dynamic>>() // Ensure correct type
        .toList()
        .reversed
        .toList();
  }

  // [UPDATE] Modify existing note using its key (id)
  Future<int> updateNote(Map<String, dynamic> row) async {
    var box = await Hive.openBox(notesBox);
    int id = row['id'] as int;
    await box.put(id, row);
    return id;
  }

  // [DELETE] Remove note by key (id)
  Future<int> deleteNote(int id) async {
    var box = await Hive.openBox(notesBox);
    await box.delete(id);
    return id;
  }

  // [UPSERT] Save quiz settings
  // Inserts if empty, otherwise updates existing entry
  Future<int> saveQuizSettings(Map<String, dynamic> settings) async {
    var box = await Hive.openBox(quizSettingsBox);

    if (box.isEmpty) {
      return await box.add(settings);
    } else {
      int id = box.keys.first as int; // Only one settings record expected
      await box.put(id, settings);
      return id;
    }
  }

  // [READ] Get quiz settings (single record)
  Future<Map<String, dynamic>?> getQuizSettings() async {
    var box = await Hive.openBox(quizSettingsBox);

    if (box.isNotEmpty) {
      final raw = box.values.first;
      // Normalize dynamic map to Map<String, dynamic>
      return Map<String, dynamic>.from(raw as Map);
    }

    return null;
  }
}