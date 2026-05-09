import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/form_submission_model.dart';
import '../../../data/models/resident_model.dart';
import '../../../data/repositories/form_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../forms/templates/form_templates.dart';
import '../cubit/case_files_cubit.dart';
import '../utils/case_file_permissions.dart';

class ResidentCaseFilesScreen extends StatelessWidget {
  final String residentId;
  final ResidentModel? resident;

  const ResidentCaseFilesScreen({
    super.key,
    required this.residentId,
    this.resident,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CaseFilesCubit(
        formRepository: FormRepository(),
        residentId: residentId,
        residentStatus: resident?.status ?? 'admitted',
      )..loadCaseFiles(),
      child: _CaseFilesView(resident: resident),
    );
  }
}

class _CaseFilesView extends StatefulWidget {
  final ResidentModel? resident;
  const _CaseFilesView({this.resident});

  @override
  State<_CaseFilesView> createState() => _CaseFilesViewState();
}

class _CaseFilesViewState extends State<_CaseFilesView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final residentName = widget.resident != null
        ? '${widget.resident!.firstName} ${widget.resident!.lastName}'
        : 'Resident';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Case Files', style: TextStyle(fontSize: 18)),
            Text(
              residentName,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<CaseFilesCubit, CaseFilesState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state.showArchived
                      ? LucideIcons.archive
                      : LucideIcons.archive,
                  color: state.showArchived ? AppColors.warning : null,
                ),
                tooltip:
                    state.showArchived ? 'Showing archived' : 'Show archived',
                onPressed: () =>
                    context.read<CaseFilesCubit>().toggleShowArchived(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(context),
          Expanded(
            child: BlocBuilder<CaseFilesCubit, CaseFilesState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.circleAlert,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text('Error loading case files'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<CaseFilesCubit>().loadCaseFiles(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<CaseFilesCubit>().loadCaseFiles(),
                  child: _buildCategoryList(context, state),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search forms...',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        context.read<CaseFilesCubit>().setSearchQuery('');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) =>
                context.read<CaseFilesCubit>().setSearchQuery(value),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: BlocBuilder<CaseFilesCubit, CaseFilesState>(
              buildWhen: (prev, curr) => prev.unitFilter != curr.unitFilter,
              builder: (context, state) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(
                        context, 'All', null, state.unitFilter == null),
                    _buildFilterChip(context, 'Social', AppConstants.unitSocial,
                        state.unitFilter == AppConstants.unitSocial),
                    _buildFilterChip(
                        context,
                        'Homelife',
                        AppConstants.unitHomelife,
                        state.unitFilter == AppConstants.unitHomelife),
                    _buildFilterChip(context, 'Psych', AppConstants.unitPsych,
                        state.unitFilter == AppConstants.unitPsych),
                    _buildFilterChip(
                        context,
                        'Medical',
                        AppConstants.unitMedical,
                        state.unitFilter == AppConstants.unitMedical),
                    _buildFilterChip(
                        context,
                        'Nutrition',
                        AppConstants.unitNutrition,
                        state.unitFilter == AppConstants.unitNutrition),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context, String label, String? unit, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => context.read<CaseFilesCubit>().setUnitFilter(unit),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, CaseFilesState state) {
    final cubit = context.read<CaseFilesCubit>();
    final categories = CaseFileCategory.values
        .where((c) =>
            c != CaseFileCategory.uploadedScanned ||
            cubit.getFilteredForms(c).isNotEmpty)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (categories.isEmpty) {
      return const Center(child: Text('No forms found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategorySection(context, cubit, state, category);
      },
    );
  }

  Widget _buildCategorySection(BuildContext context, CaseFilesCubit cubit,
      CaseFilesState state, CaseFileCategory category) {
    final forms = cubit.getFilteredForms(category);
    final missingTemplates = state.showArchived
        ? <FormTemplate>[]
        : cubit.getMissingTemplates(category);
    final isExpanded = state.expandedSections[category] ?? true;

    if (forms.isEmpty && missingTemplates.isEmpty)
      return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () => cubit.toggleSection(category),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(_getCategoryIcon(category),
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (forms.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${forms.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            ...forms.map((form) => _buildFormTile(context, form)),
            ...missingTemplates
                .map((template) => _buildMissingTile(context, template)),
          ],
        ],
      ),
    );
  }

  Widget _buildFormTile(BuildContext context, FormSubmissionModel form) {
    final template = FormTemplatesRegistry.getById(form.templateId) ??
        FormTemplatesRegistry.getByType(form.templateType);
    final name = template?.name ?? form.templateDisplayName;
    final unitColor = _getUnitColor(form.unit);

    final authState = context.read<AuthBloc>().state;
    CaseFilePermissionResult? permissions;
    if (authState is AuthAuthenticated) {
      permissions = CaseFilePermissions.getPermissions(
        userRole: authState.user.role,
        userUnit: authState.user.unit,
        formUnit: form.unit,
        formSubmitterId: form.submittedBy,
        currentUserId: authState.user.id,
        formStatus: form.status,
        isArchived: form.isArchived,
      );
    }

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: form.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                form.isArchived
                    ? LucideIcons.archive
                    : (template?.icon ?? LucideIcons.fileText),
                color: form.isArchived
                    ? AppColors.textSecondary
                    : form.statusColor,
                size: 18,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: unitColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).cardColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          decoration: form.isArchived ? TextDecoration.lineThrough : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        DateFormat('MMM d, yyyy').format(form.createdAt),
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: form.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              form.isArchived ? 'Archived' : form.statusDisplayText,
              style: TextStyle(
                color: form.isArchived
                    ? AppColors.textSecondary
                    : form.statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (form.version > 1) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'v${form.version}',
                style: TextStyle(
                  color: AppColors.info,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (permissions != null &&
              (permissions.canArchive ||
                  permissions.canRestore ||
                  permissions.canPermanentDelete))
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.ellipsisVertical, size: 18),
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                if (permissions!.canArchive && !form.isArchived)
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(LucideIcons.archive, size: 18),
                        SizedBox(width: 8),
                        Text('Archive'),
                      ],
                    ),
                  ),
                if (permissions.canRestore && form.isArchived)
                  const PopupMenuItem(
                    value: 'restore',
                    child: Row(
                      children: [
                        Icon(LucideIcons.archiveRestore, size: 18),
                        SizedBox(width: 8),
                        Text('Restore'),
                      ],
                    ),
                  ),
                if (permissions.canPermanentDelete && form.isArchived)
                  const PopupMenuItem(
                    value: 'permanentDelete',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Permanently Delete',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) => _handleFormAction(context, form, value),
            ),
        ],
      ),
      onTap:
          form.isArchived ? null : () => context.push('/forms/view/${form.id}'),
    );
  }

  Widget _buildMissingTile(BuildContext context, FormTemplate template) {
    final authState = context.read<AuthBloc>().state;
    final canCreate = authState is AuthAuthenticated &&
        CaseFilePermissions.canCreateFormType(
          userRole: authState.user.role,
          userUnit: authState.user.unit,
          templateUnit:
              AppConstants.getUnitFromServiceUnit(template.serviceUnit.name),
        );

    final residentId = context.read<CaseFilesCubit>().residentId;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Icon(
          LucideIcons.square,
          color: Colors.grey.shade400,
          size: 18,
        ),
      ),
      title: Text(
        template.name,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Missing',
        style: TextStyle(
          fontSize: 11,
          color: Colors.orange.shade700,
        ),
      ),
      trailing: canCreate
          ? IconButton(
              icon: Icon(LucideIcons.circlePlus,
                  size: 20, color: AppColors.primary),
              tooltip: 'Create this form',
              onPressed: () => context.push(
                '/forms/fill/${template.id}?residentId=$residentId',
              ),
            )
          : Tooltip(
              message:
                  'Only ${template.serviceUnit.displayName} staff can create this form',
              child: Icon(LucideIcons.lockKeyhole,
                  size: 16, color: Colors.grey.shade400),
            ),
    );
  }

  void _handleFormAction(
      BuildContext context, FormSubmissionModel form, String action) {
    final cubit = context.read<CaseFilesCubit>();

    if (action == 'archive') {
      final authState = context.read<AuthBloc>().state;
      final isCustodian = authState is AuthAuthenticated &&
          CaseFilePermissions.isCaseFolderCustodian(
              authState.user.role, authState.user.unit);
      final isCrossUnit = isCustodian && authState.user.unit != form.unit;

      if (isCrossUnit) {
        _showConfirmArchiveWithTyping(context, form, cubit);
      } else {
        _showConfirmArchive(context, form, cubit);
      }
    } else if (action == 'restore') {
      cubit.restoreForm(form.id);
    } else if (action == 'permanentDelete') {
      _showConfirmPermanentDelete(context, form, cubit);
    }
  }

  void _showConfirmArchive(
      BuildContext context, FormSubmissionModel form, CaseFilesCubit cubit) {
    final template = FormTemplatesRegistry.getById(form.templateId);
    final name = template?.name ?? form.templateDisplayName;

    final hasPendingApproval = form.isPendingReview;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Archive "$name"?'),
            if (hasPendingApproval) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.triangleAlert,
                        size: 18, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This form has pending approvals. Archiving will cancel them.',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              cubit.archiveForm(form.id);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _showConfirmPermanentDelete(
      BuildContext context, FormSubmissionModel form, CaseFilesCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Form',
            style: TextStyle(color: AppColors.error)),
        content: const Text(
            'This action is irreversible. Are you sure you want to permanently delete this form?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              cubit.permanentDeleteForm(form.id);
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showConfirmArchiveWithTyping(
      BuildContext context, FormSubmissionModel form, CaseFilesCubit cubit) {
    final template = FormTemplatesRegistry.getById(form.templateId);
    final name = template?.name ?? form.templateDisplayName;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cross-Unit Archive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'You are archiving a form from another unit. Type the form name to confirm:'),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Type form name here',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              if (controller.text.trim().toLowerCase() ==
                  name.trim().toLowerCase()) {
                Navigator.pop(ctx);
                cubit.archiveForm(form.id);
              }
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(CaseFileCategory category) {
    switch (category) {
      case CaseFileCategory.admission:
        return LucideIcons.userCheck;
      case CaseFileCategory.ongoingCare:
        return LucideIcons.filePenLine;
      case CaseFileCategory.incidentsSpecial:
        return LucideIcons.triangleAlert;
      case CaseFileCategory.medicalNutritionReports:
        return LucideIcons.stethoscope;
      case CaseFileCategory.dischargeTermination:
        return LucideIcons.logOut;
      case CaseFileCategory.inventory:
        return LucideIcons.package;
      case CaseFileCategory.uploadedScanned:
        return LucideIcons.camera;
    }
  }

  Color _getUnitColor(String unit) {
    switch (unit) {
      case AppConstants.unitSocial:
        return AppColors.unitSocial;
      case AppConstants.unitMedical:
        return AppColors.unitMedical;
      case AppConstants.unitPsych:
        return AppColors.unitPsych;
      case AppConstants.unitHomelife:
        return AppColors.unitHomelife;
      case AppConstants.unitNutrition:
        return AppColors.unitNutrition;
      default:
        return AppColors.primary;
    }
  }
}
