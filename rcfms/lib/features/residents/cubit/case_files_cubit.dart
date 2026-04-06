import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/form_submission_model.dart';
import '../../../data/repositories/form_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../forms/templates/form_templates.dart';

part 'case_files_state.dart';

class CaseFilesCubit extends Cubit<CaseFilesState> {
  final FormRepository _formRepository;
  final String residentId;
  final String residentStatus;

  CaseFilesCubit({
    required FormRepository formRepository,
    required this.residentId,
    required this.residentStatus,
  })  : _formRepository = formRepository,
        super(const CaseFilesState());

  Future<void> loadCaseFiles() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final forms = await _formRepository.getResidentCaseFiles(
        residentId: residentId,
        includeArchived: true,
      );
      final grouped = _groupFormsByCategory(forms);
      final completion = _calculateCompletion(forms);
      emit(state.copyWith(
        isLoading: false,
        allForms: forms,
        groupedForms: grouped,
        completionStats: completion,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: ErrorHandler.getUserFriendlyMessage(e)));
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setUnitFilter(String? unit) {
    emit(state.copyWith(unitFilter: unit, clearUnitFilter: unit == null));
  }

  void toggleShowArchived() {
    emit(state.copyWith(showArchived: !state.showArchived));
  }

  void toggleSection(CaseFileCategory category) {
    final expanded = Map<CaseFileCategory, bool>.from(state.expandedSections);
    expanded[category] = !(expanded[category] ?? true);
    emit(state.copyWith(expandedSections: expanded));
  }

  Future<void> archiveForm(String formId) async {
    try {
      await _formRepository.archiveForm(formId);
      await loadCaseFiles();
    } catch (e) {
      emit(state.copyWith(error: ErrorHandler.getUserFriendlyMessage(e)));
    }
  }

  Future<void> restoreForm(String formId) async {
    try {
      await _formRepository.restoreForm(formId);
      await loadCaseFiles();
    } catch (e) {
      emit(state.copyWith(error: ErrorHandler.getUserFriendlyMessage(e)));
    }
  }

  Future<void> permanentDeleteForm(String formId) async {
    try {
      await _formRepository.permanentDeleteForm(formId);
      await loadCaseFiles();
    } catch (e) {
      emit(state.copyWith(error: ErrorHandler.getUserFriendlyMessage(e)));
    }
  }

  Map<CaseFileCategory, List<FormSubmissionModel>> _groupFormsByCategory(
      List<FormSubmissionModel> forms) {
    final grouped = <CaseFileCategory, List<FormSubmissionModel>>{};

    for (final category in CaseFileCategory.values) {
      grouped[category] = [];
    }

    for (final form in forms) {
      if (form.formData['is_uploaded_record'] == true) {
        grouped[CaseFileCategory.uploadedScanned]!.add(form);
        continue;
      }

      final template = FormTemplatesRegistry.getById(form.templateId) ??
          FormTemplatesRegistry.getByType(form.templateType);

      final category = template?.category ?? CaseFileCategory.ongoingCare;
      grouped[category]!.add(form);
    }

    return grouped;
  }

  Map<String, dynamic> _calculateCompletion(List<FormSubmissionModel> forms) {
    final activeForms = forms.where((f) => !f.isArchived).toList();
    final existingTemplateIds =
        activeForms.map((f) => f.templateId).toSet();

    final expectedTemplates = FormTemplatesRegistry.templates.where((t) {
      return t.allowedResidentStatuses.contains(residentStatus) &&
          t.category == CaseFileCategory.admission;
    }).toList();

    final total = expectedTemplates.length;
    final completed = expectedTemplates
        .where((t) => existingTemplateIds.contains(t.id))
        .length;

    return {
      'total': total,
      'completed': completed,
      'percentage': total > 0 ? (completed / total * 100).round() : 0,
      'missingTemplateIds': expectedTemplates
          .where((t) => !existingTemplateIds.contains(t.id))
          .map((t) => t.id)
          .toList(),
    };
  }

  List<FormTemplate> getMissingTemplates(CaseFileCategory category) {
    final activeForms =
        state.allForms.where((f) => !f.isArchived).toList();
    final existingTemplateIds =
        activeForms.map((f) => f.templateId).toSet();

    return FormTemplatesRegistry.templates.where((t) {
      return t.category == category &&
          t.allowedResidentStatuses.contains(residentStatus) &&
          !existingTemplateIds.contains(t.id);
    }).toList();
  }

  List<FormSubmissionModel> getFilteredForms(CaseFileCategory category) {
    final forms = state.groupedForms[category] ?? [];

    return forms.where((form) {
      if (state.showArchived != form.isArchived) return false;

      if (state.unitFilter != null && form.unit != state.unitFilter) {
        return false;
      }

      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        final template = FormTemplatesRegistry.getById(form.templateId) ??
            FormTemplatesRegistry.getByType(form.templateType);
        final name = template?.name ?? form.templateType;
        if (!name.toLowerCase().contains(query)) return false;
      }

      return true;
    }).toList();
  }
}
