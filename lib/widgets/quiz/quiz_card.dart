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
    // [DATA]
    final title       = quiz['title']         as String? ?? 'Untitled Quiz';
    final description = quiz['description']   as String? ?? '';
    final count       = quiz['questionCount'] as int?    ?? 0;
    final mode        = quiz['mode']          as String? ?? 'Multiple Choice';

    return Card(
      color: AppColors.secondary_100,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.secondary_300)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // [ICON]
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

              // [TEXT SECTION]
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Baloo',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text_800,
                      ),
                    ),

                    // Description
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

                    const SizedBox(height: 4),

                    // SAME STYLE AS DeckCard count line
                    Text(
                      '$count question${count == 1 ? '' : 's'} • $mode',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary_600,
                      ),
                    ),
                  ],
                ),
              ),

              // [ACTION BUTTON - MATCHES DECK STYLE]
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.primary_600,
                ),
                onPressed: onDeleted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}