// lib/screens/lock_screen.dart
// App lock screen: PIN pad or biometric prompt

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _auth = AuthService();
  String _enteredPin = '';
  bool _showError = false;
  String _authType = 'biometric';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _authType = await _auth.getAuthType();
    if (_authType == 'biometric') {
      await _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final success = await _auth.authenticateWithBiometrics();
    if (success && mounted) widget.onUnlocked();
  }

  void _onDigit(String digit) {
    if (_enteredPin.length >= 6) return;
    setState(() {
      _enteredPin += digit;
      _showError = false;
    });
    if (_enteredPin.length >= 4) _verifyPin();
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _showError = false;
    });
  }

  Future<void> _verifyPin() async {
    final valid = await _auth.verifyPin(_enteredPin);
    if (valid) {
      widget.onUnlocked();
    } else if (_enteredPin.length >= 6) {
      setState(() {
        _enteredPin = '';
        _showError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DocNestTheme.primary,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // App logo
            const Text(
              'DocNest',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your PIN to continue',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),

            const SizedBox(height: 48),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < _enteredPin.length;
                return Container(
                  width: 14, height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? DocNestTheme.accent
                        : Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: filled ? DocNestTheme.accent : Colors.white30,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),

            if (_showError) ...[
              const SizedBox(height: 16),
              const Text(
                'Incorrect PIN. Try again.',
                style: TextStyle(color: DocNestTheme.danger, fontSize: 13),
              ),
            ],

            const SizedBox(height: 48),

            // PIN pad
            _buildPinPad(),

            const Spacer(),

            // Biometric fallback
            if (_authType == 'biometric')
              TextButton.icon(
                onPressed: _tryBiometric,
                icon: const Icon(Icons.fingerprint, color: Colors.white54),
                label: const Text(
                  'Use biometrics',
                  style: TextStyle(color: Colors.white54),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPinPad() {
    final digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: digits.map((row) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: row.map((d) => _pinButton(d)).toList(),
      )).toList(),
    );
  }

  Widget _pinButton(String label) {
    if (label.isEmpty) return const SizedBox(width: 80, height: 70);

    return GestureDetector(
      onTap: () {
        if (label == '⌫') {
          _onDelete();
        } else {
          _onDigit(label);
        }
      },
      child: Container(
        width: 80, height: 70,
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}
