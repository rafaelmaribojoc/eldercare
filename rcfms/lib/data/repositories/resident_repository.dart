import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resident_model.dart';
import '../models/ward_model.dart';
import '../../core/constants/supabase_config.dart';
import '../../core/constants/app_constants.dart';
import 'approval_repository.dart';

/// Repository for resident operations
class ResidentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  void _log(String message) {
    if (kDebugMode) {
      print('[ResidentRepository] $message');
    }
  }

  /// Get all residents
  /// [status] filter by status (default is 'active' which maps to 'admitted' in new schema for now, or we can explicit pass status)
  Future<List<ResidentModel>> getResidents({
    String? wardId,
    String? searchQuery,
    String? status, // 'admitted', 'pre_admission', etc.
    List<String>? statuses, // List of statuses to include
    // New Filters
    String? sortOrder, // 'name_asc', 'name_desc', 'date_newest', 'date_oldest'
    String? gender,
    int? minAge,
    int? maxAge,
    String? caseCategory,
    DateTime? startDate,
    DateTime? endDate,
    int page = 0,
    int pageSize = AppConstants.defaultPageSize,
    String? houseparentId, // Added for Homelife staff filtering
    String? socialWorkerId, // Added for Social Service staff filtering
  }) async {
    try {
      _log(
          'Fetching residents - filters: ward=$wardId, status=$status, houseParent=$houseparentId, socialWorker=$socialWorkerId');

      // Use dynamic to allow changing from FilterBuilder to TransformBuilder (ordering)
      // Join profiles table to get houseparent name using the houseparent_id FK
      // Join profiles table to get houseparent and social worker names
      dynamic query = _supabase.from('residents').select(
          '*, ward:wards(name), houseparent:profiles!houseparent_id(full_name), social_worker:profiles!social_worker_id(full_name)');

      // If we are specifically looking for discharged residents, ignore is_active flag (as they are inactive)
      bool includeInactive = false;
      if (status == 'discharged' || status == 'deceased') {
        includeInactive = true;
      }
      if (statuses != null &&
          (statuses.contains('discharged') || statuses.contains('deceased'))) {
        includeInactive = true;
      }

      if (!includeInactive) {
        query = query.eq('is_active', true);
      }

      // Status
      if (statuses != null && statuses.isNotEmpty) {
        query = query.filter('status', 'in', statuses);
      } else if (status != null && status != 'All') {
        query = query.eq('status', status);
      } else if (status == null && statuses == null) {
        // Default behavior if nothing specified: show admitted
        query = query.eq('status', 'admitted');
      }

      // Ward
      if (wardId != null && wardId != 'All') {
        query = query.eq('ward_id', wardId);
      }

      // Gender
      if (gender != null && gender != 'All') {
        query = query.eq('gender', gender.toLowerCase());
      }

      if (caseCategory != null && caseCategory != 'All') {
        query = query.eq('case_category', caseCategory);
      }

      // Houseparent Filter
      if (houseparentId != null) {
        query = query.eq('houseparent_id', houseparentId);
      }

      // Social Worker Filter
      if (socialWorkerId != null) {
        query = query.eq('social_worker_id', socialWorkerId);
      }

      // Date Range (Admission or Application depending on type?)
      // Let's assume Admission Date for general list, Application Date for pre-admission is tricky if mixed.
      // Ideally we filter based on the relevant date field.
      // If status is pre_admission, use application_date. Else admission_date.
      // For generic filter, maybe just check admission_date for now as it's the main one.
      if (startDate != null && endDate != null) {
        final start = startDate.toIso8601String().split('T').first;
        final end = endDate.toIso8601String().split('T').first;
        query = query.gte('admission_date', start).lte('admission_date', end);
      }

      // Search
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Search across: First Name, Last Name, Middle Name, Case Number
        query = query.or(
          'first_name.ilike.%$searchQuery%,last_name.ilike.%$searchQuery%,middle_name.ilike.%$searchQuery%,case_number.ilike.%$searchQuery%',
        );
      }

      // Age Filter (This is tricky in SQL directly without computed column)
      // We can calculate birthdate range from age
      if (minAge != null || maxAge != null) {
        final now = DateTime.now();
        if (maxAge != null) {
          final maxBirthDateForGroup =
              DateTime(now.year - maxAge, now.month, now.day);
          query = query.gte(
              'date_of_birth', maxBirthDateForGroup.toIso8601String());
        }

        if (minAge != null) {
          final minBirthDateForGroup =
              DateTime(now.year - minAge, now.month, now.day);
          query = query.lte(
              'date_of_birth', minBirthDateForGroup.toIso8601String());
        }
      }

      // Sorting
      if (sortOrder != null) {
        switch (sortOrder) {
          case 'name_desc':
            // Explicitly "Last Name (Z-A)"
            query = query
                .order('last_name', ascending: false)
                .order('first_name', ascending: false);
            break;
          case 'first_name_asc':
            query = query
                .order('first_name', ascending: true)
                .order('last_name', ascending: true);
            break;
          case 'first_name_desc':
            query = query
                .order('first_name', ascending: false)
                .order('last_name', ascending: false);
            break;
          case 'date_newest':
            // Priority: Admission -> Application -> Created
            query = query
                .order('admission_date', ascending: false, nullsFirst: false)
                .order('created_at', ascending: false);
            break;
          case 'date_oldest':
            query = query
                .order('admission_date', ascending: true, nullsFirst: true)
                .order('created_at', ascending: true);
            break;
          case 'name_asc':
          default:
            query = query
                .order('last_name', ascending: true)
                .order('first_name', ascending: true);
            break;
        }
      } else {
        // Default sort
        query = query.order('last_name', ascending: true);
      }

      final response =
          await query.range(page * pageSize, (page + 1) * pageSize - 1);

      _log('Fetched ${response.length} residents');

      // Explicitly cast to List<dynamic> to avoid runtime type errors (especially on Web)
      // and map to ResidentModel
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => ResidentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      _log('PostgrestException - code: ${e.code}, message: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      _log('Error fetching residents: $e');
      throw Exception('Failed to fetch residents: $e');
    }
  }

  /// Get residents by status (Helper)
  Future<List<ResidentModel>> getResidentsByStatus(String status) async {
    return getResidents(status: status, pageSize: 100);
  }

  /// Get total count of active residents
  /// If [status] is provided, counts only residents with that status.
  /// If [status] is omitted, counts 'admitted' residents by default.
  Future<int> getResidentCount({String? status}) async {
    try {
      var query = _supabase
          .from('residents')
          .count(CountOption.exact)
          .eq('is_active', true);

      if (status != null) {
        query = query.eq('status', status);
      } else {
        query = query.eq('status', 'admitted');
      }

      final response = await query;

      return response;
    } catch (e) {
      _log('Error counting residents: $e');
      return 0; // Return 0 on error to avoid breaking UI
    }
  }

  /// Get total count of active wards
  Future<int> getActiveWardCount() async {
    try {
      final response =
          await _supabase.from('wards').select('id').eq('is_active', true);

      return (response as List).length;
    } catch (e) {
      _log('Error counting wards: $e');
      return 0;
    }
  }

  /// Get resident by ID
  Future<ResidentModel> getResidentById(String id) async {
    try {
      final response = await _supabase
          .from('residents')
          .select(
              '*, ward:wards(name), houseparent:profiles!houseparent_id(full_name), social_worker:profiles!social_worker_id(full_name)')
          .eq('id', id)
          .single();

      return ResidentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch resident: $e');
    }
  }

  /// Get resident by NFC Tag ID
  Future<ResidentModel?> getResidentByNfcTag(String nfcTagId) async {
    try {
      final response = await _supabase
          .from('residents')
          .select('*, ward:wards(name)')
          .eq('nfc_tag_id', nfcTagId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return ResidentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch resident by NFC tag: $e');
    }
  }

  /// Get latest case number for a prefix (e.g., "A-2505")
  /// Returns null if none found.
  Future<String?> getLatestCaseNumber(String prefix) async {
    try {
      final response = await _supabase
          .from('residents')
          .select('case_number')
          .ilike('case_number', '$prefix%')
          .order('case_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return response['case_number'] as String?;
    } catch (e) {
      _log('Error fetching latest case number: $e');
      return null;
    }
  }

  /// Get residents by ward ID (for NFC scan)
  Future<List<ResidentModel>> getResidentsByWardId(String wardId) async {
    try {
      final response = await _supabase
          .from('residents')
          .select('*, ward:wards(name)')
          .eq('ward_id', wardId)
          .eq('is_active', true)
          .eq('status', 'admitted')
          .order('last_name', ascending: true);

      return response.map((json) => ResidentModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch residents for ward: $e');
    }
  }

  /// Check if resident exists (Case-insensitive First + Last name)
  Future<bool> checkResidentExists({
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _supabase
          .from('residents')
          .select('id')
          .ilike('first_name', firstName.trim())
          .ilike('last_name', lastName.trim())
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      return response != null;
    } catch (e) {
      _log('Error checking resident existence: $e');
      return false;
    }
  }

  /// Add new resident
  Future<ResidentModel> addResident({
    required String firstName,
    required String lastName,
    String? middleName,
    String? suffix,
    String? nickname,
    String? caseNumber, // Added
    String? placeOfBirth,
    required DateTime dateOfBirth,
    required String gender,
    String? wardId, // Nullable
    String? roomNumber,
    String? bedNumber,
    DateTime? admissionDate, // Nullable
    DateTime? applicationDate,
    String? referredBy,
    String? referringContactPerson, // Added
    String? referringPartyAddress,
    String? caseCategory,
    String? condition,
    String? natureOfDisability, // Added
    String? mentalHealthCondition, // Added
    String? maxProvince,
    String? city,
    String? barangay,
    String? streetAddress,
    String? civilStatus,
    String? educationalAttainment,
    String? yearsOfEducation,
    String? religion,
    String? nearestRelativeName,
    String? nearestRelativeAddress,
    String? nearestRelativeContactNumber, // Added
    String? nearestRelativeRelation, // Added
    String? custodianName,
    List<Map<String, dynamic>>? familyComposition,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? medicalNotes,
    String? allergies,
    String? primaryDiagnosis,
    Uint8List? photoBytes,
    String status = 'pre_admission',
    String? houseparentId, // Added
    String? socialWorkerId, // Added
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      String? photoUrl;

      // Upload photo if provided
      if (photoBytes != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage
            .from(SupabaseConfig.residentPhotosBucket)
            .uploadBinary(
              fileName,
              photoBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
        photoUrl = _supabase.storage
            .from(SupabaseConfig.residentPhotosBucket)
            .getPublicUrl(fileName);
      }

      final response = await _supabase
          .from('residents')
          .insert({
            'first_name': firstName,
            'last_name': lastName,
            'middle_name': middleName,
            'suffix': suffix,
            'case_number': caseNumber, // Added
            'nickname': nickname,
            'place_of_birth': placeOfBirth,
            'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
            'gender': gender,
            'ward_id': wardId,
            'room_number': roomNumber,
            'bed_number': bedNumber,
            'admission_date': admissionDate?.toIso8601String().split('T').first,
            'application_date':
                applicationDate?.toIso8601String().split('T').first,
            'referred_by': referredBy,
            'referring_contact_person': referringContactPerson, // Added
            'referring_party_address': referringPartyAddress,
            'case_category': caseCategory,
            'condition': condition,
            'nature_of_disability': natureOfDisability, // Added
            'province': maxProvince,
            'city': city,
            'barangay': barangay,
            'street_address': streetAddress,
            'civil_status': civilStatus,
            'educational_attainment': educationalAttainment,
            'years_of_education': yearsOfEducation,
            'religion': religion,
            'nearest_relative_name': nearestRelativeName,
            'nearest_relative_address': nearestRelativeAddress,
            'nearest_relative_contact_number':
                nearestRelativeContactNumber, // Added
            'nearest_relative_relation': nearestRelativeRelation, // Added
            'custodian_name': custodianName,
            'family_composition': familyComposition,
            'emergency_contact_name': emergencyContactName,
            'emergency_contact_phone': emergencyContactPhone,
            'emergency_contact_relation': emergencyContactRelation,
            'medical_notes': medicalNotes,
            'allergies': allergies,
            'primary_diagnosis': primaryDiagnosis,
            'photo_url': photoUrl,
            'created_by': userId,
            'status': status,
            'houseparent_id': houseparentId,
            'social_worker_id': socialWorkerId,
            'mental_health_condition': mentalHealthCondition, // Added
          })
          .select(
              '*, ward:wards(name), houseparent:profiles!houseparent_id(full_name), social_worker:profiles!social_worker_id(full_name)')
          .single();

      // Update ward occupancy ONLY if admitted and ward is assigned
      if (status == 'admitted' && wardId != null) {
        await _supabase.rpc('increment_ward_occupancy', params: {
          'ward_id_param': wardId,
        });
      }

      final createdResident = ResidentModel.fromJson(response);

      // Create timeline entry
      try {
        await _supabase.from('timeline_entries').insert({
          'resident_id': createdResident.id,
          'entry_type': 'milestone',
          'unit': 'admin',
          'title': status == 'pre_admission'
              ? 'Pre-admission profile created'
              : 'New resident admitted',
          'description': status == 'pre_admission'
              ? 'Applicant added to system'
              : 'Admitted to ${createdResident.wardName ?? 'Facility'}',
          'created_by': userId,
        });
      } catch (e) {
        _log('WARNING: Failed to create timeline entry: $e');
      }

      // Notify all users about the new resident/applicant
      try {
        _notifyResidentStatusChange(createdResident); // Fire and forget
      } catch (e) {
        _log('WARNING: Failed to trigger resident creation notification: $e');
      }

      return createdResident;
    } catch (e) {
      throw Exception('Failed to add resident: $e');
    }
  }

  /// Update resident
  Future<ResidentModel> updateResident({
    required String id,
    String? firstName,
    String? lastName,
    String? middleName,
    String? suffix,
    String? nickname,
    String? caseNumber, // Added
    String? placeOfBirth,
    DateTime? dateOfBirth,
    String? gender,
    String? wardId,
    String? roomNumber,
    String? bedNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? medicalNotes,
    String? allergies,
    String? primaryDiagnosis,
    Uint8List? photoBytes,
    String? status, // Added
    DateTime? admissionDate, // Added
    DateTime? applicationDate,
    String? referredBy,
    String? referringContactPerson, // Added
    String? referringPartyAddress,
    String? caseCategory,
    String? condition,
    String? natureOfDisability, // Added
    String? mentalHealthCondition, // Added
    String? province,
    String? city,
    String? barangay,
    String? streetAddress,
    String? civilStatus,
    String? educationalAttainment,
    String? yearsOfEducation,
    String? religion,
    String? nearestRelativeName,
    String? nearestRelativeAddress,
    String? nearestRelativeContactNumber, // Added
    String? nearestRelativeRelation, // Added
    String? custodianName,
    List<Map<String, dynamic>>? familyComposition,
    String? nfcTagId, // Added
    String? houseparentId, // Added
    String? socialWorkerId, // Added
    bool? isActive, // Added for re-admission
  }) async {
    try {
      // Fetch current state to check for ward/status changes
      final currentResident = await getResidentById(id);

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (middleName != null) updates['middle_name'] = middleName;
      if (suffix != null) updates['suffix'] = suffix;
      if (nickname != null) updates['nickname'] = nickname;
      if (caseNumber != null) updates['case_number'] = caseNumber; // Added
      if (placeOfBirth != null) updates['place_of_birth'] = placeOfBirth;
      if (referredBy != null) updates['referred_by'] = referredBy;
      if (referringContactPerson != null) {
        updates['referring_contact_person'] = referringContactPerson;
      }
      if (referringPartyAddress != null) {
        updates['referring_party_address'] = referringPartyAddress;
      }
      if (caseCategory != null) updates['case_category'] = caseCategory;
      if (condition != null) updates['condition'] = condition;
      if (natureOfDisability != null) {
        updates['nature_of_disability'] = natureOfDisability;
      }
      if (province != null) updates['province'] = province;
      if (city != null) updates['city'] = city;
      if (barangay != null) updates['barangay'] = barangay;
      if (streetAddress != null) updates['street_address'] = streetAddress;
      if (civilStatus != null) updates['civil_status'] = civilStatus;
      if (educationalAttainment != null) {
        updates['educational_attainment'] = educationalAttainment;
      }
      if (yearsOfEducation != null) {
        updates['years_of_education'] = yearsOfEducation;
      }
      if (religion != null) updates['religion'] = religion;
      if (nearestRelativeName != null) {
        updates['nearest_relative_name'] =
            nearestRelativeName.isEmpty ? null : nearestRelativeName;
      }
      if (nearestRelativeAddress != null) {
        updates['nearest_relative_address'] =
            nearestRelativeAddress.isEmpty ? null : nearestRelativeAddress;
      }
      if (nearestRelativeContactNumber != null) {
        updates['nearest_relative_contact_number'] =
            nearestRelativeContactNumber.isEmpty
                ? null
                : nearestRelativeContactNumber;
      }
      if (nearestRelativeRelation != null) {
        updates['nearest_relative_relation'] =
            nearestRelativeRelation.isEmpty ? null : nearestRelativeRelation;
      }
      if (custodianName != null) {
        updates['custodian_name'] =
            custodianName.isEmpty ? null : custodianName;
      }
      if (familyComposition != null) {
        updates['family_composition'] = familyComposition;
      }
      if (applicationDate != null) {
        updates['application_date'] =
            applicationDate.toIso8601String().split('T').first;
      }
      if (dateOfBirth != null) {
        updates['date_of_birth'] =
            dateOfBirth.toIso8601String().split('T').first;
      }
      if (gender != null) updates['gender'] = gender;
      if (wardId != null) updates['ward_id'] = wardId;
      if (roomNumber != null) updates['room_number'] = roomNumber;
      if (bedNumber != null) updates['bed_number'] = bedNumber;
      if (emergencyContactName != null) {
        updates['emergency_contact_name'] =
            emergencyContactName.isEmpty ? null : emergencyContactName;
      }
      if (emergencyContactPhone != null) {
        updates['emergency_contact_phone'] = emergencyContactPhone;
      }
      if (emergencyContactRelation != null) {
        updates['emergency_contact_relation'] =
            emergencyContactRelation.isEmpty ? null : emergencyContactRelation;
      }
      if (nfcTagId != null) updates['nfc_tag_id'] = nfcTagId; // Added
      if (medicalNotes != null) updates['medical_notes'] = medicalNotes;
      if (allergies != null) updates['allergies'] = allergies;
      if (primaryDiagnosis != null) {
        updates['primary_diagnosis'] = primaryDiagnosis;
      }
      if (status != null) updates['status'] = status;
      if (isActive != null) {
        updates['is_active'] = isActive; // Added for re-admission
      }
      if (admissionDate != null) {
        updates['admission_date'] = admissionDate.toIso8601String();
      }
      if (houseparentId != null) updates['houseparent_id'] = houseparentId;
      if (socialWorkerId != null) updates['social_worker_id'] = socialWorkerId;
      if (mentalHealthCondition != null) {
        updates['mental_health_condition'] = mentalHealthCondition;
      } // Added

      // Upload new photo if provided
      if (photoBytes != null) {
        final fileName = '$id/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage
            .from(SupabaseConfig.residentPhotosBucket)
            .uploadBinary(
              fileName,
              photoBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
        updates['photo_url'] = _supabase.storage
            .from(SupabaseConfig.residentPhotosBucket)
            .getPublicUrl(fileName);
      }

      // Execute the update without .select() because if RLS hides the row
      // immediately after update, .select() will crash with PGRST116 (0 rows)
      await _supabase.from('residents').update(updates).eq('id', id);

      Map<String, dynamic> finalData;

      try {
        // Try to fetch the full updated object if we still have RLS access
        final verify = await getResidentById(id);
        finalData = verify.toJson();
      } catch (_) {
        // If we lost access (e.g., reassigned to another unit), synthesize the object
        // so the UI doesn't crash.
        finalData = currentResident.toJson();
        finalData.addAll(updates); // merge what we updated
      }

      // Handle Occupancy logic if status or ward changed
      if (status == 'admitted' && currentResident.status != 'admitted') {
        // Just admitted
        if (wardId != null || currentResident.wardId != null) {
          final targetWardId = wardId ?? currentResident.wardId;
          if (targetWardId != null) {
            await _supabase.rpc('increment_ward_occupancy', params: {
              'ward_id_param': targetWardId,
            });
          }
        }

        // Notify all users about the admission
        try {
          final newResident = ResidentModel.fromJson(finalData);
          _notifyResidentStatusChange(newResident); // Fire and forget
        } catch (e) {
          _log('Failed to trigger admission notification: $e');
        }
      } else if (status == 'discharged' &&
          currentResident.status == 'admitted') {
        // Just discharged
        if (currentResident.wardId != null) {
          await _supabase.rpc('decrement_ward_occupancy', params: {
            'ward_id_param': currentResident.wardId,
          });
        }
      } else if (wardId != null &&
          wardId != currentResident.wardId &&
          currentResident.status == 'admitted') {
        // Moved wards while admitted
        if (currentResident.wardId != null) {
          await _supabase.rpc('decrement_ward_occupancy', params: {
            'ward_id_param': currentResident.wardId,
          });
        }
        await _supabase.rpc('increment_ward_occupancy', params: {
          'ward_id_param': wardId,
        });
      }

      return ResidentModel.fromJson(finalData);
    } catch (e) {
      throw Exception('Failed to update resident: $e');
    }
  }

  /// Link an NFC tag to a resident using secure RPC
  Future<void> linkNfcTag({
    required String residentId,
    required String nfcTagId,
  }) async {
    try {
      await _supabase.rpc('link_resident_nfc', params: {
        'resident_id_input': residentId,
        'nfc_tag_id_input': nfcTagId,
      });
    } catch (e) {
      throw Exception('Failed to link NFC tag: $e');
    }
  }

  /// Sends a system-wide notification when a resident is added or admitted
  Future<void> _notifyResidentStatusChange(ResidentModel resident) async {
    try {
      final isPreAdmission = resident.status == 'pre_admission';
      final notifTitle = isPreAdmission
          ? 'New Pre-admission Profile'
          : 'New Resident Admitted';
      final notifMessage = isPreAdmission
          ? '${resident.firstName} ${resident.lastName} has been added as a pre-admission applicant.'
          : '${resident.firstName} ${resident.lastName} has been officially admitted.';

      _log(
          'Broadcasting notification: $notifTitle for ${resident.firstName} ${resident.lastName}');

      // Fetch all active users
      final usersResponse =
          await _supabase.from('profiles').select('id').eq('is_active', true);

      final userIds =
          (usersResponse as List).map((u) => u['id'] as String).toList();

      if (userIds.isEmpty) return;

      final approvalRepo = ApprovalRepository();

      // We could use a backend broadcast, but loop creating notifications
      // is usually fine for a typical staff size (< 50 users).
      for (final userId in userIds) {
        // Optional: Exclude the person doing the admitting
        // if (userId == _supabase.auth.currentUser?.id) continue;

        await approvalRepo.createNotification(
          userId: userId,
          type: 'admission',
          title: notifTitle,
          message: notifMessage,
          metadata: {'resident_id': resident.id},
        );
      }

      _log('Status change broadcast complete to ${userIds.length} users.');
    } catch (e) {
      _log('Error broadcasting status change: $e');
    }
  }

  /// Discharge resident (soft delete)
  Future<void> dischargeResident(String id) async {
    try {
      final resident = await getResidentById(id);

      await _supabase.from('residents').update({
        'is_active': false,
        'status': 'discharged', // Explicitly set status
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      // Update ward occupancy
      if (resident.status == 'admitted' && resident.wardId != null) {
        await _supabase.rpc('decrement_ward_occupancy', params: {
          'ward_id_param': resident.wardId,
        });
      }
    } catch (e) {
      throw Exception('Failed to discharge resident: $e');
    }
  }

  /// Delete resident (Hard Delete - Pre-admission only)
  Future<void> deleteResident(String id) async {
    try {
      await _supabase.from('residents').delete().eq('id', id);
      // Timeline entries and photos should ideally be cascaded or handled,
      // but for now relying on database constraints or manual cleanup if needed.
    } catch (e) {
      throw Exception('Failed to delete resident: $e');
    }
  }

  /// Search residents with full text search
  Future<List<ResidentModel>> searchResidents(String query) async {
    try {
      final response = await _supabase
          .from('residents')
          .select('*, ward:wards(name)')
          .eq('is_active', true)
          //.eq('status', 'admitted') // Search active/admitted? Or all? Let's keep it open for now
          .textSearch('fts', query)
          .limit(20);

      return response.map((json) => ResidentModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search residents: $e');
    }
  }

  /// Get all wards
  Future<List<WardModel>> getWards() async {
    try {
      final response = await _supabase
          .from('wards')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);
      return (response as List)
          .map((data) => WardModel.fromJson(data))
          .toList();
    } catch (e) {
      // _logger.e('Error fetching wards: $e'); // Original comment was `throw Exception('Failed to fetch wards: $e');`
      throw Exception(
          'Failed to fetch wards: $e'); // Reverted to original error handling
    }
  }

  /// Get a real-time stream of all wards
  Stream<List<WardModel>> watchWards() {
    return _supabase
        .from('wards')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('name', ascending: true)
        .map((data) => data.map((d) => WardModel.fromJson(d)).toList());
  }

  /// Get ward by NFC tag ID
  Future<WardModel?> getWardByNfcTag(String nfcTagId) async {
    try {
      final response = await _supabase
          .from('wards')
          .select()
          .eq('nfc_tag_id', nfcTagId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return WardModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch ward by NFC tag: $e');
    }
  }

  /// Get ward by ID (used for QR code fallback)
  Future<WardModel?> getWardById(String wardId) async {
    try {
      final response = await _supabase
          .from('wards')
          .select()
          .eq('id', wardId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return WardModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch ward by ID: $e');
    }
  }

  /// Get distinct values for a specific column (for Autocomplete)
  Future<List<String>> getDistinctColumnValues(
      String column, String query) async {
    try {
      if (query.isEmpty) return [];

      // Fetch blocked values and data in parallel
      final futureBlocked = _supabase
          .from('blocked_form_options')
          .select('value')
          .eq('column_name', column);

      final futureData = _supabase
          .from('residents')
          .select(column)
          .ilike(column, '%$query%')
          .limit(50);

      final results = await Future.wait([futureBlocked, futureData]);

      final blockedRows = results[0] as List<dynamic>;
      final dataRows = results[1] as List<dynamic>;

      final blockedSet =
          blockedRows.map((e) => e['value'].toString().toLowerCase()).toSet();

      final List<String> values = [];
      for (var item in dataRows) {
        if (item[column] != null) {
          // Clean the value: remove leading/trailing commas and spaces
          // formatting: ", , City" -> "City"
          var val = item[column].toString().trim();
          val = val.replaceAll(RegExp(r'^[, ]+|[, ]+$'), '');

          // Case-insensitive check against blocked list
          if (val.isNotEmpty &&
              !values.contains(val) &&
              !blockedSet.contains(val.toLowerCase())) {
            values.add(val);
          }
        }
      }
      return values;
    } catch (e) {
      // _log('Error fetching distinct values for $column: $e');
      return [];
    }
  }

  /// Hide an autocomplete value (Add to blocklist)
  Future<void> hideAutocompleteValue(String column, String value) async {
    try {
      await _supabase.from('blocked_form_options').upsert({
        'column_name': column,
        'value': value,
      }, onConflict: 'column_name, value');
    } catch (e) {
      _log('Error hiding value: $e');
      rethrow;
    }
  }

  /// Get active staff members by unit (for reassignment dropdowns)
  Future<List<Map<String, dynamic>>> getStaffByUnit(String unit) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, role, unit')
          .eq('is_active', true)
          .eq('unit', unit)
          .order('full_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch staff by unit: $e');
    }
  }

  /// Get available beds for a ward
  Future<List<String>> getAvailableBeds(WardModel ward,
      {String? excludeResidentId}) async {
    try {
      final residents = await getResidentsByWardId(ward.id);

      // Get occupied beds, excluding specific resident if provided (for edits)
      final occupiedBeds = residents
          .where((r) =>
              r.bedNumber != null &&
              (excludeResidentId == null || r.id != excludeResidentId))
          .map((r) => r.bedNumber!)
          .toSet();

      // Generate beds 1..Capacity
      // Assuming capacity is just a number. If it makes sense to sort them numerically.
      final beds =
          List.generate(ward.capacity, (index) => (index + 1).toString())
              .where((bed) => !occupiedBeds.contains(bed))
              .toList();

      // Sort numerically to be safe (though generate is already sorted)
      // beds.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      return beds;
    } catch (e) {
      throw Exception('Failed to fetch available beds: $e');
    }
  }
}
