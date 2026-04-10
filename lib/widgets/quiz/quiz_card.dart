// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

class QuizCard extends StatelessWidget {
  // [PROPS]
  final Map<String, dynamic> quiz;
  final VoidCallback onTap;
  final VoidCallback onDeleted;

  const QuizCard({
    super.key,
    required this.quiz,
    required this.onTap,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    // [DATA] Extract quiz fields
    final title       = quiz['title']         as String? ?? 'Untitled Quiz';
    final description = quiz['description']   as String? ?? '';
    final count       = quiz['questionCount'] as int?    ?? 0;
    final mode        = quiz['mode']          as String? ?? 'Multiple Choice';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // [ICON] Quiz icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary_100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.quiz, color: AppColors.primary_600),
              ),

              const SizedBox(width: 14),

              // [TEXT] Title, description, info chips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [TEXT] Quiz title
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Baloo',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text_800,
                      ),
                    ),

                    // [TEXT] Description (if present)
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: AppColors.text_400,
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    // [ROW] Info chips
                    Row(
                      children: [
                        _buildChip(
                          '$count Q',
                          AppColors.primary_100,
                          AppColors.primary_600,
                        ),
                        const SizedBox(width: 6),
                        _buildChip(
                          mode,
                          AppColors.secondary_200,
                          AppColors.text_600,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // [ICON] Tap hint chevron
              const Icon(Icons.chevron_right, color: AppColors.text_300),
            ],
          ),
        ),
      ),
    );
  }

  // [WIDGET] Small pill-shaped info label
  Widget _buildChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}