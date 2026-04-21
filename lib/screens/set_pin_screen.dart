// lib/screens/set_pin_screen.dart
// Full-screen PIN setup: enter PIN → confirm PIN → save

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

/// Returns true when PIN was successfully saved, false/null if cancelled.
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

enum _Step { enter, confirm }

class _SetPinScreenState extends State<SetPinScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();

  _Step _step = _Step.enter;
  String _pin = '';
  String _confirmPin = '';
  bool _showError = false;
  String _errorMessage = '';

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _currentPin => _step == _Step.enter ? _pin : _confirmPin;

  void _onDigit(String digit) {
    if (_currentPin.length >= 4) return;
    setState(() {
      _showError = false;
      if (_step == _Step.enter) {
        _pin += digit;
        if (_pin.length == 4) _advanceStep();
      } else {
        _confirmPin += digit;
        if (_confirmPin.length == 4) _finish();
      }
    });
  }

  void _onDelete() {
    setState(() {
      _showError = false;
      if (_step == _Step.enter) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  void _advanceStep() {
    setState(() => _step = _Step.confirm);
  }

  Future<void> _finish() async {
    if (_pin != _confirmPin) {
      _shakeCtrl.forward(from: 0);
      setState(() {
        _showError = true;
        _errorMessage = 'PINs don\'t match. Try again.';
        _confirmPin = '';
      });
      HapticFeedback.mediumImpact();
      return;
    }
    if (_pin.length < 4) {
      setState(() {
        _showError = true;
        _errorMessage = 'PIN must be at least 4 digits.';
      });
      return;
    }
    await _auth.setPin(_pin);
    if (mounted) Navigator.pop(context, true);
  }

  void _goBack() {
    if (_step == _Step.confirm) {
      setState(() {
        _step = _Step.enter;
        _pin = '';
        _confirmPin = '';
        _showError = false;
      });
    } else {
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dots = _step == _Step.enter ? _pin.length : _confirmPin.length;

    return Scaffold(
      backgroundColor: DocNestTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70),
                    onPressed: _goBack,
                  ),
                  const Spacer(),
                ],
              ),
            ),

            const Spacer(),

            // ── Title area ────────────────────────────────────────────────
            const Icon(Icons.lock_rounded, color: Colors.white, size: 40),
            const SizedBox(height: 20),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _step == _Step.enter
                    ? 'Set your PIN'
                    : 'Confirm your PIN',
                key: ValueKey(_step),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _step == _Step.enter
                  ? 'Choose a 4 digit PIN'
                  : 'Enter the same PIN again',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 48),

            // ── PIN dots ─────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                final dx = _shakeCtrl.isAnimating
                    ? 12 * (0.5 - _shakeAnim.value).abs() *
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
                  final filled = i < dots;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
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

            // ── Error label ───────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showError ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                      color: DocNestTheme.danger, fontSize: 13),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // PIN pad 
            _buildPinPad(),

            const Spacer(),
            const SizedBox(height: 16),
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
        onTap: () {
          HapticFeedback.lightImpact();
          isDelete ? _onDelete() : _onDigit(label);
        },
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
