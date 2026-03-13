import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'username_screen.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onSkip;
  const AuthScreen({super.key, required this.onSkip});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;
  bool _loading = false;
  String _errorMsg = '';

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── EMAIL AUTH ──
  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = '⚠️ Enter email and password!');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorMsg = '⚠️ Password must be at least 6 characters!');
      return;
    }
    setState(() { _loading = true; _errorMsg = ''; });

    try {
      if (_isSignIn) {
        await SupabaseService.signInWithEmail(email, pass);
      } else {
        final res = await SupabaseService.signUpWithEmail(email, pass);
        if (res.session == null) {
          setState(() {
            _loading = false;
            _errorMsg = '✅ Verification email sent! Check your inbox.';
          });
          return;
        }
      }
      // Başarılı giriş → auth state change ile halledilir
    } catch (e) {
      final msg = e.toString();
      String friendly = '❌ $msg';
      if (msg.contains('Invalid login credentials')) friendly = '❌ Wrong email or password!';
      if (msg.contains('already registered')) friendly = '❌ This email is already registered!';
      setState(() { _errorMsg = friendly; _loading = false; });
    }
  }

  // ── OAUTH ──
  Future<void> _oauth(OAuthProvider provider) async {
    setState(() { _loading = true; _errorMsg = ''; });
    try {
      await SupabaseService.signInWithOAuth(provider);
    } catch (e) {
      setState(() { _errorMsg = '❌ ${provider.name} error: $e'; _loading = false; });
    }
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
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Başlık
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Colors.white, AppTheme.accent3],
                    ).createShader(b),
                    child: const Text(
                      '🎛️ UserLooperGen',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Hata mesajı
                  if (_errorMsg.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _errorMsg,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: _errorMsg.startsWith('✅')
                              ? const Color(0xFF22C55E)
                              : AppTheme.danger,
                        ),
                      ),
                    ),

                  // Google
                  _OAuthButton(
                    color: Colors.white,
                    textColor: const Color(0xFF333333),
                    onTap: () => _oauth(OAuthProvider.google),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _googleIcon(),
                        const SizedBox(width: 8),
                        const Text('Continue with Google',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF333333))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Microsoft
                  _OAuthButton(
                    color: const Color(0xFF2F2F2F),
                    textColor: Colors.white,
                    onTap: () => _oauth(OAuthProvider.azure),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _microsoftIcon(),
                        const SizedBox(width: 8),
                        const Text('Continue with Microsoft',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Discord
                  _OAuthButton(
                    color: const Color(0xFF5865F2),
                    textColor: Colors.white,
                    onTap: () => _oauth(OAuthProvider.discord),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _discordIcon(),
                        const SizedBox(width: 8),
                        const Text('Continue with Discord',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // GitHub
                  _OAuthButton(
                    color: const Color(0xFF24292E),
                    textColor: Colors.white,
                    onTap: () => _oauth(OAuthProvider.github),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _githubIcon(),
                        const SizedBox(width: 8),
                        const Text('Continue with GitHub',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ayırıcı
                  Row(children: [
                    const Expanded(child: Divider(color: AppTheme.border)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or continue with email',
                        style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                    ),
                    const Expanded(child: Divider(color: AppTheme.border)),
                  ]),

                  const SizedBox(height: 16),

                  // Sign In / Sign Up tabs
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(children: [
                      _AuthTab(label: 'Sign In', active: _isSignIn,
                        onTap: () => setState(() => _isSignIn = true)),
                      _AuthTab(label: 'Sign Up', active: !_isSignIn,
                        onTap: () => setState(() => _isSignIn = false)),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  // Email input
                  _AuthInput(
                    controller: _emailCtrl,
                    hint: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 10),

                  // Password input
                  _AuthInput(
                    controller: _passCtrl,
                    hint: 'Password (min. 6 characters)',
                    obscure: true,
                  ),

                  const SizedBox(height: 12),

                  // Submit butonu
                  GestureDetector(
                    onTap: _loading ? null : _submitEmail,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accent, AppTheme.accent2],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isSignIn ? 'Sign In' : 'Sign Up',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Guest geç
                  GestureDetector(
                    onTap: widget.onSkip,
                    child: const Text(
                      'Continue as guest, not now →',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── SVG İKONLAR ──
  Widget _googleIcon() => const SizedBox(
    width: 18, height: 18,
    child: CustomPaint(painter: _GooglePainter()),
  );

  Widget _microsoftIcon() => SizedBox(
    width: 18, height: 18,
    child: GridView.count(
      crossAxisCount: 2, crossAxisSpacing: 1, mainAxisSpacing: 1,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container(color: const Color(0xFFF25022)),
        Container(color: const Color(0xFF7FBA00)),
        Container(color: const Color(0xFF00A4EF)),
        Container(color: const Color(0xFFFFB900)),
      ],
    ),
  );

  Widget _discordIcon() => const Icon(Icons.discord, color: Colors.white, size: 18);

  Widget _githubIcon() => const Icon(Icons.code, color: Colors.white, size: 18);
}

// ── YARDIMCI WİDGET'LAR ──
class _OAuthButton extends StatelessWidget {
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final Widget child;
  const _OAuthButton({
    required this.color, required this.textColor,
    required this.onTap, required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: color == Colors.white ? Border.all(color: const Color(0xFFDDDDDD)) : null,
        ),
        child: child,
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _AuthTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  const _AuthInput({
    required this.controller, required this.hint,
    this.obscure = false, this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.muted),
        filled: true,
        fillColor: AppTheme.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// Google logo painter
class _GooglePainter extends CustomPainter {
  const _GooglePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    // Basitleştirilmiş Google G
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), -0.5, 2.3, true, paint);
    paint.color = Colors.white;
    canvas.drawOval(Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.6,
      height: size.height * 0.6,
    ), paint);
  }
  @override
  bool shouldRepaint(_) => false;
}
