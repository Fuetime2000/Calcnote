import 'package:flutter/material.dart';
import 'package:calcnote/src/features/security/services/app_lock_service.dart';

/// Security settings screen
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isLockEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;
  bool _isPinSet = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lockEnabled = await AppLockService.isLockEnabled();
    final biometricEnabled = await AppLockService.isBiometricEnabled();
    final biometricAvailable = await AppLockService.isBiometricAvailable();
    final pinSet = await AppLockService.isPinSet();

    setState(() {
      _isLockEnabled = lockEnabled;
      _isBiometricEnabled = biometricEnabled;
      _isBiometricAvailable = biometricAvailable;
      _isPinSet = pinSet;
      _isLoading = false;
    });
  }

  Future<void> _toggleLock(bool value) async {
    if (value && !_isPinSet) {
      // Need to set PIN first
      final pinSet = await _showSetPinDialog();
      if (!pinSet) return;
    }

    if (value) {
      await AppLockService.enableLock();
    } else {
      await AppLockService.disableLock();
    }

    setState(() {
      _isLockEnabled = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'App lock enabled' : 'App lock disabled'),
        ),
      );
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_isLockEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable App Lock first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (value) {
      // Show info dialog first
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Biometric'),
          content: const Text(
            'You will be prompted to authenticate with your fingerprint or face. '
            'This will allow you to unlock the app using biometrics instead of PIN.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (proceed != true) return;

      // Test biometric authentication
      final authenticated = await AppLockService.authenticateWithBiometrics();
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication failed or cancelled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      await AppLockService.enableBiometric();
    } else {
      await AppLockService.disableBiometric();
    }

    if (mounted) {
      setState(() {
        _isBiometricEnabled = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? '✓ Biometric authentication enabled'
              : 'Biometric authentication disabled'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _showSetPinDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SetPinDialog(),
    );

    final hasSetPin = result ?? false;
    if (hasSetPin && mounted) {
      setState(() {
        _isPinSet = true;
      });
    }

    return hasSetPin;
  }

  Future<void> _changePin() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ChangePinDialog(),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ PIN changed successfully')),
      );
      setState(() {
        _isPinSet = true;
      });
    }
  }

  Future<void> _removePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PIN'),
        content: const Text(
          'Are you sure you want to remove the PIN? This will also disable app lock.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppLockService.removePin();
      await AppLockService.disableLock();
      setState(() {
        _isPinSet = false;
        _isLockEnabled = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN removed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Security Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔒 Security Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          // App Lock Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Lock',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Protect your notes with a PIN or biometric authentication',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable App Lock'),
                    subtitle: Text(_isPinSet
                        ? 'Lock app with PIN'
                        : 'Set a PIN to enable'),
                    value: _isLockEnabled,
                    onChanged: _toggleLock,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // PIN Management
          if (_isPinSet)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PIN Management',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Change PIN'),
                      subtitle: const Text('Update your security PIN'),
                      onTap: _changePin,
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Remove PIN'),
                      subtitle: const Text('This will disable app lock'),
                      onTap: _removePin,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Biometric Authentication
          if (_isBiometricAvailable)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biometric Authentication',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use fingerprint or face recognition',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable Biometric'),
                      subtitle: Text(
                        _isLockEnabled
                            ? 'Fingerprint/Face ID'
                            : 'Enable App Lock first',
                      ),
                      value: _isBiometricEnabled,
                      onChanged: _toggleBiometric,
                    ),
                    if (!_isLockEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          '⚠️ App Lock must be enabled to use biometric authentication',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Security Info
          Card(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Security Features',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('✓', 'All data stored locally on device'),
                  _buildInfoRow('✓', 'PIN encrypted with secure storage'),
                  _buildInfoRow('✓', 'No cloud sync - complete privacy'),
                  _buildInfoRow('✓', 'Biometric authentication support'),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            icon,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetPinDialog extends StatefulWidget {
  const _SetPinDialog();

  @override
  State<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<_SetPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorText != null) {
      setState(() {
        _errorText = null;
      });
    }
  }

  Future<void> _submit() async {
    final pin = _pinController.text;
    final confirm = _confirmController.text;

    if (pin.length != 4) {
      setState(() {
        _errorText = 'PIN must be 4 digits';
      });
      return;
    }

    if (pin != confirm) {
      setState(() {
        _errorText = 'PINs do not match';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    try {
      await AppLockService.setPin(pin);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      setState(() {
        _errorText = 'Failed to set PIN';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Set PIN'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a 4-digit PIN to secure your notes'),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              onChanged: (_) => _clearError(),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              onChanged: (_) => _clearError(),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Set PIN'),
        ),
      ],
    );
  }
}

class _ChangePinDialog extends StatefulWidget {
  const _ChangePinDialog();

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;
  bool _oldPinVerified = false;

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorText != null) {
      setState(() {
        _errorText = null;
      });
    }
  }

  Future<void> _verifyOldPin() async {
    final oldPin = _oldPinController.text;
    
    if (oldPin.length != 4) {
      setState(() {
        _errorText = 'Please enter a 4-digit PIN';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final isVerified = await AppLockService.verifyPin(oldPin);
    
    if (!mounted) return;
    
    setState(() {
      _isSubmitting = false;
      if (isVerified) {
        _oldPinVerified = true;
        _errorText = null;
        _oldPinController.clear();
      } else {
        _errorText = 'Incorrect PIN. Please try again.';
      }
    });
  }

  Future<void> _submitNewPin() async {
    final newPin = _newPinController.text;
    final confirm = _confirmController.text;

    if (newPin.length != 4) {
      setState(() {
        _errorText = 'New PIN must be 4 digits';
      });
      return;
    }

    if (newPin != confirm) {
      setState(() {
        _errorText = 'New PINs do not match';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    try {
      await AppLockService.setPin(newPin);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      setState(() {
        _errorText = 'Failed to change PIN';
        _isSubmitting = false;
      });
    }
  }

  void _submit() {
    if (!_oldPinVerified) {
      _verifyOldPin();
    } else {
      _submitNewPin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_oldPinVerified ? 'Set New PIN' : 'Verify Old PIN'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_oldPinVerified) ...[
              const Text('Enter your current PIN to continue'),
              const SizedBox(height: 16),
              TextField(
                controller: _oldPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                onChanged: (_) => _clearError(),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Current PIN',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ] else ...[
              const Text('Enter your new 4-digit PIN'),
              const SizedBox(height: 16),
              TextField(
                controller: _newPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                onChanged: (_) => _clearError(),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'New PIN',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                onChanged: (_) => _clearError(),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Confirm New PIN',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_oldPinVerified ? 'Change PIN' : 'Continue'),
        ),
      ],
    );
  }
}
