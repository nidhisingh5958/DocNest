// lib/screens/settings_screen.dart
// App settings: app lock, storage usage, about

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';
import '../utils/theme.dart';
import 'set_pin_screen.dart';

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
      // Choose auth method
      final type = await _showAuthTypeDialog();
      if (type == null) return;

      if (type == 'pin') {
        final success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const SetPinScreen()),
        );
        if (success != true) return; // user cancelled
      }

      await _auth.enableAppLock(type: type);
      if (mounted) {
        setState(() {
          _appLockEnabled = true;
          _authType = type;
        });
      }
    } else {
      // Confirm before disabling
      final confirm = await _showDisableConfirmDialog();
      if (confirm != true) return;
      await _auth.disableAppLock();
      if (mounted) setState(() => _appLockEnabled = false);
    }
  }

  Future<void> _changePin() async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SetPinScreen()),
    );
    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PIN updated successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: DocNestTheme.success,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<String?> _showAuthTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Choose Lock Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_biometricAvailable) ...[
              _authOption(
                ctx: ctx,
                value: 'biometric',
                icon: Icons.fingerprint,
                iconColor: DocNestTheme.accent,
                title: 'Biometrics / Face ID',
                subtitle: 'Use your fingerprint or face to unlock',
              ),
              const SizedBox(height: 8),
            ],
            _authOption(
              ctx: ctx,
              value: 'pin',
              icon: Icons.dialpad_rounded,
              iconColor: const Color(0xFF9B59B6),
              title: 'PIN',
              subtitle: 'Set a 4–6 digit PIN code',
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _authOption({
    required BuildContext ctx,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(ctx, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: DocNestTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DocNestTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: DocNestTheme.textPrimary)),
                  Text(subtitle,
                    style: const TextStyle(
                      fontSize: 12, color: DocNestTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
              size: 18, color: DocNestTheme.textHint),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDisableConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disable App Lock?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
          'Your app will no longer require a PIN or biometrics to open.',
          style: TextStyle(fontSize: 14, color: DocNestTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DocNestTheme.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable'),
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
              secondary: Icon(
                _appLockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: _appLockEnabled
                  ? DocNestTheme.accent
                  : DocNestTheme.textSecondary,
              ),
              title: const Text('App Lock',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: Text(
                _appLockEnabled
                  ? 'Locked with ${_authType == 'pin' ? 'PIN' : 'Biometrics / Face ID'}'
                  : 'Tap to enable PIN or biometric lock',
                style: const TextStyle(fontSize: 12, color: DocNestTheme.textSecondary),
              ),
              value: _appLockEnabled,
              activeColor: DocNestTheme.accent,
              onChanged: _toggleAppLock,
            ),
            // Show Change PIN option when PIN lock is active
            if (_appLockEnabled && _authType == 'pin') ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.dialpad_rounded,
                  color: DocNestTheme.textSecondary),
                title: const Text('Change PIN',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                subtitle: const Text('Update your lock PIN',
                  style: TextStyle(fontSize: 12, color: DocNestTheme.textSecondary)),
                trailing: const Icon(Icons.chevron_right_rounded,
                  size: 18, color: DocNestTheme.textHint),
                onTap: _changePin,
              ),
            ],
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
