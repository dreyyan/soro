// lib/models/user_stats.dart
import 'dart:math';

class UserStats {
  final int totalExp;
  final int totalCoins;

  UserStats({this.totalExp = 0, this.totalCoins = 0});

  int get level => (sqrt(totalExp / 100)).floor() + 1;

  double get progressToNextLevel {
    int currentLevel = level;
    int expForCurrent = 100 * (currentLevel - 1) * (currentLevel - 1);
    int expForNext = 100 * currentLevel * currentLevel;
    
    if (expForNext == expForCurrent) return 0.0;
    return ((totalExp - expForCurrent) / (expForNext - expForCurrent)).clamp(0.0, 1.0);
  }

  static Map<String, int> calculateRewards(int score, int totalQuestions) {
    int earnedExp = (score * 10) + (totalQuestions * 2);
    int earnedCoins = score * 5;

    if (score == totalQuestions && totalQuestions > 0) {
      earnedExp = (earnedExp * 1.25).round();
    }

    return {'exp': earnedExp, 'coins': earnedCoins};
  }
}