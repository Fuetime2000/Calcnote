import 'package:flutter/material.dart';

class PdfUploadOptionsDialog extends StatefulWidget {
  final bool isNativelyEncrypted;
  
  const PdfUploadOptionsDialog({
    super.key,
    this.isNativelyEncrypted = false,
  });

  @override
  State<PdfUploadOptionsDialog> createState() => _PdfUploadOptionsDialogState();
}

class _PdfUploadOptionsDialogState extends State<PdfUploadOptionsDialog> {
  bool _compress = true;
  bool _encrypt = false;
  final TextEditingController _passwordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // If PDF is natively encrypted, enable encrypt option by default
    if (widget.isNativelyEncrypted) {
      _encrypt = true;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.isNativelyEncrypted
          ? Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Expanded(child: Text('Password-Protected PDF')),
              ],
            )
          : const Text('PDF Upload Options'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isNativelyEncrypted)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'This PDF is password-protected. Please enter the password to upload it.',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          SwitchListTile(
            title: const Text('Compress PDF'),
            subtitle: const Text('Reduce file size'),
            value: _compress,
            onChanged: (value) {
              setState(() => _compress = value);
            },
          ),
          if (!widget.isNativelyEncrypted)
            SwitchListTile(
              title: const Text('Encrypt PDF'),
              subtitle: const Text('Protect with password'),
              value: _encrypt,
              onChanged: (value) {
                setState(() => _encrypt = value);
              },
            ),
          if (_encrypt)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: widget.isNativelyEncrypted ? 'PDF Password *' : 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  helperText: widget.isNativelyEncrypted ? 'Required to open this PDF' : null,
                ),
                obscureText: true,
                autofocus: widget.isNativelyEncrypted,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'compress': _compress,
              'encrypt': _encrypt,
              'password': _encrypt ? _passwordController.text : null,
            });
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
