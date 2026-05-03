import 'package:flutter/material.dart';

import 'package:soro/main.dart';
import 'package:soro/database/database_helper.dart';

class CardsEdit extends StatefulWidget {
  final Map<String, dynamic> deck;

  const CardsEdit({super.key, required this.deck});

  @override
  State<CardsEdit> createState() => _CardsEditState();
}

class _CardsEditState extends State<CardsEdit> {
  final TextEditingController titleController = TextEditingController();
  List<Map<String, dynamic>> cardItems = [];

  @override
  void initState() {
    super.initState();
    titleController.text = widget.deck['title'] as String? ?? '';
    final cards = (widget.deck['cards'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (cards.isEmpty) {
      _addCardItem();
    } else {
      for (final card in cards) {
        _addCardItem(
          frontText: card['term'] as String? ?? '',
          backText: card['definition'] as String? ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    for (final card in cardItems) {
      (card['frontController'] as TextEditingController).dispose();
      (card['backController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addCardItem({String frontText = '', String backText = ''}) {
    setState(() {
      cardItems.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'frontController': TextEditingController(text: frontText),
        'backController': TextEditingController(text: backText),
      });
    });
  }

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

  Future<void> _saveDeck() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      _showError("Please enter a deck title.");
      return;
    }

    final cards = <Map<String, dynamic>>[];
    for (final item in cardItems) {
      final front = (item['frontController'] as TextEditingController).text.trim();
      final back = (item['backController'] as TextEditingController).text.trim();
      if (front.isEmpty || back.isEmpty) {
        _showError("All cards must have both a front and back. Please fill in all fields.");
        return;
      }
      cards.add({'term': front, 'definition': back});
    }

    if (cards.isEmpty) {
      _showError("Please add at least one card.");
      return;
    }

    final updatedDeck = {
      'id': widget.deck['id'] as String,
      'title': title,
      'description': widget.deck['description'] as String? ?? '',
      'createdAt': widget.deck['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      'cards': cards,
    };

    await DatabaseHelper().updateFlashcardDeck(widget.deck['id'] as String, updatedDeck);

    if (!mounted) return;
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Card",
          style: TextStyle(
            fontFamily: 'Baloo',
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        backgroundColor: AppColors.primary_600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
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

          // [BUTTON] Add Item
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: AppColors.secondary_50,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _addCardItem,
              icon: const Icon(Icons.add, size: 24),
              label: const Text(
                "Add Item",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary_600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ),

          // [BUTTON] Save Changes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: ElevatedButton(
              onPressed: _saveDeck,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary_600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Save Changes",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}