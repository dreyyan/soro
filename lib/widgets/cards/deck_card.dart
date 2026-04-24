// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Screens
import 'package:soro/screens/deck_details.dart';

class DeckCard extends StatelessWidget {
  // Attributes
  final Map<String, dynamic> deck;
  final bool showCards; // Toggle to show/hide individual cards
  final VoidCallback onDeleted;
  final VoidCallback onUpdated;

  // Constructor
  const DeckCard({
    super.key,
    required this.deck,
    required this.showCards,
    required this.onDeleted,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // [STATES] Deck Fields
    final cardCount   = (deck['cards'] as List?)?.length ?? 0;
    final title       = deck['title']       as String;

    return Card(
      color: AppColors.secondary_50,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeckDetails(deck: deck, onUpdated: onUpdated),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // [ICON] Deck icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary_100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.style, color: AppColors.primary_600),
              ),

              const SizedBox(width: 14),

              // [TEXT] Title, Description, and Card Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [TEXT] Deck Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Baloo',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text_800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // [TEXT] Card Count Label
                    Text(
                      '$cardCount card${cardCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary_600,
                      ),
                    ),

                    // [LIST] Show individual cards if toggle is enabled
                    if (showCards && cardCount > 0) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ...((deck['cards'] as List?)?.asMap().entries.map((entry) {
                        final index = entry.key;
                        final card = entry.value as Map<String, dynamic>;
                        final question = card['question'] as String? ?? '';
                        final answer = card['answer'] as String? ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.text_50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.text_100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary_100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Q${index + 1}',
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary_700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        question,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text_700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  answer,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    color: AppColors.text_500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }) ?? []),
                    ],
                  ],
                ),
              ),

              // [BUTTON] Delete Deck
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.primary_600),
                onPressed: onDeleted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}