// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [WIDGET] Streak Calendar
class StreakCalendar extends StatefulWidget {
  final int streak;

  const StreakCalendar({
    super.key,
    required this.streak,
  });

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  // [STATE] Calendar
  DateTime _currentMonth = DateTime.now();

  // [HELPER] Get days in month
  int _daysInMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  // [HELPER] Get first weekday of month (1 = Mon, 7 = Sun)
  int _firstWeekday(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday;
  }

  // [ACTION] Change month
  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + offset,
      );
    });
  }

  // [HELPER] Month name
  String _monthName(int month) {
    const months = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _daysInMonth(_currentMonth);
    final firstWeekday = _firstWeekday(_currentMonth);
    final today = DateTime.now();

    // [HELPER] Example streak logic (replace later with DB)
    bool isStreakDay(int day) {
      return day <= widget.streak;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary_50,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // [SECTION] Top (Streak Info)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${widget.streak}',
                    style: const TextStyle(
                      fontFamily: "Baloo",
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary_600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "day streak!",
                    style: TextStyle(
                      fontFamily: "Nunito",
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text_600,
                    ),
                  ),
                ],
              ),

              const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 28,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // [SECTION] Month Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _changeMonth(-1),
                child: const Icon(Icons.chevron_left),
              ),

              Text(
                "${_monthName(_currentMonth.month)} ${_currentMonth.year}",
                style: const TextStyle(
                  fontFamily: "Baloo",
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text_700,
                ),
              ),

              GestureDetector(
                onTap: () => _changeMonth(1),
                child: const Icon(Icons.chevron_right),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // [SECTION] Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + (firstWeekday - 1),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox();
              }

              final day = index - (firstWeekday - 2);

              final isToday =
                  today.year == _currentMonth.year &&
                  today.month == _currentMonth.month &&
                  today.day == day;

              final streakDay = isStreakDay(day);

              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: streakDay
                      ? AppColors.primary_500
                      : AppColors.secondary_100,
                  borderRadius: BorderRadius.circular(6),
                  border: isToday
                      ? Border.all(
                          color: AppColors.primary_600,
                          width: 2,
                        )
                      : null,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: streakDay
                        ? Colors.white
                        : AppColors.text_600,
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