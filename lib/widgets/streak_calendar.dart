// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [WIDGET] Streak Calendar
class StreakCalendar extends StatefulWidget {
  final int streak;

  /// Day-of-month numbers the user was actually active in the displayed month.
  /// Pass real DB data here. Example: {1, 3, 4, 5, 7} → active on those days.
  final Set<int> activeDays;

  const StreakCalendar({
    super.key,
    required this.streak,
    this.activeDays = const {},
  });

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  DateTime _currentMonth = DateTime.now();

  int _daysInMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  int _firstWeekday(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday;
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + offset,
      );
    });
  }

  String _monthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _daysInMonth(_currentMonth);
    final firstWeekday = _firstWeekday(_currentMonth);
    final today = DateTime.now();

    final isCurrentMonth =
        _currentMonth.year == today.year &&
        _currentMonth.month == today.month;

    final activeDays = widget.activeDays;

    // Streak band only renders when streak >= 3
    final hasActiveStreak = widget.streak >= 3;
    final streakStart = hasActiveStreak
        ? (today.day - widget.streak).clamp(1, today.day)
        : -1;

    bool isStreakDay(int day) {
      if (!isCurrentMonth || !hasActiveStreak) return false;
      return day >= streakStart && day <= today.day;
    }

    // Pale highlight: user was active on this day but outside the streak band
    bool isUsedDay(int day) {
      if (isStreakDay(day)) return false;
      return activeDays.contains(day);
    }

    BorderRadius streakBorderRadius(int day) {
      final gridCol = (day + firstWeekday - 2) % 7;
      final streakOverflows = streakStart == 1 && (today.day - widget.streak + 1) < 1;

      final roundLeft  = day == streakStart || gridCol == 0 || (day == 1 && streakOverflows);
      final roundRight = day == today.day   || gridCol == 6;

      const r = Radius.circular(6);
      const z = Radius.zero;

      return BorderRadius.only(
        topLeft:     roundLeft  ? r : z,
        bottomLeft:  roundLeft  ? r : z,
        topRight:    roundRight ? r : z,
        bottomRight: roundRight ? r : z,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary_50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // [SECTION] Streak Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasActiveStreak) ...[
                Row(
                  children: [
                    Text(
                      '${widget.streak + 1}',
                      style: const TextStyle(
                        fontFamily: "Nunito",
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary_500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "day streak!",
                      style: TextStyle(
                        fontFamily: "Nunito",
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text_600,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  "No active streak",
                  style: TextStyle(
                    fontFamily: "Nunito",
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text_400,
                  ),
                ),
              ],
              Icon(
                Icons.local_fire_department,
                color: hasActiveStreak ? AppColors.primary_500 : AppColors.text_300,
                size: 22,
              ),
            ],
          ),

          const SizedBox(height: 6),

          // [SECTION] Month Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _changeMonth(-1),
                child: const Icon(Icons.chevron_left, size: 18),
              ),
              Text(
                "${_monthName(_currentMonth.month)} ${_currentMonth.year}",
                style: const TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text_700,
                ),
              ),
              GestureDetector(
                onTap: () => _changeMonth(1),
                child: const Icon(Icons.chevron_right, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // [SECTION] Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + (firstWeekday - 1),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 0,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) return const SizedBox();

              final day = index - (firstWeekday - 2);

              final streakDay = isStreakDay(day);
              final usedDay   = isUsedDay(day);

              // Show today's ring ONLY when there is no active streak.
              // If streak >= 3, today is already inside the bold band.
              final isToday =
                  isCurrentMonth &&
                  today.day == day &&
                  !hasActiveStreak;

              return Padding(
                padding: streakDay
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: streakDay
                        ? AppColors.primary_500
                        : usedDay
                            ? AppColors.primary_100
                            : AppColors.secondary_50,
                    borderRadius: streakDay
                        ? streakBorderRadius(day)
                        : BorderRadius.circular(5),
                    border: isToday
                        ? Border.all(color: AppColors.primary_500, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontFamily: "Nunito",
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: streakDay ? Colors.white : AppColors.text_600,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}