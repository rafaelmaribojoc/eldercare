import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/models/resident_model.dart';
import '../../../data/models/form_submission_model.dart';
import '../../../data/models/timeline_entry_model.dart';
import '../../../data/repositories/resident_repository.dart';
import '../../../data/repositories/form_repository.dart';
import '../../../data/repositories/moca_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../forms/templates/form_templates.dart';
import '../../moca/bloc/moca_assessment_bloc.dart';
import '../../moca/models/moca_assessment_model.dart';
import '../../moca/constants/moca_colors.dart';
import 'admit_resident_wizard.dart';

import '../../../core/services/pdf_service.dart';
import '../../../core/services/nfc_service.dart';

import '../widgets/modern_notes/modern_resident_notes_sheet.dart';
import '../../../core/widgets/custom_error_dialog.dart';

class ResidentDetailScreen extends StatefulWidget {
  final String residentId;
  final bool
      isViewMode; // true = read-only (from residents list), false = full actions (from NFC)

  const ResidentDetailScreen({
    super.key,
    required this.residentId,
    this.isViewMode = false, // default to full mode for backward compatibility
  });

  @override
  State<ResidentDetailScreen> createState() => _ResidentDetailScreenState();
}

class _ResidentDetailScreenState extends State<ResidentDetailScreen> {
  ResidentModel? _resident;
  bool _isLoading = true;
  String? _error;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadResident();
  }

  Future<void> _loadResident() async {
    try {
      final repository = context.read<ResidentRepository>();
      final resident = await repository.getResidentById(widget.residentId);
      setState(() {
        _resident = resident;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandler.getUserFriendlyMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _resident == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(_hasChanges),
          ),
          title: const Text('Resident'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.circleAlert,
                  size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error ?? 'Could not load resident details.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(_hasChanges),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final resident = _resident!;
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final userUnit = user?.unit;
    final canManage = AppConstants.canManageResidents(user?.role, userUnit);

    // Get screen dimensions for responsive layout
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 360;
    final headerHeight = isSmallScreen ? 200.0 : 260.0;
    final avatarRadius = isSmallScreen ? 36.0 : 50.0;
    final nameFontSize = isSmallScreen ? 18.0 : 24.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => context.pop(_hasChanges),
            ),
            expandedHeight: headerHeight,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Photo
                        Hero(
                          tag: 'resident-${resident.id}',
                          child: CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: Colors.white,
                            backgroundImage: resident.photoUrl != null
                                ? CachedNetworkImageProvider(resident.photoUrl!)
                                : null,
                            child: resident.photoUrl == null
                                ? Text(
                                    resident.firstName[0] +
                                        resident.lastName[0],
                                    style: TextStyle(
                                      fontSize: avatarRadius * 0.64,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 16),
                        // Name
                        Text(
                          resident.fullName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        // Location
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 10 : 16,
                            vertical: isSmallScreen ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: isSmallScreen ? 14 : 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  resident.displayLocation,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Print Summary Button (New)
              IconButton(
                icon: const Icon(LucideIcons.printer, color: Colors.white),
                onPressed: () => PdfService.generateResidentProfile(resident),
                tooltip: 'Print Profile Summary',
              ),
              // Edit Button
              if (AppConstants.canManageResidents(
                  (context.read<AuthBloc>().state as AuthAuthenticated)
                      .user
                      .role,
                  (context.read<AuthBloc>().state as AuthAuthenticated)
                      .user
                      .unit))
                IconButton(
                  icon: const Icon(LucideIcons.pencil, color: Colors.white),
                  onPressed: () async {
                    await context.pushNamed(
                      'edit-resident',
                      pathParameters: {'id': resident.id},
                      extra: resident,
                    );
                    _loadResident(); // Reload after edit
                  },
                  tooltip: 'Edit Profile',
                ),
              IconButton(
                icon: const Icon(LucideIcons.chartNoAxesGantt,
                    color: Colors.white),
                onPressed: () => context.push(
                  '/residents/${resident.id}/timeline',
                ),
                tooltip: 'View Timeline',
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Pre-admission/Discharged Banner
                if (resident.status == 'pre_admission' ||
                    resident.status == 'discharged')
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.info,
                                color: AppColors.warning),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                resident.status == 'discharged'
                                    ? 'This resident has been discharged.'
                                    : 'This resident is currently in pre-admission status.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimaryLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (canManage)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                // Updated Logic: Show Allocation & Admission Wizard
                                final result = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) =>
                                      AdmitResidentWizard(resident: resident),
                                );

                                if (result == true) {
                                  _hasChanges = true;
                                  _loadResident(); // Reload on success
                                }
                              },
                              icon: const Icon(LucideIcons.logIn),
                              label: Text(resident.status == 'discharged'
                                  ? 'Re-admit Resident'
                                  : 'Admit Resident'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Quick Actions
                _buildQuickActions(context, resident, userUnit),
                const SizedBox(height: 24),

                // Basic Info
                _buildSectionCard(
                  context,
                  title: 'Basic Information',
                  icon: LucideIcons.user,
                  children: [
                    _buildInfoRow(
                        'Date of Birth',
                        DateFormat('MMMM d, yyyy')
                            .format(resident.dateOfBirth)),
                    _buildInfoRow('Age', '${resident.age} years old'),
                    _buildInfoRow('Sex', resident.gender.toUpperCase()),
                    if (resident.placeOfBirth != null)
                      _buildInfoRow('Place of Birth', resident.placeOfBirth!),
                    if (resident.religion != null)
                      _buildInfoRow('Religion', resident.religion!),
                    if (resident.civilStatus != null)
                      _buildInfoRow('Civil Status', resident.civilStatus!),
                    _buildInfoRow(
                        'Admission Date',
                        resident.admissionDate != null
                            ? DateFormat('MMMM d, yyyy')
                                .format(resident.admissionDate!)
                            : 'Not yet admitted'),
                    if (resident.applicationDate != null)
                      _buildInfoRow(
                          'Application Date',
                          DateFormat('MMMM d, yyyy')
                              .format(resident.applicationDate!)),
                    if (resident.referredBy != null)
                      _buildInfoRow('Referred By', resident.referredBy!),
                  ],
                ),
                const SizedBox(height: 16),

                // Address Information
                if (resident.province != null || resident.city != null)
                  Column(
                    children: [
                      _buildSectionCard(
                        context,
                        title: 'Address Information',
                        icon: LucideIcons.mapPin,
                        children: [
                          if (resident.streetAddress != null)
                            _buildInfoRow('Street', resident.streetAddress!),
                          if (resident.barangay != null)
                            _buildInfoRow('Barangay', resident.barangay!),
                          if (resident.city != null)
                            _buildInfoRow('City/Municipality', resident.city!),
                          if (resident.province != null)
                            _buildInfoRow('Province', resident.province!),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Family Background
                if (resident.nearestRelativeName != null ||
                    resident.familyComposition != null)
                  Column(
                    children: [
                      _buildSectionCard(
                        context,
                        title: 'Family Background',
                        icon: LucideIcons.users,
                        children: [
                          if (resident.nearestRelativeName != null)
                            _buildInfoRow('Nearest Relative',
                                resident.nearestRelativeName!),
                          if (resident.nearestRelativeAddress != null)
                            _buildInfoRow('Relative Address',
                                resident.nearestRelativeAddress!),
                          if (resident.custodianName != null)
                            _buildInfoRow('Custodian', resident.custodianName!),
                          if (resident.familyComposition != null &&
                              resident.familyComposition!.isNotEmpty) ...[
                            const Divider(),
                            const Text('Family Members:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            ...resident.familyComposition!.map((m) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Text(
                                      '• ${m['name']} (${m['relationship']}) - ${m['age']} yo'),
                                )),
                          ]
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                const SizedBox(height: 16),

                // Emergency Contact
                if (resident.emergencyContactName != null)
                  Column(
                    children: [
                      _buildSectionCard(
                        context,
                        title: 'Emergency Contact',
                        icon: LucideIcons.siren,
                        children: [
                          _buildInfoRow('Name', resident.emergencyContactName!),
                          if (resident.emergencyContactPhone != null)
                            _buildInfoRow(
                                'Phone', resident.emergencyContactPhone!),
                          if (resident.emergencyContactRelation != null)
                            _buildInfoRow('Relationship',
                                resident.emergencyContactRelation!),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Medical Info
                _buildSectionCard(
                  context,
                  title: 'Medical Information',
                  icon: LucideIcons.clipboardPlus,
                  children: [
                    if (resident.primaryDiagnosis != null)
                      _buildInfoRow(
                          'Primary Diagnosis', resident.primaryDiagnosis!),
                    if (resident.allergies != null)
                      _buildInfoRow('Allergies', resident.allergies!),
                    if (resident.medicalNotes != null)
                      _buildInfoRow('Notes', resident.medicalNotes!),
                    if (resident.primaryDiagnosis == null &&
                        resident.allergies == null &&
                        resident.medicalNotes == null)
                      const Text(
                        'No medical information recorded',
                        style: TextStyle(
                          color: AppColors.textSecondaryLight,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recent Forms Section
                _buildRecentFormsSection(context, resident),

                const SizedBox(height: 80), // Space for FAB
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/residents/${resident.id}/timeline'),
        icon: const Icon(LucideIcons.chartNoAxesGantt),
        label: const Text('View Timeline'),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    ResidentModel resident,
    String? userUnit,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSpacing = screenWidth < 360 ? 8.0 : 12.0;

    // Check if user can manage residents (transfer wards)
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final canManage = AppConstants.canManageResidents(user?.role, user?.unit);

    // Check if user is from psych unit (can do MoCA assessments)
    final isPsychUnit = userUnit == 'psych';

    // Check if user can make notes for this resident
    final canMakeNotes = AppConstants.canMakeNotesForResident(
      role: user?.role,
      unit: user?.unit,
      userId: user?.id,
      residentSocialWorkerId: resident.socialWorkerId,
      residentHouseparentId: resident.houseparentId,
    );

    debugPrint(
        '[ResidentDetail] User Role: ${user?.role}, Restricting CenterHead/SuperAdmin? ${user?.role == AppConstants.roleCenterHead || user?.role == AppConstants.roleSuperAdmin}');

    // View Mode: Hide all action buttons when accessed from residents list
    if (widget.isViewMode) {
      return const SizedBox.shrink();
    }

    // Action Mode: Show all buttons including New Form and New Assessment
    final bool canCreateForms = user?.role != AppConstants.roleCenterHead &&
        user?.role != AppConstants.roleSuperAdmin;

    // Build first row buttons dynamically to avoid spacing issues
    final List<Widget> row1Buttons = [];
    if (canCreateForms) {
      row1Buttons.add(Expanded(
        child: _QuickActionButton(
          icon: LucideIcons.fileText,
          label: 'New Form',
          color: AppColors.primary,
          compact: screenWidth < 360,
          onTap: () => _showFormSelector(context, resident, userUnit),
        ),
      ));
    }
    if (canMakeNotes) {
      row1Buttons.add(Expanded(
        child: _QuickActionButton(
          icon: LucideIcons.filePlus,
          label: 'Quick Note',
          color: AppColors.warning,
          compact: screenWidth < 360,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ModernResidentNotesSheet(
              residentId: resident.id,
              residentName: resident.fullName,
              canAddNotes: canMakeNotes,
            ),
          ),
        ),
      ));
    }
    row1Buttons.add(Expanded(
      child: _QuickActionButton(
        icon: LucideIcons.folderOpen,
        label: 'Forms',
        color: AppColors.secondary,
        compact: screenWidth < 360,
        onTap: () => _showResidentForms(context, resident),
      ),
    ));
    row1Buttons.add(Expanded(
      child: _QuickActionButton(
        icon: LucideIcons.fileText,
        label: 'Export',
        color: AppColors.accent,
        compact: screenWidth < 360,
        onTap: () => _exportResidentProfile(context, resident),
      ),
    ));

    // Intersperse spacing between buttons
    final List<Widget> row1 = [];
    for (int i = 0; i < row1Buttons.length; i++) {
      if (i > 0) row1.add(SizedBox(width: buttonSpacing));
      row1.add(row1Buttons[i]);
    }

    return Column(
      children: [
        Row(children: row1),
        // Assessment button for psych unit
        if (isPsychUnit) ...[
          SizedBox(height: buttonSpacing),
          Row(
            children: [
              if (user?.role != AppConstants.roleCenterHead &&
                  user?.role != AppConstants.roleSuperAdmin)
                Expanded(
                  child: _QuickActionButton(
                    icon: LucideIcons.brain,
                    label: 'New Assessment',
                    color: MocaColors.primary,
                    compact: screenWidth < 360,
                    onTap: () => _startMocaAssessment(context, resident),
                  ),
                ),
              if (user?.role != AppConstants.roleCenterHead &&
                  user?.role != AppConstants.roleSuperAdmin)
                SizedBox(width: buttonSpacing),
              Expanded(
                child: _QuickActionButton(
                  icon: LucideIcons.history,
                  label: 'Timeline',
                  color: AppColors.info,
                  compact: screenWidth < 360,
                  onTap: () =>
                      context.push('/residents/${resident.id}/timeline'),
                ),
              ),
            ],
          ),
        ],
        if (canManage) ...[
          SizedBox(height: buttonSpacing),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: LucideIcons.arrowLeftRight,
                  label: 'Transfer Ward',
                  color: AppColors.warning,
                  compact: screenWidth < 360,
                  onTap: () => _showWardTransferDialog(context, resident),
                ),
              ),
              if (!isPsychUnit) ...[
                SizedBox(width: buttonSpacing),
                Expanded(
                  child: _QuickActionButton(
                    icon: LucideIcons.history,
                    label: 'Timeline',
                    color: AppColors.info,
                    compact: screenWidth < 360,
                    onTap: () =>
                        context.push('/residents/${resident.id}/timeline'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// Start MoCA-P assessment with auto-filled resident data
  void _startMocaAssessment(BuildContext context, ResidentModel resident) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    // Default education years to 0 (will trigger adjustment if < 12 years)
    // In real implementation, this would be fetched from resident data
    const educationYears = 0;

    // Start assessment with resident data auto-filled
    context.read<MocaAssessmentBloc>().add(
          MocaStartAssessment(
            residentId: resident.id,
            clinicianId: user?.id,
            residentName: resident.fullName,
            residentSex: resident.gender,
            residentBirthday: resident.dateOfBirth,
            educationYears: educationYears,
            educationAdjustment: educationYears < 12,
          ),
        );

    // Navigate directly to first assessment section
    // Skip MoCA home screen - assessments start immediately from resident selection
    context.go('/moca/visuospatial');
  }

  void _showResidentForms(BuildContext context, ResidentModel resident) {
    context.push('/residents/${resident.id}/case-files', extra: resident);
  }

  Future<void> _exportResidentProfile(
      BuildContext context, ResidentModel resident) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing export data...')),
    );

    try {
      // Fetch all data for export
      final formRepo = FormRepository();
      final mocaRepo = MocaRepository();

      final forms = await formRepo.getFormsByResident(resident.id);
      final timeline = await formRepo.getTimeline(residentId: resident.id);
      final mocaAssessments =
          await mocaRepo.getAssessmentsByResident(resident.id);

      // Show dialog with export options
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(LucideIcons.fileText, color: AppColors.accent),
                const SizedBox(width: 8),
                const Text('Export Profile'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export ${resident.fullName}\'s complete profile?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHover,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExportItem(LucideIcons.user, 'Basic Information'),
                      _buildExportItem(
                          LucideIcons.clipboardPlus, 'Medical Records'),
                      _buildExportItem(LucideIcons.siren, 'Emergency Contact'),
                      _buildExportItem(
                          LucideIcons.fileText, '${forms.length} Form(s)'),
                      _buildExportItem(LucideIcons.brain,
                          '${mocaAssessments.length} MoCA Assessment(s)'),
                      _buildExportItem(LucideIcons.chartNoAxesGantt,
                          '${timeline.length} Timeline Event(s)'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await _generateProfilePdf(
                      resident, forms, mocaAssessments, timeline);
                },
                icon: const Icon(LucideIcons.fileText),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomErrorDialog.show(context,
            title: 'Export Failed',
            error: e,
            message: 'Could not generate profile export.');
      }
    }
  }

  Widget _buildExportItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondaryLight),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _linkNfcTag(BuildContext context, ResidentModel resident) async {
    try {
      final nfcService = context.read<NfcService>();
      final isAvailable = await nfcService.isAvailable();

      if (!context.mounted) return;

      if (!isAvailable) {
        CustomErrorDialog.show(context,
            title: 'NFC Error',
            message: 'NFC is not supported or enabled on this device.');
        return;
      }

      // Show instruction dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Ready to Scan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.nfc, size: 60, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Hold the NFC wristband or tag to the back of your specific NFC area in your device.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                nfcService.stopSession();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      // Start Scan
      final tagId = await nfcService.scanTag();

      if (!context.mounted) return;
      Navigator.pop(context); // Close dialog

      if (tagId != null) {
        // Save to DB
        final repository = context.read<ResidentRepository>();
        await repository.linkNfcTag(residentId: resident.id, nfcTagId: tagId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('NFC Tag linked successfully! ID: $tagId'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadResident(); // Refresh
        }
      }
    } catch (e) {
      if (mounted) {
        // Close dialog if open? Hard to track context of dialog here easily without key
        // Assuming scanTag throws or returns error, we might still be in dialog if we didn't pop
        // But we popped above.
        // Actually, if scanTag throws, we haven't popped yet.
        Navigator.pop(context); // Close dialog
        CustomErrorDialog.show(context,
            title: 'NFC Error', error: e, message: 'Failed to link NFC tag.');
      }
    }
  }

  Future<void> _generateProfilePdf(
    ResidentModel resident,
    List<FormSubmissionModel> forms,
    List<MocaAssessmentModel> mocaAssessments,
    List<TimelineEntryModel> timeline,
  ) async {
    try {
      // Show progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating PDF...')),
        );
      }

      // Use the printing package to generate PDF
      final pdf =
          await _buildProfilePdf(resident, forms, mocaAssessments, timeline);

      // Open print/share dialog
      await Printing.layoutPdf(
        onLayout: (format) async => pdf,
        name:
            '${resident.fullName}_Profile_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
    } catch (e) {
      if (mounted) {
        CustomErrorDialog.show(context,
            title: 'PDF Error', error: e, message: 'Failed to generate PDF.');
      }
    }
  }

  Future<Uint8List> _buildProfilePdf(
    ResidentModel resident,
    List<FormSubmissionModel> forms,
    List<MocaAssessmentModel> mocaAssessments,
    List<TimelineEntryModel> timeline,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(
            'Generated: ${DateFormat('MMMM d, yyyy h:mm a').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          // Header with logo placeholder
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RESIDENT PROFILE REPORT',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  resident.fullName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Resident Code: ${resident.residentCode} | Location: ${resident.displayLocation}',
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Basic Information Section
          _pdfSectionHeader('Basic Information'),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
                _pdfInfoRow('Date of Birth',
                    DateFormat('MMMM d, yyyy').format(resident.dateOfBirth)),
                _pdfInfoRow('Age', '${resident.age} years'),
                _pdfInfoRow('Sex', resident.gender.toUpperCase()),
                _pdfInfoRow(
                    'Admission Date',
                    resident.admissionDate != null
                        ? DateFormat('MMMM d, yyyy')
                            .format(resident.admissionDate!)
                        : 'Not yet admitted'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Emergency Contact Section
          if (resident.emergencyContactName != null) ...[
            _pdfSectionHeader('Emergency Contact'),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                children: [
                  _pdfInfoRow('Name', resident.emergencyContactName!),
                  if (resident.emergencyContactPhone != null)
                    _pdfInfoRow('Phone', resident.emergencyContactPhone!),
                  if (resident.emergencyContactRelation != null)
                    _pdfInfoRow(
                        'Relationship', resident.emergencyContactRelation!),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Medical Information Section
          _pdfSectionHeader('Medical Information'),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (resident.primaryDiagnosis != null)
                  _pdfInfoRow('Primary Diagnosis', resident.primaryDiagnosis!),
                if (resident.allergies != null)
                  _pdfInfoRow('Allergies', resident.allergies!),
                if (resident.medicalNotes != null)
                  _pdfInfoRow('Medical Notes', resident.medicalNotes!),
                if (resident.primaryDiagnosis == null &&
                    resident.allergies == null &&
                    resident.medicalNotes == null)
                  pw.Text('No medical information recorded',
                      style: pw.TextStyle(
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // MoCA Assessments Section
          if (mocaAssessments.isNotEmpty) ...[
            _pdfSectionHeader(
                'MoCA-P Cognitive Assessments (${mocaAssessments.length})'),
            pw.TableHelper.fromTextArray(
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding: const pw.EdgeInsets.all(6),
              headers: [
                'Date',
                'Score',
                'Risk Level',
                'Normal %',
                'MCI %',
                'Dementia %'
              ],
              data: mocaAssessments
                  .take(10)
                  .map((a) => [
                        DateFormat('MMM d, yyyy')
                            .format(a.completedAt ?? a.startedAt),
                        '${a.adjustedScore}/${a.maxScore}',
                        a.riskLevel ?? 'N/A',
                        '${((a.normalProbability ?? 0) * 100).toStringAsFixed(1)}%',
                        '${((a.mciProbability ?? 0) * 100).toStringAsFixed(1)}%',
                        '${((a.dementiaProbability ?? 0) * 100).toStringAsFixed(1)}%',
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 16),
          ],

          // Forms History Section
          _pdfSectionHeader('Forms History (${forms.length})'),
          if (forms.isEmpty)
            pw.Text('No forms on record',
                style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic, color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding: const pw.EdgeInsets.all(6),
              headers: ['Form Type', 'Date', 'Status', 'Unit'],
              data: forms
                  .take(20)
                  .map((f) => [
                        _getFormDisplayName(f.templateType),
                        DateFormat('MMM d, yyyy').format(f.createdAt),
                        f.status.toUpperCase(),
                        f.unit.toUpperCase(),
                      ])
                  .toList(),
            ),
          pw.SizedBox(height: 16),

          // Timeline Section (Recent Events)
          _pdfSectionHeader('Recent Timeline Events (${timeline.length})'),
          if (timeline.isEmpty)
            pw.Text('No timeline events recorded',
                style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic, color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding: const pw.EdgeInsets.all(6),
              headers: ['Date', 'Event', 'Unit', 'By'],
              data: timeline
                  .take(15)
                  .map((t) => [
                        DateFormat('MMM d, yyyy').format(t.createdAt),
                        t.title,
                        t.unitDisplayName,
                        t.creatorName ?? 'System',
                      ])
                  .toList(),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
              child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  void _showWardTransferDialog(BuildContext context, ResidentModel resident) {
    String? selectedWardId = resident.currentWardId;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Transfer Ward'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transfer ${resident.fullName} to a different ward:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: context.read<ResidentRepository>().getWards(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Failed to load wards');
                }
                final wards = snapshot.data!;
                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return DropdownButtonFormField<String>(
                      initialValue: selectedWardId,
                      decoration: const InputDecoration(
                        labelText: 'Select Ward',
                        prefixIcon: Icon(LucideIcons.mapPin),
                      ),
                      items: wards.map((ward) {
                        return DropdownMenuItem(
                          value: ward.id,
                          child: Text(ward.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedWardId = value);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedWardId != null &&
                  selectedWardId != resident.currentWardId) {
                Navigator.pop(dialogContext);
                await _transferResident(resident, selectedWardId!);
              }
            },
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  Future<void> _transferResident(
      ResidentModel resident, String newWardId) async {
    try {
      final repository = context.read<ResidentRepository>();
      await repository.updateResident(
        id: resident.id,
        wardId: newWardId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resident transferred successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadResident(); // Refresh the data
      }
    } catch (e) {
      if (mounted) {
        CustomErrorDialog.show(context,
            title: 'Transfer Failed',
            error: e,
            message: 'Failed to transfer resident.');
      }
    }
  }

  void _showFormSelector(
    BuildContext context,
    ResidentModel resident,
    String? userUnit,
  ) {
    if (userUnit == null) {
      CustomErrorDialog.show(context,
          title: 'Access Denied',
          message: 'You need to be assigned to a unit to create forms.');
      return;
    }

    // Guard: Staff-level social workers and houseparents can only create forms
    // for residents assigned to them.
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.isStaff) {
      final user = authState.user;
      final isSocialWorker =
          user.unit == AppConstants.unitSocial || user.role == 'social_worker';
      final isHouseparent = user.unit == AppConstants.unitHomelife ||
          user.role.startsWith('homelife');

      if (isSocialWorker && resident.socialWorkerId != user.id) {
        CustomErrorDialog.show(context,
            title: 'Access Denied',
            message:
                'You can only create forms for residents assigned to you.');
        return;
      }
      if (isHouseparent && resident.houseparentId != user.id) {
        CustomErrorDialog.show(context,
            title: 'Access Denied',
            message:
                'You can only create forms for residents assigned to you.');
        return;
      }
    }

    final formTypes = AppConstants.formTypesByUnit[userUnit] ?? [];

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
                          color: AppColors.textTertiary.withOpacity(0.4),
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
                              'Select Form Type',
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
                        onTap: () {
                          Navigator.pop(context);
                          context.push(
                            '/forms/fill/$templateId?residentId=${resident.id}&residentName=${Uri.encodeComponent(resident.fullName)}',
                          );
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
    );
  }

  String _getFormDisplayName(String templateId) {
    final template = FormTemplatesRegistry.getById(templateId);
    if (template != null) {
      return template.name;
    }
    // Fallback: format the ID nicely
    return templateId
        .replaceAll('ss_', '')
        .replaceAll('hl_', '')
        .replaceAll('ps_', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
        .join(' ');
  }

  Widget _buildRecentFormsSection(
      BuildContext context, ResidentModel resident) {
    return FutureBuilder<List<FormSubmissionModel>>(
      future: FormRepository().getFormsByResident(resident.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final forms = snapshot.data ?? [];

        final existingIds = forms.map((f) => f.templateId).toSet();
        final expectedAdmission = FormTemplatesRegistry.templates.where((t) {
          return t.allowedResidentStatuses.contains(resident.status) &&
              t.category == CaseFileCategory.admission;
        }).toList();
        final admTotal = expectedAdmission.length;
        final admComplete =
            expectedAdmission.where((t) => existingIds.contains(t.id)).length;
        final admPct = admTotal > 0 ? admComplete / admTotal : 1.0;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.folderOpen,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Case Files',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    Text(
                      '${forms.length} forms',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (admTotal > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: admPct,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              admPct >= 1.0
                                  ? AppColors.success
                                  : admPct >= 0.7
                                      ? AppColors.warning
                                      : AppColors.error,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$admComplete/$admTotal admission',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 24),
                if (forms.isEmpty)
                  const Text(
                    'No forms created yet',
                    style: TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  ...forms.take(3).map((form) => _buildFormTile(context, form)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showResidentForms(context, resident),
                    icon: const Icon(LucideIcons.folderOpen, size: 16),
                    label: const Text('View Case Files'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormTile(BuildContext context, FormSubmissionModel form) {
    final statusColor = _getStatusColor(form.status);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          LucideIcons.fileText,
          color: statusColor,
          size: 20,
        ),
      ),
      title: Text(
        _getFormDisplayName(form.templateType),
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        DateFormat('MMM d, yyyy').format(form.createdAt),
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          (form.status.isEmpty ? 'STATUS' : form.status).toUpperCase(),
          style: TextStyle(
            color: statusColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () {
        context.push('/forms/view/${form.id}');
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'submitted':
      case 'pending_review':
        return AppColors.warning;
      case 'returned':
        return AppColors.error;
      case 'draft':
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use column layout for very small screens
          if (constraints.maxWidth < 280) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            );
          }
          // Use row layout for larger screens
          final labelWidth = constraints.maxWidth < 350 ? 100.0 : 120.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(compact ? 8 : 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 10 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: compact ? 20 : 24),
              SizedBox(height: compact ? 2 : 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 10 : 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Form type card matching the Create New Form modal style
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
                  color: color.withOpacity(0.1),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                color: AppColors.textTertiary.withOpacity(0.5),
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

    // Fallback with smart defaults based on template ID prefix
    if (templateId.startsWith('ss_')) {
      return (
        LucideIcons.users,
        AppColors.unitSocial,
        _formatTemplateId(templateId),
        'Social Service'
      );
    } else if (templateId.startsWith('hl_')) {
      return (
        LucideIcons.house,
        AppColors.unitHomelife,
        _formatTemplateId(templateId),
        'Home Life Service'
      );
    } else if (templateId.startsWith('ps_')) {
      return (
        LucideIcons.brain,
        AppColors.unitPsych,
        _formatTemplateId(templateId),
        'Psychological Service'
      );
    } else if (templateId.startsWith('med_')) {
      return (
        LucideIcons.stethoscope,
        AppColors.unitMedical,
        _formatTemplateId(templateId),
        'Medical Service'
      );
    } else if (templateId.startsWith('rehab_')) {
      return (
        LucideIcons.accessibility,
        AppColors.unitRehab,
        _formatTemplateId(templateId),
        'Rehabilitation'
      );
    }

    return (
      LucideIcons.fileText,
      AppColors.primary,
      _formatTemplateId(templateId),
      'Generic'
    );
  }

  String _formatTemplateId(String templateId) {
    return templateId
        .replaceAll(RegExp(r'^(ss_|hl_|ps_|med_|rehab_)'), '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
        .join(' ');
  }
}
