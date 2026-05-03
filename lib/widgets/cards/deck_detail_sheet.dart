// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

class DeckDetailSheet extends StatelessWidget {
  // [PROPS]
  final Map<String, dynamic> deck;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DeckDetailSheet({
    super.key,
    required this.deck,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // [DATA] Extract deck fields — same pattern as QuizDetailSheet
    final title       = deck['title']       as String? ?? 'Untitled Deck';
    final description = deck['description'] as String? ?? '';
    final cardCount   = (deck['cards'] as List?)?.length ?? 0;
    final createdAt   = deck['createdAt']   as String? ?? '';

    // [FORMAT] Parse ISO date into readable MM/DD/YYYY — exact same as QuizDetailSheet
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
            // [HANDLE] Drag indicator pill — identical
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
                  // [TEXT] Deck title — same styling as QuizDetailSheet
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

                  // [DETAILS] Deck metadata rows — same _buildDetailRow helper
                  _buildDetailRow(
                    Icons.quiz_outlined,
                    'Cards',
                    '$cardCount card${cardCount == 1 ? '' : 's'}',
                  ),
                  const SizedBox(height: 10),
                  if (dateLabel.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      Icons.calendar_today_outlined,
                      'Created',
                      dateLabel,
                    ),
                  ],

                  const SizedBox(height: 28),

                  // [BUTTON] Study Cards
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onPlay,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'Study Cards',
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

                  // [BUTTON] Edit Cards — same style as QuizDetailSheet
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onEdit, // ← Just calls the callback. No logic.
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primary_600,
                      ),
                      label: const Text(
                        'Edit Cards',
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

                  // [BUTTON] Delete Cards — same style as QuizDetailSheet
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onDelete, // ← Just calls the callback. No logic.
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Delete Cards',
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

  // [WIDGET] A single icon + label + value metadata row — exact copy from QuizDetailSheet
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