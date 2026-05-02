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
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.text_600,
      ),
    );
  }

  // [WIDGET] Text input field for front/back
  Widget _buildCardField(TextEditingController controller, String placeholder) {
    return TextField(
      controller: controller,
      maxLines: null,
      minLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.text_200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.text_200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary_600, width: 2),
        ),
        hintText: placeholder,
        hintStyle: TextStyle(color: AppColors.text_300),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 14,
        color: AppColors.text_700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary_50,
      appBar: AppBar(
        title: const Text(
          "Create Card",
          style: TextStyle(fontFamily: 'Baloo', fontWeight: FontWeight.w700),
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
                  // [INPUT] Deck title
                  _buildLabel("Card Title"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "e.g. Spanish Vocab Unit 3",
                      hintStyle: TextStyle(color: AppColors.text_400),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.text_200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.text_200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary_600, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // [LABEL] Items section
                  Text(
                    "Items",
                    style: const TextStyle(
                      fontFamily: 'Baloo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text_800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // [CARDS] List of card items
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cardItems.length,
                    itemBuilder: (ctx, i) {
                      final card = cardItems[i];
                      final frontCtrl = card['frontController'] as TextEditingController;
                      final backCtrl = card['backController'] as TextEditingController;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.text_100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // [HEADER] Card number with delete button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${(i + 1).toString().padLeft(2, '0')}",
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text_400,
                                    ),
                                  ),
                                  if (cardItems.length > 1)
                                    GestureDetector(
                                      onTap: () => _removeCardItem(i),
                                      child: Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.text_100),

                            // [FRONT] Front side
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Front"),
                                  const SizedBox(height: 6),
                                  _buildCardField(frontCtrl, "Type something..."),
                                ],
                              ),
                            ),

                            const Divider(height: 1, color: AppColors.text_100),

                            // [BACK] Back side
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Back"),
                                  const SizedBox(height: 6),
                                  _buildCardField(backCtrl, "Type something..."),
                                ],
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

          // [BUTTONS] Add item and Save card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _addCardItem,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Item"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary_600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _createDeck,
                  icon: const Icon(Icons.check),
                  label: const Text("Save Card"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary_600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
