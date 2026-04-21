// lib/screens/settings_screen.dart
// App settings: app lock, storage usage, about

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth    = AuthService();
  final _docSvc  = DocumentService();

  bool _appLockEnabled = false;
  String _authType     = 'biometric';
  bool _biometricAvailable = false;
  String _storageUsed  = '—';
  int _docCount        = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lockEnabled = await _auth.isAppLockEnabled();
    final authType    = await _auth.getAuthType();
    final biometric   = await _auth.isBiometricAvailable();
    final storage     = await _docSvc.getStorageUsed();
    final count       = await _docSvc.getDocumentCount();

    setState(() {
      _appLockEnabled      = lockEnabled;
      _authType            = authType;
      _biometricAvailable  = biometric;
      _storageUsed         = storage;
      _docCount            = count;
    });
  }

  Future<void> _toggleAppLock(bool value) async {
    if (value) {
      // Show dialog to choose auth type
      final type = await _showAuthTypeDialog();
      if (type == null) return;

      if (type == 'pin') {
        final pin = await _showPinSetupDialog();
        if (pin == null) return;
        await _auth.setPin(pin);
      }

      await _auth.enableAppLock(type: type);
      setState(() {
        _appLockEnabled = true;
        _authType = type;
      });
    } else {
      await _auth.disableAppLock();
      setState(() => _appLockEnabled = false);
    }
  }

  Future<String?> _showAuthTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Lock Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_biometricAvailable)
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('Biometrics / Face ID'),
                onTap: () => Navigator.pop(ctx, 'biometric'),
              ),
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: const Text('PIN'),
              onTap: () => Navigator.pop(ctx, 'pin'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showPinSetupDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          decoration: const InputDecoration(hintText: '4–6 digit PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DocNestTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Storage ───────────────────────────────────────────────────
          _sectionHeader('Storage'),
          _settingCard([
            _infoRow(Icons.description_outlined, 'Documents', '$_docCount files'),
            const Divider(height: 1),
            _infoRow(Icons.storage_outlined, 'Storage Used', _storageUsed),
          ]),

          const SizedBox(height: 20),

          // ── Privacy & Security ────────────────────────────────────────
          _sectionHeader('Privacy & Security'),
          _settingCard([
            SwitchListTile(
              secondary: const Icon(Icons.lock_outline,
                color: DocNestTheme.textSecondary),
              title: const Text('App Lock',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: Text(
                _appLockEnabled
                  ? 'Locked with ${_authType == 'pin' ? 'PIN' : 'Biometrics'}'
                  : 'Tap to enable',
                style: const TextStyle(fontSize: 12, color: DocNestTheme.textSecondary),
              ),
              value: _appLockEnabled,
              activeColor: DocNestTheme.accent,
              onChanged: _toggleAppLock,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.no_accounts_outlined,
                color: DocNestTheme.textSecondary),
              title: const Text('No Account Required',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: const Text('DocNest never asks you to sign in',
                style: TextStyle(fontSize: 12, color: DocNestTheme.textSecondary)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cloud_off_outlined,
                color: DocNestTheme.textSecondary),
              title: const Text('100% Offline',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: const Text('Your documents never leave your device',
                style: TextStyle(fontSize: 12, color: DocNestTheme.textSecondary)),
            ),
          ]),

          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────────────
          _sectionHeader('About'),
          _settingCard([
            _infoRow(Icons.info_outline, 'Version', '1.0.0'),
            const Divider(height: 1),
            _infoRow(Icons.scanner_outlined, 'App', 'DocNest'),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.favorite_outline,
                color: DocNestTheme.danger),
              title: const Text('Built with Flutter',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: const Text('Open source. No cloud. No tracking.',
                style: TextStyle(fontSize: 12, color: DocNestTheme.textSecondary)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: DocNestTheme.textSecondary,
      ),
    ),
  );

  Widget _settingCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: DocNestTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DocNestTheme.border),
    ),
    child: Column(children: children),
  );

  Widget _infoRow(IconData icon, String label, String value) => ListTile(
    leading: Icon(icon, color: DocNestTheme.textSecondary),
    title: Text(label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    trailing: Text(value,
      style: const TextStyle(
        fontSize: 14, color: DocNestTheme.textSecondary)),
  );
}
