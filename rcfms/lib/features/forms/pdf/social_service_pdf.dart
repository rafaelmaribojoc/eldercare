import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../templates/form_templates.dart';
import 'pdf_styles.dart';

/// Social Service PDF Templates
class SocialServicePdf {
  SocialServicePdf._();

  static List<pw.Page> buildPages({
    required FormTemplate template,
    required Map<String, dynamic> data,
    required String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  }) {
    switch (template.templateType) {
      case 'pre_admission_checklist':
        return _buildPreAdmissionChecklist(data, residentName, logoBytes);
      case 'requirements_checklist':
        return _buildRequirementsChecklist(data, residentName, logoBytes);
      case 'general_intake_sheet':
        return _buildGeneralIntakeSheet(
            data, residentName, caseNumber, logoBytes);
      case 'admission_case_conference':
        return _buildCaseConference(
            data, residentName, 'ADMISSION CASE CONFERENCE', logoBytes);
      case 'case_conference':
        final type =
            (data['conference_type'] as String?)?.toUpperCase() ?? 'REGULAR';
        return _buildCaseConference(
            data, residentName, '$type CASE CONFERENCE', logoBytes);
      case 'clients_contract':
        return _buildClientsContract(data, residentName, logoBytes);
      case 'admission_slip':
        return _buildAdmissionSlip(data, residentName, caseNumber, logoBytes);
      case 'progress_notes':
        return _buildProgressNotes(data, residentName, logoBytes);
      case 'running_notes':
        return _buildRunningNotes(data, residentName, logoBytes);
      case 'intervention_plan':
        return _buildInterventionPlan(
            data, residentName, caseNumber, logoBytes);
      case 'social_case_study':
        return _buildSocialCaseStudy(data, residentName, caseNumber, logoBytes);
      case 'termination_report':
        return _buildTerminationReport(data, residentName, logoBytes);
      case 'closing_summary':
        return _buildClosingSummary(data, residentName, caseNumber, logoBytes);
      case 'quarterly_narrative':
        return _buildQuarterlyNarrative(data, residentName, logoBytes);
      case 'client_photo':
        return _buildClientPhoto(data, residentName, logoBytes);
      case 'discharge_slip':
        return _buildDischargeSlipNew(
            data, residentName, caseNumber, logoBytes);
      case 'discharge_conference':
        return _buildCaseConference(
            data, residentName, 'DISCHARGE CASE CONFERENCE', logoBytes);
      case 'pre_discharge_conference':
        return _buildCaseConference(
            data, residentName, 'PRE-DISCHARGE CASE CONFERENCE', logoBytes);
      case 'pre_donation_conference':
        return _buildCaseConference(
            data, residentName, 'PRE-DONATION CASE CONFERENCE', logoBytes);
      case 'pre_termination_plan':
        return _buildPreTerminationPlan(
            data, residentName, caseNumber, logoBytes);
      case 'after_care_plan':
        return _buildAfterCarePlan(data, residentName, caseNumber, logoBytes);
      case 'case_transfer_summary':
        return _buildCaseTransferSummary(
            data, residentName, caseNumber, logoBytes);
      case 'pre_admission_conference':
        return _buildCaseConference(
            data, residentName, 'PRE-ADMISSION CASE CONFERENCE', logoBytes);
      case 'emergency_conference':
        return _buildCaseConference(
            data, residentName, 'EMERGENCY CASE CONFERENCE', logoBytes);
      case 'kasunduan':
        return _buildKasunduan(data, residentName, logoBytes);
      case 'updated_social_case_study':
        return _buildSocialCaseStudy(data, residentName, caseNumber, logoBytes);
      default:
        return [_buildPlaceholder()];
    }
  }

  static List<pw.Page> _buildClientPhoto(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    final photoProvider = data['_photo_provider'] as pw.ImageProvider?;

    // Helper for aligned rows
    pw.Widget buildField(String label, String? value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Text(label, style: PdfStyles.normalStyle),
            ),
            pw.Text(' : ', style: PdfStyles.normalStyle),
            pw.Expanded(
              child: pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                ),
                child: pw.Text(
                  value?.toUpperCase() ?? '',
                  style: PdfStyles.normalStyle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              pw.SizedBox(height: 20),
              pw.Container(
                color: PdfColor.fromHex('#B8860B'), // Dark Goldenrod
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: pw.Text(
                  "CLIENT'S PHOTO",
                  style: PdfStyles.headerStyle.copyWith(color: PdfColors.white),
                ),
              ),
              pw.SizedBox(height: 20),

              // Photo Area
              pw.Container(
                height: 240, // Reduced from 300 to prevent overflow
                width: double.infinity,
                alignment: pw.Alignment.center,
                child: photoProvider != null
                    ? pw.Image(photoProvider, fit: pw.BoxFit.contain)
                    : pw.Text('No photo available'),
              ),

              pw.SizedBox(height: 20),

              // Fields - Use nice consistent width for labels
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                child: pw.Column(
                  children: [
                    buildField('Name', data['client_name'] ?? residentName),
                    buildField('Age', data['client_age']?.toString()),
                    buildField('Address', data['address']),
                    buildField('Sex/Status',
                        '${data['gender']?.toString().toUpperCase() ?? ''} / ${data['civil_status']?.toString().toUpperCase() ?? ''}'),
                    buildField('Date of Birth',
                        PdfStyles.formatDate(data['date_of_birth'])),
                    buildField('Place of Birth', data['place_of_birth']),
                    buildField('Educ\'l Attain', data['educ_attainment']),
                    buildField('Category', data['category']),
                    buildField('Date Admitted',
                        PdfStyles.formatDate(data['date_admitted'])),
                    buildField('Date Picture Taken',
                        PdfStyles.formatDate(data['date_picture_taken'])),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  static pw.Page _buildPlaceholder() {
    return pw.Page(
      pageFormat: PdfStyles.pageFormat,
      build: (context) =>
          pw.Center(child: pw.Text('Form template not available')),
    );
  }

  static String _formatContractDate(String? isoDate) {
    if (isoDate == null) {
      return 'This ______day of _______,_____ in Tagum City, Philippines, is signed.';
    }
    final date = DateTime.tryParse(isoDate);
    if (date == null) {
      return 'This ______day of _______,_____ in Tagum City, Philippines, is signed.';
    }

    final day = date.day;
    String suffix = 'th';
    if (day % 10 == 1 && day != 11) {
      suffix = 'st';
    } else if (day % 10 == 2 && day != 12)
      suffix = 'nd';
    else if (day % 10 == 3 && day != 13) suffix = 'rd';

    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return 'This $day$suffix day of ${monthNames[date.month - 1]}, ${date.year} in Tagum City, Philippines, is signed.';
  }

  static pw.Widget _buildWitnessSignatures(List<dynamic>? witnesses) {
    if (witnesses == null || witnesses.isEmpty) {
      // Fallback for legacy data or empty list
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Witness:', style: PdfStyles.normalStyle),
          pw.SizedBox(height: 20),
          pw.Container(
            width: 150,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            width: 150,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
          ),
        ],
      );
    }

    return pw.Wrap(
      spacing: 20,
      runSpacing: 16,
      children: witnesses.map((w) {
        final name = w['name']?.toString() ?? '';
        final designation = w['designation']?.toString() ?? 'Witness';
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Container(
              width: 140,
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1)),
              ),
              child: pw.Text(
                name.toUpperCase(),
                style: PdfStyles.smallStyle
                    .copyWith(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(designation, style: PdfStyles.smallStyle),
          ],
        );
      }).toList(),
    );
  }

  // ============ PRE-ADMISSION CHECKLIST ============
  static List<pw.Page> _buildPreAdmissionChecklist(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle('PRE-ADMISSION CHECKLIST'),

              // Client info table
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                children: [
                  _infoRow('Name', data['name'] ?? residentName, 'Date',
                      PdfStyles.formatDate(data['date'])),
                  _infoRow('Age', data['age']?.toString() ?? '', 'Category',
                      data['category'] ?? ''),
                  _singleRow('Place of Birth', data['place_of_birth'] ?? ''),
                  _singleRow('Referred by', data['referred_by'] ?? ''),
                ],
              ),
              pw.SizedBox(height: 16),

              // Category checklist
              _buildCategoryTable(data),

              pw.SizedBox(height: 16),
              PdfStyles.labeledTextArea('Remarks', data['remarks'],
                  minHeight: 80),
            ],
          );
        },
      ),
    ];
  }

  // ============ REQUIREMENTS CHECKLIST ============
  static List<pw.Page> _buildRequirementsChecklist(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    final requirements = [
      ('REFERRAL LETTER', 'referral_letter'),
      ('SOCIAL CASE STUDY REPORT', 'social_case_study_report'),
      ('CHEST X-RAY', 'chest_xray'),
      ('MEDICAL CERTIFICATE', 'medical_certificate'),
      ('LABORATORY (LATEST)', 'laboratory_latest'),
      (
        'BLOOD CHEMISTRY (FBS, SGPT, SGOT, URIC, CREATININE, CHOLESTEROL, BUN, ELECTROLYTES)',
        'blood_chemistry'
      ),
      ('URINALYSIS', 'urinalysis'),
      ('STOOL', 'stool_exam'),
      ('ULTRASOUND (IF NEEDED)', 'ultrasound'),
      ('PSYCHOLOGICAL EVALUATION', 'psychological_evaluation'),
      ('VACCINATION CARD', 'vaccination_card'),
      ('RT-PCR / ANTIGEN RESULT', 'rt_pcr_antigen'),
      ('OSCA ID', 'osca_id'),
    ];

    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle('REQUIREMENTS CHECKLIST'),

              // Client info
              pw.Row(children: [
                pw.Expanded(
                    child: PdfStyles.labelWithUnderline(
                        'Name', data['name'] ?? residentName)),
                pw.SizedBox(width: 20),
                pw.SizedBox(
                    width: 150,
                    child: PdfStyles.labelWithUnderline(
                        'Date', PdfStyles.formatDate(data['checklist_date']))),
              ]),
              pw.SizedBox(height: 4),
              pw.Row(children: [
                pw.Expanded(
                    child: PdfStyles.labelWithUnderline(
                        'Age', data['age']?.toString() ?? '')),
                pw.SizedBox(width: 20),
                pw.SizedBox(
                    width: 150,
                    child: PdfStyles.labelWithUnderline(
                        'Category', data['category'] ?? '')),
              ]),
              pw.SizedBox(height: 4),
              PdfStyles.labelWithUnderline(
                  'Place of Birth', data['place_of_birth'] ?? ''),
              PdfStyles.labelWithUnderline('Address', data['address'] ?? ''),
              PdfStyles.labelWithUnderline(
                  'Referred by', data['referred_by'] ?? ''),
              pw.SizedBox(height: 12),

              // Requirements table
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(5),
                  1: const pw.FixedColumnWidth(40),
                  2: const pw.FixedColumnWidth(40),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfStyles.headerBgColor),
                    children: [
                      _cell('REQUIREMENTS', isHeader: true),
                      _cell('YES', isHeader: true),
                      _cell('NO', isHeader: true),
                      _cell('REMARKS', isHeader: true),
                    ],
                  ),
                  ...requirements.map((req) => pw.TableRow(
                        children: [
                          _cell(req.$1),
                          _cell(data['req_${req.$2}_yes'] == true ? '✓' : '',
                              center: true),
                          _cell(data['req_${req.$2}_yes'] == false ? '✓' : '',
                              center: true),
                          _cell(data['req_${req.$2}_remarks'] ?? ''),
                        ],
                      )),
                ],
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Endorsed by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureLine(
                        data['endorsed_by_designation'] ?? 'Referral Source',
                        name: data['endorsed_by'] ?? '',
                        width: 150,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Received by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureLine(
                        data['received_by_designation'] ?? 'Social Worker',
                        name: data['received_by'] ?? '',
                        width: 150,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ];
  }

  // ============ GENERAL INTAKE SHEET ============
  static List<pw.Page> _buildGeneralIntakeSheet(
    Map<String, dynamic> data,
    String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  ) {
    return [
      pw.MultiPage(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return [
            PdfStyles.buildDswdHeader(logoBytes: logoBytes),
            PdfStyles.formTitle('GENERAL INTAKE SHEET'),

            // Header info
            pw.Row(
              children: [
                pw.Expanded(
                    child: PdfStyles.labelWithUnderline(
                        'Case No', caseNumber ?? data['case_no'] ?? '')),
                pw.SizedBox(width: 20),
                pw.SizedBox(
                    width: 150,
                    child: PdfStyles.labelWithUnderline(
                        'Date', PdfStyles.formatDate(data['intake_date']))),
              ],
            ),
            pw.Row(
              children: [
                PdfStyles.checkbox(
                    data['case_type']?.toString().toLowerCase() == 'new',
                    label: 'New'),
                pw.SizedBox(width: 20),
                PdfStyles.checkbox(
                    data['case_type']?.toString().toLowerCase() == 're-opened',
                    label: 'Re-opened'),
              ],
            ),

            PdfStyles.sectionHeader('IDENTIFYING INFORMATION'),
            PdfStyles.labelWithUnderline(
                'Name of Applicant', data['applicant_name'] ?? residentName),
            PdfStyles.labelWithUnderline(
                'Address', data['applicant_address'] ?? ''),
            pw.Row(children: [
              pw.Expanded(
                  child: PdfStyles.labelWithUnderline(
                      'Birthplace', data['birthplace'] ?? '')),
              pw.SizedBox(width: 20),
              pw.Expanded(
                  child: PdfStyles.labelWithUnderline(
                      'Birthday', PdfStyles.formatDate(data['birthday']))),
            ]),
            PdfStyles.labelWithUnderline('Name of Nearest Relative',
                data['nearest_relative_name'] ?? ''),
            PdfStyles.labelWithUnderline('Address of Nearest Relative',
                data['nearest_relative_address'] ?? ''),
            PdfStyles.labelWithUnderline('If disabled, nature of disability',
                data['disability_nature'] ?? ''),
            PdfStyles.labelWithUnderline(
                'Source of Referral', data['referral_source'] ?? ''),

            PdfStyles.sectionHeader('ASSESSMENT'),
            PdfStyles.labeledTextArea(
                'PROBLEM PRESENTED', data['problem_presented'],
                minHeight: 60),
            pw.SizedBox(height: 8),
            PdfStyles.labeledTextArea(
                'Initial Assessment', data['initial_assessment'],
                minHeight: 50),
            pw.SizedBox(height: 8),
            PdfStyles.labeledTextArea('ACTION TAKEN', data['action_taken'],
                minHeight: 40),
            pw.SizedBox(height: 8),
            PdfStyles.labeledTextArea('ASSESSMENT AND RECOMMENDATION',
                data['assessment_recommendation'],
                minHeight: 40),

            pw.SizedBox(height: 50), // Spacing before signatures

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (data['applicant_name'] != null &&
                        data['applicant_name'].toString().isNotEmpty)
                      pw.Text(data['applicant_name'],
                          style: PdfStyles.subHeaderStyle)
                    else
                      pw.Text(residentName, style: PdfStyles.subHeaderStyle),
                    pw.SizedBox(height: 2),
                    pw.SizedBox(
                      width: 180,
                      child: pw.Divider(color: PdfColors.black, thickness: 1),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('(Signature/Thumbmark of Applicant)',
                        style: PdfStyles.smallStyle),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (data['user_name'] != null &&
                        data['user_name'].toString().isNotEmpty)
                      pw.Text(data['user_name'],
                          style: PdfStyles.subHeaderStyle),
                    pw.SizedBox(height: 2),
                    pw.SizedBox(
                      width: 180,
                      child: pw.Divider(color: PdfColors.black, thickness: 1),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(data['user_title'] ?? 'Social Worker',
                        style: PdfStyles.smallStyle),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    ];
  }

  // ============ CASE CONFERENCE ============
  static List<pw.Page> _buildCaseConference(
    Map<String, dynamic> data,
    String residentName,
    String title,
    Uint8List? logoBytes,
  ) {
    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle(title.toUpperCase()),

              // Client info
              pw.Column(
                children: [
                  pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(2),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(2),
                    },
                    border: pw.TableBorder.all(
                        color: PdfStyles.borderColor, width: 0.5),
                    children: [
                      _infoRow(
                          'Name of Client',
                          data['client_name'] ?? residentName,
                          'Age',
                          data['client_age']?.toString() ?? ''),
                      _infoRow(
                          'Date Admitted',
                          PdfStyles.formatDate(data['date_admitted']),
                          'Case Category',
                          data['case_category'] ?? ''),
                    ],
                  ),
                  pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(5),
                    },
                    border: pw.TableBorder(
                      left: const pw.BorderSide(
                          color: PdfStyles.borderColor, width: 0.5),
                      right: const pw.BorderSide(
                          color: PdfStyles.borderColor, width: 0.5),
                      bottom: const pw.BorderSide(
                          color: PdfStyles.borderColor, width: 0.5),
                    ),
                    children: [
                      _singleRow('Condition', data['condition'] ?? ''),
                    ],
                  ),
                  pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(2),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(2),
                    },
                    border: pw.TableBorder(
                      left: const pw.BorderSide(
                          color: PdfStyles.borderColor, width: 0.5),
                      right: const pw.BorderSide(
                          color: PdfStyles.borderColor, width: 0.5),
                      bottom: const pw.BorderSide(
                          color: PdfStyles.borderColor, width: 0.5),
                    ),
                    children: [
                      _infoRow(
                          'Venue',
                          data['venue'] ?? '',
                          'Date of Conference',
                          PdfStyles.formatDate(data['conference_date'])),
                      _infoRow(
                          'Date Submitted',
                          PdfStyles.formatDate(data['date_submitted']),
                          'Time Allotted',
                          data['time_allotted'] ?? ''),
                    ],
                  ),
                  pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(5),
                    },
                    border: pw.TableBorder(
                      left: const pw.BorderSide(
                          color: PdfStyles.borderColor, width: 0.5),
                      right: const pw.BorderSide(
                          color: PdfStyles.borderColor, width: 0.5),
                      bottom: const pw.BorderSide(
                          color: PdfStyles.borderColor, width: 0.5),
                    ), // Avoid double top border
                    children: [
                      pw.TableRow(
                        children: [
                          _cell('Present:', isHeader: true),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(6),
                            child: _renderBullets(data['attendees']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              PdfStyles.bulletList('Objective', data['objective'],
                  minHeight: 50),
              pw.SizedBox(height: 12),

              // Discussions table
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(1)
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfStyles.headerBgColor),
                    children: [
                      _cell('Discussions', isHeader: true),
                      _cell('Agreement Reached/Recommendations',
                          isHeader: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _bulletCellMinHeight(data['discussions'] ?? '', 120),
                      _bulletCellMinHeight(
                          data['agreement_recommendations'] ?? '', 120),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Prepared by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Social Worker',
                        name: data['user_name'],
                        position: data['user_title'],
                        width: 180,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Noted by:', style: PdfStyles.normalStyle),
                  PdfStyles.signatureBlock(
                    role: 'Center Head/SWO II',
                    name: data['center_head_name']?.toString().toUpperCase() ??
                        data['noted_by']?.toString().toUpperCase() ??
                        '',
                    width: 200,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ];
  }

  // ============ CLIENT'S CONTRACT ============
  static List<pw.Page> _buildClientsContract(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle("CLIENT'S CONTRACT"),
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: PdfStyles.normalStyle,
                  children: [
                    const pw.TextSpan(text: 'I am '),
                    pw.TextSpan(
                        text:
                            data['custodian_name'] ?? '_______________________',
                        style: PdfStyles.subHeaderStyle),
                    const pw.TextSpan(text: ', of legal age, status '),
                    pw.TextSpan(
                        text: data['status'] ?? '_______',
                        style: PdfStyles.subHeaderStyle),
                    const pw.TextSpan(text: ', Filipino and a resident of '),
                    pw.TextSpan(
                        text: data['address'] ?? '_______________________',
                        style: PdfStyles.subHeaderStyle),
                    const pw.TextSpan(
                        text: '. I promise to take custody of client '),
                    pw.TextSpan(
                        text: data['client_name'] ?? residentName,
                        style: PdfStyles.subHeaderStyle),
                    const pw.TextSpan(text: ', age '),
                    pw.TextSpan(
                        text: data['client_age']?.toString() ?? '____',
                        style: PdfStyles.subHeaderStyle),
                    const pw.TextSpan(text: ', admitted on '),
                    pw.TextSpan(
                        text: PdfStyles.formatDate(data['date_admitted']),
                        style: PdfStyles.subHeaderStyle),
                    const pw.TextSpan(text: ' referred by '),
                    pw.TextSpan(
                        text: data['referred_by'] ?? '_____________',
                        style: PdfStyles.subHeaderStyle),
                    const pw.TextSpan(
                        text:
                            ' after 6 to 1 year of staying in the center based on the following agreement:'),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              _bulletPoint(
                  'Provide Parenting Capability Assessment Reports (PCAR) to respective LGU, FOs and NGO support services for family preparation for reunification or clients\' other appropriate alternative placement.'),
              _bulletPoint(
                  'It provides rehabilitation services to help people improve or maintain their physical, social, emotional, and mental health.'),
              _bulletPoint(
                  'Conduct activities to harness clients\' vocational skills geared towards enhancing capability and capacity for productivity, if applicable.'),
              _bulletPoint(
                  'Facilitate the senior citizen\'s eventual integration into his or her own family.'),
              _bulletPoint(
                  'Provide opportunities to enable older people\'s participation in community affairs, social, recreational, and cultural activities.'),
              _bulletPoint(
                  'Deliver or provide appropriate rehabilitative services based on the treatment plan.'),
              _bulletPoint(
                  'Family members and relatives are welcome to visit the center from 8:00 a.m. to 5:00 p.m. (Monday-Friday).'),
              _bulletPoint(
                  'In case of an emergency or any updates on the client, the family/relatives of the referring party will be kept updated.'),
              _bulletPoint(
                  'Constant communication and monitoring will be maintained by the family members, relatives, and partners.'),
              _bulletPoint(
                  'In the event of the death of the client, any documents or valuables received based on the record shall be turned over to the family/relatives.'),
              pw.SizedBox(height: 12),
              pw.Text(
                _formatContractDate(data['contract_date']),
                style: PdfStyles.normalStyle,
                textAlign: pw.TextAlign.justify,
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: PdfStyles.signatureBlock(
                    role: "Client's Relative",
                    name:
                        data['custodian_name']?.toString().toUpperCase() ?? '',
                    width: 180),
              ),
              pw.SizedBox(height: 12),
              pw.Center(
                  child: pw.Text('SIGNED IN THE PRESENCE OF:',
                      style: PdfStyles.subHeaderStyle)),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: _buildWitnessSignatures(
                      (data['witnesses'] as List<dynamic>? ?? []).where((w) {
                        if (data['exclude_preparer'] != true) return true;
                        final name = w['name']?.toString().toUpperCase().trim();
                        if (name == null || name.isEmpty) {
                          return true;
                        }
                        // Check against preparer/receiver (case-insensitive)
                        final preparer =
                            (data['prepared_by'] ?? data['user_name'])
                                ?.toString()
                                .toUpperCase()
                                .trim();
                        final Receiver = data['received_by']
                            ?.toString()
                            .toUpperCase()
                            .trim();

                        return name != preparer && name != Receiver;
                      }).toList(),
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Noted by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Center Head/SWO III',
                        name: data['center_head_name']
                                ?.toString()
                                .toUpperCase() ??
                            data['noted_by']?.toString().toUpperCase() ??
                            '',
                        width: 200,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ];
  }

  // ============ ADMISSION SLIP ============
  static List<pw.Page> _buildAdmissionSlip(
    Map<String, dynamic> data,
    String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  ) {
    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle('ADMISSION SLIP'),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                      'Date: ${PdfStyles.formatDate(data['admission_date'])}',
                      style: PdfStyles.normalStyle),
                  pw.SizedBox(width: 40),
                  pw.Text('Time: ${data['admission_time'] ?? ''}',
                      style: PdfStyles.normalStyle),
                ],
              ),
              pw.Center(
                  child: pw.Text(
                      'Case Control no. ${caseNumber ?? data['case_control_no'] ?? ''}',
                      style: PdfStyles.normalStyle)),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                children: [
                  _singleRow(
                      'Name of Client', data['client_name'] ?? residentName),
                  _singleRow('Age', data['client_age']?.toString() ?? ''),
                  _singleRow(
                      'Complete Address', data['complete_address'] ?? ''),
                  _singleRow('Civil Status', data['civil_status'] ?? ''),
                  _singleRow('Educational Attain.',
                      data['educational_attainment'] ?? ''),
                  _singleRow('Religion', data['religion'] ?? ''),
                  _singleRow('Referred by', data['referred_by'] ?? ''),
                  _singleRow('Complete address of Referring Party',
                      data['referring_party_address'] ?? ''),
                  _singleRow('Name and address of the nearest relative',
                      data['nearest_relative'] ?? ''),
                ],
              ),
              pw.SizedBox(height: 12),
              PdfStyles.labeledTextArea(
                  'Medical Findings/Clearance',
                  (data['medical_findings'] ?? '') +
                      (data['medical_findings'] != null &&
                              data['clearance'] != null
                          ? '\n\n'
                          : '') +
                      (data['clearance'] ?? ''),
                  minHeight: 60),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(
                      child: PdfStyles.labelWithUnderline(
                          'Assigned to Room', data['assigned_room'] ?? '')),
                  pw.SizedBox(width: 20),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Checked by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                          role: data['medical_staff_designation'] ??
                              'Medical Staff',
                          signatureBytes:
                              data['_medical_staff_name_signature_bytes'],
                          name: data['medical_staff_name'],
                          width: 120),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Admitted by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Social Worker',
                        signatureBytes: data['_prepared_by_signature_bytes'],
                        name: data['user_name'],
                        position: data['user_title'],
                        width: 150,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Approved by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Center Head/SWO III',
                        signatureBytes: data['_center_head_signature_bytes'],
                        name: data['center_head_name']
                                ?.toString()
                                .toUpperCase() ??
                            data['noted_by']?.toString().toUpperCase() ??
                            '',
                        width: 150,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text('Conformed: ___________________________',
                  style: PdfStyles.normalStyle),
            ],
          );
        },
      ),
    ];
  }

  // ============ PROGRESS NOTES ============
  static List<pw.Page> _buildProgressNotes(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle('PROGRESS NOTES'),
              PdfStyles.labelWithUnderline(
                  'Name of Client', data['client_name'] ?? residentName),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(80),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2)
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfStyles.headerBgColor),
                    children: [
                      _cell('Date', isHeader: true),
                      _cell('Observations', isHeader: true),
                      _cell('Supervisory Remarks', isHeader: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _cellMinHeight(
                          PdfStyles.formatDate(data['progress_date']), 300),
                      _cellMinHeight(data['observations'] ?? '', 300),
                      _cellMinHeight(data['supervisory_remarks'] ?? '', 300),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: PdfStyles.signatureBlock(
                  role: 'SOCIAL WORKER',
                  name: data['user_name'],
                  position: data['user_title'],
                  width: 180,
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  // ============ RUNNING NOTES ============
  static List<pw.Page> _buildRunningNotes(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle('RUNNING NOTES'),
              PdfStyles.labelWithUnderline(
                  'Name of Client', data['client_name'] ?? residentName),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(80),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2)
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfStyles.headerBgColor),
                    children: [
                      _cell('Date', isHeader: true),
                      _cell('Notes / Observations', isHeader: true),
                      _cell('Supervisory Remarks', isHeader: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _cellMinHeight(
                          PdfStyles.formatDate(data['running_date']), 350),
                      _cellMinHeight(data['notes'] ?? '', 350),
                      _cellMinHeight(data['supervisory_remarks'] ?? '', 350),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: PdfStyles.signatureBlock(
                  role: 'SOCIAL WORKER',
                  name: data['user_name'],
                  position: data['user_title'],
                  width: 180,
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  // ============ INTERVENTION PLAN ============
  static List<pw.Page> _buildInterventionPlan(
    Map<String, dynamic> data,
    String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  ) {
    // Parse activities
    final activitiesRaw = data['activities'];
    final List<Map<String, dynamic>> activityRows = [];
    if (activitiesRaw is List) {
      for (var item in activitiesRaw) {
        if (item is Map) {
          activityRows.add(Map<String, dynamic>.from(item));
        }
      }
    } else if (activitiesRaw != null && activitiesRaw.toString().isNotEmpty) {
      // Legacy support
      activityRows.add({
        'activity': activitiesRaw.toString(),
        'start_date': null,
        'end_date': null,
        'custom_time_frame': data['time_frame'],
        'use_custom_time': true,
        'responsible_person': data['responsible_person'],
        'output': '',
      });
    }

    // Helper to format time frame
    String formatTimeFrame(Map<String, dynamic> item) {
      if (item['use_custom_time'] == true) {
        return item['custom_time_frame']?.toString() ?? '';
      }
      final start = item['start_date'] != null
          ? PdfStyles.formatDate(item['start_date'])
          : 'N/A';
      final end = item['end_date'] != null
          ? PdfStyles.formatDate(item['end_date'])
          : 'N/A';
      return '$start - $end';
    }

    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle('MODIFIED INTERVENTION PLAN'),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                    'Date Prepared: ${PdfStyles.formatDate(data['date_prepared'])}',
                    style: PdfStyles.normalStyle),
              ),

              pw.Row(children: [
                pw.Expanded(
                    child: PdfStyles.labelWithUnderline(
                        'Name of Client', data['client_name'] ?? residentName)),
                pw.SizedBox(width: 20),
                pw.SizedBox(
                    width: 150,
                    child: PdfStyles.labelWithUnderline('Case Control No.',
                        caseNumber ?? data['case_control_no'] ?? '')),
              ]),
              pw.SizedBox(height: 12),

              // Goal Section
              pw.RichText(
                text: pw.TextSpan(
                  style: PdfStyles.normalStyle,
                  children: [
                    const pw.TextSpan(text: 'In three (3) months - time ('),
                    pw.TextSpan(
                      text: () {
                        if (data['goal_use_custom'] == true) {
                          return data['goal_period_text']?.toString() ??
                              '__________';
                        }
                        final start = data['goal_start_date'] != null
                            ? PdfStyles.formatDate(data['goal_start_date'])
                            : '__________';
                        final end = data['goal_end_date'] != null
                            ? PdfStyles.formatDate(data['goal_end_date'])
                            : '__________';
                        return '$start - $end';
                      }(),
                      style: PdfStyles.normalStyle
                          .copyWith(fontWeight: pw.FontWeight.bold),
                    ),
                    const pw.TextSpan(
                        text:
                            '), client\'s social functioning will be sustained.'),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Intervention table
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), // Objectives
                  1: const pw.FlexColumnWidth(3), // Activities
                  2: const pw.FlexColumnWidth(2), // Time Frame
                  3: const pw.FlexColumnWidth(2), // Responsible
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfStyles.headerBgColor),
                    children: [
                      _cell('OBJECTIVES', isHeader: true),
                      _cell('ACTIVITIES', isHeader: true),
                      _cell('TIME FRAME', isHeader: true),
                      _cell('RESPONSIBLE UNIT / PERSON', isHeader: true),
                    ],
                  ),
                  if (activityRows.isEmpty)
                    pw.TableRow(
                      children: [
                        _cellMinHeight('', 30),
                        _cellMinHeight('', 30),
                        _cellMinHeight('', 30),
                        _cellMinHeight('', 30),
                      ],
                    )
                  else
                    ...activityRows.map((item) {
                      return pw.TableRow(
                        children: [
                          _cellMinHeight(
                              item['objective']?.toString() ?? '', 30),
                          _cellMinHeight(
                              item['activity']?.toString() ?? '', 30),
                          _cellMinHeight(formatTimeFrame(item), 30),
                          _cellMinHeight(
                              item['responsible_person']?.toString() ?? '', 30),
                        ],
                      );
                    }),
                ],
              ),

              pw.Spacer(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Confirmed by Client:',
                          style: PdfStyles.normalStyle),
                      PdfStyles.signatureLine(
                        '',
                        width: 180,
                        name: (data['client_name'] ?? residentName)
                            .toString()
                            .toUpperCase(),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Prepared by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Social Worker',
                        name: data['user_name'],
                        position: data['user_title'],
                        width: 180,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Noted by:', style: PdfStyles.normalStyle),
                  PdfStyles.signatureBlock(
                    role: 'Center Head / SWO II',
                    name: data['center_head_name']?.toString().toUpperCase() ??
                        data['noted_by']?.toString().toUpperCase() ??
                        '',
                    width: 200,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ];
  }

  // ============ SOCIAL CASE STUDY REPORT ============
  static List<pw.Page> _buildSocialCaseStudy(
    Map<String, dynamic> data,
    String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  ) {
    // Multi-page document
    return [
      pw.MultiPage(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        header: (context) => context.pageNumber == 1
            ? PdfStyles.buildDswdHeader(logoBytes: logoBytes, compact: true)
            : pw.SizedBox(),
        footer: (context) => PdfStyles.pageFooter(context),
        build: (context) => [
          PdfStyles.formTitle('SOCIAL CASE STUDY REPORT'),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                      'Date Prepared: ${PdfStyles.formatDate(data['report_date'])}',
                      style: PdfStyles.normalStyle),
                ],
              ),
            ],
          ),
          PdfStyles.sectionHeader('I. IDENTIFYING INFORMATION:'),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('a. Personal data:', style: PdfStyles.subHeaderStyle),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12),
                  child: pw.Column(
                    children: [
                      _pdfRowItem('1. Name', data['name'] ?? residentName),
                      _pdfRowItem('2. Age', data['age']?.toString() ?? ''),
                      _pdfRowItem('3. Sex',
                          (data['sex'] ?? '').toString().toUpperCase()),
                      _pdfRowItem(
                          '4. Civil Status',
                          (data['civil_status'] ?? '')
                              .toString()
                              .toUpperCase()),
                      _pdfRowItem('5. Birth Place', data['birth_place'] ?? ''),
                      _pdfRowItem('6. Birth Date',
                          PdfStyles.formatDate(data['birth_date'])),
                      _pdfRowItem('7. Educt\'l Attain.',
                          data['educational_attainment'] ?? ''),
                      _pdfRowItem('8. Religion', data['religion'] ?? ''),
                      _pdfRowItem(
                          '9. Provincial Address', data['address'] ?? ''),
                      _pdfRowItem('10. Source of Referral',
                          data['referral_source'] ?? ''),
                      _pdfRowItem('11. Year Admitted',
                          data['year_admitted']?.toString() ?? ''),
                      _pdfRowItem(
                          '12. Case No.', caseNumber ?? data['case_no'] ?? ''),
                      _pdfRowItem(
                          '13. Length of Stay',
                          (data['length_of_stay'] ?? '')
                              .toString()
                              .toUpperCase()),
                      _pdfRowItem('14. Case Category',
                          (data['category'] ?? '').toString().toUpperCase()),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('b. Family Composition:',
                    style: PdfStyles.subHeaderStyle),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Table(
            border:
                pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3), // Name
              1: const pw.FlexColumnWidth(1), // Age
              2: const pw.FlexColumnWidth(2), // Relationship
              3: const pw.FlexColumnWidth(2), // Occupation
              4: const pw.FlexColumnWidth(3), // Address
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfStyles.headerBgColor),
                children: [
                  _cell('NAME', isHeader: true),
                  _cell('AGE', isHeader: true),
                  _cell('RELATIONSHIP', isHeader: true),
                  _cell('OCCUPATION', isHeader: true),
                  _cell('ADDRESS', isHeader: true),
                ],
              ),
              ...(() {
                final members = data['family_composition'];
                if (members is List && members.isNotEmpty) {
                  return members.map((member) {
                    final m = Map<String, dynamic>.from(member as Map);
                    return pw.TableRow(
                      children: [
                        _cellMinHeight(m['name']?.toString() ?? '', 25),
                        _cellMinHeight(m['age']?.toString() ?? '', 25),
                        _cellMinHeight(m['relationship']?.toString() ?? '', 25),
                        _cellMinHeight(m['occupation']?.toString() ?? '', 25),
                        _cellMinHeight(m['address']?.toString() ?? '', 25),
                      ],
                    );
                  }).toList();
                } else {
                  return [
                    pw.TableRow(
                      children: [
                        _cellMinHeight('', 25),
                        _cellMinHeight('', 25),
                        _cellMinHeight('', 25),
                        _cellMinHeight('', 25),
                        _cellMinHeight('', 25),
                      ],
                    )
                  ];
                }
              })(),
            ],
          ),
          PdfStyles.sectionHeader('II. PROBLEM PRESENTED:'),
          PdfStyles.textArea(data['problem_presented'], minHeight: 40),
          PdfStyles.sectionHeader('III. BACKGROUND OF THE CASE:'),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('a. Findings:', style: PdfStyles.subHeaderStyle),
                PdfStyles.textArea(data['findings'], minHeight: 40),
                pw.SizedBox(height: 8),
                pw.Text('b. Medical and Nutritional Needs:',
                    style: PdfStyles.subHeaderStyle),
                PdfStyles.textArea(data['medical_nutritional_needs'],
                    minHeight: 40),
                pw.SizedBox(height: 8),
                pw.Text('c. Level of Social Functioning',
                    style: PdfStyles.subHeaderStyle),
                PdfStyles.textArea(data['social_functioning'], minHeight: 40),
              ],
            ),
          ),
          PdfStyles.sectionHeader('IV. INTERVENTION PLAN:'),
          PdfStyles.textArea(data['intervention_plan'], minHeight: 40),
          PdfStyles.sectionHeader('V. ASSESSMENT:'),
          PdfStyles.textArea(data['assessment'], minHeight: 40),
          PdfStyles.sectionHeader('VI. RECOMMENDATION:'),
          PdfStyles.textArea(data['recommendation'], minHeight: 40),
          pw.SizedBox(height: 32),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Noted by:', style: PdfStyles.normalStyle),
                  PdfStyles.signatureBlock(
                    role: 'Center Head/SWO II',
                    name: (data['center_head'] ??
                            data['center_head_name'] ??
                            data['noted_by'] ??
                            '')
                        ?.toString()
                        .toUpperCase(),
                    width: 200,
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Prepared by:', style: PdfStyles.normalStyle),
                  PdfStyles.signatureBlock(
                    role: 'Social Worker',
                    name: data['prepared_by'] ?? data['user_name'],
                    position:
                        data['prepared_by_position'] ?? data['user_title'],
                    width: 200,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static pw.Widget _pdfRowItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(label, style: PdfStyles.normalStyle),
          ),
          pw.Text(':', style: PdfStyles.normalStyle),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(value,
                style: PdfStyles.normalStyle
                    .copyWith(fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ============ TERMINATION REPORT ============
  static List<pw.Page> _buildTerminationReport(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    return [
      pw.MultiPage(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (context) => [
          PdfStyles.buildDswdHeader(logoBytes: logoBytes),
          PdfStyles.formTitle('TERMINATION REPORT'),
          pw.Center(
              child: pw.Text(
                  'Date: ${PdfStyles.formatDate(data['termination_date'])}',
                  style: PdfStyles.normalStyle)),
          pw.SizedBox(height: 12),

          // Header
          PdfStyles.sectionHeader('IDENTIFYING INFORMATION:'),

          // Detailed Info Table
          pw.Table(
            border:
                pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // Label
              1: const pw.FlexColumnWidth(3), // Value
            },
            children: [
              pw.TableRow(children: [
                _cell('NAME OF RESIDENT'),
                _cell(data['client_name'] ?? residentName),
              ]),
              pw.TableRow(children: [
                _cell('AGE'),
                _cell(data['client_age']?.toString() ?? ''),
              ]),
              pw.TableRow(children: [
                _cell('SEX'),
                _cell(data['sex']?.toString().toUpperCase() ?? ''),
              ]),
              pw.TableRow(children: [
                _cell('DATE OF ADMISSION'),
                _cell(PdfStyles.formatDate(data['date_admitted'])),
              ]),
              pw.TableRow(children: [
                _cell(
                    'DATE OF DISCHARGE'), // "Discharged" -> "DISCHARGE" as per common english, or keep "DISCHARGED"? User screenshot shows "Date of Discharged" in previous step, but now says "uppercased". "DATE OF DISCHARGED" is functionally correct match. I will stick to "DATE OF DISCHARGED" to match previous text but uppercase, or "DATE OF DISCHARGE" if I want to correct grammar. Screenshot in step 5642 says "Date of Discharged". I will respect that grammar.
                _cell(PdfStyles.formatDate(data['date_discharged'])),
              ]),
              pw.TableRow(children: [
                _cell('CASE CATEGORY'),
                _cell(data['case_category']?.toString().toUpperCase() ?? ''),
              ]),
              pw.TableRow(children: [
                _cell('LENGTH OF STAY'),
                _cell(data['length_of_stay'] ?? ''),
              ]),
              pw.TableRow(children: [
                _cell('NAME/ RELATION TO THE PERSON DISCHARGED'),
                _cell(data['custodian_name'] ?? ''),
              ]),
              pw.TableRow(children: [
                _cell('ADDRESS'),
                _cell(data['address'] ?? ''),
              ]),
            ],
          ),
          pw.SizedBox(height: 12),
          PdfStyles.labeledTextArea(
              'REASON FOR CLIENT\'S ADMISSION AT THE HOME FOR THE AGED:',
              data['admission_reason'],
              minHeight: 60),
          PdfStyles.labeledTextArea(
              'INTERVENTION PROVIDED BY THE HA:', data['intervention_provided'],
              minHeight: 60),
          PdfStyles.labeledTextArea(
              'SOCIAL FUNCTIONING OF THE RESIDENT UPON DISCHARGE:',
              data['social_functioning'],
              minHeight: 60),
          PdfStyles.labeledTextArea(
              'WHY THE CASE IS BEING CLOSED:', data['closing_reason'],
              minHeight: 60),
          PdfStyles.labeledTextArea('RECOMMENDATIONS:', data['recommendations'],
              minHeight: 50),
          pw.SizedBox(height: 30),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Prepared by
              pw.Text('Prepared and submitted by:',
                  style: PdfStyles.normalStyle),
              PdfStyles.signatureBlock(
                role: 'Social Worker',
                name: data['user_name']?.toString().toUpperCase() ?? '',
                position: data['user_title'] ?? 'Social Worker',
                width: 250,
              ),
              pw.SizedBox(height: 24),

              // 2. Noted by
              pw.Text('Noted by:', style: PdfStyles.normalStyle),
              PdfStyles.signatureBlock(
                role: 'Center Head/SWO III',
                name: data['noted_by']?.toString().toUpperCase() ?? '',
                width: 250,
              ),
              pw.SizedBox(height: 24),

              // 3. Recommending Approval
              pw.Text('Recommending Approval:', style: PdfStyles.normalStyle),
              PdfStyles.signatureBlock(
                role: 'Protective Services Division Chief',
                name: '', // Empty as per request
                width: 250,
              ),
              pw.SizedBox(height: 36),

              // 4. Approved by (Centered)
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Approved by:', style: PdfStyles.normalStyle),
                    PdfStyles.signatureBlock(
                      role: 'Regional Director',
                      name: '', // Empty as per request
                      width: 250,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  // ============ CLOSING SUMMARY ============
  static List<pw.Page> _buildClosingSummary(
    Map<String, dynamic> data,
    String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  ) {
    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle('CLOSING SUMMARY'),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                          'Date: ${PdfStyles.formatDate(data['closing_date'] ?? DateTime.now().toIso8601String())}',
                          style: PdfStyles.normalStyle),
                      pw.Text('Case No. ${caseNumber ?? data['case_no'] ?? ''}',
                          style: PdfStyles.normalStyle),
                    ],
                  ),
                ],
              ),
              // Clean Layout Table
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(150), // Label
                  1: const pw.FixedColumnWidth(20), // Colon
                  2: const pw.FlexColumnWidth(), // Value
                },
                children: [
                  _cleanRow('Name', data['name'] ?? residentName),
                  _cleanRow('Age', data['age']?.toString() ?? ''),
                  _cleanRow(
                      'Sex', data['gender']?.toString().toUpperCase() ?? ''),
                  _cleanRow('Address', data['address'] ?? ''),
                  _cleanRow(
                      'Source of Referral', data['referral_source'] ?? ''),
                  _cleanRow('Date Admitted',
                      PdfStyles.formatDate(data['date_admitted'])),
                  _cleanRow('SUMMARY OF CASE', data['case_summary']),
                  _cleanRow('Address of referring Party',
                      data['referring_party_address'] ?? ''),
                  _cleanRow('Date of Discharge',
                      PdfStyles.formatDate(data['date_discharged'])),
                ],
              ),

              pw.SizedBox(height: 50),

              // Signatories - Staggered Layout
              // Prepared by (Right)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Prepared by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Social Worker',
                        name: data['user_name']?.toString().toUpperCase() ?? '',
                        position: data['user_title'] ?? 'Social Worker',
                        width: 200,
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Approved by (Left)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Approved by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Center Head/SWO II',
                        name: data['noted_by']?.toString().toUpperCase() ?? '',
                        width: 200,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ];
  }

  // ============ QUARTERLY NARRATIVE REPORT ============

  // ============ PRE-TERMINATION PLAN ============
  static List<pw.Page> _buildPreTerminationPlan(
    Map<String, dynamic> data,
    String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  ) {
    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle('PRE-TERMINATION / PRE-DISCHARGE PLAN'),

              // Date (Right Aligned)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                    'Date: ${PdfStyles.formatDate(data['date'] ?? DateTime.now().toIso8601String())}',
                    style: PdfStyles.normalStyle),
              ),
              pw.SizedBox(height: 12),

              // Client Info Clean Layout
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(130), // Label
                  1: const pw.FixedColumnWidth(20), // Colon
                  2: const pw.FlexColumnWidth(), // Value
                },
                children: [
                  _cleanRow(
                      'Name of Client', data['client_name'] ?? residentName),
                  _cleanRow(
                      'Age',
                      data['client_age']?.toString() ??
                          data['age']?.toString() ??
                          ''),
                  _cleanRow('Date Admitted',
                      PdfStyles.formatDate(data['date_admitted'])),
                  _cleanRow(
                      'Case Category',
                      data['case_category']?.toString().toUpperCase() ??
                          data['category']?.toString().toUpperCase() ??
                          ''),
                  _cleanRow(
                      'Condition',
                      data['condition']?.toString().toUpperCase() ??
                          data['health_status']?.toString().toUpperCase() ??
                          ''),
                ],
              ),
              pw.SizedBox(height: 12),

              // Objective Section
              pw.Text('Objective:',
                  style: PdfStyles.normalStyle
                      .copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('1. ${data['objective'] ?? data['objectives'] ?? ''}',
                  style: PdfStyles.normalStyle),
              pw.SizedBox(height: 12),

              // Activities Table
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), // Activities
                  1: const pw.FlexColumnWidth(2), // Responsible Person
                  2: const pw.FlexColumnWidth(1), // Time Frame
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfStyles.headerBgColor),
                    children: [
                      _cell('Activities', isHeader: true, center: true),
                      _cell('Responsible Person', isHeader: true, center: true),
                      _cell('Time Frame', isHeader: true, center: true),
                    ],
                  ),
                  if (data['activities'] is List &&
                      (data['activities'] as List).isNotEmpty) ...[
                    for (int i = 0;
                        i < (data['activities'] as List).length;
                        i++) ...[
                      (() {
                        final item = (data['activities'] as List)[i];
                        final start = PdfStyles.formatDate(item['start']);
                        final end = PdfStyles.formatDate(item['end']);
                        final range = (start.isNotEmpty && end.isNotEmpty)
                            ? '$start - $end'
                            : '$start$end';
                        return pw.TableRow(
                          children: [
                            _cellMinHeight(
                                '${i + 1}. ${item['description'] ?? ''}', 30),
                            _cellMinHeight(
                                '> ${item['responsible'] ?? ''}', 30),
                            _cellMinHeight(range, 30),
                          ],
                        );
                      })()
                    ]
                  ] else ...[
                    for (int i = 1; i <= 5; i++) ...[
                      (() {
                        final start =
                            PdfStyles.formatDate(data['time_frame_start_$i']);
                        final end =
                            PdfStyles.formatDate(data['time_frame_end_$i']);
                        final range = (start.isNotEmpty && end.isNotEmpty)
                            ? '$start - $end'
                            : '$start$end';
                        return pw.TableRow(
                          children: [
                            _cellMinHeight(
                                '$i. ${data['activity_$i'] ?? ''}', 30),
                            _cellMinHeight(
                                '> ${data['responsible_$i'] ?? ''}', 30),
                            _cellMinHeight(range, 30),
                          ],
                        );
                      })()
                    ]
                  ],
                ],
              ),

              pw.Spacer(),

              // Signatories - Staggered Layout
              // Prepared by (Right)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Prepared by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Social Worker',
                        name: data['user_name']?.toString().toUpperCase() ?? '',
                        position: data['user_title'] ?? 'Social Worker',
                        width: 200,
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Noted by (Left)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Noted by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Center Head/SWO II',
                        name: data['noted_by']?.toString().toUpperCase() ?? '',
                        width: 200,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ];
  }

  // ============ AFTER CARE PLAN ============
  static List<pw.Page> _buildAfterCarePlan(
    Map<String, dynamic> data,
    String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  ) {
    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle('AFTER CARE PLAN'),

              // Date (Right Aligned)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                    'DATE: ${PdfStyles.formatDate(data['date_prepared'] ?? DateTime.now().toIso8601String())}',
                    style: PdfStyles.normalStyle
                        .copyWith(fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 12),

              // Client Info Clean Layout
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(130), // Label
                  1: const pw.FixedColumnWidth(20), // Colon
                  2: const pw.FlexColumnWidth(), // Value
                },
                children: [
                  _cleanRow(
                      'Name of Client', data['client_name'] ?? residentName),
                  _cleanRow(
                      'Age',
                      data['client_age']?.toString() ??
                          data['age']?.toString() ??
                          ''),
                  _cleanRow('Date Admitted',
                      PdfStyles.formatDate(data['date_admitted'])),
                  _cleanRow(
                      'Case Category',
                      data['case_category']?.toString().toUpperCase() ??
                          data['category']?.toString().toUpperCase() ??
                          ''),
                  _cleanRow(
                      'Condition',
                      data['condition']?.toString().toUpperCase() ??
                          data['health_status']?.toString().toUpperCase() ??
                          ''),
                  _cleanRow('Date of Discharge',
                      PdfStyles.formatDate(data['date_discharged'])),
                ],
              ),
              pw.SizedBox(height: 12),

              // Objective Section
              PdfStyles.bulletList('Objective', data['objective'],
                  minHeight: 50),
              pw.SizedBox(height: 12),

              // Activities Table
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3), // Activities
                  1: const pw.FlexColumnWidth(2), // Time Frame
                  2: const pw.FlexColumnWidth(2), // Responsible Person
                  3: const pw.FlexColumnWidth(2), // Remarks
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfStyles.headerBgColor),
                    children: [
                      _cell('Activities', isHeader: true, center: true),
                      _cell('TIME FRAME', isHeader: true, center: true),
                      _cell('Responsible Person', isHeader: true, center: true),
                      _cell('Remarks', isHeader: true, center: true),
                    ],
                  ),
                  if (data['activities'] is List &&
                      (data['activities'] as List).isNotEmpty) ...[
                    for (int i = 0;
                        i < (data['activities'] as List).length;
                        i++) ...[
                      (() {
                        final item = (data['activities'] as List)[i];
                        return pw.TableRow(
                          children: [
                            _cellMinHeight(item['activity'] ?? '', 30),
                            _cellMinHeight(
                                '${item['time_started'] ?? ''} - ${item['time_ended'] ?? ''}',
                                30),
                            _cellMinHeight(
                                item['responsible_person'] ?? '', 30),
                            _cellMinHeight(item['remarks'] ?? '', 30),
                          ],
                        );
                      })()
                    ]
                  ] else ...[
                    // Fallback empty rows if no data
                    pw.TableRow(children: [
                      _cellMinHeight('', 30),
                      _cellMinHeight('', 30),
                      _cellMinHeight('', 30),
                      _cellMinHeight('', 30),
                    ]),
                  ]
                ],
              ),

              pw.Spacer(),

              // Signatures
              // Prepared by (Right)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Prepared by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Social Worker',
                        name: data['user_name']?.toString().toUpperCase() ?? '',
                        position: data['user_title'] ?? 'Social Worker',
                        width: 180,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Confirmed (Center - Horizontal)
              pw.Text('Confirmed:',
                  style: PdfStyles.normalStyle
                      .copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),

              // Signature Lines Grid (2x2 Layout)
              pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _signatureBlock(label: 'HP', width: 150),
                      _signatureBlock(label: 'Nurse', width: 150),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _signatureBlock(label: 'Psychometrician', width: 150),
                      _signatureBlock(label: 'C/MSWDO', width: 150),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Noted by (Left)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Noted by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Center Head/SWO II',
                        name: data['noted_by']?.toString().toUpperCase() ?? '',
                        width: 200,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ];
  }

  static pw.Widget _signatureBlock(
      {required String label, double width = 150}) {
    return pw.Column(
      children: [
        pw.Container(
          width: width,
          height: 20,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 1)),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label,
            style:
                PdfStyles.normalStyle.copyWith(fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center),
      ],
    );
  }

  // ============ CASE TRANSFER SUMMARY ============
  static List<pw.Page> _buildCaseTransferSummary(
    Map<String, dynamic> data,
    String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  ) {
    return [
      pw.MultiPage(
          pageFormat: PdfStyles.pageFormat,
          margin: PdfStyles.pageMargin,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          build: (context) => [
                PdfStyles.buildDswdHeader(logoBytes: logoBytes),
                PdfStyles.formTitle('CASE TRANSFER SUMMARY'),

                // Date Turned-over (Right Aligned)
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                      'Date Turned-over: ${PdfStyles.formatDate(data['date_turnover'])}',
                      style: PdfStyles.normalStyle),
                ),
                pw.SizedBox(height: 12),

                pw.Text('I. IDENTIFYING INFORMATION:',
                    style: PdfStyles.headerStyle),
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.only(left: 16, bottom: 8, top: 4),
                  child: pw.Text('1. Personal Data:',
                      style: PdfStyles.subHeaderStyle),
                ),
                pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16),
                    child: pw.Table(
                      columnWidths: {
                        0: const pw.FixedColumnWidth(130), // Label
                        1: const pw.FixedColumnWidth(20), // Colon
                        2: const pw.FlexColumnWidth(), // Value
                      },
                      children: [
                        _cleanRow('Name', data['client_name'] ?? residentName),
                        _cleanRow(
                            'Age',
                            data['age']?.toString() ??
                                data['client_age']?.toString() ??
                                ''),
                        _cleanRow(
                            'Sex',
                            data['sex']?.toString().toUpperCase() ??
                                data['gender']?.toString().toUpperCase() ??
                                ''),
                        _cleanRow('Civil Status', data['civil_status']),
                        _cleanRow(
                            'Birth Place',
                            data['place_of_birth'] ??
                                data['birthplace'] ??
                                data['birth_place']),
                        _cleanRow('Birth Date',
                            PdfStyles.formatDate(data['date_of_birth'])),
                        _cleanRow(
                            'Educ\'l Attain',
                            data['educational_attainment'] ??
                                data['educ_attainment']),
                        _cleanRow('Religion', data['religion']),
                        _cleanRow(
                            'Provincial Address', data['provincial_address']),
                        _cleanRow(
                            'Source of Referral',
                            data['source_of_referral'] ??
                                data['source_referral']),
                        _cleanRow('Date Admitted',
                            PdfStyles.formatDate(data['date_admitted'])),
                        _cleanRow('Case No.', caseNumber ?? data['case_no']),
                        _cleanRow('Case Category', data['case_category']),
                      ],
                    )),

                pw.SizedBox(height: 16),
                pw.Text('II. BACKGROUND OF THE CASE:',
                    style: PdfStyles.headerStyle),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  constraints: const pw.BoxConstraints(minHeight: 80),
                  child: pw.Text(
                    data['background_of_case'] ?? data['background'] ?? '',
                    style: PdfStyles.normalStyle,
                    textAlign: pw.TextAlign.justify,
                  ),
                ),

                pw.SizedBox(height: 16),
                pw.Text('III. RECOMMENDATIONS:', style: PdfStyles.headerStyle),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  constraints: const pw.BoxConstraints(minHeight: 60),
                  child: pw.Text(
                    data['recommendations'] ?? '',
                    style: PdfStyles.normalStyle,
                    textAlign: pw.TextAlign.justify,
                  ),
                ),

                pw.SizedBox(height: 40),

                // Signatories
                pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Received by:',
                                style: PdfStyles.normalStyle),
                            pw.SizedBox(height: 8),
                            PdfStyles.signatureBlock(
                                role: 'C/MSWDO',
                                name: data['received_by']
                                        ?.toString()
                                        .toUpperCase() ??
                                    '',
                                width: 180),
                          ]),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Turned-over by:',
                                style: PdfStyles.normalStyle),
                            pw.SizedBox(height: 8),
                            PdfStyles.signatureBlock(
                                role: 'Social Worker',
                                name: data['turned_over_by']
                                        ?.toString()
                                        .toUpperCase() ??
                                    '',
                                position: 'Social Worker',
                                width: 180),
                          ]),
                    ]),

                pw.SizedBox(height: 30),

                pw.Center(
                    child: pw.Column(children: [
                  pw.Text('Noted by:', style: PdfStyles.normalStyle),
                  pw.SizedBox(height: 8),
                  PdfStyles.signatureBlock(
                      role: 'Center Head/SWO II',
                      name: (data['noted_by'] != null &&
                              data['noted_by'].toString().isNotEmpty)
                          ? data['noted_by'].toString().toUpperCase()
                          : 'MS. PRESCIOUS GRACE A. ARQUINTILLO',
                      width: 200),
                ])),
              ]),
    ];
  }

  // ============ CLIENT'S KASUNDUAN ============
  static List<pw.Page> _buildKasunduan(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    // Helper to build a bilingual item row
    pw.Widget buildItem(String number, String english, String tagalog) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 24,
              child: pw.Text('$number.', style: PdfStyles.normalStyle),
            ),
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: '$english ',
                      style: PdfStyles.normalStyle,
                    ),
                    pw.TextSpan(
                      text: '($tagalog)',
                      style: PdfStyles.normalStyle.copyWith(
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return [
      pw.MultiPage(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) => [
          PdfStyles.buildDswdHeader(logoBytes: logoBytes),

          // Gold Header Title
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            color: PdfColors.amber, // Gold-ish
            child: pw.Center(
              child: pw.Text(
                'CLIENT\'S KASUNDUAN',
                style: PdfStyles.headerStyle.copyWith(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          // Introductory Paragraph
          pw.RichText(
            text: pw.TextSpan(
              style: PdfStyles.normalStyle,
              children: [
                const pw.TextSpan(text: 'I am '),
                PdfStyles.spanUnderline(data['client_name'] ?? residentName),
                const pw.TextSpan(text: ', of legal age, status, '),
                PdfStyles.spanUnderline(data['status'] ?? ''),
                const pw.TextSpan(text: ', Filipino and a resident of '),
                PdfStyles.spanUnderline(data['resident_of'] ?? ''),
                const pw.TextSpan(text: '.'),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'I agree and signed the institutions policy and regulations.',
            style: PdfStyles.normalStyle,
          ),
          pw.SizedBox(height: 16),

          // 14 Items
          buildItem(
            '1',
            'This institution acts as a temporary shelter.',
            'Kini na institusyon kay temporaryong puluy-anan lamang',
          ),
          buildItem(
            '2',
            'Out on pass for the client is strictly observed and must be approved by the Center Head before going out in the center.',
            'Sa panahon na mogawas ko sa center para sa importanteng transaksyon, mo fill in ko sa out on pass unya kini pagaaprubahan sa Center Head',
          ),
          buildItem(
            '3',
            'Important documents or valuables of the client will be turned over to the case manager assigned, such as money, documents, jewelry, IDs, and others for safekeeping.',
            'Kung dunay mga importanteng gamit sama sa kwarta, dokumento, alahas, ID ug uban pa',
          ),
          buildItem(
            '4',
            'I give permission to find, locate, and contact my known family members.',
            'Naga tugot ako sa pagpangita ug pagcontact sa akong nahibal-an na pamilya',
          ),
          buildItem(
            '5',
            'I am permitted to allow my family to visit every Monday through Friday at 8 a.m. to 5 p.m.',
            'Gatugot ako na, kung mobisita akong pamilya matag lunes to biyernes lang 8am-5pm',
          ),
          buildItem(
            '6',
            'Upon admission, I authorize the staff to check and examine my possessions.',
            'Gatugot na inventorahon akong gamit sa pagsulod diri',
          ),
          buildItem(
            '7',
            'I allow the personnel to verify and inventory my items on a regular basis.',
            'Motuman sa regulasyon sa inventory akong gamit matag bulan',
          ),
          buildItem(
            '8',
            'I allow the staff to take any pointed object I have, such as a blade.',
            'Gatugot sa pagkuha sa akong gamit na talinis sama sa gunting, blade etc.',
          ),
          buildItem(
            '9',
            'I agree that I will be monitored on a regular basis by the staff.',
            'Gatugot usab ko na monitoron sa kwarto',
          ),
          buildItem(
            '10',
            'I will engage in all Center activities.',
            'Muapil ako sa mga aktibidad sa maong Center',
          ),
          buildItem(
            '11',
            'I\'ll interact socially with my other residents.',
            'Makig halobilo ug musabot sa akong mga kauban',
          ),
          buildItem(
            '12',
            'I\'m aware that there are others in the room besides me.',
            'Kabalo ako na dili lang ako sa isa ka kwarto',
          ),
          buildItem(
            '13',
            'I authorize the personnel to conduct a medical examination and other medical interventions if necessary.',
            'Gatugot na magpa check-up ug muapil sa unsa pa na medical na intervention na ihatag sa akoa',
          ),
          buildItem(
            '14',
            'And, in accordance with the Pandemic COVID-19 Protocol, I agree to be isolated for 14 days.',
            'Ug subay sa COVID-19 na pandemya, gatugot ako na mag isolate sa 14 days ka adlaw',
          ),

          pw.SizedBox(height: 12),

          // Date Signed
          pw.RichText(
            text: pw.TextSpan(
              style: PdfStyles.normalStyle,
              children: [
                const pw.TextSpan(text: 'This '),
                PdfStyles.spanUnderline(
                    PdfStyles.formatDateDay(data['date_signed']),
                    width: 40),
                const pw.TextSpan(text: ' day of '),
                PdfStyles.spanUnderline(
                    PdfStyles.formatDateMonth(data['date_signed']),
                    width: 80),
                const pw.TextSpan(
                    text: ' in Tagum City, Philippines, is signed.'),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          pw.NewPage(),

          // Signatures
          pw.Text('SIGNED IN THE PRESENCE OF:',
              style: PdfStyles.normalStyle
                  .copyWith(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 24),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: PdfStyles.signatureLine(
                  'Client\'s Name',
                  name: (data['client_name'] ?? residentName)
                      .toString()
                      .toUpperCase(),
                  width: double.infinity,
                ),
              ),
              pw.SizedBox(width: 40),
              pw.Expanded(
                child: PdfStyles.signatureLine(
                  'Social Worker',
                  name: (data['user_name'] ?? '').toString().toUpperCase(),
                  width: double.infinity,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          pw.Center(
            child: pw.Column(
              children: [
                pw.Text('Noted by:', style: PdfStyles.normalStyle),
                pw.SizedBox(height: 16),
                PdfStyles.signatureBlock(
                  role: 'Center Head',
                  name: data['noted_by']?.toString().toUpperCase() ??
                      data['center_head_name']?.toString().toUpperCase() ??
                      '',
                  position: 'Center Head/SWO III',
                  width: 200,
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  static List<pw.Page> _buildQuarterlyNarrative(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle(
                  '${data['quarter'] ?? '1ST'} QUARTER PROGRESS NARRATIVE REPORT'),
              pw.Row(children: [
                pw.Expanded(
                    child: PdfStyles.labelWithUnderline(
                        'Name of client', data['client_name'] ?? residentName)),
                pw.SizedBox(width: 20),
                pw.SizedBox(
                    width: 150,
                    child: PdfStyles.labelWithUnderline(
                        'Date', PdfStyles.formatDate(data['report_date']))),
              ]),
              pw.SizedBox(height: 12),
              pw.Text('SOCIAL SERVICE', style: PdfStyles.subHeaderStyle),
              PdfStyles.textArea(data['social_service'], minHeight: 50),
              pw.SizedBox(height: 8),
              pw.Text('MEDICAL SERVICE', style: PdfStyles.subHeaderStyle),
              PdfStyles.textArea(data['medical_service'], minHeight: 50),
              pw.SizedBox(height: 8),
              pw.Text('PSYCH SERVICE', style: PdfStyles.subHeaderStyle),
              PdfStyles.textArea(data['psych_service'], minHeight: 50),
              pw.SizedBox(height: 8),
              pw.Text('HOMELIFE SERVICE', style: PdfStyles.subHeaderStyle),
              PdfStyles.textArea(data['homelife_service'], minHeight: 50),
              pw.SizedBox(height: 8),
              pw.Text('PSD SERVICE', style: PdfStyles.subHeaderStyle),
              PdfStyles.textArea(data['psd_service'], minHeight: 50),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Prepared by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Social Worker',
                        name: data['user_name']?.toString().toUpperCase() ?? '',
                        position: data['user_title'] ?? 'Social Worker',
                        width: 150,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Noted by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Center Head/SWO II',
                        name: data['noted_by']?.toString().toUpperCase() ?? '',
                        width: 150,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ];
  }

  // ============ HELPER METHODS ============

  static pw.Widget _bulletPoint(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4, left: 16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ', style: PdfStyles.normalStyle),
          pw.Expanded(
            child: pw.Text(text,
                style: PdfStyles.normalStyle, textAlign: pw.TextAlign.justify),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCategoryTable(Map<String, dynamic> data) {
    final categories = ['Abandoned', 'Neglected', 'Unattached', 'Homeless'];
    final ageRanges = [
      '60 to below 71',
      '71 to below 80',
      '80 and above',
      '60 and below'
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(30),
        4: const pw.FixedColumnWidth(30),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfStyles.headerBgColor),
          children: [
            _cell('', isHeader: true),
            _cell('Case Category', isHeader: true),
            _cell('SENIOR CITIZENS', isHeader: true),
            _cell('M', isHeader: true),
            _cell('F', isHeader: true),
          ],
        ),
        ...categories.asMap().entries.expand((entry) {
          final idx = entry.key;
          final category = entry.value;
          return [
            pw.TableRow(children: [
              _cell('${idx + 1}.'),
              _cell(category, isHeader: true),
              _cell(''),
              _cell(''),
              _cell(''),
            ]),
            ...ageRanges.map((range) => pw.TableRow(children: [
                  _cell(''),
                  _cell(''),
                  _cell(range),
                  _cell(''),
                  _cell(''),
                ])),
          ];
        }),
      ],
    );
  }

  static pw.TableRow _infoRow(
      String label1, String value1, String label2, String value2) {
    return pw.TableRow(
      children: [
        _cell('$label1:', isHeader: true),
        _cell(value1),
        _cell('$label2:', isHeader: true),
        _cell(value2),
      ],
    );
  }

  static pw.TableRow _singleRow(String label, String value) {
    return pw.TableRow(
      children: [
        _cell('$label:', isHeader: true),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value, style: PdfStyles.normalStyle),
        ),
      ],
    );
  }

  static pw.Widget _cell(String text,
      {bool isHeader = false, bool center = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: isHeader ? PdfStyles.labelStyle : PdfStyles.normalStyle,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _cellMinHeight(String text, double minHeight) {
    return pw.Container(
      constraints: pw.BoxConstraints(minHeight: minHeight),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: PdfStyles.normalStyle),
    );
  }

  static pw.Widget _renderBullets(String? content) {
    final items =
        (content ?? '').split('\n').where((s) => s.trim().isNotEmpty).toList();
    if (items.isEmpty) return pw.Text('', style: PdfStyles.normalStyle);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items
          .map((item) => pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: PdfStyles.normalStyle),
                    pw.Expanded(
                        child: pw.Text(item, style: PdfStyles.normalStyle)),
                  ]))
          .toList(),
    );
  }

  static pw.Widget _bulletCellMinHeight(String? content, double minHeight) {
    return pw.Container(
      constraints: pw.BoxConstraints(minHeight: minHeight),
      padding: const pw.EdgeInsets.all(6),
      child: _renderBullets(content),
    );
  }

  static pw.TableRow _cleanRow(String label, String? value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(label, style: PdfStyles.normalStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(':', style: PdfStyles.normalStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(value ?? '', style: PdfStyles.normalStyle),
        ),
      ],
    );
  }

  // DISCHARGED SLIP
  static List<pw.Page> _buildDischargeSlipNew(
    Map<String, dynamic> data,
    String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  ) {
    return [
      pw.MultiPage(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfStyles.buildDswdHeader(logoBytes: logoBytes),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'DISCHARGED SLIP',
                    style: PdfStyles.headerStyle
                        .copyWith(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 20),
                // Date/Time/Case No (Right Aligned)
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                        pw.Text('Date: ', style: PdfStyles.normalStyle),
                        pw.Text(PdfStyles.formatDate(data['discharge_date']),
                            style: PdfStyles.normalStyle),
                      ]),
                      pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                        pw.Text('Time: ', style: PdfStyles.normalStyle),
                        pw.Text(
                            (data['discharge_time'] as String?)
                                    ?.replaceAll(RegExp(r'TimeOfDay\('), '')
                                    .replaceAll(')', '') ??
                                '',
                            style: PdfStyles.normalStyle),
                      ]),
                      pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                        pw.Text('Case No. ', style: PdfStyles.normalStyle),
                        pw.Text(data['case_no'] ?? caseNumber ?? '',
                            style: PdfStyles.normalStyle),
                      ]),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('To Whom It May Concern:',
                    style: PdfStyles.normalStyle),
                pw.SizedBox(height: 10),
                pw.RichText(
                  text: pw.TextSpan(
                    style: PdfStyles.normalStyle,
                    children: [
                      const pw.TextSpan(
                          text: 'I acknowledge receiving client '),
                      PdfStyles.spanUnderline(
                          data['resident_name'] ?? residentName),
                      const pw.TextSpan(text: ', '),
                      PdfStyles.spanUnderline(
                          '${data['age']?.toString() ?? ''} years old'),
                      const pw.TextSpan(
                          text:
                              ' from DSWD-Home for the Aged, Visayan Village, Tagum City this day '),
                      PdfStyles.spanUnderline(
                          PdfStyles.formatDate(data['discharge_date'])),
                      const pw.TextSpan(text: '.'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Custodian Signatories (Right side)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        PdfStyles.signatureLine(
                          'Custodian',
                          name: (data['custodian_name'] as String?)
                              ?.toUpperCase(),
                          width: 250,
                        ),
                        pw.SizedBox(height: 10),
                        PdfStyles.signatureLine(
                          'Relationship',
                          name: (data['custodian_relationship'] as String?)
                              ?.toUpperCase(),
                          width: 250,
                        ),
                        pw.SizedBox(height: 10),
                        PdfStyles.signatureLine(
                          'Address',
                          name: (data['custodian_address'] as String?)
                              ?.toUpperCase(),
                          width: 450,
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                // Witness (Left side)
                pw.Text('Witness:', style: PdfStyles.normalStyle),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: PdfStyles.signatureLine(
                        'Social Worker',
                        name: (data['social_worker'] as String?)?.toUpperCase(),
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: PdfStyles.signatureLine(
                        'C/MSWDO',
                        name: (data['cmswdo'] as String?)?.toUpperCase(),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),
                // Approved By
                pw.Center(
                  child: pw.Text('Approved by:', style: PdfStyles.normalStyle),
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: PdfStyles.signatureLine('Center Head/SWO II',
                      name: (data['center_head'] as String?)?.toUpperCase(),
                      width: 250),
                ),

                pw.SizedBox(height: 20),
                pw.Text('Medical Findings:', style: PdfStyles.normalStyle),
                pw.Text('Recommendation/s:', style: PdfStyles.normalStyle),

                // Medical Findings
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {0: const pw.FlexColumnWidth()},
                  children: [
                    ...(() {
                      final findings = (data['medical_findings'] is List)
                          ? (data['medical_findings'] as List)
                          : (data['medical_findings']?.toString().split('\n') ??
                              []);
                      // Filter empty strings if needed, or keep them
                      final displayList = findings
                          .where((e) => e.toString().trim().isNotEmpty)
                          .toList();

                      // Ensure at least 5 rows
                      final rows = <pw.TableRow>[];
                      for (int i = 0; i < 5; i++) {
                        String text = '';
                        if (i < displayList.length) {
                          text = displayList[i].toString();
                        }
                        rows.add(
                          pw.TableRow(
                            children: [
                              pw.Container(
                                constraints:
                                    const pw.BoxConstraints(minHeight: 20),
                                padding: const pw.EdgeInsets.all(4),
                                child:
                                    pw.Text(text, style: PdfStyles.normalStyle),
                              )
                            ],
                          ),
                        );
                      }
                      // If more than 5, add the rest
                      for (int i = 5; i < displayList.length; i++) {
                        rows.add(
                          pw.TableRow(
                            children: [
                              pw.Container(
                                constraints:
                                    const pw.BoxConstraints(minHeight: 20),
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(displayList[i].toString(),
                                    style: PdfStyles.normalStyle),
                              )
                            ],
                          ),
                        );
                      }
                      return rows;
                    })(),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text('Checked by:', style: PdfStyles.normalStyle),
                ),
                pw.SizedBox(height: 20),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: PdfStyles.signatureLine(
                    'Medical Staff',
                    name: (data['medical_staff'] as String?)?.toUpperCase(),
                    width: 200,
                  ),
                ),
              ],
            )
          ];
        },
      ),
    ];
  }
}
