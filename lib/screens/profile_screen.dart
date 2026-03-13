import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

// ── AUTH EKRANI ──
class AuthScreen extends StatefulWidget {
  final VoidCallback onSkip;
  const AuthScreen({super.key, required this.onSkip});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _msg = '';
  bool _loading = false;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _emailAuth() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) { setState(() => _msg = '⚠️ Enter email and password!'); return; }
    if (pass.length < 6) { setState(() => _msg = '⚠️ Password must be at least 6 characters!'); return; }
    setState(() { _loading = true; _msg = '⏳ Please wait...'; });
    try {
      if (_isSignIn) {
        await SupabaseService.signInWithEmail(email, pass);
      } else {
        final res = await SupabaseService.signUpWithEmail(email, pass);
        if (res.session == null) { setState(() { _msg = '✅ Verification email sent!'; _loading = false; }); return; }
      }
    } catch (e) {
      final errMap = {'Invalid login credentials': '❌ Wrong email or password!', 'User already registered': '❌ This email is already registered!'};
      setState(() => _msg = errMap[e.toString()] ?? '❌ $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _oauth(String provider) async {
    try {
      if (provider == 'google') await SupabaseService.signInWithGoogle();
      if (provider == 'discord') await SupabaseService.signInWithDiscord();
      if (provider == 'github') await SupabaseService.signInWithGithub();
    } catch (e) { setState(() => _msg = '❌ $provider error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(colors: [Colors.white, AppTheme.accent3]).createShader(b),
                    child: const Text('🎛️ UserLooperGen', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  if (_msg.isNotEmpty) Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _msg.startsWith('✅') ? const Color(0xFF22C55E) : AppTheme.danger)),
                  ),
                  _OAuthBtn(color: Colors.white, textColor: const Color(0xFF333333), borderColor: const Color(0xFFDDDDDD), label: 'Continue with Google', emoji: 'G', onTap: () => _oauth('google')),
                  const SizedBox(height: 10),
                  _OAuthBtn(color: const Color(0xFF5865F2), textColor: Colors.white, label: 'Continue with Discord', emoji: '🎮', onTap: () => _oauth('discord')),
                  const SizedBox(height: 10),
                  _OAuthBtn(color: const Color(0xFF24292E), textColor: Colors.white, label: 'Continue with GitHub', emoji: '🐙', onTap: () => _oauth('github')),
                  const SizedBox(height: 16),
                  Row(children: [const Expanded(child: Divider(color: AppTheme.border)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or email', style: const TextStyle(fontSize: 12, color: AppTheme.muted))), const Expanded(child: Divider(color: AppTheme.border))]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      _Tab(label: 'Sign In', active: _isSignIn, onTap: () => setState(() => _isSignIn = true)),
                      _Tab(label: 'Sign Up', active: !_isSignIn, onTap: () => setState(() => _isSignIn = false)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  _AuthInput(controller: _emailCtrl, hint: 'Email address', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 10),
                  _AuthInput(controller: _passCtrl, hint: 'Password (min. 6 characters)', obscure: true),
                  const SizedBox(height: 14),
                  _loading
                      ? const CircularProgressIndicator(color: AppTheme.accent)
                      : _GradientBtn(label: _isSignIn ? 'Sign In' : 'Sign Up', onTap: _emailAuth),
                  const SizedBox(height: 14),
                  GestureDetector(onTap: widget.onSkip, child: const Text('Continue as guest →', style: TextStyle(fontSize: 12, color: AppTheme.muted, decoration: TextDecoration.underline))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── KULLANICI ADI DİYALOGU ──
class UsernameDialog extends StatefulWidget {
  final String userId;
  final Function(String) onSaved;
  const UsernameDialog({super.key, required this.userId, required this.onSaved});
  @override
  State<UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<UsernameDialog> {
  final _ctrl = TextEditingController();
  String _msg = '';
  bool _loading = false;

  Future<void> _save() async {
    final input = _ctrl.text.trim();
    if (!RegExp(r'^[a-zA-Z0-9_-]{3,20}$').hasMatch(input)) {
      setState(() => _msg = '⚠️ 3-20 chars, letters/numbers/_ and - only!');
      return;
    }
    setState(() { _loading = true; _msg = '⏳ Checking...'; });
    if (await SupabaseService.isUsernameTaken(input)) {
      setState(() { _msg = '❌ Username already taken!'; _loading = false; });
      return;
    }
    await SupabaseService.createProfile(widget.userId, input);
    widget.onSaved(input);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎭 Choose a Username', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
            const SizedBox(height: 8),
            const Text('Permanent. Only letters, numbers, _ and - (3-20 chars)', style: TextStyle(fontSize: 12, color: AppTheme.muted, height: 1.5)),
            const SizedBox(height: 14),
            _AuthInput(controller: _ctrl, hint: 'e.g. MageLord'),
            if (_msg.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_msg, style: TextStyle(fontSize: 13, color: _msg.startsWith('✅') ? const Color(0xFF22C55E) : AppTheme.danger)),
            ],
            const SizedBox(height: 14),
            _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : _GradientBtn(label: '✅ Continue', onTap: _save),
          ],
        ),
      ),
    );
  }
}

// ── PROFİL EKRANI ──
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    final p = await SupabaseService.getProfile(user.id);
    if (mounted) setState(() => _profile = p);
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    if (mounted) setState(() => _profile = null);
  }

  void _editProfile() {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    final meta = user.userMetadata ?? {};
    final ctrl = TextEditingController(text: meta['display_name'] ?? meta['full_name'] ?? '');
    String msg = '';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, set) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✏️ Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
              const SizedBox(height: 14),
              _AuthInput(controller: ctrl, hint: 'Display name'),
              if (msg.isNotEmpty) ...[const SizedBox(height: 8), Text(msg, style: const TextStyle(fontSize: 13, color: AppTheme.danger))],
              const SizedBox(height: 14),
              _GradientBtn(label: '💾 Save', onTap: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) { set(() => msg = '⚠️ Cannot be empty!'); return; }
                try {
                  await SupabaseService.updateDisplayName(name);
                  Navigator.pop(ctx);
                  _showToast('✅ Profile updated!');
                  setState(() {});
                } catch (e) { set(() => msg = '❌ $e'); }
              }),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.muted))),
            ],
          ),
        ),
      )),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: AppTheme.textColor)),
      backgroundColor: AppTheme.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.accent)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    if (user == null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👤', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text('Guest', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
              const SizedBox(height: 8),
              const Text('Sign in to upload loops and save your creations.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppTheme.muted, height: 1.5)),
              const SizedBox(height: 16),
              _GradientBtn(label: '🔑 Sign In / Register', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AuthScreen(onSkip: () => Navigator.pop(context))));
              }),
            ],
          ),
        ),
      ));
    }

    final meta = user.userMetadata ?? {};
    final displayName = meta['display_name'] ?? meta['full_name'] ?? meta['name'] ?? user.email?.split('@')[0] ?? 'User';
    final username = _profile?['username'] ?? user.email?.split('@')[0] ?? 'user';
    final role = _profile?['role'] ?? 'user';
    final avatarUrl = meta['avatar_url'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profil kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
            child: Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: avatarUrl == null ? const LinearGradient(colors: [AppTheme.accent, AppTheme.accent2]) : null,
                    image: avatarUrl != null ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
                  ),
                  child: avatarUrl == null ? const Center(child: Text('🎵', style: TextStyle(fontSize: 32))) : null,
                ),
                const SizedBox(height: 12),
                Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
                const SizedBox(height: 4),
                Text('@$username', style: const TextStyle(fontSize: 12, color: AppTheme.muted, fontFamily: 'monospace')),
                if (role != 'user') ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(role == 'admin' ? '👑 Admin' : '🛡️ Moderator',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppTheme.accent3)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsGroup(title: 'ACCOUNT', items: [
            _SettingRow(icon: '✏️', label: 'Edit Profile', onTap: _editProfile),
            _SettingRow(icon: '🚪', label: 'Sign Out', danger: true, onTap: _signOut),
          ]),
          const SizedBox(height: 16),
          _SettingsGroup(title: 'APP', items: [
            _SettingRow(icon: '📄', label: 'Terms of Service', onTap: () {}),
            _SettingRow(icon: '🔒', label: 'Privacy Policy', onTap: () {}),
            _SettingRow(icon: '💬', label: 'Discord', onTap: () {}),
          ]),
          const SizedBox(height: 16),
          const Text('v1.0.1RE • EnderArcane Studio', style: TextStyle(fontSize: 11, color: AppTheme.muted, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

// ── ORTAK WİDGETLER ──
class _OAuthBtn extends StatelessWidget {
  final Color color; final Color textColor; final Color? borderColor;
  final String label, emoji; final VoidCallback onTap;
  const _OAuthBtn({required this.color, required this.textColor, required this.label, required this.emoji, required this.onTap, this.borderColor});
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, child: ElevatedButton(
    style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: textColor, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: borderColor != null ? BorderSide(color: borderColor!) : BorderSide.none)),
    onPressed: onTap,
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 16)), const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
    ]),
  ));
}

class _Tab extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap, child: AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: active ? AppTheme.accent : Colors.transparent, borderRadius: BorderRadius.circular(10)),
    child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : AppTheme.muted)),
  )));
}

class _AuthInput extends StatelessWidget {
  final TextEditingController controller; final String hint; final bool obscure; final TextInputType? keyboardType;
  const _AuthInput({required this.controller, required this.hint, this.obscure = false, this.keyboardType});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller, obscureText: obscure, keyboardType: keyboardType,
    style: const TextStyle(color: AppTheme.textColor, fontSize: 14),
    decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppTheme.muted, fontSize: 14),
      filled: true, fillColor: AppTheme.surface2, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent))),
  );
}

class _GradientBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _GradientBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, child: DecoratedBox(
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accent2]), borderRadius: BorderRadius.circular(12)),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
    ),
  ));
}

class _SettingsGroup extends StatelessWidget {
  final String title; final List<Widget> items;
  const _SettingsGroup({required this.title, required this.items});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(18,14,18,8), child: Text(title, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.muted, letterSpacing: 1, fontWeight: FontWeight.bold))),
      ...items,
    ]));
}

class _SettingRow extends StatelessWidget {
  final String icon, label; final VoidCallback onTap; final bool danger;
  const _SettingRow({required this.icon, required this.label, required this.onTap, this.danger = false});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border))),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: danger ? AppTheme.danger : AppTheme.textColor))),
      const Text('›', style: TextStyle(color: AppTheme.muted, fontSize: 18)),
    ]),
  ));
}
