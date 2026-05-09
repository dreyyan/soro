// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

class CardsSettings extends StatefulWidget {
  const CardsSettings({super.key});

  @override
  State<CardsSettings> createState() => _CardsSettingsState();
}

class _CardsSettingsState extends State<CardsSettings> {
  // [STATES] Deck settings
  List<Map<String, dynamic>> cardItems = [];

  // [STATES] Randomization options
  bool _randomizeOrder = false;
  bool _randomizeSides = false;

  // [CONTROLLERS] Form inputs
  final TextEditingController titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // [INIT] Start with one empty card item
    _addCardItem();
  }

  @override
  void dispose() {
    titleController.dispose();
    for (var card in cardItems) {
      (card['frontController'] as TextEditingController).dispose();
      (card['backController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  // [ADD] Create a new empty card item
  void _addCardItem() {
    setState(() {
      cardItems.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'frontController': TextEditingController(),
        'backController': TextEditingController(),
      });
    });
  }

  // [REMOVE] Delete a card item by index
  void _removeCardItem(int index) {
    final card = cardItems[index];
    (card['frontController'] as TextEditingController).dispose();
    (card['backController'] as TextEditingController).dispose();
    setState(() => cardItems.removeAt(index));
  }

  // [REORDER] Drag-to-reorder handler
  void _reorderCards(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = cardItems.removeAt(oldIndex);
      cardItems.insert(newIndex, item);
    });
  }

  // [ERROR] Show a simple error dialog
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // [CREATE] Validate, save deck to DB, then pop back to Cards screen
  Future<void> _createDeck() async {
    final title = titleController.text.trim();

    // [VALIDATION] Title required
    if (title.isEmpty) {
      _showError("Please enter a deck title.");
      return;
    }

    // [VALIDATION] Collect all card data
    final cards = <Map<String, dynamic>>[];
    for (var item in cardItems) {
      final front = (item['frontController'] as TextEditingController).text.trim();
      final back = (item['backController'] as TextEditingController).text.trim();

      if (front.isEmpty || back.isEmpty) {
        _showError("All cards must have both a front and back. Please fill in all fields.");
        return;
      }

      cards.add({
        'term': front,
        'definition': back,
      });
    }

    if (cards.isEmpty) {
      _showError("Please add at least one card.");
      return;
    }

    // [SAVE] Persist deck to the user's saved decks list
    await DatabaseHelper().addFlashcardDeck({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'description': '',
      'createdAt': DateTime.now().toIso8601String(),
      'randomizeOrder': _randomizeOrder,
      'randomizeSides': _randomizeSides,
      'cards': cards,
    });

    if (!mounted) return;

    // [NAVIGATE] Return to Cards screen so the new deck appears in the list
    Navigator.pop(context);
  }

  // [WIDGET] Section label text
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.text_700,
      ),
    );
  }

  // [WIDGET] Text input field for front/back
  Widget _buildCardField(TextEditingController controller, String placeholder) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary_300),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: AppColors.text_400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 15,
          color: AppColors.text_700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary_50,
      body: SafeArea(
        child: Column(
        children: [
            _buildHeader(),

            // [CONTENT] Scrollable card items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // [INPUT] Deck title label
                  Text(
                    "Card Title",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text_700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // [INPUT] Deck title field
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondary_100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text_700,
                      ),
                      decoration: InputDecoration(
                        hintText: "Type card title...",
                        hintStyle: TextStyle(color: AppColors.text_400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // [SECTION] Randomization options
                  Text(
                    "Options",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text_700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondary_100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.secondary_300),
                    ),
                    child: Column(
                      children: [
                        // [TOGGLE] Randomize card order
                        SwitchListTile(
                          value: _randomizeOrder,
                          onChanged: (val) => setState(() => _randomizeOrder = val),
                          activeColor: AppColors.primary_600,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          title: const Text(
                            "Randomize Order",
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text_700,
                            ),
                          ),
                          subtitle: const Text(
                            "Shuffle cards each time you play",
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: AppColors.text_400,
                            ),
                          ),
                        ),

                        Divider(height: 1, color: AppColors.secondary_300),

                        // [TOGGLE] Randomize front/back sides
                        SwitchListTile(
                          value: _randomizeSides,
                          onChanged: (val) => setState(() => _randomizeSides = val),
                          activeColor: AppColors.primary_600,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          title: const Text(
                            "Randomize Sides",
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text_700,
                            ),
                          ),
                          subtitle: const Text(
                            "Randomly flip front and back",
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: AppColors.text_400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // [LABEL] Items section
                  Text(
                    "Items",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text_700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // [EMPTY STATE] Shown when no cards added yet
                  if (cardItems.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppColors.secondary_100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.secondary_300),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.style_outlined, size: 48, color: AppColors.text_200),
                          const SizedBox(height: 12),
                          Text(
                            'No items yet',
                            style: TextStyle(
                              fontFamily: 'Baloo',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text_300,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + Add Item to create one',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              color: AppColors.text_300,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  // [CARDS] Reorderable list of card items
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cardItems.length,
                    onReorder: _reorderCards,
                    itemBuilder: (ctx, i) {
                      final card = cardItems[i];
                      final frontCtrl = card['frontController'] as TextEditingController;
                      final backCtrl = card['backController'] as TextEditingController;

                      return Container(
                        key: ValueKey(card['id']),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.secondary_100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.secondary_300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // [HEADER] Card number + drag handle
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Text(
                                    "${(i + 1).toString().padLeft(2, '0')}",
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text_700,
                                    ),
                                  ),
                                  const Spacer(),
                                  ReorderableDragStartListener(
                                    index: i,
                                    child: Icon(
                                      Icons.drag_indicator,
                                      color: AppColors.text_400,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // [FRONT] Front side input
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Front"),
                                  const SizedBox(height: 6),
                                  _buildCardField(frontCtrl, "Type something..."),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // [BACK] Back side input
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Back"),
                                  const SizedBox(height: 6),
                                  _buildCardField(backCtrl, "Type something..."),
                                ],
                              ),
                            ),

                            // [DELETE] Delete button
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _removeCardItem(i),
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text(
                                  "Delete",
                                  style: TextStyle(fontFamily: 'Nunito', fontSize: 15),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // [FOOTER] Action Buttons — Add Item + Save Card
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.secondary_50,
                border: Border(
                  top: BorderSide(
                    color: AppColors.secondary_200,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // [BUTTON] Add Item
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addCardItem,
                      icon: const Icon(Icons.playlist_add_rounded),
                      label: const Text(
                        'Add Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.text_700,
                        elevation: 0,
                        side: BorderSide(
                          color: AppColors.secondary_300,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // [BUTTON] Save Card
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _createDeck,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text(
                        'Save Card',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary_600,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // [WIDGET] Header — matches QuizSettings layout
  Widget _buildHeader() {
    return Material(
      color: AppColors.secondary_50,
      elevation: 3,
      shadowColor: AppColors.secondary_500.withValues(alpha: 0.4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.primary_600),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              'Create Card',
              style: TextStyle(
                fontFamily: 'Baloo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary_600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}