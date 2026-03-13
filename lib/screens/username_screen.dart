import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class UsernameScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onDone;
  const UsernameScreen({super.key, required this.userId, required this.onDone});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _ctrl = TextEditingController();
  String _msg = '';
  bool _loading = false;
  bool _success = false;

  Future<void> _save() async {
    final input = _ctrl.text.trim();
    final pattern = RegExp(r'^[a-zA-Z0-9_\-]{3,20}$');
    if (!pattern.hasMatch(input)) {
      setState(() => _msg = '⚠️ 3-20 chars, only letters/numbers/_ and - allowed!');
      return;
    }
    setState(() { _loading = true; _msg = '⏳ Checking...'; });

    final taken = await SupabaseService.isUsernameTaken(input);
    if (taken) {
      setState(() { _loading = false; _msg = '❌ This username is already taken!'; });
      return;
    }

    try {
      await SupabaseService.createProfile(widget.userId, input);
      setState(() { _success = true; _msg = '✅ Welcome, @$input!'; });
      await Future.delayed(const Duration(milliseconds: 800));
      widget.onDone();
    } catch (e) {
      setState(() { _loading = false; _msg = '❌ Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('👤', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  const Text(
                    'Choose a Username',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textColor),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '3-20 characters. Letters, numbers, _ and - only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.muted),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: AppTheme.textColor),
                    decoration: InputDecoration(
                      hintText: 'your_username',
                      hintStyle: const TextStyle(color: AppTheme.muted),
                      prefixText: '@',
                      prefixStyle: const TextStyle(color: AppTheme.accent2),
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_msg.isNotEmpty)
                    Text(
                      _msg,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _success ? const Color(0xFF22C55E)
                            : _msg.startsWith('⏳') ? AppTheme.muted
                            : AppTheme.danger,
                      ),
                    ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _loading ? null : _save,
                    child: Container(
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
                                ))
                            : const Text('Save Username',
                                style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                )),
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
}
