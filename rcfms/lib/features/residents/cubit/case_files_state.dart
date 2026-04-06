part of 'case_files_cubit.dart';

class CaseFilesState extends Equatable {
  final List<FormSubmissionModel> allForms;
  final Map<CaseFileCategory, List<FormSubmissionModel>> groupedForms;
  final Map<CaseFileCategory, bool> expandedSections;
  final String searchQuery;
  final String? unitFilter;
  final bool showArchived;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> completionStats;

  const CaseFilesState({
    this.allForms = const [],
    this.groupedForms = const {},
    this.expandedSections = const {},
    this.searchQuery = '',
    this.unitFilter,
    this.showArchived = false,
    this.isLoading = false,
    this.error,
    this.completionStats = const {},
  });

  CaseFilesState copyWith({
    List<FormSubmissionModel>? allForms,
    Map<CaseFileCategory, List<FormSubmissionModel>>? groupedForms,
    Map<CaseFileCategory, bool>? expandedSections,
    String? searchQuery,
    String? unitFilter,
    bool clearUnitFilter = false,
    bool? showArchived,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? completionStats,
  }) {
    return CaseFilesState(
      allForms: allForms ?? this.allForms,
      groupedForms: groupedForms ?? this.groupedForms,
      expandedSections: expandedSections ?? this.expandedSections,
      searchQuery: searchQuery ?? this.searchQuery,
      unitFilter: clearUnitFilter ? null : (unitFilter ?? this.unitFilter),
      showArchived: showArchived ?? this.showArchived,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      completionStats: completionStats ?? this.completionStats,
    );
  }

  @override
  List<Object?> get props => [
        allForms,
        groupedForms,
        expandedSections,
        searchQuery,
        unitFilter,
        showArchived,
        isLoading,
        error,
        completionStats,
      ];
}
