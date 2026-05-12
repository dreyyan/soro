// [IMPORT] Shared Preferences
// Uses shared_preferences instead of Hive because on Flutter Web, Hive stores
// data in IndexedDB which is scoped to the exact origin (hostname + PORT).
// When the local dev server restarts on a different port, all data is lost.
// shared_preferences on web uses window.localStorage which is scoped only to
// the hostname, so data persists across server restarts and port changes.
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math'; // Required for sqrt()
import 'package:soro/models/user_stats.dart';


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

  // [ACTION] Check if first launch
  Future<bool> isFirstLaunch() async {
    final prefs = await _prefs;
    return prefs.getBool('hasSeenOnboarding') != true;
  }

  // [ACTION] Mark onboarding as seen
  Future<void> setOnboardingSeen() async {
    final prefs = await _prefs;
    await prefs.setBool('hasSeenOnboarding', true);
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

  // [STATISTICS] Academic Stats
  Future<Map<String, dynamic>> getAcademicStats() async {
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

  // [REWARDS] Player Progression Stats (XP, Coins, Level)
  Future<UserStats> getProgressionStats() async {
    final email = await _loggedInEmail();
    if (email == null) {
      return UserStats(
        totalExp: 0,
        totalCoins: 0,
      );
    }
    final prefs = await _prefs;
    return UserStats(
      totalExp: prefs.getInt('${email}_totalExp') ?? 0,
      totalCoins: prefs.getInt('${email}_totalCoins') ?? 0,
    );
  }

  // [SAVE] Adds XP and Coins, returns true if the user leveled up
  Future<bool> saveRewards(int exp, int coins) async {
    final email = await _loggedInEmail();
    if (email == null) return false;
    
    final prefs = await _prefs;
    
    // 1. Get current stats using your renamed function
    final current = await getProgressionStats();
    final oldLevel = current.level;
    
    // 2. Calculate new totals
    final newExp = current.totalExp + exp;
    final newCoins = current.totalCoins + coins;
    
    // 3. Persist the updated values to SharedPreferences
    await prefs.setInt('${email}_totalExp', newExp);
    await prefs.setInt('${email}_totalCoins', newCoins);

    // 4. Create a temporary object with the NEW data to check the level
    // This uses the internal logic of your UserStats class automatically
    final updatedStats = UserStats(totalExp: newExp, totalCoins: newCoins);
    
    // 5. Check for rank achievements
    await _checkRankAchievements(newExp);
    
    // 6. Return true if the new level is higher than the old level
    return updatedStats.level > oldLevel;
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

  Future<Map<String, dynamic>> recordQuizResult(int correct, int total) async {
    final email = await _loggedInEmail();
    if (email == null) {
      return {'expEarned': 0, 'coinsEarned': 0, 'leveledUp': false};
    }
    
    final prefs       = await _prefs;
    final prevCorrect = prefs.getInt('${email}_quizCorrect') ?? 0;
    final prevTotal   = prefs.getInt('${email}_quizTotal')   ?? 0;
    final newCorrect = prevCorrect + correct;
    final newTotal = prevTotal + total;
    
    await prefs.setInt('${email}_quizCorrect', newCorrect);
    await prefs.setInt('${email}_quizTotal', newTotal);
    await _refreshStreak();
    
    // [CALCULATE] Accuracy-based rewards
    final accuracy = total > 0 ? (correct / total) : 0.0;
    final baseExp = 20;
    final bonusExp = ((correct / total) * 30).toInt(); // 0-30 bonus XP based on accuracy
    final expEarned = baseExp + bonusExp;
    final coinsEarned = (accuracy * 10).toInt(); // 0-10 coins based on accuracy
    final accuracyPercent = (accuracy * 100).toInt();
    
    // [AWARD] Rewards and check for level up
    final leveledUp = await saveRewards(expEarned, coinsEarned);
    
    // [QUEST PROGRESS] Update daily quests
    await _progressQuest('dailyStudy');
    await _updateQuestProgress('correctAnswers10', correct);
    await _updateQuestProgress('completeQuiz2', 1);
    
    // [QUEST] Accuracy quest progress (store accuracy as progress value)
    if (accuracyPercent >= 80) {
      await _updateQuestProgress('accuracy80', accuracyPercent);
    }
    
    // [ACHIEVEMENT] Check quiz milestone progression
    for (int i = 0; i < quizMilestones.length; i++) {
      if (newTotal >= quizMilestones[i] && prevTotal < quizMilestones[i]) {
        await unlockAchievement('quizMilestone');
      }
    }
    
    // [ACHIEVEMENT] Check accuracy milestone progression
    for (int i = 0; i < accuracyMilestones.length; i++) {
      if (accuracyPercent >= accuracyMilestones[i] && prevCorrect < newCorrect) {
        // Only check once per quiz
        if (i == 0) {
          await unlockAchievement('accuracyMilestone');
        }
      }
    }
    
    return {
      'expEarned': expEarned,
      'coinsEarned': coinsEarned,
      'leveledUp': leveledUp,
      'accuracy': accuracyPercent,
    };
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
    
    // [ACHIEVEMENTS] Check for streak milestones
    await _checkStreakAchievements(streak);
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
    final email = await _loggedInEmail();
    if (email == null) return;
    
    final decks = await getFlashcardDecks();
    final prevDecksCount = decks.length;
    
    decks.add(deck);
    await _saveFlashcardDecks(decks);
    await incrementCardsCreated();
    
    // [CARDS] Count total cards in the deck
    final cardCount = ((deck['cards'] as List?) ?? []).length;
    
    // [REWARDS] Add XP and progress quests
    await addExp(5);
    await _progressQuest('dailyStudy');
    await _updateQuestProgress('createCards5', cardCount);
    
    // [ACHIEVEMENTS] Check deck milestone progression
    final decksCreated = decks.length;
    for (int i = 0; i < deckMilestones.length; i++) {
      if (decksCreated >= deckMilestones[i] && prevDecksCount < deckMilestones[i]) {
        await unlockAchievement('deckMilestone');
      }
    }
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

  Future<void> updateSavedQuiz(Map<String, dynamic> quiz) async {
  final quizzes = await getSavedQuizzes();
  final idx = quizzes.indexWhere((q) => q['id'] == quiz['id']);
  if (idx == -1) return;
  quizzes[idx] = quiz;
  await _saveQuizzes(quizzes);
}

  // * [CURRENCY]  (coins, XP, achievements)
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
    final exp    = prefs.getInt('${email}_totalExp')   ?? 0;
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
    final current = prefs.getInt('${email}_totalExp') ?? 0;
    await prefs.setInt('${email}_totalExp', current + amount);
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

  // [GET] All achievements with unlock status and progressive milestone info
  Future<List<Map<String, dynamic>>> getAllAchievements() async {
    final email = await _loggedInEmail();
    if (email == null) return [];
    
    final prefs = await _prefs;
    
    final rawAch = prefs.getString('${email}_achievements');
    final unlockedIds = rawAch != null
        ? List<String>.from(_decodeList(rawAch).cast<String>())
        : <String>[];

    // [GET] Stats for progressive milestones
    final stats = await getAcademicStats();
    final quizCount = stats['quizTotal'] as int;
    final deckCount = stats['cardsCreated'] as int;
    final accuracy = stats['accuracy'] as int? ?? 0;

    // [BUILD] Achievement list with progressive milestone info
    final result = <Map<String, dynamic>>[];
    
    for (final achDef in achievementDefs) {
      final achId = achDef['id'] as String;
      final isProgressive = achDef['isProgressive'] as bool? ?? false;
      
      if (!isProgressive) {
        // [STATIC] Non-progressive achievements
        result.add({
          ...achDef,
          'unlocked': unlockedIds.contains(achId),
        });
      } else {
        // [PROGRESSIVE] Build current milestone info
        final type = achDef['type'] as String;
        int currentLevel = 0;
        int currentMilestone = 0;
        String currentTitle = '';
        String currentIcon = '';
        String currentRarity = '';
        String currentDescription = '';
        bool unlocked = false;

        if (type == 'quiz') {
          // [QUIZ] Find which milestone level they're at
          for (int i = 0; i < quizMilestones.length; i++) {
            if (quizCount >= quizMilestones[i]) {
              currentLevel = i;
              unlocked = true;
            } else {
              break;
            }
          }
          currentMilestone = currentLevel < quizMilestones.length ? quizMilestones[currentLevel] : quizMilestones.last;
          currentTitle = quizTitles[currentLevel];
          currentIcon = quizIcons[currentLevel];
          currentRarity = quizRarities[currentLevel];
          currentDescription = 'Complete ${currentMilestone} quizzes';
        } else if (type == 'deck') {
          // [DECK] Find which milestone level they're at
          for (int i = 0; i < deckMilestones.length; i++) {
            if (deckCount >= deckMilestones[i]) {
              currentLevel = i;
              unlocked = true;
            } else {
              break;
            }
          }
          currentMilestone = currentLevel < deckMilestones.length ? deckMilestones[currentLevel] : deckMilestones.last;
          currentTitle = deckTitles[currentLevel];
          currentIcon = deckIcons[currentLevel];
          currentRarity = deckRarities[currentLevel];
          currentDescription = 'Create ${currentMilestone} decks';
        } else if (type == 'accuracy') {
          // [ACCURACY] Find which milestone level they're at
          for (int i = 0; i < accuracyMilestones.length; i++) {
            if (accuracy >= accuracyMilestones[i]) {
              currentLevel = i;
              unlocked = true;
            } else {
              break;
            }
          }
          currentMilestone = currentLevel < accuracyMilestones.length ? accuracyMilestones[currentLevel] : accuracyMilestones.last;
          currentTitle = accuracyTitles[currentLevel];
          currentIcon = accuracyIcons[currentLevel];
          currentRarity = accuracyRarities[currentLevel];
          currentDescription = 'Achieve ${currentMilestone}% accuracy';
        }

        result.add({
          ...achDef,
          'title': currentTitle,
          'icon': currentIcon,
          'rarity': currentRarity,
          'description': currentDescription,
          'currentMilestone': currentMilestone,
          'currentLevel': currentLevel,
          'unlocked': unlocked,
        });
      }
    }
    
    return result;
  }

  // [CHECK] Rank achievements and unlock if applicable
  Future<void> _checkRankAchievements(int totalExp) async {
    if (totalExp >= (rankTiers[1]['minExp'] as int)) {
      await unlockAchievement('rankApprentice');
    }
    if (totalExp >= (rankTiers[2]['minExp'] as int)) {
      await unlockAchievement('rankScholar');
    }
    if (totalExp >= (rankTiers[3]['minExp'] as int)) {
      await unlockAchievement('rankExpert');
    }
    if (totalExp >= (rankTiers[4]['minExp'] as int)) {
      await unlockAchievement('rankMaster');
    }
  }

  // [CHECK] Streak achievements and unlock if applicable
  Future<void> _checkStreakAchievements(int streakDays) async {
    if (streakDays >= 3) {
      await unlockAchievement('streak3');
    }
    if (streakDays >= 7) {
      await unlockAchievement('streak7');
    }
    if (streakDays >= 14) {
      await unlockAchievement('streak14');
    }
    if (streakDays >= 30) {
      await unlockAchievement('streak30');
    }
  }

  // [HELPER] Derive rank title, icon, and progress from total XP
  static Map<String, dynamic> getRankFromExp(int exp) {
    Map<String, dynamic> current = rankTiers.first;
    for (final tier in rankTiers) {
      if (exp >= (tier['minExp'] as int)) current = tier;
    }
    final idx     = rankTiers.indexOf(current);
    final next    = idx < rankTiers.length - 1 ? rankTiers[idx + 1] : null;
    final nextExp = next != null ? (next['minExp'] as int) : null;
    final progress = nextExp != null
      ? (exp / nextExp).clamp(0.0, 1.0)
      : 1.0;
    return {
      ...current,
      'exp':      exp,
      'nextExp':  nextExp,
      'progress': progress,
    };
  }

  // * [ACHIEVEMENTS] 20+ achievements with tracking
  // [PROGRESSIVE] Quiz milestones: 1 → 5 → 10 → 50 → 100
  static const List<int> quizMilestones = [1, 5, 10, 50, 100];
  static const List<String> quizTitles = ['Quiz Master', 'Quiz Veteran', 'Quiz Warrior', 'Quiz Champion', 'Quiz Legend'];
  static const List<String> quizIcons = ['📝', '📚', '⚔️', '🏆', '⭐'];
  static const List<String> quizRarities = ['common', 'common', 'uncommon', 'rare', 'rare'];

  // [PROGRESSIVE] Deck milestones: 1 → 5 → 10 → 50 → 100
  static const List<int> deckMilestones = [1, 5, 10, 50, 100];
  static const List<String> deckTitles = ['Creator', 'Content Creator', 'Deck Master', 'Deck Legend', 'Deck Architect'];
  static const List<String> deckIcons = ['🃏', '📋', '🎨', '💎', '🏢'];
  static const List<String> deckRarities = ['common', 'common', 'uncommon', 'rare', 'legendary'];

  // [PROGRESSIVE] Accuracy milestones: 80% → 90% → 100%
  static const List<int> accuracyMilestones = [80, 90, 100];
  static const List<String> accuracyTitles = ['Accurate', 'Perfectionist', 'Flawless'];
  static const List<String> accuracyIcons = ['🎯', '💯', '✨'];
  static const List<String> accuracyRarities = ['common', 'uncommon', 'legendary'];

  static const List<Map<String, dynamic>> achievementDefs = [
    // [PROGRESSIVE ACHIEVEMENTS - Grid item updates as you progress]
    {'id': 'quizMilestone', 'title': 'Quiz Progression', 'description': 'Progressive quizzes', 'icon': '📝', 'isRepeatable': false, 'rarity': 'common', 'isProgressive': true, 'type': 'quiz'},
    {'id': 'deckMilestone', 'title': 'Deck Progression', 'description': 'Progressive decks', 'icon': '🃏', 'isRepeatable': false, 'rarity': 'common', 'isProgressive': true, 'type': 'deck'},
    {'id': 'accuracyMilestone', 'title': 'Accuracy Progression', 'description': 'Progressive accuracy', 'icon': '🎯', 'isRepeatable': false, 'rarity': 'common', 'isProgressive': true, 'type': 'accuracy'},

    // [RANK ACHIEVEMENTS]
    {'id': 'rankApprentice', 'title': 'Rising Star', 'description': 'Reach Apprentice rank', 'icon': '📖', 'isRepeatable': false, 'rarity': 'common'},
    {'id': 'rankScholar', 'title': 'Scholar', 'description': 'Reach Scholar rank', 'icon': '🎓', 'isRepeatable': false, 'rarity': 'uncommon'},
    {'id': 'rankExpert', 'title': 'Expert', 'description': 'Reach Expert rank', 'icon': '⚡', 'isRepeatable': false, 'rarity': 'rare'},
    {'id': 'rankMaster', 'title': 'Ultimate Master', 'description': 'Reach Master rank', 'icon': '👑', 'isRepeatable': false, 'rarity': 'legendary'},

    // [STREAK ACHIEVEMENTS - NOT in daily quests]
    {'id': 'streak3', 'title': 'Warm Up', 'description': 'Maintain a 3-day study streak', 'icon': '🔥', 'isRepeatable': true, 'rarity': 'common'},
    {'id': 'streak7', 'title': 'On Fire', 'description': 'Maintain a 7-day study streak', 'icon': '🔥🔥', 'isRepeatable': true, 'rarity': 'uncommon'},
    {'id': 'streak14', 'title': 'Unstoppable', 'description': 'Maintain a 14-day study streak', 'icon': '🌟', 'isRepeatable': true, 'rarity': 'rare'},
    {'id': 'streak30', 'title': 'Legendary Grinder', 'description': 'Maintain a 30-day study streak', 'icon': '👑', 'isRepeatable': true, 'rarity': 'legendary'},
  ];

  // * [DAILY QUESTS] 3 quests generated per day: 1 fixed + 2 random from pool
  static const List<Map<String, dynamic>> _fixedDailyQuest = [
    {
      'id':          'dailyStudy',
      'title':       'Daily Study',
      'description': 'Complete a quiz or create a deck',
      'icon':        '📖',
      'goal':        1,
      'rewardExp':   25,
      'rewardCoins': 10,
      'difficulty':  'easy',
    },
  ];

  static const List<Map<String, dynamic>> _questPool = [
    {
      'id':          'correctAnswers10',
      'title':       'Accuracy Focused',
      'description': 'Get 10 correct answers across quizzes',
      'icon':        '✅',
      'goal':        10,
      'rewardExp':   50,
      'rewardCoins': 20,
      'difficulty':  'medium',
    },
    {
      'id':          'createCards5',
      'title':       'Card Maker',
      'description': 'Create 5 flashcards today',
      'icon':        '🃏',
      'goal':        5,
      'rewardExp':   40,
      'rewardCoins': 15,
      'difficulty':  'medium',
    },
    {
      'id':          'completeQuiz2',
      'title':       'Quiz Enthusiast',
      'description': 'Complete 2 quizzes today',
      'icon':        '📝📝',
      'goal':        2,
      'rewardExp':   60,
      'rewardCoins': 25,
      'difficulty':  'hard',
    },
    {
      'id':          'accuracy80',
      'title':       'Accuracy Master',
      'description': 'Achieve 80%+ accuracy on a quiz',
      'icon':        '🎯',
      'goal':        80,
      'rewardExp':   55,
      'rewardCoins': 22,
      'difficulty':  'hard',
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
      // [FIXED] First quest is always the same
      final quests = List<Map<String, dynamic>>.from(_fixedDailyQuest);
      
      // [RANDOM] Select 2 random quests from the pool
      final random = Random();
      final poolIndices = List.generate(_questPool.length, (i) => i);
      poolIndices.shuffle(random);
      for (int i = 0; i < 2 && i < poolIndices.length; i++) {
        quests.add(_questPool[poolIndices[i]]);
      }
      
      // [ADD STATE] Initialize progress fields
      final fresh = quests
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
      // Fallback if no quests saved for today
      final quests = List<Map<String, dynamic>>.from(_fixedDailyQuest);
      final random = Random();
      final poolIndices = List.generate(_questPool.length, (i) => i);
      poolIndices.shuffle(random);
      for (int i = 0; i < 2 && i < poolIndices.length; i++) {
        quests.add(_questPool[poolIndices[i]]);
      }
      return quests
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
      if (questId == 'maintainStreak') {
        // [STREAK] Use actual streak value
        final stats = await getAcademicStats();
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

  // [QUEST PROGRESS] Update specific quest by type
  Future<void> _updateQuestProgress(String questType, int amount) async {
    final email = await _loggedInEmail();
    if (email == null) return;

    final quests = await getDailyQuests();
    bool changed = false;

    for (int i = 0; i < quests.length; i++) {
      if (quests[i]['completed'] == true) continue;
      
      final questId = quests[i]['id'] as String;
      if (questId == questType) {
        final progress = ((quests[i]['progress'] as int?) ?? 0) + amount;
        final goal = quests[i]['goal'] as int;
        final completed = progress >= goal;
        quests[i] = {...quests[i], 'progress': progress, 'completed': completed};
        changed = true;
      }
    }

    if (changed) {
      final prefs = await _prefs;
      await prefs.setString('${email}_quests', _encodeList(quests));
    }
  }

  // [CLAIM] Award XP + coins for a completed quest; returns false if invalid
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