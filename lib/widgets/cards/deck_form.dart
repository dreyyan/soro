// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

class DeckForm extends StatefulWidget {
  // [PROPS]
  final VoidCallback onCreated; // Callback to refresh the deck list after creation

  const DeckForm({super.key, required this.onCreated});

  @override
  State<DeckForm> createState() => _DeckFormState();
}

class _DeckFormState extends State<DeckForm> {
  // [CONTROLLERS]
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // [SUBMIT] Validate, save deck to Hive, then close dialog
  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc  = _descCtrl.text.trim();
    if (title.isEmpty) return;

    final deck = {
      'id':          DateTime.now().millisecondsSinceEpoch.toString(),
      'title':       title,
      'description': desc,
      'createdAt':   DateTime.now().toIso8601String(),
      'cards':       <Map<String, dynamic>>[],
    };

    await DatabaseHelper().addFlashcardDeck(deck);
    widget.onCreated();
    if (mounted) Navigator.pop(context); // [CLOSE] Dismiss the dialog
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'New Card',
        style: TextStyle(fontFamily: 'Baloo', fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // [INPUT] Card title
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Card Title',
              hintText:  'e.g. Biology Chapter 3',
            ),
          ),

          const SizedBox(height: 12),

          // [INPUT] Optional description
          TextField(
            controller: _descCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
          ),
        ],
      ),
      actions: [
        // [BUTTON] Cancel
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        // [BUTTON] Create deck
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary_600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}