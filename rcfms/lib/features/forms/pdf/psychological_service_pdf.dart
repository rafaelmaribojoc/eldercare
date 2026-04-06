import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../templates/form_templates.dart';
import 'pdf_styles.dart';

/// Psychological Service PDF Templates
class PsychologicalServicePdf {
  PsychologicalServicePdf._();

  static List<pw.Page> buildPages({
    required FormTemplate template,
    required Map<String, dynamic> data,
    required String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  }) {
    switch (template.templateType) {
      case 'progress_notes':
        return _buildProgressNotes(data, residentName, logoBytes);
      case 'group_sessions':
        return _buildGroupSessionsReport(data, residentName, logoBytes);
      case 'individual_sessions':
        return _buildIndividualSessionsReport(data, residentName, logoBytes);
      case 'inter_service_referral':
        return _buildInterServiceReferral(data, residentName, logoBytes);
      case 'initial_assessment':
        return _buildInitialAssessment(data, residentName, logoBytes);
      case 'psychometrician_report':
        return _buildPsychometricianReport(data, residentName, logoBytes);
      default:
        return [_buildPlaceholder()];
    }
  }

  static pw.Page _buildPlaceholder() {
    return pw.Page(
      pageFormat: PdfStyles.pageFormat,
      build: (context) =>
          pw.Center(child: pw.Text('Form template not available')),
    );
  }

  static String _toUpper(dynamic value) {
    return value?.toString().toUpperCase() ?? '';
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
              // Top Right Document Code
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  'DSWD-GF-010A | REV 00 | 22 SEP 2023',
                  style:
                      pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                ),
              ),

              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle('PROGRESS NOTES'),

              // Form Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      'Name of Client: ${_toUpper(data['client_name'] ?? residentName)}',
                      style: PdfStyles.labelStyle),
                  pw.Text(
                      'Coverage: ${_toUpper(data['coverage_month'] ?? 'January')}, ${data['coverage_year'] ?? DateTime.now().year}',
                      style: PdfStyles.labelStyle),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                  'Date Submitted: ${PdfStyles.formatDate(data['date_submitted']).toUpperCase()}',
                  style: PdfStyles.labelStyle),
              pw.SizedBox(height: 12),

              // Progress table
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfStyles.headerBgColor),
                    children: [
                      _cell('Observations / Findings', isHeader: true),
                      _cell('Supervisory Remarks', isHeader: true),
                    ],
                  ),
                  // Section A, B, C Row
                  pw.TableRow(
                    children: [
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 300),
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('A. Mental Health Status:',
                                style: PdfStyles.labelStyle),
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(
                                  left: 12, top: 4, bottom: 12),
                              child: pw.Text(
                                  _toUpper(data['mental_health_status']),
                                  style: PdfStyles.normalStyle),
                            ),
                            pw.Text('B. Activities of Daily Living:',
                                style: PdfStyles.labelStyle),
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(
                                  left: 12, top: 4, bottom: 12),
                              child: pw.Text(_toUpper(data['adl_status']),
                                  style: PdfStyles.normalStyle),
                            ),
                            pw.Text('C. Socio-Emotional: Demonstrates:',
                                style: PdfStyles.labelStyle),
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(
                                  left: 12, top: 4, bottom: 12),
                              child: pw.Text(_toUpper(data['socio_emotional']),
                                  style: PdfStyles.normalStyle),
                            ),
                          ],
                        ),
                      ),
                      _cellMinHeight(
                          _toUpper(data['supervisory_remarks']), 300),
                    ],
                  ),
                  // Section D Header Row
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        color: PdfStyles.textColor, // Dark background
                        child: pw.Text('D. WAYS FORWARD :',
                            style: PdfStyles.labelStyle
                                .copyWith(color: PdfColor.fromInt(0xFFFFFFFF))),
                      ),
                      pw.Container(), // Empty adjacent cell
                    ],
                  ),
                  // Section D Content Row
                  pw.TableRow(
                    children: [
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 150),
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_toUpper(data['ways_forward']),
                            style: PdfStyles.normalStyle),
                      ),
                      _cellMinHeight('', 150), // Empty remarks
                    ],
                  ),
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
                      pw.Text('Prepared by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: data['prepared_by_designation'] ??
                            'Psychometrician',
                        name: _toUpper(data['prepared_by']),
                        licenseNo: data['prepared_by_license'],
                        width: 200,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Noted by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Center Head',
                        name: _toUpper(
                            data['noted_by'] ?? 'CANDELARIA C. TINGSON, RSW'),
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

  // ============ GROUP SESSIONS REPORT ============
  static List<pw.Page> _buildGroupSessionsReport(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    final participants = (data['participant_details'] as List<dynamic>?) ?? [];

    return [
      pw.MultiPage(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        header: (context) => context.pageNumber == 1
            ? PdfStyles.buildDswdHeader(logoBytes: logoBytes)
            : pw.SizedBox(),
        footer: (context) => PdfStyles.pageFooter(context),
        build: (context) => [
          PdfStyles.formTitle('GROUP SESSIONS REPORT'),
          PdfStyles.confidentialityNotice(),
          pw.SizedBox(height: 12),

          // Session type
          pw.Row(
            children: [
              PdfStyles.checkbox(data['type_referral'] ?? false,
                  label: 'By Referral'),
              pw.SizedBox(width: 30),
              PdfStyles.checkbox(data['type_walkin'] ?? false,
                  label: 'Walk-in'),
              pw.SizedBox(width: 30),
              PdfStyles.checkbox(data['type_as_needed'] ?? false,
                  label: 'As Need Arises'),
            ],
          ),
          pw.SizedBox(height: 12),

          pw.Row(children: [
            pw.Expanded(
                child: PdfStyles.labelWithUnderline('Date of Session',
                    PdfStyles.formatDate(data['session_date']))),
            pw.SizedBox(width: 20),
            pw.Expanded(
                child: PdfStyles.labelWithUnderline('Date of Report',
                    PdfStyles.formatDate(data['report_date']))),
          ]),

          PdfStyles.sectionHeader('REASON FOR SESSION'),
          PdfStyles.textArea(_toUpper(data['reason_for_session']),
              minHeight: 40),

          PdfStyles.sectionHeader('PARTICIPANTS'),
          PdfStyles.textArea(_toUpper(data['participants']), minHeight: 40),

          PdfStyles.sectionHeader('OBJECTIVES OF THE SESSION'),
          PdfStyles.textArea(_toUpper(data['objectives']), minHeight: 40),

          PdfStyles.sectionHeader('SESSION NARRATIVE'),
          PdfStyles.textArea(_toUpper(data['session_narrative']),
              minHeight: 80),

          PdfStyles.sectionHeader('AGREEMENTS/LESSONS IMPARTED'),

          // Participant-specific table if available
          if (participants.isNotEmpty) ...[
            pw.Table(
              border:
                  pw.TableBorder.all(color: PdfStyles.borderColor, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfStyles.headerBgColor),
                  children: [
                    _cell('Participant', isHeader: true),
                    _cell('Challenges', isHeader: true),
                    _cell('Agreements/Lessons Imparted', isHeader: true),
                  ],
                ),
                ...participants.map((p) {
                  final participant = p as Map<String, dynamic>;
                  return pw.TableRow(
                    children: [
                      _cell(_toUpper(participant['name'])),
                      _cell(_toUpper(participant['challenges'])),
                      _cell(_toUpper(participant['agreements'])),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 8),
          ],

          PdfStyles.textArea(_toUpper(data['general_agreements']),
              minHeight: 50),

          PdfStyles.sectionHeader('RECOMMENDATIONS'),
          PdfStyles.textArea(_toUpper(data['recommendations']), minHeight: 60),

          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Prepared by:', style: PdfStyles.normalStyle),
                  PdfStyles.signatureBlock(
                    role: 'Psychometrician',
                    name: data['prepared_by'],
                    licenseNo: data['license_no'],
                    width: 200,
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Noted by:', style: PdfStyles.normalStyle),
                  PdfStyles.signatureBlock(
                    role: 'Center Head',
                    name: _toUpper(data['noted_by']),
                    width: 180,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ];
  }

  // ============ INDIVIDUAL SESSIONS REPORT ============
  static List<pw.Page> _buildIndividualSessionsReport(
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
              // Header
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              pw.SizedBox(height: 8),
              PdfStyles.formTitle('INDIVIDUAL SESSIONS REPORT'),
              PdfStyles.confidentialityNotice(),
              pw.SizedBox(height: 12),

              // Session type
              pw.Row(
                children: [
                  PdfStyles.checkbox(data['type_referral'] ?? false,
                      label: 'By Referral'),
                  pw.SizedBox(width: 30),
                  PdfStyles.checkbox(data['type_walkin'] ?? false,
                      label: 'Walk-in'),
                  pw.SizedBox(width: 30),
                  PdfStyles.checkbox(data['type_as_needed'] ?? false,
                      label: 'As Need Arises'),
                ],
              ),
              pw.SizedBox(height: 12),

              PdfStyles.labelWithUnderline(
                  'Client Name', _toUpper(data['client_name'] ?? residentName)),
              pw.Row(children: [
                pw.Expanded(
                    child: PdfStyles.labelWithUnderline('Date of Session',
                        PdfStyles.formatDate(data['session_date']))),
                pw.SizedBox(width: 20),
                pw.Expanded(
                    child: PdfStyles.labelWithUnderline('Date of Report',
                        PdfStyles.formatDate(data['report_date']))),
              ]),

              PdfStyles.sectionHeader('REASON FOR SESSION'),
              PdfStyles.textArea(data['reason_for_session'], minHeight: 40),

              PdfStyles.sectionHeader('OBJECTIVES OF THE SESSION'),
              PdfStyles.textArea(data['objectives'], minHeight: 40),

              PdfStyles.sectionHeader('SESSION NARRATIVE'),
              PdfStyles.textArea(data['session_narrative'], minHeight: 100),

              PdfStyles.sectionHeader('AGREEMENTS/LESSONS IMPARTED'),
              PdfStyles.textArea(data['agreements'], minHeight: 50),

              PdfStyles.sectionHeader('RECOMMENDATIONS'),
              PdfStyles.textArea(data['recommendations'], minHeight: 50),

              pw.Spacer(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Prepared by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: data['prepared_by_designation'] ??
                            'Psychometrician',
                        name: _toUpper(data['prepared_by']),
                        licenseNo: data['prepared_by_license'],
                        width: 200,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Noted by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Center Head',
                        name: _toUpper(
                            data['noted_by'] ?? 'CANDELARIA C. TINGSON, RSW'),
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

  // ============ INTER-SERVICE REFERRAL ============
  static List<pw.Page> _buildInterServiceReferral(
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
              // Header
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              pw.Center(
                  child: pw.Text('Psychological Service',
                      style: PdfStyles.subHeaderStyle)),
              pw.SizedBox(height: 12),
              pw.SizedBox(height: 12),
              PdfStyles.formTitle('REFERRAL FORM'),

              PdfStyles.labelWithUnderline('Date of Referral',
                  PdfStyles.formatDate(data['referral_date'])),
              pw.SizedBox(height: 12),

              // Client info
              pw.Row(children: [
                pw.Expanded(
                  flex: 2,
                  child: PdfStyles.labelWithUnderline(
                      'Name', _toUpper(data['client_name'] ?? residentName)),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: PdfStyles.labelWithUnderline(
                      'Nickname', _toUpper(data['nickname'])),
                ),
              ]),
              pw.Row(children: [
                pw.Expanded(
                  child: PdfStyles.labelWithUnderline('Date of Birth',
                      PdfStyles.formatDate(data['date_of_birth'])),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: PdfStyles.labelWithUnderline(
                      'Age', data['age']?.toString() ?? ''),
                ),
              ]),
              PdfStyles.labelWithUnderline(
                  'Ward/Room', _toUpper(data['ward_room'])),

              PdfStyles.sectionHeader('REASON FOR REFERRAL'),
              PdfStyles.textArea(_toUpper(data['reason_for_referral']),
                  minHeight: 100),

              PdfStyles.sectionHeader('Challenges Presented'),
              PdfStyles.textArea(_toUpper(data['challenges_presented']),
                  minHeight: 150),

              pw.Spacer(),

              // Referring party
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  PdfStyles.signatureLine('',
                      name: _toUpper(data['referring_person']), width: 200),
                  pw.SizedBox(height: 4),
                  PdfStyles.labelWithUnderline(
                      'Position', _toUpper(data['referring_position'])),
                  PdfStyles.labelWithUnderline(
                      'Unit / Service', _toUpper(data['referring_unit'])),
                ],
              ),
            ],
          );
        },
      ),
    ];
  }

  // ============ INITIAL PSYCHOLOGICAL ASSESSMENT ============
  static List<pw.Page> _buildInitialAssessment(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    final interventions = (data['intervention_items'] as List<dynamic>?) ?? [];

    return [
      pw.MultiPage(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        header: (context) => context.pageNumber == 1
            ? PdfStyles.buildDswdHeader(logoBytes: logoBytes)
            : pw.SizedBox(),
        footer: (context) => PdfStyles.pageFooter(context),
        build: (context) => [
          PdfStyles.formTitle('INITIAL PSYCHOLOGICAL ASSESSMENT'),
          PdfStyles.confidentialityNotice(),
          pw.SizedBox(height: 12),
          _buildIdentifyingData(data, residentName),
          PdfStyles.sectionHeader('II. REASON FOR REFERRAL'),
          PdfStyles.textArea(data['reason_for_referral'], minHeight: 60),
          PdfStyles.sectionHeader('III. ASSESSMENT TOOLS AND OTHER PROCEDURES'),
          PdfStyles.textArea(data['assessment_tools'], minHeight: 60),
          PdfStyles.sectionHeader('IV. RESULTS AND DISCUSSION'),
          PdfStyles.textArea(data['results_discussion'], minHeight: 120),
          _buildInterventionPlan(interventions),
          pw.SizedBox(height: 20),
          _buildPsychSignatures(data),
        ],
      ),
    ];
  }

  // ============ PSYCHOMETRICIAN'S REPORT ============
  static List<pw.Page> _buildPsychometricianReport(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    final interventions = (data['intervention_items'] as List<dynamic>?) ?? [];

    return [
      pw.MultiPage(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        header: (context) => context.pageNumber == 1
            ? PdfStyles.buildDswdHeader(logoBytes: logoBytes)
            : pw.SizedBox(),
        footer: (context) => PdfStyles.pageFooter(context),
        build: (context) => [
          PdfStyles.formTitle("PSYCHOMETRICIAN'S REPORT"),
          PdfStyles.confidentialityNotice(),
          pw.SizedBox(height: 12),
          _buildIdentifyingDataExtended(data, residentName),
          PdfStyles.sectionHeader('II. REASON FOR REFERRAL'),
          PdfStyles.textArea(data['reason_for_referral'], minHeight: 60),
          PdfStyles.sectionHeader('BRIEF HISTORY'),
          PdfStyles.textArea(data['brief_history'], minHeight: 80),
          PdfStyles.sectionHeader('BEHAVIORAL OBSERVATION'),
          PdfStyles.textArea(data['behavioral_observation'], minHeight: 80),
          PdfStyles.sectionHeader('III. ASSESSMENT TOOLS AND OTHER PROCEDURES'),
          PdfStyles.textArea(data['assessment_tools'], minHeight: 60),
          PdfStyles.sectionHeader('MENTAL STATUS EXAMINATION'),
          PdfStyles.textArea(data['mental_status_exam'], minHeight: 80),
          PdfStyles.sectionHeader('IV. RESULTS AND DISCUSSION'),
          PdfStyles.textArea(data['results_discussion'], minHeight: 120),
          _buildInterventionPlan(interventions),
          pw.SizedBox(height: 20),
          _buildPsychSignatures(data),
        ],
      ),
    ];
  }

  // ============ HELPER METHODS ============

  static pw.Widget _pdfRowItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(label, style: PdfStyles.normalStyle),
          ),
          pw.Text(': ', style: PdfStyles.normalStyle),
          pw.Expanded(
            child: pw.Text(value,
                style: PdfStyles.normalStyle
                    .copyWith(fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildIdentifyingData(
      Map<String, dynamic> data, String residentName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfStyles.sectionHeader('I. IDENTIFYING DATA'),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12),
          child: pw.Column(
            children: [
              _pdfRowItem('Name', _toUpper(data['name'] ?? residentName)),
              _pdfRowItem('Nickname', _toUpper(data['nickname'])),
              _pdfRowItem(
                  'Date of Birth', PdfStyles.formatDate(data['date_of_birth'])),
              _pdfRowItem('Age', data['age']?.toString() ?? ''),
              _pdfRowItem('Sex', _toUpper(data['sex'])),
              _pdfRowItem('Address', _toUpper(data['address'])),
              _pdfRowItem('Religious Affiliation',
                  _toUpper(data['religious_affiliation'])),
              _pdfRowItem('Educational Attainment',
                  _toUpper(data['educational_attainment'])),
              _pdfRowItem('Date of Admission',
                  PdfStyles.formatDate(data['date_of_admission'])),
              _pdfRowItem('Date of Assessment',
                  PdfStyles.formatDate(data['date_of_assessment'])),
              _pdfRowItem('Date of Report',
                  PdfStyles.formatDate(data['date_of_report'])),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildIdentifyingDataExtended(
      Map<String, dynamic> data, String residentName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfStyles.sectionHeader('I. IDENTIFYING DATA'),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12),
          child: pw.Column(
            children: [
              _pdfRowItem('Name', _toUpper(data['name'] ?? residentName)),
              _pdfRowItem('Nickname', _toUpper(data['nickname'])),
              _pdfRowItem(
                  'Date of Birth', PdfStyles.formatDate(data['date_of_birth'])),
              _pdfRowItem('Age', data['age']?.toString() ?? ''),
              _pdfRowItem('Sex', _toUpper(data['sex'])),
              _pdfRowItem('Address', _toUpper(data['address'])),
              _pdfRowItem('Religious Affiliation',
                  _toUpper(data['religious_affiliation'])),
              _pdfRowItem('Educational Attainment',
                  _toUpper(data['educational_attainment'])),
              _pdfRowItem('Category', _toUpper(data['category'])),
              _pdfRowItem('Date of Admission',
                  PdfStyles.formatDate(data['date_of_admission'])),
              _pdfRowItem('Date of Assessment',
                  PdfStyles.formatDate(data['date_of_assessment'])),
              _pdfRowItem('Date of Report',
                  PdfStyles.formatDate(data['date_of_report'])),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildInterventionPlan(List<dynamic> interventions) {
    if (interventions.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PdfStyles.sectionHeader('V. RECOMMENDATIONS / INTERVENTION PLAN'),
          pw.Text('No intervention items recorded.',
              style: PdfStyles.normalStyle),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfStyles.sectionHeader('V. RECOMMENDATIONS / INTERVENTION PLAN'),
        ...interventions.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value as Map<String, dynamic>;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfStyles.borderColor, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Activity #${index + 1}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfStyles.primaryColor,
                  ),
                ),
                pw.SizedBox(height: 8),
                _pdfLabelValue('Objective', item['objectives']),
                pw.SizedBox(height: 8),
                _pdfLabelValue('Activity', item['activity']),
                pw.SizedBox(height: 8),
                _pdfLabelValue(
                    'Responsible Person', item['responsible_person']),
                pw.SizedBox(height: 8),
                _pdfLabelValue('Time Frame', item['time_frame']),
                pw.SizedBox(height: 8),
                _pdfLabelValue('Outcome', item['outcome']),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _pdfLabelValue(String label, String? value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColor.fromInt(0xFF616161),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value ?? '',
          style: PdfStyles.normalStyle,
        ),
      ],
    );
  }

  static pw.Widget _buildPsychSignatures(Map<String, dynamic> data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Prepared by:', style: PdfStyles.normalStyle),
            PdfStyles.signatureBlock(
              role: data['prepared_by_designation'] ??
                  data['profession'] ??
                  'Psychometrician',
              name: data['prepared_by'],
              licenseNo: data['prepared_by_license'] ?? data['license_no'],
              width: 200,
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Noted by:', style: PdfStyles.normalStyle),
            PdfStyles.signatureBlock(
              role: data['noted_by_designation'] ??
                  data['noted_by_position'] ??
                  'Center Head',
              name: data['noted_by'] ?? 'CANDELARIA C. TINGSON, RSW',
              width: 200,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: isHeader ? PdfStyles.labelStyle : PdfStyles.normalStyle,
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
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
}
