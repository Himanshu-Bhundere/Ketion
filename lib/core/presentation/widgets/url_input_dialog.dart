import 'package:flutter/material.dart';

class UrlInputDialog extends StatefulWidget {
  final String title;
  final String hintText;

  const UrlInputDialog({
    super.key,
    this.title = 'Enter URL',
    this.hintText = 'https://example.com',
  });

  static Future<String?> show(
    BuildContext context, {
    String title = 'Enter URL',
    String hintText = 'https://example.com',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => UrlInputDialog(
        title: title,
        hintText: hintText,
      ),
    );
  }

  @override
  State<UrlInputDialog> createState() => _UrlInputDialogState();
}

class _UrlInputDialogState extends State<UrlInputDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.hasScheme && uri.host.isNotEmpty;
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          keyboardType: TextInputType.url,
          onFieldSubmitted: (_) => _submit(),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'URL is required';
            }
            if (!_isValidUrl(value.trim())) {
              return 'Please enter a valid URL (e.g. https://...)';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
