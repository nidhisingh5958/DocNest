// lib/screens/lock_screen.dart
// App lock screen: shows unlock UI (PIN or biometric).
// When called from settings the setup flow is handled in set_pin_screen.dart.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();

  String _enteredPin = '';
  bool _showError = false;
  String _authType = 'biometric';
  bool _biometricAvailable = false;
  bool _loading = true;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // track attempts for rate limiting feedback
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );
    _init();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final authType = await _auth.getAuthType();
    final bioAvailable = await _auth.isBiometricAvailable();
    if (!mounted) return;
    setState(() {
      _authType = authType;
      _biometricAvailable = bioAvailable;
      _loading = false;
    });
    // Auto-trigger biometric if that is the chosen method
    if (_authType == 'biometric' && _biometricAvailable) {
      await Future.delayed(const Duration(milliseconds: 300));
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final success = await _auth.authenticateWithBiometrics();
    if (success && mounted) widget.onUnlocked();
  }

  void _onDigit(String digit) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += digit;
      _showError = false;
    });
    // Auto-verify at 4 digits (minimum PIN length)
    if (_enteredPin.length == 4) _scheduleVerify();
  }

  // Allow the dot animation to render before verifying
  void _scheduleVerify() {
    Future.delayed(const Duration(milliseconds: 80), _verifyPin);
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _showError = false;
    });
  }

  Future<void> _verifyPin() async {
    final valid = await _auth.verifyPin(_enteredPin);
    if (!mounted) return;
    if (valid) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
    } else {
      _attempts++;
      HapticFeedback.vibrate();
      _shakeCtrl.forward(from: 0);
      setState(() {
        _enteredPin = '';
        _showError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: DocNestTheme.primary,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white38),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DocNestTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top padding ───────────────────────────────────────────────
            const Spacer(flex: 2),

            // ── Brand ─────────────────────────────────────────────────────
            const Icon(Icons.lock_rounded, color: Colors.white70, size: 36),
            const SizedBox(height: 16),
            const Text(
              'DocNest',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _authType == 'biometric'
                  ? 'Use biometrics or enter your PIN'
                  : 'Enter your PIN to continue',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 48),

            // ── PIN dots ─────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                final dx = _shakeCtrl.isAnimating
                    ? 14 *
                        (0.5 - _shakeAnim.value).abs() *
                        (_shakeAnim.value > 0.5 ? 1 : -1)
                    : 0.0;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? DocNestTheme.accent
                          : Colors.white.withOpacity(0.15),
                      border: Border.all(
                        color: filled
                            ? DocNestTheme.accent
                            : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Error message ─────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showError ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  _attempts >= 5
                      ? 'Too many attempts. Keep trying.'
                      : 'Incorrect PIN. Try again.',
                  style: const TextStyle(
                    color: DocNestTheme.danger,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── PIN pad ───────────────────────────────────────────────────
            _buildPinPad(),

            const Spacer(flex: 1),

            // ── Biometric fallback ────────────────────────────────────────
            if (_biometricAvailable)
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: TextButton.icon(
                  onPressed: _tryBiometric,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.fingerprint, size: 26),
                  label: const Text(
                    'Use biometrics',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              )
            else
              const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPinPad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: rows
          .map((row) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map(_pinButton).toList(),
              ))
          .toList(),
    );
  }

  Widget _pinButton(String label) {
    if (label.isEmpty) return const SizedBox(width: 80, height: 72);

    final isDelete = label == '⌫';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => isDelete ? _onDelete() : _onDigit(label),
        borderRadius: BorderRadius.circular(40),
        splashColor: Colors.white12,
        highlightColor: Colors.white10,
        child: Container(
          width: 80,
          height: 72,
          alignment: Alignment.center,
          child: isDelete
              ? const Icon(Icons.backspace_outlined,
                  color: Colors.white60, size: 22)
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                  ),
                ),
        ),
      ),
    );
  }
}
