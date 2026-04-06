import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/ward_model.dart';
import '../../core/constants/supabase_config.dart';
import '../../core/utils/backend_config.dart';

/// Repository for admin operations
class AdminRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  void _log(String message) {
    if (kDebugMode) {
      print('[AdminRepository] $message');
    }
  }

  /// Get all users (admin only) using service role to bypass RLS
  Future<List<UserModel>> getAllUsers() async {
    try {
      _log('Fetching all users using service role...');
      final response = await http.get(
        Uri.parse(
            '${SupabaseConfig.url}/rest/v1/profiles?select=*&order=full_name.asc'),
        headers: {
          'apikey': SupabaseConfig.serviceRoleKey,
          'Authorization': 'Bearer ${SupabaseConfig.serviceRoleKey}',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch users: ${response.body}');
      }

      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      _log('Error in getAllUsers: $e');
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Provision new user directly via Supabase Auth REST API
  ///
  /// Returns the created user and temporary password
  Future<({UserModel user, String tempPassword})> provisionUser({
    required String email,
    required String fullName,
    String? workId,
    required String role,
    String? unit,
    String? licenseNo,
    DateTime? licenseExpiryDate,
  }) async {
    try {
      _log('Provisioning new user: $email');

      // Check if email already exists
      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existing != null) {
        _log('User already exists with email: $email');
        throw Exception('A user with this email already exists');
      }

      // Format role to match database constraints (e.g., social_staff, medical_head)
      String effectiveRole = role;
      if (unit != null &&
          (role == 'staff' || role == 'head' || role == 'center_doctor')) {
        effectiveRole = '${unit}_$role';
      }

      // Generate a simple temporary password (easy to type on mobile)
      final tempPassword = 'Welcome123!';
      _log('Creating auth user via Admin API...');

      // Call Supabase Admin API to create user (using service role key)
      final response = await http
          .post(
            Uri.parse('${SupabaseConfig.url}/auth/v1/admin/users'),
            headers: {
              'Content-Type': 'application/json',
              'apikey': SupabaseConfig.serviceRoleKey,
              'Authorization': 'Bearer ${SupabaseConfig.serviceRoleKey}',
            },
            body: jsonEncode({
              'email': email,
              'password': tempPassword,
              'email_confirm': true, // Auto-confirm email
              'user_metadata': {
                'full_name': fullName,
                'work_id': workId,
                'role': effectiveRole,
                'unit': unit,
                'license_no': licenseNo,
                'license_expiry_date': licenseExpiryDate?.toIso8601String(),
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      final authData = jsonDecode(response.body) as Map<String, dynamic>;
      _log('Auth API response status: ${response.statusCode}');

      // Check for errors
      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorMsg = authData['msg'] ??
            authData['error_description'] ??
            authData['message'] ??
            authData['error'] ??
            'Failed to create user (${response.statusCode})';
        _log('Auth API error: $errorMsg');
        throw Exception(errorMsg);
      }

      final userId = authData['id'] as String;
      _log('Auth user created with ID: $userId');

      // Update the profile with role and unit using service role key (bypasses RLS)
      await Future.delayed(
          const Duration(milliseconds: 500)); // Wait for trigger
      _log('Upserting profile for user: $userId');

      final profileUpdateResponse = await http
          .post(
            Uri.parse('${SupabaseConfig.url}/rest/v1/profiles'),
            headers: {
              'Content-Type': 'application/json',
              'apikey': SupabaseConfig.serviceRoleKey,
              'Authorization': 'Bearer ${SupabaseConfig.serviceRoleKey}',
              'Prefer': 'resolution=merge-duplicates,return=representation',
            },
            body: jsonEncode({
              'id': userId,
              'email': email,
              'full_name': fullName,
              'work_id': workId,
              'role': effectiveRole,
              'unit': unit,
              'license_no': licenseNo,
              'license_expiry_date': licenseExpiryDate?.toIso8601String(),
              'is_active': true,
              'profile_completed': false,
            }),
          )
          .timeout(const Duration(seconds: 15));

      _log('Profile upsert response: ${profileUpdateResponse.statusCode}');
      if (profileUpdateResponse.statusCode != 200 &&
          profileUpdateResponse.statusCode != 201) {
        _log('Profile update error: ${profileUpdateResponse.body}');
        throw Exception(
            'User created in Auth, but failed to create Profile: ${profileUpdateResponse.body}');
      }

      // Fetch the created user profile using service role
      final profileGetResponse = await http.get(
        Uri.parse(
            '${SupabaseConfig.url}/rest/v1/profiles?id=eq.$userId&select=*'),
        headers: {
          'apikey': SupabaseConfig.serviceRoleKey,
          'Authorization': 'Bearer ${SupabaseConfig.serviceRoleKey}',
        },
      ).timeout(const Duration(seconds: 10));

      final profiles = jsonDecode(profileGetResponse.body) as List;
      final profileData = profiles.isNotEmpty
          ? profiles.first as Map<String, dynamic>
          : {
              'id': userId,
              'email': email,
              'full_name': fullName,
              'work_id': workId,
              'role': effectiveRole,
              'unit': unit,
              'license_expiry_date': licenseExpiryDate?.toIso8601String(),
              'is_active': true,
            };

      _log('User provisioned successfully: $email');

      // Log action (non-blocking)
      logAction(
        action: 'Create User',
        details: 'Created user $email ($fullName) with role $role',
      );

      // Notify Super Admin (non-blocking)
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        createNotification(
          userId: currentUser.id,
          type: 'system_alert',
          title: 'User Provisioned',
          message: 'Successfully created account for $fullName ($role).',
          metadata: {'user_id': userId, 'email': email},
        );
      }

      return (
        user: UserModel.fromJson(profileData),
        tempPassword: tempPassword,
      );
    } catch (e) {
      _log('Failed to provision user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update an existing user's profile
  Future<UserModel> updateUserProfile({
    required String userId,
    required String fullName,
    String? workId,
    required String role,
    String? unit,
    String? licenseNo,
    DateTime? licenseExpiryDate,
  }) async {
    try {
      _log('Updating user profile via Admin REST API: $userId');

      // Format role to match database constraints (e.g., social_staff, medical_head)
      String effectiveRole = role;
      if (unit != null &&
          (role == 'staff' || role == 'head' || role == 'center_doctor')) {
        effectiveRole = '${unit}_$role';
      }

      final body = {
        'full_name': fullName,
        'work_id': workId,
        'role': effectiveRole,
        'unit': unit,
        'license_no': licenseNo,
        'license_expiry_date': licenseExpiryDate?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await http
          .patch(
            Uri.parse('${SupabaseConfig.url}/rest/v1/profiles?id=eq.$userId'),
            headers: {
              'Content-Type': 'application/json',
              'apikey': SupabaseConfig.serviceRoleKey,
              'Authorization': 'Bearer ${SupabaseConfig.serviceRoleKey}',
              'Prefer': 'return=representation',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        _log(
            'Profile update failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update user profile: ${response.body}');
      }

      final updatedData = jsonDecode(response.body) as List;
      if (updatedData.isEmpty) {
        throw Exception('User profile not found or update failed');
      }

      // Log action (non-blocking)
      logAction(
        action: 'Update User',
        details: 'Updated profile for user $userId',
      );

      return UserModel.fromJson(updatedData.first);
    } catch (e) {
      _log('Error updating profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Deactivate user
  Future<void> deactivateUser(String userId) async {
    try {
      final resolvedUrl = await BackendConfig.getBackendUrl();
      final url = Uri.parse('$resolvedUrl/deactivate-user');
      print('Calling Deactivate URL: $url');

      // Use Backend API (Service Role)
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'status': 'inactive',
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Deactivate Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Backend Deactivation failed: ${response.body}');
      }

      // Non-blocking log
      logAction(
        action: 'Deactivate User',
        details: 'Deactivated user $userId',
      );
    } catch (e) {
      print('Deactivation Error: $e');
      throw Exception('Failed to deactivate user: $e');
    }
  }

  /// Reactivate user
  Future<void> reactivateUser(String userId) async {
    try {
      final resolvedUrl = await BackendConfig.getBackendUrl();
      final url = Uri.parse('$resolvedUrl/reactivate-user');
      print('Calling Reactivate URL: $url');

      // Use Backend API (Service Role)
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'admin_id': _supabase.auth.currentUser?.id,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Reactivate Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Backend Reactivation failed: ${response.body}');
      }

      // Non-blocking log
      logAction(
        action: 'Reactivate User',
        details: 'Reactivated user $userId',
      );
    } catch (e) {
      throw Exception('Failed to reactivate user: $e');
    }
  }

  /// Update user role
  Future<UserModel> updateUserRole({
    required String userId,
    required String role,
    String? unit,
  }) async {
    try {
      final response = await _supabase
          .from('profiles')
          .update({
            'role': role,
            'unit': unit,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Get all wards
  Future<List<WardModel>> getAllWards() async {
    try {
      final response = await _supabase
          .from('wards')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true)
          .timeout(const Duration(seconds: 15));

      return response.map((json) => WardModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch wards: $e');
    }
  }

  /// Get Houseparents (Homelife Unit)
  Future<List<UserModel>> getHouseparents() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('unit', 'homelife')
          .eq('is_active', true)
          .order('full_name', ascending: true)
          .timeout(const Duration(seconds: 15));

      return response.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch houseparents: $e');
    }
  }

  /// Get Social Workers (Social Service Unit)
  Future<List<UserModel>> getSocialWorkers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('unit', 'social')
          .eq('is_active', true)
          .order('full_name', ascending: true)
          .timeout(const Duration(seconds: 15));

      return response.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch social workers: $e');
    }
  }

  /// Create ward
  Future<WardModel> createWard({
    required String name,
    String? description,
    String? nfcTagId,
    int? capacity,
    String? floor,
    String? building,
  }) async {
    try {
      final response = await _supabase
          .from('wards')
          .insert({
            'name': name,
            'description': description,
            'nfc_tag_id': nfcTagId,
            'capacity': capacity ?? 0,
            'floor': floor,
            'building': building,
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 15));

      // Non-blocking log
      logAction(
        action: 'Create Ward',
        details: 'Created ward $name',
      );

      return WardModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create ward: $e');
    }
  }

  /// Update ward
  Future<WardModel> updateWard({
    required String id,
    String? name,
    String? description,
    String? nfcTagId,
    int? capacity,
    String? floor,
    String? building,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (nfcTagId != null) updates['nfc_tag_id'] = nfcTagId;
      if (capacity != null) updates['capacity'] = capacity;
      if (floor != null) updates['floor'] = floor;
      if (building != null) updates['building'] = building;

      final response = await _supabase
          .from('wards')
          .update(updates)
          .eq('id', id)
          .select()
          .single()
          .timeout(const Duration(seconds: 15));

      // Non-blocking log
      logAction(
        action: 'Update Ward',
        details: 'Updated ward $id',
      );

      return WardModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update ward: $e');
    }
  }

  /// Assign NFC tag to ward
  Future<WardModel> assignNfcTag({
    required String wardId,
    required String nfcTagId,
  }) async {
    try {
      // Check if NFC tag is already assigned to another ward
      // Use secure RPC function to bypass RLS for staff
      final response = await _supabase
          .rpc('assign_ward_nfc', params: {
            'ward_id_input': wardId,
            'nfc_tag_id_input': nfcTagId,
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 15));

      return WardModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('already assigned')) {
        throw Exception('This NFC tag is already assigned to another ward');
      }
      throw Exception('Failed to assign NFC tag: $e');
    }
  }

  /// Delete ward (soft delete)
  Future<void> deleteWard(String id) async {
    try {
      await _supabase
          .from('wards')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .timeout(const Duration(seconds: 15));

      // Non-blocking log
      logAction(
        action: 'Delete Ward',
        details: 'Deleted/Deactivated ward $id',
      );
    } catch (e) {
      throw Exception('Failed to delete ward: $e');
    }
  }

  /// Get audit logs
  Future<List<Map<String, dynamic>>> getAuditLogs({
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      final response = await _supabase
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1)
          .timeout(const Duration(seconds: 15));

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch audit logs: $e');
    }
  }

  /// Get facility statistics
  Future<Map<String, dynamic>> getFacilityStats() async {
    final stats = {
      'total_residents': 0,
      'total_wards': 0,
      'total_users': 0,
      'pending_forms': 0,
    };

    try {
      _log('Fetching facility statistics...');

      // Helper to fetch count for a table with a filter
      Future<int> getCount(String table,
          {String? column, dynamic value}) async {
        try {
          // Use a simpler approach that is less likely to have type issues
          final response = await _supabase
              .from(table)
              .select('id')
              .eq(column ?? 'is_active', value ?? true)
              .limit(1)
              .count(CountOption.exact)
              .timeout(const Duration(seconds: 5));

          return response.count;
        } catch (e) {
          _log('Error fetching count for $table: $e');
          return 0;
        }
      }

      final results = await Future.wait([
        getCount('residents', column: 'is_active', value: true),
        getCount('wards', column: 'is_active', value: true),
        getCount('profiles', column: 'is_active', value: true),
        getCount('form_submissions', column: 'status', value: 'pending_review'),
      ]);

      stats['total_residents'] = results[0];
      stats['total_wards'] = results[1];
      stats['total_users'] = results[2];
      stats['pending_forms'] = results[3];

      _log('getFacilityStats: Final Results: $stats');
      return stats;
    } catch (e) {
      _log('Unexpected error in getFacilityStats: $e');
      return stats; // Return whatever we have (even if all zeros) to avoid hanging the UI
    }
  }

  /// Log an action to audit logs
  Future<void> logAction({
    required String action,
    required String details,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('audit_logs').insert({
        'user_id': user.id,
        'user_email': user.email,
        'action': action,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Don't fail the operation if logging fails, just log to console
      _log('Failed to create audit log: $e');
    }
  }

  /// Create a notification
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (userId.isEmpty) return;

      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'metadata': metadata ?? {},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _log('Failed to create notification: $e');
    }
  }
}
