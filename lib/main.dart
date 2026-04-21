// lib/main.dart
// DocNest — offline document scanner
// Entry point: sets up theme, routing, and bottom navigation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'screens/scan_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/share_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/lock_screen.dart';
import 'widgets/app_drawer.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation for scanning clarity
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Light status bar icons (dark content on light background)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const DocNestApp());
}

class DocNestApp extends StatelessWidget {
  const DocNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocNest',
      debugShowCheckedModeBanner: false,
      theme: DocNestTheme.light,
      home: const AppGate(),
    );
  }
}

// ── App Gate: check app lock before showing main UI ──────────────────────────
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  final _auth = AuthService();
  bool _checking = true;
  bool _locked   = false;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    final lockEnabled = await _auth.isAppLockEnabled();
    setState(() {
      _locked   = lockEnabled;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      // Very brief splash while checking lock state
      return const Scaffold(
        backgroundColor: DocNestTheme.primary,
        body: Center(
          child: Text(
            'DocNest',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
        ),
      );
    }

    if (_locked) {
      return LockScreen(onUnlocked: () => setState(() => _locked = false));
    }

    return const MainShell();
  }
}

// ── Main Shell: bottom navigation with 3 tabs + side drawer ──────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // GlobalKey lets us open the drawer programmatically from child widgets
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Keep all screens alive for fast tab switching
  final List<Widget> _screens = const [
    ScanScreen(),
    DocumentsScreen(),
    ShareScreen(),
  ];

  // Tab metadata for the AppBar title
  static const List<String> _tabTitles = ['DocNest', 'Documents', 'Share'];
  static const List<IconData> _tabIcons = [
    Icons.document_scanner_rounded,
    Icons.folder_rounded,
    Icons.share_rounded,
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      // ── App Bar with hamburger ────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: DocNestTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x14000000),
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.menu_rounded),
            color: DocNestTheme.primary,
            tooltip: 'Open menu',
            onPressed: _openDrawer,
          ),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_nobg.png',
              width: 32, height: 32,
            ),
            const SizedBox(width: 8),
            Text(
              _tabTitles[_currentIndex],
              style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: DocNestTheme.primary, letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          // Quick settings shortcut in the app bar
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            color: DocNestTheme.textSecondary,
            tooltip: 'Settings',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ── Side Drawer ───────────────────────────────────────────────────
      drawer: AppDrawer(
        onNavigate: (tabIndex) {
          setState(() => _currentIndex = tabIndex);
        },
      ),

      // ── Body: tabs kept alive ─────────────────────────────────────────
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ── Bottom Navigation ─────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: DocNestTheme.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.document_scanner_outlined),
              activeIcon: Icon(Icons.document_scanner_rounded),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder_rounded),
              label: 'Documents',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.share_outlined),
              activeIcon: Icon(Icons.share_rounded),
              label: 'Share',
            ),
          ],
        ),
      ),
    );
  }
}
