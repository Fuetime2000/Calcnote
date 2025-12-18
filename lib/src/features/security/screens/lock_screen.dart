import 'package:flutter/material.dart';
import 'package:calcnote/src/features/security/services/app_lock_service.dart';

/// Lock screen for PIN/Fingerprint authentication
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final List<String> _enteredPin = [];
  bool _isError = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await AppLockService.isBiometricAvailable();
    final enabled = await AppLockService.isBiometricEnabled();
    
    setState(() {
      _biometricAvailable = available && enabled;
    });

    // Auto-trigger biometric if available
    if (_biometricAvailable) {
      _authenticateWithBiometric();
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final success = await AppLockService.authenticateWithBiometrics();
    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onNumberTap(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin.add(number);
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _isError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final pin = _enteredPin.join();
    final isValid = await AppLockService.verifyPin(pin);

    if (isValid) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _isError = true;
        _enteredPin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // App icon and title
            Icon(
              Icons.lock_outline,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'CalcNote',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter PIN to unlock',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _enteredPin.length
                        ? (_isError ? Colors.red : theme.colorScheme.primary)
                        : theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: _isError
                          ? Colors.red
                          : theme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            
            if (_isError) ...[
              const SizedBox(height: 16),
              const Text(
                'Incorrect PIN',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            
            const SizedBox(height: 48),
            
            // Number pad
            _buildNumberPad(theme),
            
            const SizedBox(height: 24),
            
            // Biometric button
            if (_biometricAvailable)
              TextButton.icon(
                icon: const Icon(Icons.fingerprint),
                label: const Text('Use Fingerprint'),
                onPressed: _authenticateWithBiometric,
              ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _buildNumberRow(['1', '2', '3'], theme),
          const SizedBox(height: 16),
          _buildNumberRow(['4', '5', '6'], theme),
          const SizedBox(height: 16),
          _buildNumberRow(['7', '8', '9'], theme),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72),
              _buildNumberButton('0', theme),
              SizedBox(
                width: 72,
                height: 72,
                child: IconButton(
                  icon: const Icon(Icons.backspace_outlined),
                  onPressed: _onBackspace,
                  iconSize: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberRow(List<String> numbers, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        return _buildNumberButton(number, theme);
      }).toList(),
    );
  }

  Widget _buildNumberButton(String number, ThemeData theme) {
    return SizedBox(
      width: 72,
      height: 72,
      child: ElevatedButton(
        onPressed: () => _onNumberTap(number),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          foregroundColor: theme.colorScheme.onSurface,
        ),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
