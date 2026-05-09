import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/bloc/auth_bloc.dart';

import '../templates/form_templates.dart';
import '../pdf/pdf_generator.dart';
import '../../../data/repositories/form_repository.dart'; // Added
import '../../../core/constants/app_constants.dart'; // Added
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_error_dialog.dart';

/// Responsive screen for previewing and printing form PDFs
class FormPdfPreviewScreen extends StatefulWidget {
  final FormTemplate template;
  final Map<String, dynamic> formData;
  final String residentName;
  final String residentId;
  final String? submissionId;
  final String? caseNumber;
  final bool isEditing;
  final String? status;

  const FormPdfPreviewScreen({
    super.key,
    required this.template,
    required this.formData,
    required this.residentName,
    required this.residentId,
    this.submissionId,
    this.caseNumber,
    this.isEditing = false,
    this.status,
  });

  @override
  State<FormPdfPreviewScreen> createState() => _FormPdfPreviewScreenState();
}

class _FormPdfPreviewScreenState extends State<FormPdfPreviewScreen> {
  bool _isLoading = true;
  String? _error;
  bool _isSignedWithNfc = false;
  Uint8List? _cachedPdfBytes; // Cache for generated PDF bytes

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await PdfGenerator.initialize();

      // Optimistically start generating the PDF immediately in the background
      // while the screen is still showing the initial loading spinner.
      _generatePdf().then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }).catchError((e, stackTrace) {
        debugPrint('[PdfPreview] PDF generation error: $e\n$stackTrace');
        if (mounted) {
          setState(() {
            _error = ErrorHandler.getUserFriendlyMessage(e);
            _isLoading = false;
          });
        }
      });
    } catch (e, stackTrace) {
      debugPrint('[PdfPreview] Initialization error: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getUserFriendlyMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screen) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.template.name,
              style: TextStyle(
                fontSize:
                    screen.value(mobile: 16.0, tablet: 18.0, desktop: 20.0),
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.backgroundDark
                : AppColors.getServiceUnitColor(
                    widget.template.serviceUnit.name),
            foregroundColor: AppColors.textInverse,
            actions: _buildActions(screen),
          ),
          body: _buildBody(screen),
          bottomNavigationBar: _buildBottomBar(screen),
        );
      },
    );
  }

  List<Widget> _buildActions(ScreenInfo screen) {
    if (screen.isMobile) {
      // Mobile: Use popup menu
      return [
        PopupMenuButton<String>(
          icon: const Icon(LucideIcons.ellipsisVertical),
          onSelected: (value) {
            switch (value) {
              case 'share':
                _sharePdf();
                break;
              case 'print':
                _printPdf();
                break;
              case 'download_pdf':
                _downloadPdf(context, null, null);
                break;
              case 'download_docx':
                _downloadDocx();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download_pdf',
              child: ListTile(
                leading: Icon(LucideIcons.fileText),
                title: Text('Download as PDF'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'download_docx',
              child: ListTile(
                leading: Icon(LucideIcons.fileText),
                title: Text('Download as Word'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(LucideIcons.share2),
                title: Text('Share'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'print',
              child: ListTile(
                leading: Icon(LucideIcons.printer),
                title: Text('Print'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ];
    }

    // Tablet/Desktop: Show action buttons
    return [
      OutlinedButton.icon(
        onPressed: () => _showDownloadOptions(),
        icon: const Icon(LucideIcons.download),
        label: const Text('Download'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
        ),
      ),
      const SizedBox(width: 8),
      OutlinedButton.icon(
        onPressed: _sharePdf,
        icon: const Icon(LucideIcons.share2),
        label: const Text('Share'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
        ),
      ),
      const SizedBox(width: 8),
      OutlinedButton.icon(
        onPressed: _printPdf,
        icon: const Icon(LucideIcons.printer),
        label: const Text('Print'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
        ),
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildBottomBar(ScreenInfo screen) {
    // Check if form is already approved/submitted to determine button state
    final status = widget.status ?? widget.formData['status'];
    final isReadOnly = status == AppConstants.statusApproved;
    final isSigned = status == AppConstants.statusSubmitted;

    // If fully approved, there's no need to show the editor or signing actions
    if (isReadOnly) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screen.horizontalPadding,
        vertical: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.filePenLine),
                label: const Text('Back to Editor'),
              ),
            ),
            if (!isReadOnly) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveForSigning,
                  icon: const Icon(LucideIcons.clipboardCheck),
                  label: Text(
                    isSigned ? 'Update Submission' : 'Save for Signing',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveForSigning() async {
    setState(() => _isLoading = true);
    try {
      // We need to use FormRepository to save/update.
      // Copy logic from FormFillScreen generally.
      // But we need to ensure we have a valid submission ID or create one.

      // Note: FormPdfPreviewScreen doesn't usually edit data, but "Save for Signing" implies changing status to 'submitted'.

      final formRepository = context.read<FormRepository>();

      // If we don't have submissionId, we must create one.
      // But FormPdfPreviewScreen is usually pushed FROM FormFillScreen which HAS the data.

      String? currentSubmissionId = widget.submissionId;

      // Prepare data
      Map<String, dynamic> dataToSave = Map.from(widget.formData);
      dataToSave['status'] = AppConstants.statusSubmitted;

      if (currentSubmissionId != null) {
        // yield to event loop
        await Future.delayed(Duration.zero);

        await formRepository.updateDraft(
          id: currentSubmissionId,
          formData: dataToSave,
          status: AppConstants.statusSubmitted,
        );
      } else {
        final submission = await formRepository.createDraft(
          residentId: widget.residentId,
          templateId: widget.template.id,
          templateType: widget.template.templateType,
          unit: widget.template.serviceUnit.name, // Approximate unit
          formData: dataToSave,
          status: AppConstants.statusSubmitted,
        );
        currentSubmissionId = submission.id;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form saved for signing successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // Navigate back?
        // Since we signed it, maybe go back to list.
        Navigator.of(context).pop(true); // Return true to refresh
      }
    } catch (e) {
      if (mounted) {
        CustomErrorDialog.show(context,
            title: 'Save Failed',
            error: e,
            message: 'Failed to save form for signing.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _getFormDataWithUser() {
    final authState = context.read<AuthBloc>().state;
    final Map<String, dynamic> data = Map.from(widget.formData);

    if (authState is AuthAuthenticated) {
      data['user_name'] = authState.user.fullName;
      data['user_license'] = authState.user.licenseNo; // Added license mapping
      if (_isSignedWithNfc) {
        data['user_name'] = "${authState.user.fullName} (Verified)";
        data['user_title'] = "${authState.user.jobTitle} • Digitally Signed";
        data['prepared_by_position'] =
            "${authState.user.jobTitle} • Digitally Signed";
      } else {
        data['user_title'] = authState.user.jobTitle;
        data['prepared_by_position'] = authState.user.jobTitle;
      }
    }

    return data;
  }

  Widget _buildBody(ScreenInfo screen) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(
                height:
                    screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0)),
            Text(
              'Generating PDF...',
              style: TextStyle(
                fontSize:
                    screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(screen.horizontalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: screen.value(mobile: 48.0, tablet: 56.0, desktop: 64.0),
                color: AppColors.error,
              ),
              SizedBox(
                  height:
                      screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              Text(
                'Error generating PDF',
                style: TextStyle(
                  fontSize:
                      screen.value(mobile: 18.0, tablet: 20.0, desktop: 22.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize:
                      screen.value(mobile: 13.0, tablet: 14.0, desktop: 15.0),
                ),
              ),
              SizedBox(
                  height:
                      screen.value(mobile: 20.0, tablet: 22.0, desktop: 24.0)),
              ElevatedButton.icon(
                onPressed: _initialize,
                icon: const Icon(LucideIcons.refreshCw),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return PdfPreview(
      build: (format) => _generatePdf(),
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      allowPrinting: false,
      allowSharing: false,
      maxPageWidth: screen.value(mobile: 400.0, tablet: 600.0, desktop: 700.0),
      pdfFileName: _getFileName(),
      initialPageFormat: PdfPageFormat.letter,
      padding: EdgeInsets.all(
          screen.value(mobile: 8.0, tablet: 16.0, desktop: 24.0)),
      loadingWidget: _cachedPdfBytes != null
          ? null // No spinner if already primed
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(
                      height: screen.value(
                          mobile: 12.0, tablet: 14.0, desktop: 16.0)),
                  Text(
                    'Loading preview...',
                    style: TextStyle(
                      fontSize: screen.value(
                          mobile: 14.0, tablet: 15.0, desktop: 16.0),
                    ),
                  ),
                ],
              ),
            ),
      onError: (context, error) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: screen.value(mobile: 40.0, tablet: 44.0, desktop: 48.0),
                color: AppColors.error,
              ),
              const SizedBox(height: 8),
              Text(
                'Error: ${ErrorHandler.getUserFriendlyMessage(error)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:
                      screen.value(mobile: 13.0, tablet: 14.0, desktop: 15.0),
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        );
      },
      actions: [],
    );
  }

  Future<Uint8List> _generatePdf() async {
    // Return cached bytes if available to avoid redundant calls
    if (_cachedPdfBytes != null) {
      return _cachedPdfBytes!;
    }

    final data = await _getFormDataWithSignatures();

    final bytes = await PdfGenerator.generatePdf(
      template: widget.template,
      data: data,
      residentName: widget.residentName,
      caseNumber: widget.caseNumber,
    );

    _cachedPdfBytes = bytes;
    return bytes;
  }

  Future<Map<String, dynamic>> _getFormDataWithSignatures() async {
    final data = _getFormDataWithUser();
    final authState = context.read<AuthBloc>().state;
    final submissionId = widget.submissionId;
    if (submissionId != null && submissionId.isNotEmpty) {
      try {
        final client = Supabase.instance.client;
        final sigsRes = await client
            .from('form_signatures')
            .select(
                'field_name, signature_url, signer_id, profiles(full_name, title)')
            .eq('form_submission_id', submissionId);

        for (var row in sigsRes) {
          if (row['signature_url'] != null) {
            final fieldStr = row['field_name'] as String;
            data['${fieldStr}_signature_url'] = row['signature_url'];

            if (row['profiles'] != null) {
              final fullName = row['profiles']['full_name'];
              final title = row['profiles']['title'];

              // Generic: populate the fieldStr key with the signer's name
              if (fullName != null) data[fieldStr] = fullName;
              if (title != null) {
                // Handle "None" designation
                data['${fieldStr}_designation'] =
                    (title.toString().toLowerCase() == 'none') ? null : title;
              }

              // Handle specific aliases for consistency across templates
              if (fieldStr == 'noted_by') {
                data['noted_by_name'] = fullName;
                data['noted_by_signature_url'] = row['signature_url'];
                data['noted_by_designation'] =
                    (title.toString().toLowerCase() == 'none')
                        ? 'CENTER HEAD'
                        : title;
                // Map noted_by to center_head aliases as well
                data['center_head_name'] = fullName;
                data['center_head'] = fullName;
                data['center_head_signature_url'] = row['signature_url'];
                data['center_head_designation'] = data['noted_by_designation'];
                data['approved_by'] = fullName;
                data['approved_by_designation'] = data['noted_by_designation'];
              } else if (fieldStr == 'center_head_name' ||
                  fieldStr == 'approved_by' ||
                  fieldStr == 'center_head') {
                data['center_head_name'] = fullName;
                data['center_head_signature_url'] = row['signature_url'];
                data['center_head_designation'] =
                    (title.toString().toLowerCase() == 'none')
                        ? 'CENTER HEAD'
                        : title;
                // Add alias without _name for templates using just center_head
                data['center_head'] = fullName;
                data['noted_by'] = fullName;
                data['noted_by_signature_url'] = row['signature_url'];
                data['noted_by_designation'] = data['center_head_designation'];
                data['approved_by_designation'] =
                    data['center_head_designation'];
              } else if (fieldStr == 'medical_staff_name') {
                data['medical_staff_name'] = fullName;
                data['medical_staff'] = fullName; // Alias
                data['medical_staff_name_signature_url'] = row['signature_url'];
                data['medical_staff_designation'] =
                    (title.toString().toLowerCase() == 'none')
                        ? 'DOCTOR'
                        : title;
              } else if (fieldStr == 'prepared_by') {
                data['prepared_by'] = fullName;
                data['user_name'] = fullName;
                data['prepared_by_name'] = fullName;
                data['prepared_by_signature_url'] = row['signature_url'];
                data['prepared_by_designation'] =
                    (title.toString().toLowerCase() == 'none') ? null : title;
              }
            }
          }
        }

        // Also fetch form_approvals to get designations BEFORE signatures are applied
        try {
          final approvalsRes = await client
              .from('form_approvals')
              .select('signature_field_name, recipient_id, recipient_name')
              .eq('form_submission_id', submissionId);

          if (approvalsRes.isNotEmpty) {
            final recipientIds =
                approvalsRes.map((r) => r['recipient_id'] as String).toList();
            final profilesRes = await client
                .from('profiles')
                .select('id, title, role')
                .inFilter('id', recipientIds);

            final profileMap = {for (var p in profilesRes) p['id']: p};

            for (var row in approvalsRes) {
              final fieldStr = row['signature_field_name'] as String?;
              if (fieldStr != null && fieldStr.isNotEmpty) {
                final fullName = row['recipient_name'];
                final profile = profileMap[row['recipient_id']];
                final title = profile != null ? profile['title'] : null;
                final role = profile != null ? profile['role'] : null;

                if (fullName != null) {
                  // Generic name assignment (only if not already set by signatures)
                  data[fieldStr] ??= fullName;
                }

                String? designation;
                if (title != null &&
                    title.toString().trim().isNotEmpty &&
                    title.toString().toLowerCase() != 'none') {
                  designation = title.toString();
                }

                if (designation != null) {
                  data['${fieldStr}_designation'] ??= designation;
                }

                // Handle aliases just like in signatures
                if (fieldStr == 'noted_by') {
                  data['noted_by_name'] ??= fullName;
                  data['noted_by_designation'] ??= designation ?? 'CENTER HEAD';
                  data['center_head_name'] ??= fullName;
                  data['center_head'] ??= fullName;
                  data['center_head_designation'] ??=
                      designation ?? 'CENTER HEAD';
                  data['approved_by'] ??= fullName;
                  data['approved_by_designation'] ??=
                      designation ?? 'CENTER HEAD';
                } else if (fieldStr == 'center_head_name' ||
                    fieldStr == 'approved_by' ||
                    fieldStr == 'center_head') {
                  data['center_head_name'] ??= fullName;
                  data['center_head'] ??= fullName;
                  data['noted_by'] ??= fullName;
                  data['center_head_designation'] ??=
                      designation ?? 'CENTER HEAD';
                  data['noted_by_designation'] ??= designation ?? 'CENTER HEAD';
                  data['approved_by_designation'] ??=
                      designation ?? 'CENTER HEAD';
                } else if (fieldStr == 'medical_staff_name') {
                  data['medical_staff_name'] ??= fullName;
                  data['medical_staff'] ??= fullName;
                  data['medical_staff_designation'] ??= designation ?? 'DOCTOR';
                }

                // Map parallel roles (received_by) for Incident Report based on role
                if (fieldStr == 'received_by' ||
                    fieldStr == 'received_social' ||
                    fieldStr == 'received_psych' ||
                    fieldStr == 'received_medical') {
                  if (role == 'social_head' || role == 'social_worker') {
                    data['received_social'] ??= fullName;
                    data['received_social_designation'] ??= title;
                  } else if (role == 'psych_head' || role == 'psych_worker') {
                    data['received_psych'] ??= fullName;
                    data['received_psych_designation'] ??= title;
                  } else if (role == 'medical_head' ||
                      role == 'medical_center_doctor') {
                    data['received_medical'] ??= fullName;
                    data['received_medical_designation'] ??= title;
                  }
                }

                // Map attested_by for Incident Report
                if (fieldStr == 'attested_by') {
                  data['attested_by'] ??= fullName;
                  data['attested_by_designation'] ??= title;
                }
              }
            }
          }
        } catch (e) {
          debugPrint(
              '[FormPdfPreviewScreen] Error fetching approvals for PDF titles: $e');
        }
      } catch (_) {}
    }

    // Fetch default heads (Center Head, Service Heads) from profiles for PDF fields
    // if they haven't already been set by signatures or approvals.
    // This ensures designations and names appear even BEFORE submission.
    try {
      final client = Supabase.instance.client;
      final headsRes = await client
          .from('profiles')
          .select('full_name, title, role')
          .inFilter('role', [
        'center_head',
        'medical_head',
        'psych_head',
        'social_head'
      ]).eq('status', 'approved'); // Assuming active profiles

      for (var head in headsRes) {
        final role = head['role'];
        final fullName = head['full_name'];
        final title = head['title'];

        String? designation;
        if (title != null &&
            title.toString().trim().isNotEmpty &&
            title.toString().toLowerCase() != 'none') {
          designation = title.toString();
        }

        if (role == 'center_head') {
          data['center_head_name'] ??= fullName;
          data['cswdo_name'] ??= fullName;
          data['center_head'] ??= fullName;
          data['noted_by'] ??= fullName;
          data['approved_by'] ??= fullName;

          final chDesignation = designation ?? 'CENTER HEAD';
          if (data['center_head_designation'] == null ||
              data['center_head_designation'].toString().trim().isEmpty) {
            data['center_head_designation'] = chDesignation;
          }
          if (data['approved_by_designation'] == null ||
              data['approved_by_designation'].toString().trim().isEmpty) {
            data['approved_by_designation'] = chDesignation;
          }
          if (data['noted_by_designation'] == null ||
              data['noted_by_designation'].toString().trim().isEmpty) {
            data['noted_by_designation'] = chDesignation;
          }
        } else if (role == 'medical_head') {
          data['received_medical'] ??= fullName;
          if (data['received_medical_designation'] == null ||
              data['received_medical_designation'].toString().trim().isEmpty) {
            data['received_medical_designation'] =
                designation ?? 'MEDICAL OFFICER';
          }
        } else if (role == 'psych_head') {
          data['received_psych'] ??= fullName;
          if (data['received_psych_designation'] == null ||
              data['received_psych_designation'].toString().trim().isEmpty) {
            data['received_psych_designation'] = designation ?? 'PSYCHOLOGIST';
          }
        } else if (role == 'social_head') {
          data['received_social'] ??= fullName;
          if (data['received_social_designation'] == null ||
              data['received_social_designation'].toString().trim().isEmpty) {
            data['received_social_designation'] =
                designation ?? 'SOCIAL WORKER';
          }
        }
      }
    } catch (e) {
      debugPrint(
          '[FormPdfPreviewScreen] Error fetching default head profiles: $e');
    }

    // Fallback: if we don't have a stored per-submission preparer signature,
    // use the current profile signature.
    if (data['prepared_by_signature_url'] == null &&
        authState is AuthAuthenticated) {
      data['prepared_by_signature_url'] = authState.user.signatureUrl;
      debugPrint(
          '[FormPdfPreview] WARNING: Falling back to current profile signature for prepared_by. submissionId=$submissionId');
    }
    if (data['prepared_by_designation'] == null ||
        data['prepared_by_designation'].toString().toLowerCase() == 'none') {
      if (authState is AuthAuthenticated) {
        data['prepared_by_designation'] =
            (authState.user.title?.toLowerCase() == 'none')
                ? 'SOCIAL WORKER'
                : authState.user.title;
      }
    }

    return data;
  }

  String _getFileName() {
    final sanitizedName = widget.residentName
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(' ', '_');
    final sanitizedTemplate = widget.template.name
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(' ', '_');
    final date = DateTime.now().toIso8601String().split('T')[0];
    return '${sanitizedTemplate}_${sanitizedName}_$date.pdf';
  }

  Future<void> _printPdf() async {
    try {
      final data = await _getFormDataWithSignatures();
      await PdfGenerator.printPdf(
        template: widget.template,
        data: data,
        residentName: widget.residentName,
        caseNumber: widget.caseNumber,
      );
    } catch (e) {
      if (mounted) {
        CustomErrorDialog.show(context,
            title: 'Print Failed', error: e, message: 'Failed to print PDF.');
      }
    }
  }

  Future<void> _sharePdf() async {
    try {
      final data = await _getFormDataWithSignatures();
      await PdfGenerator.sharePdf(
        template: widget.template,
        data: data,
        residentName: widget.residentName,
        caseNumber: widget.caseNumber,
      );
    } catch (e) {
      if (mounted) {
        CustomErrorDialog.show(context,
            title: 'Share Failed', error: e, message: 'Failed to share PDF.');
      }
    }
  }

  Future<void> _downloadPdf(
      BuildContext context, dynamic build, dynamic format) async {
    await _sharePdf();
  }

  void _showDownloadOptions() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Download as...'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadPdf(context, null, null);
            },
            child: const ListTile(
              leading: Icon(LucideIcons.fileText, color: Colors.red),
              title: Text('PDF Document'),
              subtitle: Text('Non-editable, ready to print'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadDocx();
            },
            child: const ListTile(
              leading: Icon(LucideIcons.fileText, color: Colors.blue),
              title: Text('Word Document (.docx)'),
              subtitle: Text('Editable in Microsoft Word'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadDocx() async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var isLoadingDialogVisible = false;

    void closeLoadingDialogIfOpen() {
      if (!isLoadingDialogVisible || !rootNavigator.mounted) return;
      rootNavigator.pop();
      isLoadingDialogVisible = false;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (ctx) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Flexible(child: Text('Generating Word document...')),
            ],
          ),
        ),
      ).then((_) {
        isLoadingDialogVisible = false;
      });
      isLoadingDialogVisible = true;

      final data = await _getFormDataWithSignatures();
      final docxBytes = await PdfGenerator.generateDocx(
        template: widget.template,
        data: data,
        residentName: widget.residentName,
        caseNumber: widget.caseNumber,
      );

      closeLoadingDialogIfOpen();

      final sanitizedName = widget.residentName
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_');
      final sanitizedTemplate = widget.template.name
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_');
      final date = DateTime.now().toIso8601String().split('T')[0];
      final fileName = '${sanitizedTemplate}_${sanitizedName}_$date.docx';

      if (kIsWeb) {
        await Printing.sharePdf(bytes: docxBytes, filename: fileName);
        return;
      }

      try {
        // Save to Documents directory
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}${Platform.pathSeparator}$fileName';

        final file = File(filePath);
        await file.writeAsBytes(docxBytes);

        if (!mounted) return;

        // Show success with option to open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Word document saved: $fileName'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                launchUrl(Uri.file(filePath));
              },
            ),
          ),
        );
      } catch (innerE) {
        debugPrint('File save failed, falling back to share: $innerE');
        await Printing.sharePdf(bytes: docxBytes, filename: fileName);
      }
    } catch (e) {
      closeLoadingDialogIfOpen();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      closeLoadingDialogIfOpen();
    }
  }
}

/// Responsive button widget to open PDF preview
class PdfPreviewButton extends StatelessWidget {
  final FormTemplate template;
  final Map<String, dynamic> formData;
  final String residentName;
  final String residentId; // Added
  final String? caseNumber;
  final String? label;
  final IconData? icon;
  final bool expanded;

  const PdfPreviewButton({
    super.key,
    required this.template,
    required this.formData,
    required this.residentName,
    required this.residentId, // Added
    this.caseNumber,
    this.label,
    this.icon,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);

    final button = ElevatedButton.icon(
      onPressed: () => _openPreview(context),
      icon: Icon(
        icon ?? LucideIcons.fileText,
        size: screen.value(mobile: 18.0, tablet: 20.0, desktop: 22.0),
      ),
      label: Text(
        label ?? 'View PDF',
        style: TextStyle(
          fontSize: screen.value(mobile: 13.0, tablet: 14.0, desktop: 15.0),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        padding: EdgeInsets.symmetric(
          horizontal: screen.value(mobile: 16.0, tablet: 20.0, desktop: 24.0),
          vertical: screen.value(mobile: 10.0, tablet: 12.0, desktop: 14.0),
        ),
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  void _openPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FormPdfPreviewScreen(
          template: template,
          formData: formData,
          residentName: residentName,
          residentId: residentId, // Added residentId
          caseNumber: caseNumber,
        ),
      ),
    );
  }
}

/// Responsive quick print button
class QuickPrintButton extends StatelessWidget {
  final FormTemplate template;
  final Map<String, dynamic> formData;
  final String residentName;
  final String? caseNumber;
  final bool showLabel;

  const QuickPrintButton({
    super.key,
    required this.template,
    required this.formData,
    required this.residentName,
    this.caseNumber,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);

    if (showLabel || screen.isDesktop) {
      return TextButton.icon(
        onPressed: () => _print(context),
        icon: Icon(
          LucideIcons.printer,
          size: screen.value(mobile: 18.0, tablet: 20.0, desktop: 22.0),
        ),
        label: const Text('Print'),
      );
    }

    return IconButton(
      onPressed: () => _print(context),
      icon: Icon(
        LucideIcons.printer,
        size: screen.value(mobile: 22.0, tablet: 24.0, desktop: 26.0),
      ),
      tooltip: 'Print',
    );
  }

  Future<void> _print(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Flexible(child: Text('Preparing to print...')),
            ],
          ),
        ),
      );

      await PdfGenerator.printPdf(
        template: template,
        data: formData,
        residentName: residentName,
        caseNumber: caseNumber,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        CustomErrorDialog.show(context,
            title: 'Print Failed', error: e, message: 'Failed to print PDF.');
      }
    }
  }
}
