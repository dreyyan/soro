// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Quest Screen — Rank, Currency, Daily Quests, Achievements
// ─────────────────────────────────────────────────────────────────────────────

class Quest extends StatefulWidget {
  const Quest({super.key});

  @override
  State<Quest> createState() => _QuestState();
}

class _QuestState extends State<Quest> {
  // [STATE]
  Map<String, dynamic> _currency  = {'coins': 0, 'exp': 0, 'achievements': []};
  List<Map<String, dynamic>> _quests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final currency = await DatabaseHelper().getCurrency();
    final quests   = await DatabaseHelper().getDailyQuests();
    if (!mounted) return;
    setState(() {
      _currency  = currency;
      _quests    = quests;
      _isLoading = false;
    });
  }

  Future<void> _claimReward(String questId) async {
    final success = await DatabaseHelper().claimQuestReward(questId);
    if (!mounted) return;
    if (success) {
      await _load(); // refresh all data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Reward claimed!'),
          backgroundColor: AppColors.green_600,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  Map<String, dynamic> get _rank {
    final exp = _currency['exp'] as int? ?? 0;
    return DatabaseHelper.getRankFromExp(exp);
  }

  Color _questColor(Map<String, dynamic> quest) {
    if (quest['rewardClaimed'] == true) return AppColors.green_100;
    if (quest['completed'] == true) return AppColors.primary_100;
    return Colors.white;
  }

  // ─────────────────────────────────────────────
  // UI SECTIONS
  // ─────────────────────────────────────────────

  // ── Currency Row ─────────────────────────────────────────────────────────
  Widget _buildCurrencyRow() {
    final coins = _currency['coins'] as int? ?? 0;
    final exp   = _currency['exp']   as int? ?? 0;
    final achievements =
        (_currency['achievements'] as List?)?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _currencyChip('🪙', '$coins', 'Coins',
              AppColors.secondary_50, AppColors.secondary_700),
          const SizedBox(width: 10),
          _currencyChip('⚡', '$exp', 'EXP',
              AppColors.primary_100, AppColors.primary_700),
          const SizedBox(width: 10),
          _currencyChip('🏅', '$achievements', 'Badges',
              AppColors.green_100, AppColors.green_700),
        ],
      ),
    );
  }

  Widget _currencyChip(
      String emoji, String value, String label, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Baloo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                color: fg.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rank Card ─────────────────────────────────────────────────────────────
  Widget _buildRankCard() {
    final rank     = _rank;
    final title    = rank['title']    as String;
    final icon     = rank['icon']     as String;
    final exp      = rank['exp']      as int;
    final nextExp  = rank['nextExp']  as int?;
    final progress = rank['progress'] as double;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary_600, AppColors.primary_800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Rank',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Baloo',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$exp EXP',
                      style: const TextStyle(
                        fontFamily: 'Baloo',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (nextExp != null)
                      Text(
                        '/ $nextExp to next',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // EXP progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            if (nextExp != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${nextExp - exp} EXP to ${_nextRankTitle()}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Max rank reached! 👑',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _nextRankTitle() {
    final exp  = _currency['exp'] as int? ?? 0;
    final rank = DatabaseHelper.getRankFromExp(exp);
    final idx  = DatabaseHelper.rankTiers
        .indexWhere((t) => t['title'] == rank['title']);
    if (idx < DatabaseHelper.rankTiers.length - 1) {
      return DatabaseHelper.rankTiers[idx + 1]['title'] as String;
    }
    return '';
  }

  // ── Daily Quests ──────────────────────────────────────────────────────────
  Widget _buildDailyQuests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Daily Quests',
            style: TextStyle(
              fontFamily: 'Baloo',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text_800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Resets at midnight',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: AppColors.text_400,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._quests.map((q) => _questCard(q)),
      ],
    );
  }

  Widget _questCard(Map<String, dynamic> quest) {
    final id           = quest['id']            as String;
    final title        = quest['title']         as String;
    final description  = quest['description']   as String;
    final icon         = quest['icon']          as String;
    final goal         = quest['goal']          as int;
    final progress     = quest['progress']      as int? ?? 0;
    final completed    = quest['completed']     as bool? ?? false;
    final claimed      = quest['rewardClaimed'] as bool? ?? false;
    final rewardExp    = quest['rewardExp']     as int;
    final rewardCoins  = quest['rewardCoins']   as int;

    final progressFrac = (progress / goal).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _questColor(quest),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: claimed
              ? AppColors.green_300
              : completed
                  ? AppColors.primary_300
                  : AppColors.text_100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Baloo',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text_800,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: AppColors.text_500,
                      ),
                    ),
                  ],
                ),
              ),
              // Claim / status badge
              if (claimed)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.green_500,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✓ Claimed',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              else if (completed)
                GestureDetector(
                  onTap: () => _claimReward(id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary_600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Claim!',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  '$progress/$goal',
                  style: const TextStyle(
                    fontFamily: 'Baloo',
                    fontSize: 14,
                    color: AppColors.text_400,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressFrac,
              minHeight: 8,
              backgroundColor: AppColors.text_100,
              valueColor: AlwaysStoppedAnimation(
                claimed
                    ? AppColors.green_500
                    : AppColors.primary_500,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Rewards line
          Row(
            children: [
              const Icon(Icons.star_outline,
                  size: 14, color: AppColors.text_400),
              const SizedBox(width: 4),
              Text(
                'Reward: +$rewardExp EXP  •  +$rewardCoins coins',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppColors.text_400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Achievements ──────────────────────────────────────────────────────────
  Widget _buildAchievements() {
    final earned = List<String>.from(
        _currency['achievements'] as List? ?? []);

    // All defined achievements
    const allAchievements = [
      {'id': 'first_card',  'title': 'First Card',    'icon': '🃏', 'desc': 'Create your first flashcard'},
      {'id': 'first_quiz',  'title': 'Quiz Starter',  'icon': '📝', 'desc': 'Complete your first quiz'},
      {'id': 'streak_3',    'title': 'On Fire',        'icon': '🔥', 'desc': 'Reach a 3-day streak'},
      {'id': 'scholar',     'title': 'Scholar',        'icon': '🎓', 'desc': 'Reach Scholar rank'},
      {'id': 'card_10',     'title': 'Card Collector', 'icon': '📚', 'desc': 'Create 10 flashcards'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Achievements',
            style: TextStyle(
              fontFamily: 'Baloo',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text_800,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: allAchievements.length,
            itemBuilder: (_, i) {
              final ach      = allAchievements[i];
              final unlocked = earned.contains(ach['id']);
              return Container(
                decoration: BoxDecoration(
                  color: unlocked
                      ? AppColors.primary_100
                      : AppColors.text_50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: unlocked
                        ? AppColors.primary_300
                        : AppColors.text_100,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      unlocked ? ach['icon']! : '🔒',
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ach['title']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Baloo',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: unlocked
                            ? AppColors.primary_700
                            : AppColors.text_300,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ach['desc']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        color: unlocked
                            ? AppColors.text_500
                            : AppColors.text_200,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary_50,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    // Page title
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Quest',
                        style: TextStyle(
                          fontFamily: 'Baloo',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text_800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Currency row
                    _buildCurrencyRow(),
                    const SizedBox(height: 16),

                    // Rank card
                    _buildRankCard(),
                    const SizedBox(height: 24),

                    // Daily quests
                    _buildDailyQuests(),
                    const SizedBox(height: 28),

                    // Achievements
                    _buildAchievements(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}