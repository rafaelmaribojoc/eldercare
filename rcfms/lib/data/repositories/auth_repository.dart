import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user_model.dart';
import '../../core/constants/supabase_config.dart';
import '../../core/utils/backend_config.dart';

/// Repository for authentication operations
class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  void _log(String message) {
    if (kDebugMode) {
      print('[AuthRepository] $message');
    }
  }

  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _log('Attempting login for: $email');

      // 0. Pre-check internet connection
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _log('Network check failed: No connection available.');
        throw const SocketException('No internet connection');
      }

      // 1. Pre-check if account is active BEFORE signing in to prevent session race
      try {
        final profileResponse = await _supabase
            .from('profiles')
            .select('is_active')
            .eq('email', email)
            .maybeSingle();

        if (profileResponse != null && profileResponse['is_active'] == false) {
          _log('User is inactive (pre-check). Blocking login attempt.');
          throw Exception(
              'Your account is inactive. Please contact your administrator.');
        }
      } catch (e) {
        // If it's our "inactive" exception, rethrow it
        if (e.toString().contains('inactive')) rethrow;
        // Otherwise ignore database errors during pre-check (e.g. if user doesn't exist yet)
        _log('Pre-check skipped or failed: $e');
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _log(
          'Auth response received - User ID: ${response.user?.id}, Session: ${response.session != null}');

      if (response.user == null) {
        throw Exception('Login failed. Please check your credentials.');
      }

      // Fetch user profile - may need to be created if trigger didn't work
      _log('Fetching profile for user: ${response.user!.id}');
      UserModel profile;
      try {
        profile = await getUserProfile(response.user!.id);
        _log('Profile fetched successfully: ${profile.email}');
      } catch (e) {
        _log('Profile not found, attempting to create one: $e');
        // Profile doesn't exist - create it from auth user metadata
        profile = await _createProfileFromAuthUser(response.user!);
        _log('Profile created successfully');
      }
      if (!profile.isActive) {
        _log('User account is inactive. Signing out...');
        await signOut();
        throw Exception(
            'Your account is inactive. Please contact your administrator.');
      }

      return profile;
    } on AuthException catch (e) {
      _log('AuthException: ${e.message}');
      throw Exception(e.message);
    } on PostgrestException catch (e) {
      _log('PostgrestException: code=${e.code}, message=${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      _log('General error during sign in: $e');
      throw Exception('An error occurred during sign in: $e');
    }
  }

  /// Trigger backend login notification
  Future<void> triggerLoginNotification(String userId, String email) async {
    final resolvedUrl = await BackendConfig.getBackendUrl();
    final backendUrl = '$resolvedUrl/notify-login';
    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'email': email,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Backend returned ${response.statusCode}: ${response.body}');
      }
      _log('Login notification trigger sent successfully');
    } catch (e) {
      // Fire and forget, but log error
      _log('Failed to trigger login notification: $e');
      // preventing rethrow to not block login flow
    }
  }

  /// Create profile from auth user if trigger didn't work
  Future<UserModel> _createProfileFromAuthUser(User authUser) async {
    _log('Creating profile from auth user metadata');
    final metadata = authUser.userMetadata ?? {};

    final profileData = {
      'id': authUser.id,
      'email': authUser.email ?? '',
      'full_name': metadata['full_name'] ?? 'New User',
      'work_id': metadata['work_id'] ?? 'TEMP-${authUser.id.substring(0, 8)}',
      'role': metadata['role'] ?? 'social_staff',
      'unit': metadata['unit'],
      'is_active': true,
    };

    try {
      await _supabase.from('profiles').upsert(profileData);
      _log('Profile upserted successfully');
      return UserModel.fromJson(profileData);
    } catch (e) {
      _log('Failed to create profile: $e');
      // Return a temporary model if upsert fails
      return UserModel.fromJson(profileData);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    _log('Signing out user...');
    try {
      await _supabase.auth.signOut();
      _log('Sign out successful');
    } catch (e) {
      _log('Sign out error: $e');
      // Force clear session even on error
      rethrow;
    }
  }

  /// Get user profile from profiles table
  Future<UserModel> getUserProfile(String userId) async {
    try {
      _log('Fetching profile for userId: $userId');

      // First try by ID
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _log('Profile found by ID');
        return UserModel.fromJson(response);
      }

      // If not found by ID, try by email from auth user
      final authUser = _supabase.auth.currentUser;
      if (authUser?.email != null) {
        _log('Profile not found by ID, trying by email: ${authUser!.email}');
        final emailResponse = await _supabase
            .from('profiles')
            .select()
            .eq('email', authUser.email!)
            .maybeSingle();

        if (emailResponse != null) {
          _log('Profile found by email');
          return UserModel.fromJson(emailResponse);
        }

        // No profile found but user is authenticated - create profile using existing method
        _log('No profile found, creating one for authenticated user');
        return _createProfileFromAuthUser(authUser);
      }

      // No profile found and no auth user email
      _log('No profile found for user');
      throw Exception('Profile not found. Please contact administrator.');
    } on PostgrestException catch (e) {
      _log(
          'PostgrestException - code: ${e.code}, message: ${e.message}, details: ${e.details}, hint: ${e.hint}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      _log('General error in getUserProfile: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    required String userId,
    String? username,
    String? title,
    String? nfcCardId,
    String? licenseNo,
    DateTime? licenseExpiryDate,
    String? avatarUrl,
    bool? profileCompleted,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (username != null) {
        updates['username'] = username.isEmpty ? null : username;
      }
      if (title != null) {
        updates['title'] = title.isEmpty ? null : title; // Added
      }
      if (nfcCardId != null) {
        updates['nfc_card_id'] = nfcCardId.isEmpty ? null : nfcCardId;
      }
      if (licenseNo != null) {
        updates['license_no'] = licenseNo.isEmpty ? null : licenseNo;
      }
      if (licenseExpiryDate != null) {
        updates['license_expiry_date'] = licenseExpiryDate.toIso8601String();
      }
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (profileCompleted != null) {
        updates['profile_completed'] = profileCompleted;
      }

      await _supabase.from('profiles').update(updates).eq('id', userId);

      return getUserProfile(userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Upload signature
  Future<String> uploadSignature({
    required String userId,
    required Uint8List signatureBytes,
  }) async {
    try {
      final fileName = '$userId/signature.png';

      await _supabase.storage
          .from(SupabaseConfig.signaturesBucket)
          .uploadBinary(
            fileName,
            signatureBytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );

      final signatureUrl = _supabase.storage
          .from(SupabaseConfig.signaturesBucket)
          .getPublicUrl(fileName);

      // Update profile with signature URL
      await _supabase.from('profiles').update({
        'signature_url': signatureUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return signatureUrl;
    } catch (e) {
      throw Exception('Failed to upload signature: $e');
    }
  }

  /// Upload avatar
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
    required String extension,
  }) async {
    try {
      final fileName = '$userId/avatar.$extension';

      // Map extension to MIME type safely
      final mimeType = switch (extension.toLowerCase()) {
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg', // Default fallback
      };

      await _supabase.storage.from(SupabaseConfig.avatarsBucket).uploadBinary(
            fileName,
            imageBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      final avatarUrl = _supabase.storage
          .from(SupabaseConfig.avatarsBucket)
          .getPublicUrl(fileName);

      // Add a timestamp to the URL to bust cache
      final timestampedUrl =
          '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Update profile with avatar URL
      await _supabase.from('profiles').update({
        'avatar_url': timestampedUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return timestampedUrl;
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  /// Check if current user has a signature
  Future<bool> hasSignature() async {
    final userId = currentUserId;
    if (userId == null) return false;

    final profile = await getUserProfile(userId);
    return profile.signatureUrl != null && profile.signatureUrl!.isNotEmpty;
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) return null;

    return getUserProfile(userId);
  }

  /// Get user profile by NFC Card ID (For Tap-to-Login/Sign)
  /// Get user profile by NFC Card ID (For Tap-to-Login/Identify)
  /// Uses secure RPC to allow unauthenticated lookup of minimal info
  Future<Map<String, dynamic>?> getUserByNfc(String nfcCardId) async {
    try {
      final response = await _supabase.rpc('get_user_by_nfc_id', params: {
        'nfc_id_input': nfcCardId,
      }).maybeSingle();

      if (response == null) return null;

      return response;
    } catch (e) {
      _log('Failed to fetch user by NFC: $e');
      return null;
    }
  }

  /// Unlink NFC card from user profile
  Future<void> unlinkNfc(String userId) async {
    try {
      await _supabase.from('profiles').update({
        'nfc_card_id': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to unlink NFC card: $e');
    }
  }
}
