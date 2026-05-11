// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

class QuizDetailSheet extends StatelessWidget {
  // [PROPS]
  final Map<String, dynamic> quiz;
  final VoidCallback onPlay;
  final Function(Map<String, dynamic>) onEdit;
  final VoidCallback onDelete;

  const QuizDetailSheet({
    super.key,
    required this.quiz,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // [DATA] Extract quiz fields
    final title       = quiz['title']         as String? ?? 'Untitled Quiz';
    final description = quiz['description']   as String? ?? '';
    final count       = quiz['questionCount'] as int?    ?? 0;
    final mode        = quiz['mode']          as String? ?? 'Multiple Choice';
    final timeLimit   = quiz['timeLimitSecs'] as int?;
    final createdAt   = quiz['createdAt']     as String? ?? '';

    // [FORMAT] Parse ISO date into readable MM/DD/YYYY
    String dateLabel = '';
    if (createdAt.isNotEmpty) {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) dateLabel = '${dt.month}/${dt.day}/${dt.year}';
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.secondary_50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // [HANDLE] Drag indicator pill
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.text_200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // [TEXT] Quiz title
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Baloo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text_700,
              ),
            ),
          ),

          // [TEXT] Description (if present)
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  color: AppColors.text_500,
                ),
              ),
            )
          else
            const SizedBox(height: 16),

          // [DETAILS] Metadata info rows (non-tappable)
          _buildInfoRow(
            Icons.quiz_outlined,
            'Questions',
            '$count question${count == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.category_outlined, 'Mode', mode),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.timer_outlined,
            'Time Limit',
            timeLimit != null ? '${timeLimit ~/ 60} min' : 'No limit',
          ),
          if (dateLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoRow(Icons.calendar_today_outlined, 'Created', dateLabel),
          ],

          const SizedBox(height: 16),

          // [ACTION] Start Quiz — primary (filled)
          _buildActionRow(
            icon: Icons.play_arrow_rounded,
            label: 'Start Quiz',
            isPrimary: true,
            onTap: onPlay,
          ),
          const SizedBox(height: 10),

          // [ACTION] Edit Quiz
          _buildActionRow(
            icon: Icons.edit_outlined,
            label: 'Edit Quiz',
            onTap: () => onEdit(quiz),
          ),
          const SizedBox(height: 10),

          // [ACTION] Delete Quiz — danger
          _buildActionRow(
            icon: Icons.delete_outline,
            label: 'Delete Quiz',
            isDanger: true,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }

  // [WIDGET] Non-tappable metadata row — plain row, no card border
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.text_500),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text_400,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text_700,
            ),
          ),
        ],
      ),
    );
  }

  // [WIDGET] Tappable action row — identical structure to Sort option rows
  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDanger = false,
  }) {
    final bgColor = isPrimary
        ? AppColors.primary_600
        : isDanger
            ? Colors.transparent
            : Colors.transparent;
    final borderColor = isPrimary
        ? AppColors.primary_600
        : isDanger
            ? Colors.transparent
            : Colors.transparent;
    final iconColor = isPrimary
        ? Colors.white
        : isDanger
            ? Colors.redAccent
            : AppColors.text_500;
    final textColor = isPrimary
        ? Colors.white
        : isDanger
            ? Colors.redAccent
            : AppColors.text_700;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isPrimary ? 16 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}