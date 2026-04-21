// lib/widgets/app_drawer.dart
// Side drawer accessible from the home screen hamburger menu.
// Shows app branding, stats, quick navigation, and settings access.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/document_service.dart';
import '../services/auth_service.dart';
import '../screens/settings_screen.dart';
import '../utils/theme.dart';

class AppDrawer extends StatefulWidget {
  /// Callback so tapping a nav item in the drawer can switch the bottom tab
  final ValueChanged<int>? onNavigate;

  const AppDrawer({super.key, this.onNavigate});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _docService = DocumentService();
  final _auth       = AuthService();

  // App stats shown in the drawer header
  int    _docCount     = 0;
  String _storageUsed  = '—';
  bool   _lockEnabled  = false;

  // ── App metadata ───────────────────────────────────────────────────────────
  static const String _appVersion  = '1.0.0';
  static const String _buildNumber = '1';
  static const String _releaseDate = 'April 2025';
  static const String _developer   = 'DocNest Team';
  static const String _license     = 'Open Source · MIT';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final count   = await _docService.getDocumentCount();
    final storage = await _docService.getStorageUsed();
    final locked  = await _auth.isAppLockEnabled();
    if (mounted) {
      setState(() {
        _docCount    = count;
        _storageUsed = storage;
        _lockEnabled = locked;
      });
    }
  }

  void _close() => Navigator.pop(context);

  void _navigate(int tabIndex) {
    _close();
    widget.onNavigate?.call(tabIndex);
  }

  void _openSettings() {
    _close();
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300,
      backgroundColor: DocNestTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            // Ensure the column fills at least the available height
            // so short content doesn't bunch at the top
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // ── Header ──────────────────────────────────────────────
                  _buildHeader(),

                  // ── Stats row ───────────────────────────────────────────
                  _buildStatsRow(),

                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // ── Navigation items ─────────────────────────────────────
                  _drawerItem(
                    icon: Icons.document_scanner_rounded,
                    label: 'Scan',
                    subtitle: 'Camera document scanner',
                    color: DocNestTheme.accent,
                    onTap: () => _navigate(0),
                  ),
                  _drawerItem(
                    icon: Icons.folder_rounded,
                    label: 'Documents',
                    subtitle: 'Browse your saved files',
                    color: const Color(0xFF4ECDC4),
                    onTap: () => _navigate(1),
                  ),
                  _drawerItem(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    subtitle: 'Bluetooth · Wi-Fi Direct',
                    color: const Color(0xFF9B59B6),
                    onTap: () => _navigate(2),
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // ── Settings ─────────────────────────────────────────────
                  _drawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    subtitle: _lockEnabled ? 'App lock enabled' : 'App lock · storage',
                    color: DocNestTheme.textSecondary,
                    onTap: _openSettings,
                    trailing: _lockEnabled
                      ? const Icon(Icons.lock_rounded, size: 14,
                          color: DocNestTheme.accent)
                      : null,
                  ),

                  // Spacer replacement: flexible empty space that grows
                  // without causing overflow
                  const Spacer(),

                  // ── App info footer ───────────────────────────────────────
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header: branding + tagline ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: const BoxDecoration(
        color: DocNestTheme.primary,
        borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App icon placeholder
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),

          // App name
          const Text(
            'DocNest',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Offline document scanner',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 16),

          // Version badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: DocNestTheme.accent.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DocNestTheme.accent.withOpacity(0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: DocNestTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'v$_appVersion',
                  style: const TextStyle(
                    color: DocNestTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row: doc count + storage ────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              icon: Icons.description_rounded,
              value: '$_docCount',
              label: 'Documents',
              iconColor: DocNestTheme.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              icon: Icons.storage_rounded,
              value: _storageUsed,
              label: 'Storage used',
              iconColor: const Color(0xFF4ECDC4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DocNestTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocNestTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: DocNestTheme.textPrimary,
                )),
              Text(label,
                style: const TextStyle(
                  fontSize: 10, color: DocNestTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Nav item ───────────────────────────────────────────────────────────────
  Widget _drawerItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(label,
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: DocNestTheme.textPrimary,
            )),
          subtitle: Text(subtitle,
            style: const TextStyle(
              fontSize: 11, color: DocNestTheme.textSecondary)),
          trailing: trailing ?? const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: DocNestTheme.textHint,
          ),
          dense: true,
        ),
      ),
    );
  }

  // ── Footer: version details + privacy note ─────────────────────────────────
  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DocNestTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DocNestTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About header
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                size: 14, color: DocNestTheme.textSecondary),
              const SizedBox(width: 6),
              const Text('About DocNest',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: DocNestTheme.textSecondary,
                )),
              const Spacer(),
              // Copy version tap
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: 'DocNest v$_appVersion (build $_buildNumber)'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Version copied'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: const Icon(Icons.copy_rounded,
                  size: 13, color: DocNestTheme.textHint),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Details grid
          _infoRow('Version',     'v$_appVersion (build $_buildNumber)'),
          _infoRow('Released',    _releaseDate),
          _infoRow('Developer',   _developer),
          _infoRow('License',     _license),
          _infoRow('Platform',    'Android 7.0+'),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Privacy badges
          Row(
            children: [
              _badge(Icons.cloud_off_rounded, 'No cloud'),
              const SizedBox(width: 6),
              _badge(Icons.no_accounts_rounded, 'No login'),
              const SizedBox(width: 6),
              _badge(Icons.wifi_off_rounded, 'Offline'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(key,
              style: const TextStyle(
                fontSize: 11, color: DocNestTheme.textHint)),
          ),
          Expanded(
            child: Text(value,
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: DocNestTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: DocNestTheme.accentSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: DocNestTheme.accent),
          const SizedBox(width: 4),
          Text(label,
            style: const TextStyle(
              fontSize: 10, color: DocNestTheme.accent,
              fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
