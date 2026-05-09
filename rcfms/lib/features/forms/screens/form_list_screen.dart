import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/form_submission_model.dart';
import '../../../data/models/resident_model.dart';
import '../../../data/repositories/form_repository.dart';
import '../../../data/repositories/resident_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../templates/form_templates.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/utils/interaction_utils.dart';

class FormListScreen extends StatefulWidget {
  final String? initialTab;

  const FormListScreen({
    super.key,
    this.initialTab,
  });

  @override
  State<FormListScreen> createState() => _FormListScreenState();
}

class _FormListScreenState extends State<FormListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FormRepository _formRepo = FormRepository();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  List<FormSubmissionModel> _forms = [];
  bool _isLoading = true;
  String? _error;

  List<String> _tabs = ['All', 'Draft', 'For Signing', 'Signed'];
  bool _isApprover = false;
  bool _isAdmin = false;
  bool _isCenterHead = false;
  bool _isUnitHead = false;
  List<FormSubmissionModel> _pendingForms = [];
  List<FormSubmissionModel> _archivedForms = [];
  bool _isProcessing = false;
  final _throttler =
      AppThrottler(throttleDuration: const Duration(milliseconds: 600));

  @override
  void initState() {
    super.initState();
    _checkRoleAndInit();
  }

  void _checkRoleAndInit() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      // Approvers: Center Head and Unit Head
      _isApprover = AppConstants.canApproveforms(authState.user.role);
      // Admins: Super Admin (view only for forms)
      _isAdmin = authState.user.role == AppConstants.roleSuperAdmin;
      _isCenterHead = authState.user.role == AppConstants.roleCenterHead;
      _isUnitHead = authState.user.isUnitHead;
    }

    if (_isCenterHead) {
      // Center Head: Review/sign only — single tab
      _tabs = ['For Review'];
    } else if (_isUnitHead || _isAdmin) {
      _tabs = [
        if (_isUnitHead || _isApprover) 'For Review',
        'All',
        'Draft',
        'For Signing',
        'Signed',
        'Returned',
        'Archived'
      ];
    } else if (_isApprover) {
      _tabs = [
        'For Review',
        'All',
        'Draft',
        'For Signing',
        'Signed',
        'Returned'
      ];
    } else {
      // Standard user
      _tabs = ['All', 'Draft', 'For Signing', 'Signed', 'Returned'];
    }

    _tabController = TabController(length: _tabs.length, vsync: this);

    // Handle initial tab selection if provided
    if (widget.initialTab != null) {
      final initialIndex = _tabs.indexOf(widget.initialTab!);
      if (initialIndex != -1) {
        _tabController.index = initialIndex;
      }
    }

    _tabController.addListener(_handleTabSelection);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    _throttler.run(() {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tabName = _tabs.isNotEmpty && _tabController.index < _tabs.length
          ? _tabs[_tabController.index]
          : '';

      if (tabName == 'For Review') {
        await _loadPendingApprovals();
      } else if (tabName == 'Archived') {
        await _loadArchivedForms();
      } else if (_isAdmin) {
        await _loadUnitForms();
      } else {
        await _loadForms();
      }
    } catch (e) {
      setState(() {
        _error = ErrorHandler.getUserFriendlyMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadArchivedForms() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    // Admins see all archived, unit heads see their unit
    final unit = _isAdmin ? null : authState.user.unit;
    final forms = await _formRepo.getArchivedForms(unit: unit);

    if (!mounted) return;

    setState(() {
      _archivedForms = forms;
      _isLoading = false;
    });
  }

  Future<void> _loadForms() async {
    final forms = await _formRepo.getForms();
    if (!mounted) return;

    debugPrint('DEBUG: Loaded ${forms.length} forms');
    for (var f in forms) {
      debugPrint('DEBUG: Form ${f.id} status: ${f.status}');
    }
    setState(() {
      _forms = forms;
      _isLoading = false;
    });
  }

  Future<void> _loadUnitForms() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final unit = authState.user.unit ?? 'all';
    final forms = await _formRepo.getUnitForms(unit: unit);

    if (!mounted) return;

    setState(() {
      _forms = forms;
      _isLoading = false;
    });
  }

  Future<void> _loadPendingApprovals() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    // Now uses form_approvals.recipient_id to only show forms sent to this user
    final forms = await _formRepo.getPendingApprovals(
      unit: authState.user.unit ?? 'all',
    );

    if (!mounted) return;

    setState(() {
      _pendingForms = forms;
      _isLoading = false;
    });
  }

  List<FormSubmissionModel> _getFilteredForms(int tabIndex) {
    if (tabIndex >= _tabs.length) return [];
    final tabName = _tabs[tabIndex];

    if (tabName == 'For Review') {
      return _pendingForms;
    } else if (tabName == 'Archived') {
      return _archivedForms;
    } else if (tabName == 'All') {
      return _forms;
    } else if (tabName == 'Draft') {
      return _forms.where((f) => f.status == 'draft').toList();
    } else if (tabName == 'For Signing') {
      return _forms
          .where((f) => [
                AppConstants.statusSubmitted,
                AppConstants.statusPendingReview,
                AppConstants.statusPendingMedicalReview,
                AppConstants.statusPendingFinalApproval,
                AppConstants.statusPendingSupervisor,
                AppConstants.statusPendingMultiApproval,
                AppConstants.statusPendingHeadApproval,
                AppConstants.statusPendingDoctorReview,
                AppConstants.statusPendingSocialWorker,
              ].contains(f.status))
          .toList();
    } else if (tabName == 'Signed') {
      return _forms.where((f) => f.status == 'approved').toList();
    } else if (tabName == 'Returned') {
      return _forms.where((f) => f.status == 'returned').toList();
    }
    return _forms;
  }

  // Track forms currently being processed
  final Set<String> _processingFormIds = {};

  Future<void> _uploadSignedForm() async {
    // 1. Load current "For Signing" forms
    setState(() => _isLoading = true);
    List<FormSubmissionModel> forSigningForms;
    try {
      final all = await _formRepo.getForms();
      forSigningForms = all
          .where((f) =>
              f.status == AppConstants.statusSubmitted ||
              f.status == AppConstants.statusPendingReview ||
              f.status == AppConstants.statusPendingMedicalReview ||
              f.status == AppConstants.statusPendingFinalApproval ||
              f.status == AppConstants.statusPendingSupervisor ||
              f.status == AppConstants.statusPendingMultiApproval ||
              f.status == AppConstants.statusPendingHeadApproval ||
              f.status == AppConstants.statusPendingDoctorReview ||
              f.status == AppConstants.statusPendingSocialWorker)
          .toList();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    if (forSigningForms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No forms are currently awaiting signing'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // 2. Select an existing "For Signing" form
    final selectedForm = await showDialog<FormSubmissionModel>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Form to Upload Signed Copy'),
        children: forSigningForms.map((form) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, form),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTemplateName(form.templateType),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    form.residentName ?? 'Unknown Resident',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (selectedForm == null) return;

    // 3. Pick file (image or PDF)
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    // 4. Upload against the existing form submission
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final file = result.files.single;
      final ext = file.extension?.toLowerCase() ?? '';
      final fileType = ext == 'pdf' ? 'pdf' : 'image';

      await _formRepo.uploadSignedForm(
        formSubmissionId: selectedForm.id,
        imageBytes: file.bytes!,
        fileName: file.name,
        fileType: fileType,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed form uploaded successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      _refreshKey.currentState?.show();
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveForm(FormSubmissionModel form) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Form'),
        content: Text(
          'Are you sure you want to approve "${form.templateDisplayName}" '
          'for ${form.residentName}? Your signature will be applied.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _processingFormIds.add(form.id);
    });

    try {
      await _formRepo.approveForm(form.id);

      if (mounted) {
        setState(() {
          _processingFormIds.remove(form.id);
          // Optimistic update: remove from lists locally
          _pendingForms.removeWhere((f) => f.id == form.id);
          // Also update the main list if present
          final index = _forms.indexWhere((f) => f.id == form.id);
          if (index != -1) {
            // For the master list, update status
            _forms[index] = _forms[index].copyWith(status: 'approved');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form approved successfully'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        // Trigger refresh animation and reload data
        _refreshKey.currentState?.show();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _processingFormIds.remove(form.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _returnForm(FormSubmissionModel form) async {
    final commentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Return "${form.templateDisplayName}" to ${form.submitterName}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comment (required)',
                hintText: 'Explain why the form is being returned...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            onPressed: () {
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please add a comment'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Return'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _formRepo.returnForm(
        id: form.id,
        comment: commentController.text.trim(),
      );

      if (mounted) {
        setState(() {
          // Optimistic removal from pending list
          _pendingForms.removeWhere((f) => f.id == form.id);
          // Update status in main list
          final index = _forms.indexWhere((f) => f.id == form.id);
          if (index != -1) {
            _forms[index] = _forms[index].copyWith(status: 'returned');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form returned to submitter'),
            backgroundColor: AppColors.warning,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _archiveForm(FormSubmissionModel form) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Form'),
        content: Text(
          'Are you sure you want to archive this ${form.status.replaceAll('_', ' ')} form? It will be moved to the Archived list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _formRepo.archiveForm(form.id);

      if (mounted) {
        setState(() {
          _forms.removeWhere((f) => f.id == form.id);
          _pendingForms.removeWhere((f) => f.id == form.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form archived successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _restoreForm(FormSubmissionModel form) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Form'),
        content: const Text(
            'Are you sure you want to restore this form to the active list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _formRepo.restoreForm(form.id);

      if (mounted) {
        setState(() {
          _archivedForms.removeWhere((f) => f.id == form.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form restored successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _permanentDeleteForm(FormSubmissionModel form) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete Form',
            style: TextStyle(color: AppColors.error)),
        content: const Text(
            'This action is irreversible. Are you sure you want to permanently delete this form?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _formRepo.permanentDeleteForm(form.id);

      if (mounted) {
        setState(() {
          _archivedForms.removeWhere((f) => f.id == form.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form permanently deleted'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showSidebar = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null,
      body: Column(
        children: [
          // Unified Two-Row Header
          Container(
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Title and Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        'Forms',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Spacer(),
                      // Actions
                      AppIconButton(
                        icon: LucideIcons.refreshCw,
                        tooltip: 'Refresh',
                        onPressed: _loadData,
                      ),
                      if (!_isAdmin && showSidebar)
                        AppIconButton(
                          icon: LucideIcons.fileUp,
                          tooltip: 'Upload signed form image',
                          onPressed: _uploadSignedForm,
                        ),
                      if (showSidebar)
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final user =
                                state is AuthAuthenticated ? state.user : null;
                            if (user != null &&
                                (user.role == AppConstants.roleCenterHead ||
                                    user.role == AppConstants.roleSuperAdmin)) {
                              return const SizedBox.shrink();
                            }

                            return AppIconButton(
                              icon: LucideIcons.circlePlus,
                              tooltip: 'New Form',
                              onPressed: _showNewFormSheet,
                            );
                          },
                        ),
                      if (!showSidebar) const SizedBox(width: 8),
                    ],
                  ),
                ),
                // Row 2: Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    controller: _tabController,
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    isScrollable: true,
                    tabAlignment: showSidebar ? null : TabAlignment.start,
                    dividerColor: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (index) {
                return _buildFormList(index);
              }),
            ),
          ),
        ],
      ),
      // bottomNavigationBar / scan FAB: handled by ShellScaffold
    );
  }

  Widget _buildFormList(int tabIndex) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final forms = _getFilteredForms(tabIndex);
    final isApprovalTab =
        (_isCenterHead || _isUnitHead || _isApprover) && tabIndex == 0;

    // Check if this is the "Signed" tab (Approved)
    // Center Head/Unit Head: index 2. Staff: index 3. Approver: index 1.
    final isSignedTab = ((_isCenterHead || _isUnitHead) && tabIndex == 2) ||
        (_isApprover && tabIndex == 1) ||
        (!_isApprover && !_isAdmin && tabIndex == 3);

    // If signed tab, we can show the upload button (Fab or Header?)
    // Let's add it to the top of the list if list is not empty,
    // or as part of the empty state.

    if (forms.isEmpty) {
      if (isApprovalTab) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.circleCheck,
                size: 80,
                color: AppColors.success.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'All caught up!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'No forms awaiting review',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
            ],
          ),
        );
      }
      return _buildEmptyState(tabIndex, isSignedTab);
    }

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _loadData,
      child: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: forms.length +
                (isSignedTab ? 1 : 0), // Add padding for FAB if needed
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (isSignedTab && index == 0) {
                // return upload button header
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: OutlinedButton.icon(
                    onPressed: _uploadSignedForm,
                    icon: const Icon(LucideIcons.fileUp),
                    label: const Text('Upload Signed Form'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                );
              }

              final formIndex = isSignedTab ? index - 1 : index;
              final form = forms[formIndex];

              if (isApprovalTab) {
                return _ActionableFormCard(
                  form: form,
                  isProcessing: _processingFormIds.contains(form.id),
                  onView: () => context
                      .push('/forms/view/${form.id}?mode=review')
                      .then((result) {
                    if (result == true && mounted) _loadData();
                  }),
                  onApprove: () => _approveForm(form),
                  onReturn: () => _returnForm(form),
                );
              }

              final tabName = _tabs.isNotEmpty && tabIndex < _tabs.length
                  ? _tabs[tabIndex]
                  : '';
              final isArchivedTab = tabName == 'Archived';
              final canManageArchive = _isUnitHead || _isAdmin;

              return _FormCard(
                form: form,
                onTap: () {
                  if (form.status == 'draft' ||
                      form.status == AppConstants.statusSubmitted) {
                    context.push(
                        '/forms/fill/${form.templateId}?formId=${form.id}');
                  } else {
                    final isPendingReview = form.status ==
                            AppConstants.statusPendingReview ||
                        form.status ==
                            AppConstants.statusPendingFinalApproval ||
                        form.status == AppConstants.statusPendingHeadApproval;
                    final url = isPendingReview
                        ? '/forms/view/${form.id}?mode=review'
                        : '/forms/view/${form.id}';
                    context.push(url).then((result) {
                      if (result == true && mounted) _loadData();
                    });
                  }
                },
                onArchive: canManageArchive && !isArchivedTab
                    ? () => _archiveForm(form)
                    : null,
                onRestore: canManageArchive && isArchivedTab
                    ? () => _restoreForm(form)
                    : null,
                onPermanentDelete: canManageArchive && isArchivedTab
                    ? () => _permanentDeleteForm(form)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex, bool isSignedTab) {
    String message;
    if (_isApprover) {
      switch (tabIndex) {
        case 0:
          message = 'No forms for review';
          break;
        case 1:
          message = 'No signed forms';
          break;
        case 2:
          message = 'No returned forms';
          break;
        default:
          message = 'No forms';
      }
    } else {
      switch (tabIndex) {
        case 0:
          message = 'No draft forms';
          break;
        case 1:
          message = 'No returned forms';
          break;
        case 2:
          message = 'No submitted forms';
          break;
        case 3:
          message = 'No signed forms';
          break;
        default:
          message = 'No forms yet';
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: const Icon(
              LucideIcons.fileText,
              size: 40,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (isSignedTab) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _uploadSignedForm,
              icon: const Icon(LucideIcons.fileUp),
              label: const Text('Upload Signed Form'),
            ),
          ] else if (!_isApprover)
            Text(
              'Create a new form to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: const Icon(
                LucideIcons.circleAlert,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load forms',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_error != null && _error!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewFormSheet() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final parentContext = context;
    final authState = context.read<AuthBloc>().state;
    String? userUnit;
    if (authState is AuthAuthenticated) {
      userUnit = authState.user.unit;
    }

    final formTypes = AppConstants.formTypesByUnit[userUnit] ??
        AppConstants.formTypesByUnit['social']!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! > 10) {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create New Form',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formTypes.length} templates available',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Template list
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: formTypes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final templateId = formTypes[index];
                      return _FormTypeCard(
                        templateId: templateId,
                        onTap: () async {
                          // 1. Close template selector
                          Navigator.pop(context);

                          // 2. Show resident picker using parent context
                          final resident = await showDialog<ResidentModel>(
                            context: parentContext,
                            builder: (context) {
                              final template =
                                  FormTemplatesRegistry.getById(templateId);
                              return _ResidentPickerDialog(
                                allowedStatuses:
                                    template?.allowedResidentStatuses,
                              );
                            },
                          );

                          // 3. If resident selected, navigate to form fill
                          if (resident != null && parentContext.mounted) {
                            await parentContext.push(
                              Uri(
                                path: '/forms/fill/$templateId',
                                queryParameters: {
                                  'residentId': resident.id,
                                  'residentName': resident.fullName,
                                },
                              ).toString(),
                            );
                            // Refresh logic after returning from form creation
                            if (parentContext.mounted) {
                              debugPrint(
                                  'DEBUG: Refreshing form list after create');
                              _refreshKey.currentState?.show();
                              _loadData();
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _isProcessing = false);
    });
  }
}

class _ActionableFormCard extends StatelessWidget {
  final FormSubmissionModel form;
  final VoidCallback onView;
  final VoidCallback onApprove;
  final VoidCallback onReturn;
  final bool isProcessing;

  const _ActionableFormCard({
    required this.form,
    required this.onView,
    required this.onApprove,
    required this.onReturn,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: InkWell(
        onTap: isProcessing ? null : onView,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: form.unitColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.fileText,
                          color: form.unitColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatTemplateName(form.templateType),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              form.residentName ?? 'Unknown Resident',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: form.unitColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          form.unit.toUpperCase(),
                          style: TextStyle(
                            color: form.unitColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Submitter info
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.user,
                        size: 16,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Submitted by ${form.submitterName ?? 'Unknown'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                      ),
                      const Spacer(),
                      const Icon(
                        LucideIcons.clock,
                        size: 16,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, h:mm a')
                            .format(form.submittedAt ?? form.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (form.isReturned && form.reviewComment != null) ...[
              const Divider(height: 1),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.info,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Returned by ${form.reviewerName ?? 'Reviewer'}: ${form.reviewComment}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const Divider(height: 1),
            // Actions removed: approvers must open the form to review/sign/return.
          ],
        ),
      ),
    );
  }
}

class _ResidentPickerDialog extends StatefulWidget {
  final List<String>? allowedStatuses;

  const _ResidentPickerDialog({this.allowedStatuses});

  @override
  State<_ResidentPickerDialog> createState() => _ResidentPickerDialogState();
}

class _ResidentPickerDialogState extends State<_ResidentPickerDialog> {
  final ResidentRepository _residentRepo = ResidentRepository();
  final TextEditingController _searchController = TextEditingController();

  List<ResidentModel> _residents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    try {
      // Restrict to assigned residents when user is staff-level homelife or social worker
      String? houseparentId;
      String? socialWorkerId;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated && authState.user.isStaff) {
        final u = authState.user;
        if (u.unit == AppConstants.unitHomelife ||
            u.role.startsWith('homelife')) {
          houseparentId = u.id;
        } else if (u.unit == AppConstants.unitSocial ||
            u.role == 'social_worker') {
          socialWorkerId = u.id;
        }
      }

      final residents = await _residentRepo.getResidents(
        statuses: widget.allowedStatuses ??
            ['admitted'], // Default to admitted if not specified
        houseparentId: houseparentId,
        socialWorkerId: socialWorkerId,
      );
      if (mounted) {
        setState(() {
          _residents = residents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getUserFriendlyMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  List<ResidentModel> get _filteredResidents {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _residents;

    return _residents.where((r) {
      return r.fullName.toLowerCase().contains(query) ||
          r.residentCode.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Resident',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select the resident this form is for',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by name or code...',
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : _filteredResidents.isEmpty
                          ? const Center(child: Text('No residents found'))
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredResidents.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final resident = _filteredResidents[index];
                                return Material(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () =>
                                        Navigator.pop(context, resident),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                AppColors.primarySurface,
                                            child: Text(
                                              (resident.fullName.isNotEmpty)
                                                  ? resident.fullName[0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  resident.fullName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '${resident.residentCode} • ${resident.wardName ?? "No Ward"}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(LucideIcons.chevronRight,
                                              color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Utility to format template type names for display
String _formatTemplateName(String templateType) {
  // Map of template types to user-friendly names
  const templateNames = {
    'pre_admission_checklist': 'Pre-Admission Checklist',
    'requirements_checklist': 'Requirements Checklist',
    'general_intake_sheet': 'General Intake Sheet',
    'admission_case_conference': 'Admission Case Conference',
    'clients_contract': "Client's Contract",
    'admission_slip': 'Admission Slip',
    'progress_notes': 'Progress Notes',
    'running_notes': 'Running Notes',
    'intervention_plan': 'Intervention Plan',
    'social_case_study': 'Social Case Study',
    'case_conference': 'Case Conference',
    'termination_report': 'Termination Report',
    'closing_summary': 'Closing Summary',
    'quarterly_narrative': 'Quarterly Narrative Report',
    'inventory_admission': 'Inventory Upon Admission',
    'inventory_discharge': 'Inventory Upon Discharge',
    'inventory_monthly': 'Monthly Inventory Report',
    'incident_report': 'Incident Report',
    'out_on_pass': 'Out on Pass',
    'group_sessions': 'Group Sessions Report',
    'individual_sessions': 'Individual Sessions Report',
    'inter_service_referral': 'Inter-Service Referral',
    'initial_assessment': 'Initial Assessment',
    'psychometrician_report': "Psychometrician's Report",
    'daily_vitals': 'Daily Vitals',
    'medical_abstract': 'Medical Abstract',
    'moca_p_scoring': 'MOCA-P Scoring',
    'behavior_log': 'Behavior Log',
    'therapy_session_notes': 'Therapy Session Notes',
    'daily_activity_log': 'Daily Activity Log',
  };

  // Return mapped name or format the raw template type
  if (templateNames.containsKey(templateType)) {
    return templateNames[templateType]!;
  }

  // Fallback: Convert snake_case to Title Case
  return templateType
      .split('_')
      .map((word) =>
          word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
      .join(' ');
}

class _FormCard extends StatelessWidget {
  final FormSubmissionModel form;
  final VoidCallback onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final VoidCallback? onPermanentDelete;

  const _FormCard({
    required this.form,
    required this.onTap,
    this.onArchive,
    this.onRestore,
    this.onPermanentDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        onLongPress: onArchive ?? onRestore, // Alternate trigger
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: form.unitColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  LucideIcons.fileText,
                  color: form.unitColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTemplateName(form.templateType),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            form.residentName ?? 'Resident',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(
                            color:
                                AppColors.textTertiary.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM d').format(form.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Status or Actions
              _StatusBadge(status: form.status, label: form.statusDisplayText),
              if (onArchive != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(LucideIcons.archive, color: AppColors.error),
                  onPressed: onArchive,
                  tooltip: 'Archive',
                )
              ] else if (onRestore != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(LucideIcons.rotateCcw,
                      color: AppColors.primary),
                  onPressed: onRestore,
                  tooltip: 'Restore',
                )
              ],
              if (onPermanentDelete != null) ...[
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: AppColors.error),
                  onPressed: onPermanentDelete,
                  tooltip: 'Delete Permanently',
                )
              ],
              if (onArchive == null &&
                  onRestore == null &&
                  onPermanentDelete == null) ...[
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _getStatusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  (Color, Color) _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return (
          AppColors.statusDraft,
          AppColors.surfaceHover,
        );
      case 'submitted':
        return (
          AppColors.statusSubmitted,
          AppColors.infoSurface,
        );
      case 'pending_review':
      case 'pending_supervisor':
      case 'pending_multi_approval':
      case 'pending_head_approval':
      case 'pending_final_approval':
      case 'pending_doctor_review':
      case 'pending_social_worker':
      case 'pending_medical_review':
        return (
          AppColors.statusPendingReview,
          AppColors.warningSurface,
        );
      case 'approved':
        return (
          AppColors.statusApproved,
          AppColors.successSurface,
        );
      case 'returned':
        return (
          AppColors.statusReturned,
          AppColors.errorSurface,
        );
      default:
        return (
          AppColors.textSecondary,
          AppColors.surfaceHover,
        );
    }
  }
}

class _FormTypeCard extends StatelessWidget {
  final String templateId;
  final VoidCallback onTap;

  const _FormTypeCard({
    required this.templateId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, displayName, unitName) = _getFormTypeInfo(templateId);

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                color: AppColors.textTertiary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, String, String) _getFormTypeInfo(String templateId) {
    final template = FormTemplatesRegistry.getById(templateId);
    if (template != null) {
      return (
        template.icon,
        AppColors.getServiceUnitColor(template.serviceUnit.name),
        template.name,
        template.serviceUnit.displayName,
      );
    }

    // Fallback with smart defaults
    if (templateId.startsWith('ss_')) {
      return (
        LucideIcons.users,
        AppColors.unitSocial,
        _formatTemplateName(templateId),
        'Social Service'
      );
    } else if (templateId.startsWith('hl_')) {
      return (
        LucideIcons.house,
        AppColors.unitHomelife,
        _formatTemplateName(templateId),
        'Home Life Service'
      );
    } else if (templateId.startsWith('ps_')) {
      return (
        LucideIcons.brain,
        AppColors.unitPsych,
        _formatTemplateName(templateId),
        'Psychological Service'
      );
    } else if (templateId.startsWith('med_')) {
      return (
        LucideIcons.stethoscope,
        AppColors.unitMedical,
        _formatTemplateName(templateId),
        'Medical Service'
      );
    } else if (templateId.startsWith('rehab_')) {
      return (
        LucideIcons.accessibility,
        AppColors.unitRehab,
        _formatTemplateName(templateId),
        'Rehabilitation'
      );
    }

    return (
      LucideIcons.fileText,
      AppColors.primary,
      _formatTemplateName(templateId),
      'Generic'
    );
  }
}
