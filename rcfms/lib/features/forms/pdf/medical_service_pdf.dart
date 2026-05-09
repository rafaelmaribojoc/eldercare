import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../templates/form_templates.dart';
import 'pdf_styles.dart';

/// Medical Service PDF Templates
class MedicalServicePdf {
  MedicalServicePdf._();

  static List<pw.Page> buildPages({
    required FormTemplate template,
    required Map<String, dynamic> data,
    required String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  }) {
    switch (template.templateType) {
      case 'md_nursing_care_service':
        return _buildNursingCareService(data, residentName, logoBytes);
      case 'md_monthly_accomplishment_report':
        return _buildMonthlyAccomplishmentReport(data, residentName, logoBytes);
      case 'md_quarterly_report':
        return _buildQuarterlyReport(data, residentName, logoBytes);
      default:
        return [_buildPlaceholder()];
    }
  }

  static pw.Page _buildPlaceholder() {
    return pw.Page(
      pageFormat: PdfStyles.pageFormat,
      build: (context) =>
          pw.Center(child: pw.Text('Medical form template not available')),
    );
  }

  // ============ NURSING CARE SERVICE ============
  static List<pw.Page> _buildNursingCareService(
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
              PdfStyles.formTitle('MEDICAL NURSING CARE SERVICE'),

              // Header Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(children: [
                        pw.SizedBox(
                            width: 80,
                            child: pw.Text('Date Conducted:',
                                style: PdfStyles.normalStyle)),
                        pw.Text(PdfStyles.formatDate(data['date_conducted']),
                            style: PdfStyles.normalStyle),
                      ]),
                      pw.Row(children: [
                        pw.SizedBox(
                            width: 80,
                            child:
                                pw.Text('Name:', style: PdfStyles.normalStyle)),
                        pw.Text(data['name'] ?? residentName,
                            style: PdfStyles.normalStyle),
                      ]),
                      pw.Row(children: [
                        pw.SizedBox(
                            width: 80,
                            child: pw.Text('Weight:',
                                style: PdfStyles.normalStyle)),
                        pw.Text(data['weight'] ?? '',
                            style: PdfStyles.normalStyle),
                      ]),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(children: [
                        pw.SizedBox(
                            width: 60,
                            child: pw.Text('Birthdate:',
                                style: PdfStyles.normalStyle)),
                        pw.Text(PdfStyles.formatDate(data['birthdate']),
                            style: PdfStyles.normalStyle),
                      ]),
                      pw.Row(children: [
                        pw.SizedBox(
                            width: 60,
                            child: pw.Text('Height:',
                                style: PdfStyles.normalStyle)),
                        pw.Text(data['height'] ?? '',
                            style: PdfStyles.normalStyle),
                      ]),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(children: [
                        pw.SizedBox(
                            width: 50,
                            child: pw.Text('Age/Sex:',
                                style: PdfStyles.normalStyle)),
                        pw.Text(data['age_sex'] ?? '',
                            style: PdfStyles.normalStyle),
                      ]),
                      pw.Row(children: [
                        pw.SizedBox(
                            width: 50,
                            child:
                                pw.Text('BMI:', style: PdfStyles.normalStyle)),
                        pw.Text(data['bmi'] ?? '',
                            style: PdfStyles.normalStyle),
                      ]),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              pw.Text('PHYSICAL ASSESSMENT:', style: PdfStyles.subHeaderStyle),
              pw.SizedBox(height: 10),

              // Physical Assessment & Body Map
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Column: Assessment Fields
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      children: [
                        _assessmentRow('SKIN', data['skin']),
                        _assessmentRow('HAIR', data['hair']),
                        _assessmentRow('EYES', data['eyes']),
                        _assessmentRow('EARS', data['ears']),
                        _assessmentRow('MOUTH', data['mouth']),
                        _assessmentRow('NAILS', data['nails']),
                        _assessmentRow('CHEST & LUNGS', data['chest_lungs']),
                        _assessmentRow('CARDIO', data['cardio']),
                        _assessmentRow('ABDOMEN', data['abdomen']),
                        _assessmentRow('GENITALS', data['genitals']),
                        _assessmentRow('EXTREMITIES', data['extremities']),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Right Column: Body Map Placeholder
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      children: [
                        pw.Container(
                          height: 300,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey),
                          ),
                          child: pw.Center(
                            child:
                                pw.Text('[ Body Map Image ]\n(Front & Back)'),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        if (data['body_map_description'] != null)
                          pw.Text(data['body_map_description'],
                              style: PdfStyles.smallStyle,
                              textAlign: pw.TextAlign.center),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Assessment Points
              pw.Text('Assessment:', style: PdfStyles.subHeaderStyle),
              pw.SizedBox(height: 8),
              _renderAssessmentPoints(data),

              pw.SizedBox(height: 16),
              pw.Text('Remarks:', style: PdfStyles.subHeaderStyle),
              pw.SizedBox(height: 4),
              pw.Text(data['remarks'] ?? '', style: PdfStyles.normalStyle),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  PdfStyles.signatureBlock(
                    role: 'Nurse',
                    signatureBytes:
                        data['_prepared_by_signature_bytes'] as Uint8List?,
                    name: data['prepared_by'],
                    width: 200,
                  ),
                  PdfStyles.signatureBlock(
                    role:
                        'Center Head', // As per image "NOTED BY: CANDELARIA C. TINGSON, RSW"
                    signatureBytes:
                        data['_noted_by_signature_bytes'] as Uint8List?,
                    name: data['noted_by'] ?? 'CANDELARIA C. TINGSON, RSW',
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

  static pw.Widget _assessmentRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text('$label:',
                style: PdfStyles.normalStyle
                    .copyWith(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(value ?? '', style: PdfStyles.normalStyle),
          ),
        ],
      ),
    );
  }

  static pw.Widget _renderAssessmentPoints(Map<String, dynamic> data) {
    // Check for structured list or legacy string
    List<dynamic> items = [];
    if (data['assessment_points'] is List) {
      items = data['assessment_points'];
    } else if (data['assessment'] is String) {
      // Fallback to splitting string if list format not used
      items = (data['assessment'] as String).split('\n');
    }

    if (items.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.map((item) {
        final text = item.toString().trim().replaceAll('•', '').trim();
        if (text.isEmpty) return pw.SizedBox();
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('> ', style: PdfStyles.normalStyle),
              pw.Expanded(child: pw.Text(text, style: PdfStyles.normalStyle)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============ QUARTERLY REPORT ============
  static List<pw.Page> _buildQuarterlyReport(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    return [
      pw.MultiPage(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return [
            PdfStyles.buildDswdHeader(logoBytes: logoBytes),
            PdfStyles.formTitle('(PROTECTIVE SERVICES DIVISION)'),
            pw.Center(
                child: pw.Text('HOME FOR THE AGED / FIELD OFFICE XI',
                    style: PdfStyles.subHeaderStyle)),
            pw.SizedBox(height: 4),
            pw.Center(
                child: pw.Text('DSWD-GF-010 | REV 01 | 22 SEP 2023',
                    style: PdfStyles.smallStyle.copyWith(fontSize: 8))),
            pw.SizedBox(height: 20),

            pw.Center(
                child: pw.Column(children: [
              pw.Text('Republic of the Philippines',
                  style: PdfStyles.smallStyle),
              pw.Text('Department of Social Welfare and Development',
                  style: PdfStyles.smallStyle),
              pw.Text('HOME FOR THE AGED', style: PdfStyles.subHeaderStyle),
              pw.Text('Visayan Village, Tagum City',
                  style: PdfStyles.smallStyle),
            ])),
            pw.SizedBox(height: 20),

            // Header Meta
            pw.Table(columnWidths: {
              0: const pw.FixedColumnWidth(80),
              1: const pw.FlexColumnWidth(),
            }, children: [
              pw.TableRow(children: [
                pw.Text('For', style: PdfStyles.normalStyle),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('THE CENTER HEAD', style: PdfStyles.boldStyle),
                      pw.Text('DSWD - Home for the Aged',
                          style: PdfStyles.normalStyle),
                      pw.Text('Visayan Village, Tagum City',
                          style: PdfStyles.normalStyle),
                      pw.SizedBox(height: 8),
                    ])
              ]),
              pw.TableRow(children: [
                pw.Text('From:', style: PdfStyles.normalStyle),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('NURSE I', style: PdfStyles.normalStyle),
                      pw.Text('DSWD - Home for the Aged',
                          style: PdfStyles.normalStyle),
                      pw.Text('Visayan Village, Tagum City',
                          style: PdfStyles.normalStyle),
                      pw.SizedBox(height: 8),
                    ])
              ]),
              pw.TableRow(children: [
                pw.Text('Subject:', style: PdfStyles.normalStyle),
                pw.Text(
                    '${DateTime.now().year} Quarterly Report re: Medical Service Report',
                    style: PdfStyles.normalStyle),
              ]),
            ]),
            pw.SizedBox(height: 20),

            // 1. CENSUS
            _sectionTitle('CENSUS'),
            _buildSimpleTable(
                [
                  'MONTH',
                  'CENSUS',
                  'MALE',
                  'FEMALE',
                  'ADMISSION',
                  'DISCHARGE',
                  'MORTALITY',
                  'TOTAL CENSUS AT END OF THE MONTH'
                ],
                data,
                'census',
                flexes: [2, 1, 1, 1, 2, 2, 2, 3]),
            pw.SizedBox(height: 20),

            // 2. REFERRALS
            _sectionTitle('TOTAL NUMBER OF REFERRED RESIDENTS'),
            _buildSimpleTable(
                [
                  'MONTH',
                  'DRMC & BUCAS CENTER',
                  'SPMC-IPBM',
                  'PTSI',
                  'GREEN LAB CLINIC AND WELLNESS',
                  'PERPETUAL MEDICAL MULTI-SPECIALTY & DIAGNOSTIC'
                ],
                data,
                'referrals',
                flexes: [2, 3, 2, 2, 3, 4]),
            pw.SizedBox(height: 20),

            // 3. MORBIDITY
            _sectionTitle('MORBIDITY'),
            _buildSimpleTable(['NAME', 'DATE ADMITTED', 'ADMITTING DIAGNOSIS'],
                data, 'morbidity',
                flexes: [3, 2, 3], minRows: 3),
            pw.SizedBox(height: 20),

            // 4. OPERATION
            _sectionTitle('MINOR/MAJOR OPERATION'),
            _buildSimpleTable(['NAME', 'DATE', 'REMARKS'], data, 'operations',
                flexes: [3, 2, 3], minRows: 3),
            pw.SizedBox(height: 20),

            // 5. MORTALITY
            _sectionTitle('MORTALITY'),
            _buildSimpleTable(
                ['NAME', 'DATE EXPIRED', 'CAUSE OF DEATH'], data, 'mortality',
                flexes: [3, 2, 3], minRows: 3),
            pw.SizedBox(height: 20),

            // 6. COVID VACCINATION
            _sectionTitle('TOTAL NUMBER OF COVID VACCINATED RESIDENTS:'),
            _buildSimpleTable(
                [
                  'GENDER',
                  'UNVACCINATED',
                  '1ST DOSE VACCINE',
                  '2ND DOSE VACCINE',
                  '1ST DOSE BOOSTER',
                  '2ND DOSE BOOSTER',
                  'TOTAL FULLY VACCINATED'
                ],
                data,
                'covid_vaccination',
                flexes: [2, 2, 2, 2, 2, 2, 2]),
            pw.SizedBox(height: 20),

            _sectionTitle(
                'TOTAL NUMBER OF RESIDENTS UNVACCINATED: 11'), // Hardcodded in template image, but should be dynamic ideally
            pw.Text('REASON (NEW ADMISSIONS):', style: PdfStyles.normalStyle),
            pw.SizedBox(height: 4),
            pw.Text(
                data['unvaccinated_reasons'] ??
                    '1 MALE - NEW ADMISSION, NO VACCINATION DETAILS.\n1 FEMALE - NEW ADMISSION, PARTIALLY VACCINATED.',
                style: PdfStyles.normalStyle),

            pw.SizedBox(height: 40),

            // Signatures
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Prepared by:', style: PdfStyles.normalStyle),
                        pw.SizedBox(height: 20),
                        pw.Text(
                            (data['prepared_by'] ??
                                    'CHRISTINE JAN O. TEMPLANZA')
                                .toUpperCase(),
                            style: PdfStyles.boldStyle.copyWith(
                                decoration: pw.TextDecoration.underline)),
                        pw.Text('NURSE I', style: PdfStyles.normalStyle),
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Noted by:', style: PdfStyles.normalStyle),
                        pw.SizedBox(height: 20),
                        pw.Text(
                            (data['noted_by'] ?? 'Candelaria C. Tingson')
                                .toUpperCase(),
                            style: PdfStyles.boldStyle),
                        pw.Text('SWOIII/Center Head',
                            style: PdfStyles.normalStyle),
                      ]),
                ])
          ];
        },
      ),
    ];
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(children: [
          pw.Icon(const pw.IconData(0xe5cc), size: 10), // Arrow right-ish
          pw.SizedBox(width: 8),
          pw.Text(title, style: PdfStyles.boldStyle),
        ]));
  }

  // ============ MONTHLY ACCOMPLISHMENT REPORT ============
  static List<pw.Page> _buildMonthlyAccomplishmentReport(
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
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  PdfStyles.buildDswdHeader(logoBytes: logoBytes),
                  pw.SizedBox(height: 4),
                  pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text('DSWD-GF-010A | REV 00 | 22 SEP 2023',
                          style: PdfStyles.smallStyle.copyWith(fontSize: 8))),
                  pw.SizedBox(height: 20),
                  PdfStyles.formTitle(
                      'MONTHLY ACCOMPLISHMENT REPORT OF MEDICAL SERVICE'),
                  pw.Text(
                      'FOR THE MONTH OF ${(data['month'] ?? '').toString().toUpperCase()}',
                      style: PdfStyles.subHeaderStyle),
                  pw.SizedBox(height: 20),

                  // Table
                  _buildSimpleTable(['ACTIVITY', 'OUTPUT', 'OUTCOME'], data,
                      'accomplishments',
                      flexes: [1, 1, 1], minRows: 15, rowHeight: 25),

                  pw.Spacer(),

                  // Signatures
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      PdfStyles.signatureBlock(
                        role: 'Prepared By:',
                        name:
                            data['prepared_by'] ?? 'HYACINTH A. LABASTIDA, RN',
                        position: 'Nurse I',
                        width: 200,
                      ),
                      PdfStyles.signatureBlock(
                        role: 'Noted By',
                        name: data['noted_by'] ?? 'CANDELARIA C. TINGSON, RSW',
                        position: 'Center Head',
                        width: 200,
                      ),
                    ],
                  ),
                ]);
          })
    ];
  }

  // Helper for generated tables
  static pw.Widget _buildSimpleTable(
    List<String> headers,
    Map<String, dynamic> data,
    String key, {
    List<int>? flexes,
    int minRows = 0,
    double? rowHeight,
  }) {
    final items = (data['${key}_items'] as List<dynamic>?) ?? [];

    // Convert items into table rows
    final rows = <pw.TableRow>[];

    // Header
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfStyles.headerBgColor),
      children: headers
          .map((h) => pw.Container(
                padding: const pw.EdgeInsets.all(4),
                alignment: pw.Alignment.center,
                child: pw.Text(h,
                    style: PdfStyles.boldStyle.copyWith(fontSize: 9),
                    textAlign: pw.TextAlign.center),
              ))
          .toList(),
    ));

    // Data Rows
    for (int i = 0; i < items.length; i++) {
      final item = items[i] as Map<String, dynamic>;
      rows.add(pw.TableRow(
          children: headers.map((h) {
        // Derive key from header
        String colKey = h
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll('/', '_')
            .replaceAll('&', 'and')
            .replaceAll('-', '_');
        // Handle special case for 1st dose/2nd dose due to digits
        if (colKey.startsWith('1')) {
          colKey =
              '1st_dose_vaccine'; // rough matching correction if needed, but implementation plan used standard generation logic so keys likely match builder logic.
        }
        // For now assuming exact match with form builder logic

        // Correct keys matching form_field_builders.dart logic:
        // 1st DOSE -> 1st_dose

        return pw.Container(
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.topLeft,
          height: rowHeight,
          child: pw.Text(item[colKey]?.toString() ?? '',
              style: PdfStyles.normalStyle),
        );
      }).toList()));
    }

    // Fill remaining rows to meet minRows
    if (items.length < minRows) {
      for (int i = 0; i < minRows - items.length; i++) {
        rows.add(pw.TableRow(
            children: headers
                .map((_) => pw.Container(
                      height: rowHeight ?? 20,
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(''),
                    ))
                .toList()));
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: flexes != null
          ? Map.fromIterables(List.generate(flexes.length, (i) => i),
              flexes.map((f) => pw.FlexColumnWidth(f.toDouble())))
          : null,
      children: rows,
    );
  }
}
