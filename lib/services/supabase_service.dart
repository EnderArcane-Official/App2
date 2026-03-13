import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String url = 'https://murolvpildiiexpemlyb.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11cm9sdnBpbGRpaWV4cGVtbHliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwODI1MjUsImV4cCI6MjA4ODY1ODUyNX0.iNxTGX_MUs5yZz0fkef8JletpKw3rgyj4IWA93Tcj5Y';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static User? get currentUser => client.auth.currentUser;
  static Stream<AuthState> get authStream => client.auth.onAuthStateChange;

  // Deep link — android/ios manifest'e de eklenmeli
  static const String redirectUrl = 'io.enderarcane.userloopergen://auth-callback';

  static Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
      queryParams: {'access_type': 'offline', 'prompt': 'consent'},
    );
  }

  static Future<void> signInWithDiscord() async {
    await client.auth.signInWithOAuth(OAuthProvider.discord, redirectTo: redirectUrl);
  }

  static Future<void> signInWithGithub() async {
    await client.auth.signInWithOAuth(OAuthProvider.github, redirectTo: redirectUrl);
  }

  static Future<AuthResponse> signInWithEmail(String email, String pass) async {
    return await client.auth.signInWithPassword(email: email, password: pass);
  }

  static Future<AuthResponse> signUpWithEmail(String email, String pass) async {
    return await client.auth.signUp(email: email, password: pass);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final res = await client.from('profiles').select().eq('id', userId).single();
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isUsernameTaken(String username) async {
    try {
      await client.from('profiles').select('id').eq('username', username).single();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> createProfile(String userId, String username) async {
    await client.from('profiles').insert({'id': userId, 'username': username, 'role': 'user'});
  }

  static Future<void> updateDisplayName(String name) async {
    await client.auth.updateUser(UserAttributes(data: {'display_name': name}));
  }
}
