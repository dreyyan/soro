// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Screens
import 'package:soro/screens/deck_details.dart';

// [IMPORT] Widgets
import 'package:soro/widgets/cards/deck_card.dart';
import 'package:soro/widgets/cards/deck_form.dart';

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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseHelper().deleteFlashcardDeck(id);
    await _loadDecks();
  }

  // [OPEN] Navigate to DeckDetails page
  void _openDeck(Map<String, dynamic> deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeckDetails(deck: deck, onUpdated: _loadDecks),
      ),
    );
  }

  // [DIALOG] Show the DeckForm dialog to create a new deck
  void _showCreateDeckDialog() {
    showDialog(
      context: context,
      builder: (_) => DeckForm(onCreated: _loadDecks),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decks = _sortedDecks;

    // Total individual cards across all decks
    final totalCards = _decks.fold<int>(
      0,
      (sum, d) => sum + ((d['cards'] as List?)?.length ?? 0),
    );

    return Scaffold(
      backgroundColor: AppColors.secondary_100,
      body: SafeArea(
        child: Column(
          children: [
            // [COMPONENT] Header
            _buildHeader(totalCards),

            // [COMPONENT] Deck list / empty state
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
                            onDeleted: () => _deleteDeck(
                              decks[i]['id'] as String,
                              decks[i]['title'] as String,
                            ),
                            onUpdated: _loadDecks,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // [WIDGET] Top header row - title, count, sort, add button
  Widget _buildHeader(int totalCards) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // [TEXT] Title + card count
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Baloo',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text_800,
                ),
                children: [
                  const TextSpan(text: 'My Flashcards '),
                  TextSpan(
                    text: '($totalCards)',
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

          // [BUTTON] Sort menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: AppColors.text_500),
            tooltip: 'Sort by',
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'newest', child: Text('Newest first')),
              PopupMenuItem(value: 'oldest', child: Text('Oldest first')),
              PopupMenuItem(value: 'alpha',  child: Text('A → Z')),
            ],
          ),

          // [BUTTON] Create new deck
          IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: AppColors.primary_600,
              size: 28,
            ),
            tooltip: 'New Deck',
            onPressed: _showCreateDeckDialog,
          ),
        ],
      ),
    );
  }

  // [WIDGET] Shown when no decks exist yet
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style_outlined, size: 64, color: AppColors.text_200),
          const SizedBox(height: 12),
          const Text(
            'No decks yet',
            style: TextStyle(
              fontFamily: 'Baloo',
              fontSize: 18,
              color: AppColors.text_400,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to create your first flashcard deck',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: AppColors.text_300,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showCreateDeckDialog,
            icon:  const Icon(Icons.add),
            label: const Text('Create Deck'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary_600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}