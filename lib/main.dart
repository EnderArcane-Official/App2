import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/supabase_service.dart';
import 'theme.dart';
import 'screens/pad_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/library_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await SupabaseService.init();
  runApp(const UserLooperGenApp());
}

class UserLooperGenApp extends StatelessWidget {
  const UserLooperGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UserLooperGen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark.copyWith(
        textTheme: GoogleFonts.syneTextTheme(AppTheme.dark.textTheme).apply(
          bodyColor: AppTheme.textColor,
          displayColor: AppTheme.textColor,
        ),
      ),
      home: const AppEntry(),
    );
  }
}

// ── İLK AÇILIŞ — Consent + Auth akışı ──
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});
  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _consentDone = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // Supabase session kontrolü
    final session = SupabaseService.client.auth.currentSession;
    // Gerçek uygulamada SharedPreferences ile consent kontrolü yapılır
    // Şimdilik direkt MainShell'e geçiyoruz
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }
    return const MainShell();
  }
}

// ── ANA SHELL ──
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _index = 0;

  // Auth değişikliklerini dinle
  @override
  void initState() {
    super.initState();
    SupabaseService.authStream.listen((event) async {
      if (!mounted) return;
      if (event.event == AuthChangeEvent.signedIn) {
        final user = event.session?.user;
        if (user != null) {
          final profile = await SupabaseService.getProfile(user.id);
          if (profile == null && mounted) {
            // Yeni kullanıcı — kullanıcı adı sor
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => UsernameDialog(
                userId: user.id,
                onSaved: (username) {
                  Navigator.pop(context);
                  _showToast('✅ Welcome, @$username!');
                  setState(() {}); // Profil ekranını yenile
                },
              ),
            );
          } else {
            _showToast('✅ Welcome back!');
            setState(() {});
          }
        }
      }
      if (event.event == AuthChangeEvent.signedOut) {
        setState(() {});
        _showToast('👋 Signed out.');
      }
    });
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: AppTheme.textColor)),
      backgroundColor: AppTheme.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.accent),
      ),
    ));
  }

  static const _titles = ['UserLooperGen', 'Pad Screen', 'Library', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _HomeScreen(),
      const PadScreen(),
      LibraryScreen(onLoadToPad: null),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [AppTheme.accent2, AppTheme.accent3]).createShader(b),
          child: Text(_titles[_index], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppTheme.border)),
      ),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: AppTheme.border))),
        child: SafeArea(
          child: Row(
            children: [
              _NavBtn(icon: '🏠', label: 'Home', active: _index == 0, onTap: () => setState(() => _index = 0)),
              _NavBtn(icon: '🎛️', label: 'Pad', active: _index == 1, onTap: () => setState(() => _index = 1)),
              _NavBtn(icon: '📚', label: 'Library', active: _index == 2, onTap: () => setState(() => _index = 2)),
              _NavBtn(icon: '👤', label: 'Profile', active: _index == 3, onTap: () => setState(() => _index = 3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String icon, label; final bool active; final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: 22, color: active ? AppTheme.accent2 : AppTheme.muted)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: active ? AppTheme.accent2 : AppTheme.muted)),
        if (active) Container(margin: const EdgeInsets.only(top: 4), width: 32, height: 2, decoration: BoxDecoration(color: AppTheme.accent2, borderRadius: BorderRadius.circular(2))),
      ],
    )),
  ));
}

// ── HOME ──
class _HomeScreen extends StatelessWidget {
  const _HomeScreen();
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(alignment: Alignment.center, children: [
            Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppTheme.accent.withOpacity(0.4), Colors.transparent]))),
            Container(width: 90, height: 90, decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
              child: const Center(child: Text('🎵', style: TextStyle(fontSize: 40)))),
          ]),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [Colors.white, AppTheme.accent3], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(b),
            child: const Text('Create Your\nLoop', textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -1, color: Colors.white)),
          ),
          const SizedBox(height: 12),
          const Text('Load sounds, loop and record your\nmusic with the 4×4 pad.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppTheme.muted, height: 1.6)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.findAncestorStateOfType<MainShellState>()?.setState(() => context.findAncestorStateOfType<MainShellState>()?._index = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accent2]),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 32, offset: const Offset(0, 8))],
              ),
              child: const Text('▶ Start', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    ));
  }
}
