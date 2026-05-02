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
    final gameMode    = quiz['gameMode']      as String? ?? 'Classic';
    final timeLimit   = quiz['timeLimitSecs'] as int?;
    final createdAt   = quiz['createdAt']     as String? ?? '';

    // [FORMAT] Parse ISO date into readable MM/DD/YYYY
    String dateLabel = '';
    if (createdAt.isNotEmpty) {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) dateLabel = '${dt.month}/${dt.day}/${dt.year}';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.secondary_50,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // [HANDLE] Drag indicator pill
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.text_200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // [CONTENT] Scrollable body
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // [TEXT] Quiz title
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Baloo',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text_800,
                    ),
                  ),

                  // [TEXT] Description (if present)
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: AppColors.text_500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // [DETAILS] Quiz metadata rows
                  _buildDetailRow(
                    Icons.quiz_outlined,
                    'Questions',
                    '$count question${count == 1 ? '' : 's'}',
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.category_outlined, 'Mode', mode),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.sports_esports_outlined, 'Game Mode', gameMode),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    Icons.timer_outlined,
                    'Time Limit',
                    timeLimit != null ? '${timeLimit ~/ 60} min' : 'No limit',
                  ),
                  if (dateLabel.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      Icons.calendar_today_outlined,
                      'Created',
                      dateLabel,
                    ),
                  ],

                  const SizedBox(height: 28),

                  // [BUTTON] Start Quiz — launches quiz immediately
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onPlay,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'Start Quiz',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary_600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // [BUTTON] Edit Quiz — opens QuizSettings with existing data
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => onEdit(quiz),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primary_600,
                      ),
                      label: const Text(
                        'Edit Quiz',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary_600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.primary_600,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // [BUTTON] Delete Quiz — removes quiz from saved list
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Delete Quiz',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [WIDGET] A single icon + label + value metadata row
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary_600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: AppColors.text_400,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text_700,
            ),
          ),
        ),
      ],
    );
  }
}