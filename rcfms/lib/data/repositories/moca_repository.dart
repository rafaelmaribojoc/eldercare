import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/moca/models/moca_assessment_model.dart';
import '../../features/moca/services/dementia_probability_calculator.dart';

/// Repository for managing MoCA assessments in the database
class MocaRepository {
  final SupabaseClient _client;

  MocaRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch assessments within a date range (completed only).
  ///
  /// Note: Supabase/PostgREST aggregation isn't used here; the caller computes
  /// analytics client-side from DB rows.
  Future<List<MocaAssessmentModel>> getAssessmentsInRange({
    required DateTime from,
    DateTime? to,
    int limit = 1000,
    String? clinicianId,
  }) async {
    var query = _client
        .from('moca_assessments')
        .select()
        .not('completed_at', 'is', null)
        .gte('completed_at', from.toIso8601String());

    if (to != null) {
      query = query.lte('completed_at', to.toIso8601String());
    }
    if (clinicianId != null && clinicianId.isNotEmpty) {
      query = query.eq('clinician_id', clinicianId);
    }

    final response =
        await query.order('completed_at', ascending: false).limit(limit);

    return (response as List)
        .map((json) => MocaAssessmentModel.fromJson(_convertDbResponse(json)))
        .toList();
  }

  /// Get a map of clinician_id -> clinician full_name from `profiles`.
  Future<Map<String, String>> getClinicianNames({
    String? unit,
  }) async {
    var query = _client.from('profiles').select('id, full_name');
    if (unit != null && unit.isNotEmpty) {
      query = query.eq('unit', unit);
    }

    final response = await query;
    final map = <String, String>{};
    for (final row in (response as List)) {
      final id = row['id']?.toString();
      final name = row['full_name']?.toString();
      if (id != null && id.isNotEmpty && name != null && name.isNotEmpty) {
        map[id] = name;
      }
    }
    return map;
  }

  /// Save a completed MoCA assessment
  Future<MocaAssessmentModel> saveAssessment(
      MocaAssessmentModel assessment) async {
    // Validate required fields
    if (assessment.residentId == null || assessment.residentId!.isEmpty) {
      throw Exception(
          'Cannot save assessment: No resident selected. Please start the assessment from a resident profile.');
    }
    if (assessment.clinicianId == null || assessment.clinicianId!.isEmpty) {
      throw Exception(
          'Cannot save assessment: No clinician ID. Please ensure you are logged in.');
    }

    // Calculate risk probabilities
    final probabilityResult = DementiaProbabilityCalculator.calculate(
      assessment.adjustedScore,
    );

    final data = {
      'id': assessment.id,
      'resident_id': assessment.residentId,
      'clinician_id': assessment.clinicianId,
      'resident_name': assessment.residentName ?? 'Unknown',
      'resident_sex': assessment.residentSex,
      'resident_birthday': assessment.residentBirthday?.toIso8601String(),
      'education_years': assessment.educationYears,
      'started_at': assessment.startedAt.toIso8601String(),
      'completed_at': assessment.completedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'total_score': assessment.totalScore,
      'max_score': assessment.maxScore,
      'education_adjustment': assessment.educationAdjustment,
      'risk_level': probabilityResult.riskLevel,
      'normal_probability': probabilityResult.normalProbability,
      'mci_probability': probabilityResult.mciProbability,
      'dementia_probability': probabilityResult.dementiaProbability,
      'section_results': _sectionResultsToJson(assessment.sectionResults),
    };

    final response =
        await _client.from('moca_assessments').upsert(data).select().single();

    return MocaAssessmentModel.fromJson(_convertDbResponse(response));
  }

  /// Get all assessments for a resident
  Future<List<MocaAssessmentModel>> getAssessmentsByResident(
      String residentId) async {
    final response = await _client
        .from('moca_assessments')
        .select()
        .eq('resident_id', residentId)
        .order('completed_at', ascending: false);

    return (response as List)
        .map((json) => MocaAssessmentModel.fromJson(_convertDbResponse(json)))
        .toList();
  }

  /// Get a single assessment by ID
  Future<MocaAssessmentModel?> getAssessmentById(String id) async {
    final response = await _client
        .from('moca_assessments')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return MocaAssessmentModel.fromJson(_convertDbResponse(response));
  }

  /// Get recent assessments by clinician
  Future<List<MocaAssessmentModel>> getAssessmentsByClinician(
    String clinicianId, {
    int limit = 10,
  }) async {
    final response = await _client
        .from('moca_assessments')
        .select()
        .eq('clinician_id', clinicianId)
        .order('completed_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => MocaAssessmentModel.fromJson(_convertDbResponse(json)))
        .toList();
  }

  /// Get all completed assessments (for psych head dashboard)
  Future<List<MocaAssessmentModel>> getAllAssessments({
    int limit = 50,
    String? riskLevel,
  }) async {
    var query = _client
        .from('moca_assessments')
        .select()
        .not('completed_at', 'is', null);

    if (riskLevel != null) {
      query = query.eq('risk_level', riskLevel);
    }

    final response =
        await query.order('completed_at', ascending: false).limit(limit);

    return (response as List)
        .map((json) => MocaAssessmentModel.fromJson(_convertDbResponse(json)))
        .toList();
  }

  /// Convert section results map to JSON-compatible format
  Map<String, dynamic> _sectionResultsToJson(
      Map<String, SectionResult> results) {
    final json = <String, dynamic>{};
    results.forEach((key, value) {
      json[key] = value.toJson();
    });
    return json;
  }

  /// Convert database response to model-compatible format
  Map<String, dynamic> _convertDbResponse(Map<String, dynamic> response) {
    return {
      'id': response['id'],
      'clinician_id': response['clinician_id'],
      'resident_id': response['resident_id'],
      'resident_name': response['resident_name'],
      'resident_sex': response['resident_sex'],
      'resident_birthday': response['resident_birthday'],
      'education_years': response['education_years'],
      'started_at': response['started_at'],
      'completed_at': response['completed_at'],
      'total_score': response['total_score'],
      'max_score': response['max_score'],
      'education_adjustment': response['education_adjustment'],
      'section_results': response['section_results'],
      'created_at': response['created_at'],
    };
  }
}
