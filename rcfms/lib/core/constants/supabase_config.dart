/// Supabase configuration constants
/// Replace these with your actual Supabase project credentials
class SupabaseConfig {
  SupabaseConfig._();

  /// Your Supabase project URL
  /// Your Supabase project URL
  /// Your Supabase project URL
  /// Format: https://[project-ref].supabase.co
  static const String url = 'https://xkurkaykkywfslakemez.supabase.co';

  /// Your Supabase anon/public key
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhrdXJrYXlra3l3ZnNsYWtlbWV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4MzQxNjEsImV4cCI6MjA4NDQxMDE2MX0.oWHoKHrerTdYqGbzEFKYDCCLNyJxVCiWz_qRu0xzARI';

  /// Service role key for admin operations (DEVELOPMENT ONLY!)
  /// WARNING: Never expose this in production apps!
  static const String serviceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhrdXJrYXlra3l3ZnNsYWtlbWV6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODgzNDE2MSwiZXhwIjoyMDg0NDEwMTYxfQ.qrV6ywXNfqfvR2iWTUMw0r-rLzFq7Abf1ArdcD7ECS0';

  /// Backend API URL for admin operations
  // For deployment: 'https://eldercare-rcfms-v2.onrender.com/api'
  // For local dev: 'http://127.0.0.1:5000/api'
  static const String backendUrl = 'http://127.0.0.1:5000/api';

  /// Storage bucket names
  static const String signaturesBucket = 'signatures';
  static const String residentPhotosBucket = 'resident_photos';
  static const String avatarsBucket = 'avatars';
  static const String documentsBucket = 'documents';
}
