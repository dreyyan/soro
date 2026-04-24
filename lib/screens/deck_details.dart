// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

class DeckDetails extends StatefulWidget {
  // [PROPS]
  final Map<String, dynamic> deck;
  final VoidCallback onUpdated; // Callback to refresh the deck list in Cards

  const DeckDetails({super.key, required this.deck, required this.onUpdated});

  @override
  State<DeckDetails> createState() => _DeckDetailsState();
}

class _DeckDetailsState extends State<DeckDetails> {
  // [STATES]
  late Map<String, dynamic> _deck;
  bool _showCards = false;

  // [CONTROLLERS]
  final _termCtrl = TextEditingController();
  final _defCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _deck = Map<String, dynamic>.from(widget.deck);
  }

  @override
  void dispose() {
    _termCtrl.dispose();
    _defCtrl.dispose();
    super.dispose();
  }

  // [GET] Deep copy of the current card list
  List<Map<String, dynamic>> get _cards => List<Map<String, dynamic>>.from(
        (_deck['cards'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );

  // [SAVE] Persist deck changes to Hive and notify parent
  Future<void> _save() async {
    await DatabaseHelper().updateFlashcardDeck(_deck['id'] as String, _deck);
    widget.onUpdated();
  }

  // [ADD] Append a new card to the deck
  void _addCard() {
    final term = _termCtrl.text.trim();
    final def  = _defCtrl.text.trim();
    if (term.isEmpty || def.isEmpty) return;

    final cards = _cards;
    cards.add({'term': term, 'definition': def});

    setState(() {
      _deck = {..._deck, 'cards': cards};
      _termCtrl.clear();
      _defCtrl.clear();
    });

    _save();
  }

  // [DELETE] Remove a card by index
  void _deleteCard(int index) {
    final cards = _cards;
    cards.removeAt(index);
    setState(() => _deck = {..._deck, 'cards': cards});
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;

    return Scaffold(
      backgroundColor: AppColors.secondary_200,
      appBar: AppBar(
        title: Text(
          _deck['title'] as String,
          style: const TextStyle(
            fontFamily: 'Baloo',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.primary_600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [],
      ),
      body: Column(
        children: [
          // [COMPONENT] Add card form
          _buildAddCardForm(),

          // [LABEL] Card count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text(
                  '${cards.length} card${cards.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text_400,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _showCards ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showCards = !_showCards),
                  tooltip: _showCards ? 'Hide cards' : 'Show cards',
                  padding: EdgeInsets.zero,
                  color: AppColors.text_400,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // [LIST] Cards or empty state
          Expanded(
            child: cards.isEmpty
                ? const Center(
                    child: Text(
                      'No cards yet - add one above!',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: AppColors.text_300,
                      ),
                    ),
                  )
                : _showCards
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: cards.length,
                        itemBuilder: (ctx, i) => _buildCardTile(cards[i], i),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility_off,
                              size: 48,
                              color: AppColors.text_300,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Cards are hidden',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                color: AppColors.text_400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap the eye icon to show them',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                color: AppColors.text_300,
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // [WIDGET] Inline form to add a new term/definition pair
  Widget _buildAddCardForm() {
    return Material(
      color: AppColors.secondary_50,
      elevation: 4,
      shadowColor: AppColors.secondary_500.withValues(alpha: 0.3),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // [LABEL] Section title
            const Text(
              'Add a card',
              style: TextStyle(
                fontFamily: 'Baloo',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text_700,
              ),
            ),

            const SizedBox(height: 12),

            // [INPUT] Term (full width)
            TextField(
              controller: _termCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Term',
                filled: true,
                fillColor: AppColors.secondary_100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // [INPUT] Definition (full width)
            TextField(
              controller: _defCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Definition',
                filled: true,
                fillColor: AppColors.secondary_100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // [BUTTON] Add card (full width)
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _addCard,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Card',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary_600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [WIDGET] A single card row in the list
  Widget _buildCardTile(Map<String, dynamic> card, int index) {
    return Card(
      color: AppColors.secondary_50,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // [TEXT] Term
        title: Text(
          card['term'] as String,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            color: AppColors.text_800,
          ),
        ),

        // [TEXT] Definition
        subtitle: Text(
          card['definition'] as String,
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: AppColors.text_500,
          ),
        ),

        // [BUTTON] Delete card
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.primary_600),
          onPressed: () => _deleteCard(index),
        ),
      ),
    );
  }
}