// [IMPORT] Shared Preferences
// Uses shared_preferences instead of Hive because on Flutter Web, Hive stores
// data in IndexedDB which is scoped to the exact origin (hostname + PORT).
// When the local dev server restarts on a different port, all data is lost.
// shared_preferences on web uses window.localStorage which is scoped only to
// the hostname, so data persists across server restarts and port changes.
import 'package:shared_preferences/shared_preferences.dart';

// [IMPORT] JSON
import 'dart:convert';

class DatabaseHelper {
  // [SINGLETON]
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // [INIT] No-op — shared_preferences initializes lazily
  static Future<void> init() async {}

  // [HELPERS]

  // [GET] SharedPreferences instance (cached for performance)
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // [GET] Logged-in user's email from storage
  Future<String?> _loggedInEmail() async {
    final prefs = await _prefs;
    return prefs.getString('session_loggedInEmail');
  }

  // [FORMAT] Today's date as yyyy-MM-dd
  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // [ENCODE] Safely encode a list to a JSON string for storage
  String _encodeList(List<dynamic> list) => jsonEncode(list);

  // [DECODE] Safely decode a JSON string back to a list
  List<dynamic> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  // [ENCODE] Safely encode a map to a JSON string for storage
  String _encodeMap(Map<String, dynamic> map) => jsonEncode(map);

  // [DECODE] Safely decode a JSON string back to a map
  Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  // * [AUTHENTICATION]
  // [REGISTER] Returns null on success, error string on failure
  Future<String?> registerUser(Map<String, dynamic> userData) async {
    final prefs = await _prefs;
    final email = (userData['email'] as String).trim().toLowerCase();

    // [CHECK] Duplicate email
    final rawUsers = prefs.getString('users');
    final users = _decodeList(rawUsers)
        .map((u) => Map<String, dynamic>.from(u as Map))
        .toList();

    final existing = users.any(
      (u) => (u['email'] as String).toLowerCase() == email,
    );
    if (existing) return 'An account with this email already exists.';

    users.add({...userData, 'email': email});
    await prefs.setString('users', _encodeList(users));
    return null;
  }

  // [LOGIN] Returns null on success, error string on failure
  Future<String?> loginUser(String email, String password) async {
    final prefs = await _prefs;
    final normalizedEmail = email.trim().toLowerCase();

    final rawUsers = prefs.getString('users');
    final users = _decodeList(rawUsers)
        .map((u) => Map<String, dynamic>.from(u as Map))
        .toList();

    final match = users.where(
      (u) =>
          (u['email'] as String).toLowerCase() == normalizedEmail &&
          u['password'] == password,
    );
    if (match.isEmpty) return 'Incorrect email or password.';

    await prefs.setString('session_loggedInEmail', normalizedEmail);
    return null;
  }

  // [GET] Currently logged-in user's full profile map
  Future<Map<String, dynamic>?> getLoggedInUser() async {
    final email = await _loggedInEmail();
    if (email == null) return null;

    final prefs = await _prefs;
    final rawUsers = prefs.getString('users');
    final users = _decodeList(rawUsers)
        .map((u) => Map<String, dynamic>.from(u as Map))
        .toList();

    final match = users.where(
      (u) => (u['email'] as String).toLowerCase() == email,
    );
    if (match.isEmpty) return null;
    return match.first;
  }

  // [UPDATE] Merge profile fields for the logged-in user
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final email = await _loggedInEmail();
    if (email == null) return;

    final prefs = await _prefs;
    final rawUsers = prefs.getString('users');
    final users = _decodeList(rawUsers)
        .map((u) => Map<String, dynamic>.from(u as Map))
        .toList();

    final idx = users.indexWhere(
      (u) => (u['email'] as String).toLowerCase() == email,
    );
    if (idx == -1) return;

    users[idx] = {...users[idx], ...updates};
    await prefs.setString('users', _encodeList(users));
  }

  // [CHANGE PASSWORD] Verifies current password then updates
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = await _loggedInEmail();
    if (email == null) return false;

    final prefs = await _prefs;
    final rawUsers = prefs.getString('users');
    final users = _decodeList(rawUsers)
        .map((u) => Map<String, dynamic>.from(u as Map))
        .toList();

    final idx = users.indexWhere(
      (u) => (u['email'] as String).toLowerCase() == email,
    );
    if (idx == -1) return false;
    if (users[idx]['password'] != currentPassword) return false;

    users[idx]['password'] = newPassword;
    await prefs.setString('users', _encodeList(users));
    return true;
  }

  // [LOGOUT] Clear the session key
  Future<void> logoutUser() async {
    final prefs = await _prefs;
    await prefs.remove('session_loggedInEmail');
  }

  // [CHECK] Whether a session exists
  Future<bool> isLoggedIn() async {
    final prefs = await _prefs;
    return prefs.containsKey('session_loggedInEmail');
  }

  // * [STATISTICS]  (scoped per user: "<email>_<field>")
  Future<Map<String, dynamic>> getUserStats() async {
    final email = await _loggedInEmail();
    if (email == null) {
      return {
        'cardsCreated': 0,
        'quizCorrect':  0,
        'quizTotal':    0,
        'streakDays':   0,
        'accuracy':     null,
      };
    }
    final prefs   = await _prefs;
    final cards   = prefs.getInt('${email}_cardsCreated') ?? 0;
    final correct = prefs.getInt('${email}_quizCorrect')  ?? 0;
    final total   = prefs.getInt('${email}_quizTotal')    ?? 0;
    final streak  = prefs.getInt('${email}_streakDays')   ?? 0;
    return {
      'cardsCreated': cards,
      'quizCorrect':  correct,
      'quizTotal':    total,
      'streakDays':   streak,
      'accuracy':     total > 0 ? ((correct / total) * 100).round() : null,
    };
  }

  Future<void> incrementCardsCreated() async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final prefs   = await _prefs;
    final current = prefs.getInt('${email}_cardsCreated') ?? 0;
    await prefs.setInt('${email}_cardsCreated', current + 1);
    await _refreshStreak();
  }

  Future<void> decrementCardsCreated() async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final prefs   = await _prefs;
    final current = prefs.getInt('${email}_cardsCreated') ?? 0;
    await prefs.setInt('${email}_cardsCreated', (current - 1).clamp(0, 999999));
  }

  Future<void> recordQuizResult(int correct, int total) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final prefs       = await _prefs;
    final prevCorrect = prefs.getInt('${email}_quizCorrect') ?? 0;
    final prevTotal   = prefs.getInt('${email}_quizTotal')   ?? 0;
    await prefs.setInt('${email}_quizCorrect', prevCorrect + correct);
    await prefs.setInt('${email}_quizTotal',   prevTotal   + total);
    await _refreshStreak();
    await addExp(20 + correct * 2);
    await _progressQuest('completeQuiz');
  }

  // [INTERNAL] Increment or reset the study streak based on today's date
  Future<void> _refreshStreak() async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final prefs    = await _prefs;
    final today    = _todayString();
    final lastDate = prefs.getString('${email}_lastStudyDate');
    if (lastDate == today) return; // [SKIP] Already updated today

    int streak = prefs.getInt('${email}_streakDays') ?? 0;
    if (lastDate == null) {
      streak = 1;
    } else {
      final diff =
          DateTime.parse(today).difference(DateTime.parse(lastDate)).inDays;
      streak = diff == 1 ? streak + 1 : 1;
    }
    await prefs.setInt('${email}_streakDays',       streak);
    await prefs.setString('${email}_lastStudyDate', today);
  }

  // * [FLASHCARDS]
  Future<List<Map<String, dynamic>>> getFlashcardDecks() async {
    final email = await _loggedInEmail();
    if (email == null) return [];
    final prefs = await _prefs;
    final raw   = prefs.getString('${email}_decks');
    return _decodeList(raw)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _saveFlashcardDecks(List<Map<String, dynamic>> decks) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final prefs = await _prefs;
    await prefs.setString('${email}_decks', _encodeList(decks));
  }

  Future<void> addFlashcardDeck(Map<String, dynamic> deck) async {
    final decks = await getFlashcardDecks();
    decks.add(deck);
    await _saveFlashcardDecks(decks);
    await incrementCardsCreated();
    await addExp(5);
    await _progressQuest('createCard');
  }

  Future<void> updateFlashcardDeck(
      String id, Map<String, dynamic> updated) async {
    final decks = await getFlashcardDecks();
    final idx   = decks.indexWhere((d) => d['id'] == id);
    if (idx == -1) return;
    decks[idx] = updated;
    await _saveFlashcardDecks(decks);
  }

  Future<void> deleteFlashcardDeck(String id) async {
    final decks = await getFlashcardDecks();
    decks.removeWhere((d) => d['id'] == id);
    await _saveFlashcardDecks(decks);
    await decrementCardsCreated();
  }

  // [GET] All individual cards across all decks (for quiz use)
  Future<List<Map<String, dynamic>>> getAllCards() async {
    final decks = await getFlashcardDecks();
    final all   = <Map<String, dynamic>>[];
    for (final deck in decks) {
      for (final c in (deck['cards'] as List? ?? [])) {
        all.add({
          'term':       c['term'],
          'definition': c['definition'],
          'deckTitle':  deck['title'],
          'deckId':     deck['id'],
        });
      }
    }
    return all;
  }

  // * [QUIZZES]
  Future<List<Map<String, dynamic>>> getSavedQuizzes() async {
    final email = await _loggedInEmail();
    if (email == null) return [];
    final prefs = await _prefs;
    final raw   = prefs.getString('${email}_quizzes');
    return _decodeList(raw)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _saveQuizzes(List<Map<String, dynamic>> quizzes) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final prefs = await _prefs;
    await prefs.setString('${email}_quizzes', _encodeList(quizzes));
  }

  Future<void> addSavedQuiz(Map<String, dynamic> quiz) async {
    final quizzes = await getSavedQuizzes();
    quizzes.add(quiz);
    await _saveQuizzes(quizzes);
  }

  Future<void> deleteSavedQuiz(String id) async {
    final quizzes = await getSavedQuizzes();
    quizzes.removeWhere((q) => q['id'] == id);
    await _saveQuizzes(quizzes);
  }

  // * [CURRENCY]  (coins, EXP, achievements)
  static const List<Map<String, dynamic>> rankTiers = [
    {'title': 'Novice',     'minExp': 0,    'icon': '🌱'},
    {'title': 'Apprentice', 'minExp': 500,  'icon': '📖'},
    {'title': 'Scholar',    'minExp': 1500, 'icon': '🎓'},
    {'title': 'Expert',     'minExp': 3500, 'icon': '⚡'},
    {'title': 'Master',     'minExp': 7000, 'icon': '👑'},
  ];

  Future<Map<String, dynamic>> getCurrency() async {
    final email = await _loggedInEmail();
    if (email == null) {
      return {'coins': 0, 'exp': 0, 'achievements': <String>[]};
    }
    final prefs  = await _prefs;
    final coins  = prefs.getInt('${email}_coins') ?? 0;
    final exp    = prefs.getInt('${email}_exp')   ?? 0;
    final rawAch = prefs.getString('${email}_achievements');
    final achievements = rawAch != null
        ? List<String>.from(_decodeList(rawAch).cast<String>())
        : <String>[];
    return {'coins': coins, 'exp': exp, 'achievements': achievements};
  }

  Future<void> addCoins(int amount) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final prefs   = await _prefs;
    final current = prefs.getInt('${email}_coins') ?? 0;
    await prefs.setInt('${email}_coins', current + amount);
  }

  Future<void> spendCoins(int amount) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final prefs   = await _prefs;
    final current = prefs.getInt('${email}_coins') ?? 0;
    await prefs.setInt('${email}_coins', (current - amount).clamp(0, 999999));
  }

  Future<void> addExp(int amount) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final prefs   = await _prefs;
    final current = prefs.getInt('${email}_exp') ?? 0;
    await prefs.setInt('${email}_exp', current + amount);
  }

  Future<void> unlockAchievement(String achievementId) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final prefs = await _prefs;
    final raw   = prefs.getString('${email}_achievements');
    final list  = List<String>.from(_decodeList(raw).cast<String>());
    if (!list.contains(achievementId)) {
      list.add(achievementId);
      await prefs.setString('${email}_achievements', _encodeList(list));
    }
  }

  // [HELPER] Derive rank title, icon, and progress from total EXP
  static Map<String, dynamic> getRankFromExp(int exp) {
    Map<String, dynamic> current = rankTiers.first;
    for (final tier in rankTiers) {
      if (exp >= (tier['minExp'] as int)) current = tier;
    }
    final idx     = rankTiers.indexOf(current);
    final next    = idx < rankTiers.length - 1 ? rankTiers[idx + 1] : null;
    final nextExp = next != null ? (next['minExp'] as int) : null;
    final progress = nextExp != null
        ? ((exp - (current['minExp'] as int)) /
               (nextExp - (current['minExp'] as int)))
            .clamp(0.0, 1.0)
        : 1.0;
    return {
      ...current,
      'exp':      exp,
      'nextExp':  nextExp,
      'progress': progress,
    };
  }

  // * [DAILY QUESTS] 3 quests generated per day, reset at midnight.
  static const List<Map<String, dynamic>> _questDefs = [
    {
      'id':          'createCard',
      'title':       'Card Creator',
      'description': 'Create at least 1 flashcard today',
      'icon':        '🃏',
      'goal':        1,
      'rewardExp':   30,
      'rewardCoins': 10,
    },
    {
      'id':          'completeQuiz',
      'title':       'Quiz Taker',
      'description': 'Complete at least 1 quiz today',
      'icon':        '📝',
      'goal':        1,
      'rewardExp':   50,
      'rewardCoins': 20,
    },
    {
      'id':          'studyStreak',
      'title':       'On a Roll',
      'description': 'Maintain a study streak of 2+ days',
      'icon':        '🔥',
      'goal':        2,
      'rewardExp':   40,
      'rewardCoins': 15,
    },
  ];

  // [GET] Today's daily quests with current progress; auto-resets on new day
  Future<List<Map<String, dynamic>>> getDailyQuests() async {
    final email = await _loggedInEmail();
    if (email == null) return [];

    final prefs     = await _prefs;
    final today     = _todayString();
    final savedDate = prefs.getString('${email}_questDate');

    // [RESET] New day — wipe progress and start fresh
    if (savedDate != today) {
      final fresh = _questDefs
          .map((q) => {
                ...q,
                'progress':      0,
                'completed':     false,
                'rewardClaimed': false,
              })
          .toList();
      await prefs.setString('${email}_questDate',  today);
      await prefs.setString('${email}_quests',     _encodeList(fresh));
      return List<Map<String, dynamic>>.from(fresh);
    }

    // [LOAD] Return existing quest progress
    final raw = prefs.getString('${email}_quests');
    if (raw == null) {
      return _questDefs
          .map((q) => {
                ...q,
                'progress':      0,
                'completed':     false,
                'rewardClaimed': false,
              })
          .toList();
    }
    return _decodeList(raw)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // [INTERNAL] Advance quest progress when a relevant action is triggered
  Future<void> _progressQuest(String questId) async {
    final email = await _loggedInEmail();
    if (email == null) return;

    final quests  = await getDailyQuests();
    bool changed  = false;

    for (int i = 0; i < quests.length; i++) {
      if (quests[i]['id'] != questId) continue;
      if (quests[i]['completed'] == true) continue;

      int progress;
      if (questId == 'studyStreak') {
        // [STREAK] Use actual streak value instead of incrementing
        final stats = await getUserStats();
        progress = stats['streakDays'] as int? ?? 0;
      } else {
        progress = ((quests[i]['progress'] as int?) ?? 0) + 1;
      }

      final goal      = quests[i]['goal'] as int;
      final completed = progress >= goal;
      quests[i] = {...quests[i], 'progress': progress, 'completed': completed};
      changed = true;
    }

    if (changed) {
      final prefs = await _prefs;
      await prefs.setString('${email}_quests', _encodeList(quests));
    }
  }

  // [CLAIM] Award EXP + coins for a completed quest; returns false if invalid
  Future<bool> claimQuestReward(String questId) async {
    final email = await _loggedInEmail();
    if (email == null) return false;

    final quests = await getDailyQuests();
    final idx    = quests.indexWhere((q) => q['id'] == questId);
    if (idx == -1) return false;

    final quest = quests[idx];
    if (quest['completed'] != true)     return false;
    if (quest['rewardClaimed'] == true) return false;

    await addExp(quest['rewardExp']     as int);
    await addCoins(quest['rewardCoins'] as int);
    quests[idx] = {...quest, 'rewardClaimed': true};

    final prefs = await _prefs;
    await prefs.setString('${email}_quests', _encodeList(quests));
    return true;
  }

  // * [QUIZ SETTINGS] (single shared record)
  Future<int> saveQuizSettings(Map<String, dynamic> settings) async {
    final prefs = await _prefs;
    await prefs.setString('quiz_settings', _encodeMap(settings));
    return 0;
  }

  Future<Map<String, dynamic>?> getQuizSettings() async {
    final prefs = await _prefs;
    return _decodeMap(prefs.getString('quiz_settings'));
  }

  // * [LEGACY NOTES]
  Future<int> insertNote(Map<String, dynamic> row) async {
    final prefs = await _prefs;
    final raw   = prefs.getString('notes');
    final notes = _decodeList(raw)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final id = DateTime.now().millisecondsSinceEpoch;
    notes.insert(0, {...row, 'id': id});
    await prefs.setString('notes', _encodeList(notes));
    return id;
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final prefs = await _prefs;
    final raw   = prefs.getString('notes');
    return _decodeList(raw)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<int> updateNote(Map<String, dynamic> row) async {
    final prefs = await _prefs;
    final raw   = prefs.getString('notes');
    final notes = _decodeList(raw)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final id  = row['id'] as int;
    final idx = notes.indexWhere((n) => n['id'] == id);
    if (idx != -1) notes[idx] = row;
    await prefs.setString('notes', _encodeList(notes));
    return id;
  }

  Future<int> deleteNote(int id) async {
    final prefs = await _prefs;
    final raw   = prefs.getString('notes');
    final notes = _decodeList(raw)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    notes.removeWhere((n) => n['id'] == id);
    await prefs.setString('notes', _encodeList(notes));
    return id;
  }
}