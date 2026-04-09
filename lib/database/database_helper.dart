// [IMPORT] Hive
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseHelper {
  // [SINGLETON]
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Box Names
  static const String notesBox        = 'notes';
  static const String quizSettingsBox = 'quiz_settings';
  static const String usersBox        = 'users';
  static const String sessionBox      = 'session';
  static const String statsBox        = 'stats';
  static const String flashcardsBox   = 'flashcards_v2';  // per-user flashcard sets
  static const String quizzesBox      = 'quizzes';        // per-user saved quizzes
  static const String currencyBox     = 'currency';       // coins, exp, achievements
  static const String questsBox       = 'quests';         // daily quest progress

  // [INIT]
  static Future<void> init() async {
    await Hive.initFlutter();
  }

  // [HELPERS]
  Future<String?> _loggedInEmail() async {
    final b = await Hive.openBox(sessionBox);
    return b.get('loggedInEmail') as String?;
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // [AUTHENTICATION]
  Future<String?> registerUser(Map<String, dynamic> userData) async {
    final box = await Hive.openBox(usersBox);
    final email = (userData['email'] as String).trim().toLowerCase();
    final existing = box.values.cast<Map>().any(
          (u) => (u['email'] as String).toLowerCase() == email,
        );
    if (existing) return 'An account with this email already exists.';
    await box.add({...userData, 'email': email});
    return null;
  }

  Future<String?> loginUser(String email, String password) async {
    final box = await Hive.openBox(usersBox);
    final normalizedEmail = email.trim().toLowerCase();
    final match = box.values.cast<Map>().where(
          (u) =>
              (u['email'] as String).toLowerCase() == normalizedEmail &&
              u['password'] == password,
        );
    if (match.isEmpty) return 'Incorrect email or password.';
    final sessionB = await Hive.openBox(sessionBox);
    await sessionB.put('loggedInEmail', normalizedEmail);
    return null;
  }

  Future<Map<String, dynamic>?> getLoggedInUser() async {
    final email = await _loggedInEmail();
    if (email == null) return null;
    final box = await Hive.openBox(usersBox);
    final match = box.values.cast<Map>().where(
          (u) => (u['email'] as String).toLowerCase() == email,
        );
    if (match.isEmpty) return null;
    return Map<String, dynamic>.from(match.first);
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final box = await Hive.openBox(usersBox);
    dynamic userKey;
    for (final key in box.keys) {
      final u = box.get(key) as Map?;
      if (u != null && (u['email'] as String).toLowerCase() == email) {
        userKey = key;
        break;
      }
    }
    if (userKey == null) return;
    final existing = Map<String, dynamic>.from(box.get(userKey) as Map);
    await box.put(userKey, {...existing, ...updates});
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = await _loggedInEmail();
    if (email == null) return false;

    final box = await Hive.openBox(usersBox);

    // Find the user by email
    dynamic userKey;
    Map<String, dynamic>? userData;

    for (final key in box.keys) {
      final u = box.get(key) as Map?;
      if (u != null && (u['email'] as String).toLowerCase() == email) {
        userKey = key;
        userData = Map<String, dynamic>.from(u);
        break;
      }
    }

    if (userKey == null || userData == null) return false;

    // Verify current password
    if (userData['password'] != currentPassword) {
      return false;
    }

    // Update with new password
    userData['password'] = newPassword;

    await box.put(userKey, userData);
    return true;
  }

  Future<void> logoutUser() async {
    final b = await Hive.openBox(sessionBox);
    await b.delete('loggedInEmail');
  }

  Future<bool> isLoggedIn() async {
    final b = await Hive.openBox(sessionBox);
    return b.containsKey('loggedInEmail');
  }

  // [STATISTICS]
  Future<Map<String, dynamic>> getUserStats() async {
    final box   = await Hive.openBox(statsBox);
    final email = await _loggedInEmail();
    if (email == null) {
      return {'cardsCreated': 0, 'quizCorrect': 0, 'quizTotal': 0, 'streakDays': 0, 'accuracy': null};
    }
    final cards   = (box.get('${email}_cardsCreated') as int?) ?? 0;
    final correct = (box.get('${email}_quizCorrect')  as int?) ?? 0;
    final total   = (box.get('${email}_quizTotal')    as int?) ?? 0;
    final streak  = (box.get('${email}_streakDays')   as int?) ?? 0;
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
    final box = await Hive.openBox(statsBox);
    final current = (box.get('${email}_cardsCreated') as int?) ?? 0;
    await box.put('${email}_cardsCreated', current + 1);
    await _refreshStreak();
  }

  Future<void> decrementCardsCreated() async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final box = await Hive.openBox(statsBox);
    final current = (box.get('${email}_cardsCreated') as int?) ?? 0;
    await box.put('${email}_cardsCreated', (current - 1).clamp(0, 999999));
  }

  Future<void> recordQuizResult(int correct, int total) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final box = await Hive.openBox(statsBox);
    final prevCorrect = (box.get('${email}_quizCorrect') as int?) ?? 0;
    final prevTotal   = (box.get('${email}_quizTotal')   as int?) ?? 0;
    await box.put('${email}_quizCorrect', prevCorrect + correct);
    await box.put('${email}_quizTotal',   prevTotal   + total);
    await _refreshStreak();

    // Award EXP for completing a quiz
    await addExp(20 + correct * 2);
    await _progressQuest('completeQuiz');
  }

  Future<void> _refreshStreak() async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final box   = await Hive.openBox(statsBox);
    final today = _todayString();
    final lastDate = box.get('${email}_lastStudyDate') as String?;
    if (lastDate == today) return;
    int streak = (box.get('${email}_streakDays') as int?) ?? 0;
    if (lastDate == null) {
      streak = 1;
    } else {
      final diff = DateTime.parse(today).difference(DateTime.parse(lastDate)).inDays;
      streak = diff == 1 ? streak + 1 : 1;
    }
    await box.put('${email}_streakDays',    streak);
    await box.put('${email}_lastStudyDate', today);
  }

  // [FLASHCARDS]
  Future<List<Map<String, dynamic>>> getFlashcardDecks() async {
    final email = await _loggedInEmail();
    if (email == null) return [];
    final box = await Hive.openBox(flashcardsBox);
    final raw = box.get('${email}_decks');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  Future<void> _saveFlashcardDecks(List<Map<String, dynamic>> decks) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final box = await Hive.openBox(flashcardsBox);
    await box.put('${email}_decks', decks);
  }

  Future<void> addFlashcardDeck(Map<String, dynamic> deck) async {
    final decks = await getFlashcardDecks();
    decks.add(deck);
    await _saveFlashcardDecks(decks);
    await incrementCardsCreated();
    await addExp(5);
    await _progressQuest('createCard');
  }

  Future<void> updateFlashcardDeck(String id, Map<String, dynamic> updated) async {
    final decks = await getFlashcardDecks();
    final idx = decks.indexWhere((d) => d['id'] == id);
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

  // Get all individual cards across all decks (for legacy quiz support)
  Future<List<Map<String, dynamic>>> getAllCards() async {
    final decks = await getFlashcardDecks();
    final all = <Map<String, dynamic>>[];
    for (final deck in decks) {
      final cards = (deck['cards'] as List? ?? []);
      for (final c in cards) {
        all.add({
          'term': c['term'],
          'definition': c['definition'],
          'deckTitle': deck['title'],
          'deckId': deck['id'],
        });
      }
    }
    return all;
  }

  // [QUIZZES]
  Future<List<Map<String, dynamic>>> getSavedQuizzes() async {
    final email = await _loggedInEmail();
    if (email == null) return [];
    final box = await Hive.openBox(quizzesBox);
    final raw = box.get('${email}_quizzes');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  Future<void> _saveQuizzes(List<Map<String, dynamic>> quizzes) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final box = await Hive.openBox(quizzesBox);
    await box.put('${email}_quizzes', quizzes);
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

  // [CURRENCY]
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
    final box  = await Hive.openBox(currencyBox);
    final coins = (box.get('${email}_coins') as int?) ?? 0;
    final exp   = (box.get('${email}_exp')   as int?) ?? 0;
    final rawAch = box.get('${email}_achievements');
    final achievements = rawAch != null
        ? List<String>.from(rawAch as List)
        : <String>[];
    return {'coins': coins, 'exp': exp, 'achievements': achievements};
  }

  Future<void> addCoins(int amount) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final box   = await Hive.openBox(currencyBox);
    final current = (box.get('${email}_coins') as int?) ?? 0;
    await box.put('${email}_coins', current + amount);
  }

  Future<void> spendCoins(int amount) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final box     = await Hive.openBox(currencyBox);
    final current = (box.get('${email}_coins') as int?) ?? 0;
    await box.put('${email}_coins', (current - amount).clamp(0, 999999));
  }

  Future<void> addExp(int amount) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final box     = await Hive.openBox(currencyBox);
    final current = (box.get('${email}_exp') as int?) ?? 0;
    await box.put('${email}_exp', current + amount);
  }

  Future<void> unlockAchievement(String achievementId) async {
    final email = await _loggedInEmail();
    if (email == null) return;
    final box  = await Hive.openBox(currencyBox);
    final raw  = box.get('${email}_achievements');
    final list = raw != null ? List<String>.from(raw as List) : <String>[];
    if (!list.contains(achievementId)) {
      list.add(achievementId);
      await box.put('${email}_achievements', list);
    }
  }

  // [HELPER] Derive rank from total EXP
  static Map<String, dynamic> getRankFromExp(int exp) {
    Map<String, dynamic> current = rankTiers.first;
    for (final tier in rankTiers) {
      if (exp >= (tier['minExp'] as int)) current = tier;
    }
    // Find next tier
    final idx = rankTiers.indexOf(current);
    final next = idx < rankTiers.length - 1 ? rankTiers[idx + 1] : null;
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

  // [DAILY QUESTS] 3 quests are generated per day, which resets at midnight
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

  // [GET] Today's daily quests with current progress for the logged-in user.
  // Resets progress automatically if the date has changed.
  Future<List<Map<String, dynamic>>> getDailyQuests() async {
    final email = await _loggedInEmail();
    if (email == null) return [];

    final box   = await Hive.openBox(questsBox);
    final today = _todayString();

    // Check if we need to reset (new day or first time)
    final savedDate = box.get('${email}_questDate') as String?;
    if (savedDate != today) {
      // New day — reset progress (but keep definitions)
      final fresh = _questDefs.map((q) => {
            ...q,
            'progress': 0,
            'completed': false,
            'rewardClaimed': false,
          }).toList();
      await box.put('${email}_questDate',  today);
      await box.put('${email}_quests',     fresh);
      return List<Map<String, dynamic>>.from(fresh);
    }

    // Load existing progress
    final raw = box.get('${email}_quests');
    if (raw == null) return _questDefs.map((q) => {...q, 'progress': 0, 'completed': false, 'rewardClaimed': false}).toList();
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // [INTERNAL] Advance quest progress when a relevant action occurs.
  Future<void> _progressQuest(String questId) async {
    final email = await _loggedInEmail();
    if (email == null) return;

    final quests = await getDailyQuests();
    bool changed = false;

    for (int i = 0; i < quests.length; i++) {
      if (quests[i]['id'] != questId) continue;
      if (quests[i]['completed'] == true) continue;

      // Special case: studyStreak uses actual streak value
      int progress;
      if (questId == 'studyStreak') {
        final stats = await getUserStats();
        progress = (stats['streakDays'] as int? ?? 0);
      } else {
        progress = ((quests[i]['progress'] as int?) ?? 0) + 1;
      }

      final goal      = quests[i]['goal'] as int;
      final completed = progress >= goal;
      quests[i] = {...quests[i], 'progress': progress, 'completed': completed};
      changed = true;
    }

    if (changed) {
      final box = await Hive.openBox(questsBox);
      await box.put('${email}_quests', quests);
    }
  }

  // [CLAIM] Reward for a completed quest. Call when user taps "Claim".
  // Returns false if quest not completed or already claimed.
  Future<bool> claimQuestReward(String questId) async {
    final email = await _loggedInEmail();
    if (email == null) return false;

    final quests = await getDailyQuests();
    final idx    = quests.indexWhere((q) => q['id'] == questId);
    if (idx == -1) return false;

    final quest = quests[idx];
    if (quest['completed'] != true)     return false;
    if (quest['rewardClaimed'] == true) return false;

    await addExp(quest['rewardExp']   as int);
    await addCoins(quest['rewardCoins'] as int);
    quests[idx] = {...quest, 'rewardClaimed': true};

    final box = await Hive.openBox(questsBox);
    await box.put('${email}_quests', quests);
    return true;
  }

  // [LEGACY NOTES]
  Future<int> insertNote(Map<String, dynamic> row) async {
    var box = await Hive.openBox(notesBox);
    return await box.add(row);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    var box = await Hive.openBox(notesBox);
    return box.values.cast<Map<String, dynamic>>().toList().reversed.toList();
  }

  Future<int> updateNote(Map<String, dynamic> row) async {
    var box = await Hive.openBox(notesBox);
    int id  = row['id'] as int;
    await box.put(id, row);
    return id;
  }

  Future<int> deleteNote(int id) async {
    var box = await Hive.openBox(notesBox);
    await box.delete(id);
    return id;
  }

  // [QUIZ SETTINGS]
  Future<int> saveQuizSettings(Map<String, dynamic> settings) async {
    var box = await Hive.openBox(quizSettingsBox);
    if (box.isEmpty) {
      return await box.add(settings);
    } else {
      int id = box.keys.first as int;
      await box.put(id, settings);
      return id;
    }
  }

  Future<Map<String, dynamic>?> getQuizSettings() async {
    var box = await Hive.openBox(quizSettingsBox);
    if (box.isNotEmpty) {
      return Map<String, dynamic>.from(box.values.first as Map);
    }
    return null;
  }
}