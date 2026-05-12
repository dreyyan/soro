// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Screens
import 'package:soro/screens/cards/cards_settings.dart';
import 'package:soro/screens/cards/cards_edit.dart';
import 'package:soro/screens/cards/cards_start.dart';

// [IMPORT] Widgets
import 'package:soro/widgets/cards/deck_card.dart';
import 'package:soro/widgets/cards/deck_form.dart';
import 'package:soro/widgets/cards/deck_detail_sheet.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

class Cards extends StatefulWidget {
  const Cards({super.key});

  @override
  State<Cards> createState() => _CardsState();
}

class _CardsState extends State<Cards> {
  // [STATES]
  List<Map<String, dynamic>> _decks = [];
  bool _isLoading = true;
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  // [LOAD] Fetch all decks for the logged-in user
  Future<void> _loadDecks() async {
    final decks = await DatabaseHelper().getFlashcardDecks();
    if (!mounted) return;
    setState(() {
      _decks = decks;
      _isLoading = false;
    });
  }

  // [SORT] Return a sorted copy of _decks based on _sortBy
  List<Map<String, dynamic>> get _sortedDecks {
    final copy = List<Map<String, dynamic>>.from(_decks);
    switch (_sortBy) {
      case 'oldest':
        copy.sort((a, b) =>
            (a['createdAt'] as String).compareTo(b['createdAt'] as String));
        break;
      case 'alpha':
        copy.sort((a, b) =>
            (a['title'] as String).compareTo(b['title'] as String));
        break;
      case 'newest':
      default:
        copy.sort((a, b) =>
            (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    }
    return copy;
  }

  // [DELETE] Show confirmation dialog then remove deck
  Future<void> _deleteDeck(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Deck'),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: 0.5,
              color: AppColors.text_700,
            ).copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseHelper().deleteFlashcardDeck(id);
    await _loadDecks();
  }

  // [NAVIGATE] Go to CardsSettings to create a new deck
  Future<void> _createDeck() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CardsSettings()),
    );
    await _loadDecks();
  }

  // [DIALOG] Show DeckDetailSheet as modal bottom sheet
  void _showDeckDetailSheet(Map<String, dynamic> deck) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      enableDrag: true,
      builder: (_) => DeckDetailSheet(
        deck: deck,
        onPlay: () {
          Navigator.pop(context);
          final cards = (deck['cards'] as List? ?? []).cast<Map<String, dynamic>>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CardsPlay(),
              settings: RouteSettings(
                arguments: {
                  'title': deck['title'] as String? ?? 'Flashcard Deck',
                  'cards': cards,
                  'randomizeOrder': deck['randomizeOrder'] as bool? ?? false,
                  'randomizeSides': deck['randomizeSides'] as bool? ?? false,
                },
              ),
            ),
          );
        },
        onEdit: () {
          Navigator.pop(context);
          _showEditDeckDialog(deck);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteDeck(deck['id'] as String, deck['title'] as String);
        },
      ),
    );
  }

  // [DIALOG] Show DeckForm in edit mode
  void _showEditDeckDialog(Map<String, dynamic> deck) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CardsEdit(deck: deck)),
    ).then((_) {
      _loadDecks();
    });
  }

  // [SORT] Show custom sort bottom sheet
  Future<void> _showSortSheet() async {
    final options = [
      _SortOption(value: 'newest', label: 'Newest First', icon: Icons.arrow_downward_rounded),
      _SortOption(value: 'oldest', label: 'Oldest First', icon: Icons.arrow_upward_rounded),
      _SortOption(value: 'alpha',  label: 'A → Z',        icon: Icons.sort_by_alpha_rounded),
      _SortOption(value: 'reverse_alpha',  label: 'Z → A',        icon: Icons.sort_by_alpha_rounded),
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
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
              // Drag handle
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

              // Sheet title
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  'Sort Decks',
                  style: TextStyle(
                    fontFamily: 'Baloo',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text_700,
                  ),
                ),
              ),

              // Options
              ...options.map((opt) {
                final isActive = _sortBy == opt.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: isActive
                        ? AppColors.primary_500
                        : AppColors.secondary_100,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(ctx, opt.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primary_500
                                : AppColors.secondary_300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              opt.icon,
                              size: 20,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.text_500,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              opt.label,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.text_700,
                              ),
                            ),
                            const Spacer(),
                            if (isActive)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );

    if (selected != null) setState(() => _sortBy = selected);
  }

  @override
  Widget build(BuildContext context) {
    final decks = _sortedDecks;

    // Total number of decks created
    final totalDecks = _decks.length;

    return Scaffold(
      backgroundColor: AppColors.secondary_50,
      body: SafeArea(
        child: Column(
          children: [
            // [COMPONENT] Header (Title + Count only)
            _buildHeader(totalDecks),

            // [COMPONENT] Deck List / Empty State
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : decks.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: decks.length,
                          itemBuilder: (ctx, i) => DeckCard(
                            deck: decks[i],
                            showCards: false,
                            onDeleted: () => _deleteDeck(
                              decks[i]['id'] as String,
                              decks[i]['title'] as String,
                            ),
                            onUpdated: _loadDecks,
                            onTap: () => _showDeckDetailSheet(decks[i]),
                          ),
                        ),
            ),

            // [COMPONENT] Action Buttons (Sort + Add Deck)
            _buildActionButtons(_createDeck),
          ],
        ),
      ),
    );
  }

  // [WIDGET] Top Header Row - Title + Card Count only
  Widget _buildHeader(int totalDecks) {
    return Material(
      color: AppColors.secondary_50,
      elevation: 1,
      shadowColor: AppColors.secondary_500.withValues(alpha: 0.4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Baloo',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text_700,
            ),
            children: [
              const TextSpan(text: 'My Cards '),
              TextSpan(
                text: '($totalDecks)',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text_400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [WIDGET] Bottom Action Buttons (Sort + Add Deck)
  Widget _buildActionButtons(VoidCallback onAddDeck) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.secondary_50,
      child: Row(
        children: [
          // [BUTTON] Sort Menu
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showSortSheet,
              icon: const Icon(Icons.sort),
              label: const Text(
                'Sort',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary_100,
                foregroundColor: AppColors.text_700,
                elevation: 1,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.secondary_300),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // [BUTTON] Create Card
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAddDeck,
              icon: const Icon(Icons.add),
              label: const Text(
                'Create Card',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary_500,
                foregroundColor: Colors.white,
                elevation: 1,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [WIDGET] Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style_outlined, size: 64, color: AppColors.text_200),
          const SizedBox(height: 12),
          const Text(
            'No cards yet',
            style: TextStyle(
              fontFamily: 'Baloo',
              fontSize: 18,
              color: AppColors.text_400,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "Create Card" to get started',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: AppColors.text_300,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// [MODEL] Sort option data
class _SortOption {
  final String value;
  final String label;
  final IconData icon;
  const _SortOption({required this.value, required this.label, required this.icon});
}