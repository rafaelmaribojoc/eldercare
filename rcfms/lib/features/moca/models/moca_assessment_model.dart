/// Assessment section enumeration
enum AssessmentSection {
  visuospatial,
  naming,
  memory,
  attention,
  language,
  abstraction,
  delayedRecall,
  orientation,
}

/// Assessment model for MoCA-P
class MocaAssessmentModel {
  final String id;
  final String? clinicianId;
  final String? residentId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int totalScore;
  final int maxScore;
  final bool educationAdjustment;
  final Map<String, SectionResult> sectionResults;
  final DateTime createdAt;

  // Resident details for auto-fill
  final String? residentName;
  final String? residentSex;
  final DateTime? residentBirthday;
  final int educationYears; // Years of formal education

  // Risk assessment results (populated from database)
  final String? riskLevel;
  final double? normalProbability;
  final double? mciProbability;
  final double? dementiaProbability;

  const MocaAssessmentModel({
    required this.id,
    this.clinicianId,
    this.residentId,
    required this.startedAt,
    this.completedAt,
    required this.totalScore,
    this.maxScore = 30,
    required this.educationAdjustment,
    required this.sectionResults,
    required this.createdAt,
    this.residentName,
    this.residentSex,
    this.residentBirthday,
    this.educationYears = 0,
    this.riskLevel,
    this.normalProbability,
    this.mciProbability,
    this.dementiaProbability,
  });

  /// Create empty assessment
  factory MocaAssessmentModel.empty({
    required String id,
    String? clinicianId,
    String? residentId,
    bool educationAdjustment = false,
    String? residentName,
    String? residentSex,
    DateTime? residentBirthday,
    int educationYears = 0,
  }) {
    return MocaAssessmentModel(
      id: id,
      clinicianId: clinicianId,
      residentId: residentId,
      startedAt: DateTime.now(),
      totalScore: 0,
      educationAdjustment: educationAdjustment,
      sectionResults: {},
      createdAt: DateTime.now(),
      residentName: residentName,
      residentSex: residentSex,
      residentBirthday: residentBirthday,
      educationYears: educationYears,
    );
  }

  /// Create from JSON
  factory MocaAssessmentModel.fromJson(Map<String, dynamic> json) {
    final sectionResultsJson = json['section_results'] as Map<String, dynamic>?;
    final sectionResults = <String, SectionResult>{};

    if (sectionResultsJson != null) {
      sectionResultsJson.forEach((key, value) {
        sectionResults[key] = SectionResult.fromJson(value);
      });
    }

    return MocaAssessmentModel(
      id: json['id'] as String,
      clinicianId: json['clinician_id'] as String?,
      residentId: json['resident_id'] as String?,
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      totalScore: json['total_score'] as int,
      maxScore: json['max_score'] as int? ?? 30,
      educationAdjustment: json['education_adjustment'] as bool? ?? false,
      sectionResults: sectionResults,
      createdAt: DateTime.parse(json['created_at']),
      residentName: json['resident_name'] as String?,
      residentSex: json['resident_sex'] as String?,
      residentBirthday: json['resident_birthday'] != null
          ? DateTime.parse(json['resident_birthday'])
          : null,
      educationYears: json['education_years'] as int? ?? 0,
      riskLevel: json['risk_level'] as String?,
      normalProbability: (json['normal_probability'] as num?)?.toDouble(),
      mciProbability: (json['mci_probability'] as num?)?.toDouble(),
      dementiaProbability: (json['dementia_probability'] as num?)?.toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final sectionResultsJson = <String, dynamic>{};
    sectionResults.forEach((key, value) {
      sectionResultsJson[key] = value.toJson();
    });

    return {
      'id': id,
      'clinician_id': clinicianId,
      'resident_id': residentId,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'total_score': totalScore,
      'max_score': maxScore,
      'education_adjustment': educationAdjustment,
      'section_results': sectionResultsJson,
      'created_at': createdAt.toIso8601String(),
      'resident_name': residentName,
      'resident_sex': residentSex,
      'resident_birthday': residentBirthday?.toIso8601String(),
      'education_years': educationYears,
      'risk_level': riskLevel,
      'normal_probability': normalProbability,
      'mci_probability': mciProbability,
      'dementia_probability': dementiaProbability,
    };
  }

  /// Copy with
  MocaAssessmentModel copyWith({
    String? id,
    String? clinicianId,
    String? residentId,
    DateTime? startedAt,
    DateTime? completedAt,
    int? totalScore,
    int? maxScore,
    bool? educationAdjustment,
    Map<String, SectionResult>? sectionResults,
    DateTime? createdAt,
    String? residentName,
    String? residentSex,
    DateTime? residentBirthday,
    int? educationYears,
    String? riskLevel,
    double? normalProbability,
    double? mciProbability,
    double? dementiaProbability,
  }) {
    return MocaAssessmentModel(
      id: id ?? this.id,
      clinicianId: clinicianId ?? this.clinicianId,
      residentId: residentId ?? this.residentId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      totalScore: totalScore ?? this.totalScore,
      maxScore: maxScore ?? this.maxScore,
      educationAdjustment: educationAdjustment ?? this.educationAdjustment,
      sectionResults: sectionResults ?? this.sectionResults,
      createdAt: createdAt ?? this.createdAt,
      residentName: residentName ?? this.residentName,
      residentSex: residentSex ?? this.residentSex,
      residentBirthday: residentBirthday ?? this.residentBirthday,
      educationYears: educationYears ?? this.educationYears,
      riskLevel: riskLevel ?? this.riskLevel,
      normalProbability: normalProbability ?? this.normalProbability,
      mciProbability: mciProbability ?? this.mciProbability,
      dementiaProbability: dementiaProbability ?? this.dementiaProbability,
    );
  }

  /// Get adjusted total score
  int get adjustedScore {
    if (educationAdjustment) {
      return totalScore + 1 > maxScore ? maxScore : totalScore + 1;
    }
    return totalScore;
  }

  /// Check if score is normal
  bool get isNormal => adjustedScore >= 26;

  /// Get completion status
  bool get isComplete => completedAt != null;

  /// Get duration
  Duration? get duration {
    if (completedAt != null) {
      return completedAt!.difference(startedAt);
    }
    return null;
  }

  /// Get section result
  SectionResult? getSectionResult(AssessmentSection section) {
    return sectionResults[section.name];
  }

  @override
  String toString() {
    return 'MocaAssessmentModel(id: $id, totalScore: $totalScore, adjustedScore: $adjustedScore)';
  }
}

/// Section result model
class SectionResult {
  final String section;
  final int score;
  final int maxScore;
  final Map<String, dynamic> details;
  final DateTime completedAt;

  const SectionResult({
    required this.section,
    required this.score,
    required this.maxScore,
    required this.details,
    required this.completedAt,
  });

  /// Create from JSON
  factory SectionResult.fromJson(Map<String, dynamic> json) {
    return SectionResult(
      section: json['section'] as String,
      score: json['score'] as int,
      maxScore: json['max_score'] as int,
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      completedAt: DateTime.parse(json['completed_at']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'section': section,
      'score': score,
      'max_score': maxScore,
      'details': details,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  /// Copy with
  SectionResult copyWith({
    String? section,
    int? score,
    int? maxScore,
    Map<String, dynamic>? details,
    DateTime? completedAt,
  }) {
    return SectionResult(
      section: section ?? this.section,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      details: details ?? this.details,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
