import 'package:supabase_flutter/supabase_flutter.dart';

/// Central override point for the Supabase client (mirrors the old
/// FirebaseInstances). Everything reads the client through here.
class SupabaseInstances {
  static SupabaseClient? _override;
  static SupabaseClient get client => _override ?? Supabase.instance.client;
  static set client(SupabaseClient c) => _override = c;

  static GoTrueClient get auth => client.auth;
  static String? get uid => client.auth.currentUser?.id;
}
