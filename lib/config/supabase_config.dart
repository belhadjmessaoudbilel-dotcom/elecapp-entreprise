import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const _url     = 'https://xeumwptdojngpkcbkbwh.supabase.co';
  static const _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhldW13cHRkb2puZ3BrY2JrYndoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1NjgzMTQsImV4cCI6MjA5NTE0NDMxNH0.0kNh550ubPTu_ewC-9nyn3SFBJaAZtcwkmY7T22rNYA';

  static String get url     => dotenv.env['SUPABASE_URL']?.isNotEmpty     == true ? dotenv.env['SUPABASE_URL']!     : _url;
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty == true ? dotenv.env['SUPABASE_ANON_KEY']! : _anonKey;
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}
