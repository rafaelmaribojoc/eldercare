import 'package:flutter/material.dart';

/// A simple dialog to collect manual text input (e.g., for external signatories)
class ManualTextDialog extends StatefulWidget {
  final String title;
  final String label;
  final String initialValue;

  const ManualTextDialog({
    super.key,
    required this.title,
    required this.label,
    this.initialValue = '',
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String label,
    String initialValue = '',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => ManualTextDialog(
        title: title,
        label: label,
        initialValue: initialValue,
      ),
    );
  }

  @override
  State<ManualTextDialog> createState() => _ManualTextDialogState();
}

class _ManualTextDialogState extends State<ManualTextDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.words,
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
