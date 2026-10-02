/// Public (client-safe) Supabase settings. The publishable key is designed to
/// ship inside the app; row-level security is what protects the data.
/// Override per build with --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tcvldfsydgxxfdyrwspv.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_U1z5ZX785c7JtlVlsEudSw_esh8giFR',
  );

  /// OAuth client ids for native Google sign-in (see docs/SUPABASE_SETUP.md).
  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// Deep link used by password-reset / email-confirmation emails (mobile).
  static const authRedirect = 'com.fitbudpk.fitbud://login-callback/';

  static const profileBucket = 'avatars';
  static const chatBucket = 'chat-media';
}
