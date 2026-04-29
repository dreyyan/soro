// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

class DeckForm extends StatefulWidget {
  // [PROPS]
  final VoidCallback onCreated;
  final Map<String, dynamic>? deck; // ← ADD THIS (optional for edit mode)

  const DeckForm({
    super.key,
    required this.onCreated,
    this.deck, // ← ADD THIS
  });

  @override
  State<DeckForm> createState() => _DeckFormState();
}

class _DeckFormState extends State<DeckForm> {
  // [CONTROLLERS]
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl; // ← ADD DESCRIPTION

  @override
  void initState() {
    super.initState();
    
    // [INIT] Pre-fill controllers if editing existing deck
    _titleCtrl = TextEditingController(
      text: widget.deck?['title'] as String? ?? '',
    );
    _descriptionCtrl = TextEditingController(
      text: widget.deck?['description'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // [SUBMIT] Validate, save deck to database, then close dialog
  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    if (widget.deck != null) {
      // [UPDATE] Existing deck
      await DatabaseHelper().updateFlashcardDeck(
        widget.deck!['id'] as String,
        {
          'title': title,
          'description': description,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } else {
      // [CREATE] New deck
      final deck = {
        'id':          DateTime.now().millisecondsSinceEpoch.toString(),
        'title':       title,
        'description': description,
        'createdAt':   DateTime.now().toIso8601String(),
        'cards':       <Map<String, dynamic>>[],
      };
      await DatabaseHelper().addFlashcardDeck(deck);
    }

    widget.onCreated(); // Refresh parent list
    if (mounted) Navigator.pop(context); // Close dialog
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.deck != null;
    
    return AlertDialog(
      title: Text(
        isEditing ? 'Edit Deck' : 'New Deck', // ← FIX: Was "New Card"
        style: const TextStyle(
          fontFamily: 'Baloo',
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // [INPUT] Deck title
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Deck Title', // ← FIX: Was "Card Title"
              hintText: isEditing ? 'Enter new title' : 'e.g. Biology Chapter 3',
            ),
          ),
          const SizedBox(height: 12),
          
          // [INPUT] Deck description (NEW)
          TextField(
            controller: _descriptionCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Brief description of this deck',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        // [BUTTON] Cancel
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        // [BUTTON] Save/Create
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary_600,
            foregroundColor: Colors.white,
          ),
          child: Text(isEditing ? 'Save Changes' : 'Create'), // ← Dynamic label
        ),
      ],
    );
  }
}