// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Screens
import 'package:soro/screens/deck_details.dart';

class DeckCard extends StatelessWidget {
  // [PROPS]
  final Map<String, dynamic> deck;
  final VoidCallback onDeleted;
  final VoidCallback onUpdated;

  const DeckCard({
    super.key,
    required this.deck,
    required this.onDeleted,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // [DATA] Extract deck fields
    final cardCount   = (deck['cards'] as List?)?.length ?? 0;
    final title       = deck['title']       as String;
    final description = deck['description'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
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

              // [TEXT] Title, description, card count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [TEXT] Deck title
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

                    const SizedBox(height: 4),

                    // [TEXT] Card count label
                    Text(
                      '$cardCount card${cardCount == 1 ? '' : 's'}',
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

              // [BUTTON] Delete deck
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.text_300),
                onPressed: onDeleted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}