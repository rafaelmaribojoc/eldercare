import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

import '../templates/form_templates.dart';
import 'pdf_styles.dart';

/// Home Life Service PDF Templates
class HomeLifeServicePdf {
  HomeLifeServicePdf._();

  static List<pw.Page> buildPages({
    required FormTemplate template,
    required Map<String, dynamic> data,
    required String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  }) {
    switch (template.templateType) {
      case 'inventory_admission':
        return _buildInventoryAdmission(data, residentName, logoBytes);
      case 'inventory_discharge':
        return _buildInventoryDischarge(data, residentName, logoBytes);
      case 'inventory_monthly':
        return _buildInventoryMonthly(data, residentName, logoBytes);
      case 'progress_notes':
        return _buildProgressNotes(data, residentName, logoBytes);
      case 'incident_report':
        return _buildIncidentReport(data, residentName, logoBytes);
      case 'out_on_pass':
        return _buildOutOnPass(data, residentName, logoBytes);
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

  // ============ INVENTORY UPON ADMISSION ============
  static List<pw.Page> _buildInventoryAdmission(
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
              PdfStyles.formTitle('INVENTORY OF BELONGINGS'),
              pw.Center(
                child: pw.Text(
                  'UPON ADMISSION',
                  style: PdfStyles.headerStyle,
                ),
              ),
              pw.SizedBox(height: 16),

              // Client info
              pw.Row(
                children: [
                  pw.Expanded(
                    child: PdfStyles.labelWithUnderline(
                      'Name of the client',
                      data['client_name'] ?? residentName,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              PdfStyles.labelWithUnderline(
                'Date',
                PdfStyles.formatDate(data['inventory_date']),
              ),
              pw.SizedBox(height: 16),

              // Inventory table
              _buildInventoryTable(
                  data['admission_items'] as List<dynamic>? ?? []),

              pw.SizedBox(height: 16),

              // Signatures
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  PdfStyles.signatureBlock(
                    role: 'Signature of Client',
                    signatureBytes: data['_client_signature_bytes'],
                    width: 150,
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  PdfStyles.signatureBlock(
                    role: 'Referring Party',
                    name: data['referring_party'],
                    width: 120,
                  ),
                  PdfStyles.signatureBlock(
                    role: 'HP on duty',
                    name: data['inspected_by'],
                    position: 'Inspected by',
                    width: 120,
                  ),
                  PdfStyles.signatureBlock(
                    role: 'Supervising Houseparent',
                    name: data['attested_by'],
                    position: 'Attested by',
                    width: 130,
                  ),
                  PdfStyles.signatureBlock(
                    role: 'Center Head',
                    name: data['noted_by'],
                    position: 'Noted by',
                    width: 120,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ];
  }

  // ============ INVENTORY UPON DISCHARGE ============
  static List<pw.Page> _buildInventoryDischarge(
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
              PdfStyles.formTitle('INVENTORY OF BELONGINGS'),
              pw.Center(
                child: pw.Text(
                  'UPON DISCHARGE',
                  style: PdfStyles.headerStyle,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: PdfStyles.labelWithUnderline(
                      'Name of the client',
                      data['client_name'] ?? residentName,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              PdfStyles.labelWithUnderline(
                'Date',
                PdfStyles.formatDate(data['inventory_date']),
              ),
              pw.SizedBox(height: 16),
              _buildInventoryTable(
                  data['discharge_items'] as List<dynamic>? ?? []),
              pw.SizedBox(height: 16),
              // Signatures
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  PdfStyles.signatureBlock(
                    role: 'Signature of Client',
                    signatureBytes: data['_client_signature_bytes'],
                    width: 150,
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  PdfStyles.signatureBlock(
                    role: 'Receiving Party',
                    name: data['receiving_party'],
                    width: 120,
                  ),
                  PdfStyles.signatureBlock(
                    role: 'HP on duty',
                    name: data['inspected_by'],
                    position: 'Inspected by',
                    width: 120,
                  ),
                  PdfStyles.signatureBlock(
                    role: 'Supervising Houseparent',
                    name: data['attested_by'],
                    position: 'Attested by',
                    width: 130,
                  ),
                  PdfStyles.signatureBlock(
                    role: 'Center Head',
                    name: data['noted_by'],
                    position: 'Noted by',
                    width: 120,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ];
  }

  // ============ MONTHLY INVENTORY ============
  static List<pw.Page> _buildInventoryMonthly(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    final pages = <pw.Page>[];

    // First page with header and clothing/toiletries
    pages.add(pw.Page(
      pageFormat: PdfStyles.pageFormat,
      margin: PdfStyles.pageMargin,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfStyles.buildDswdHeader(logoBytes: logoBytes),
            PdfStyles.formTitle('INVENTORY OF BELONGINGS'),
            pw.Center(
              child: pw.Text(
                'FOR THE MONTH OF ${(data['month'] ?? 'JANUARY').toString().toUpperCase()} ${data['year'] ?? DateTime.now().year}',
                style: PdfStyles.headerStyle,
              ),
            ),
            pw.SizedBox(height: 12),

            PdfStyles.labelWithUnderline(
                'Name of client', data['client_name'] ?? residentName),
            pw.SizedBox(height: 16),

            // A. Clothing
            pw.Text('A. CLOTHING', style: PdfStyles.subHeaderStyle),
            pw.SizedBox(height: 4),
            _buildInventoryTable(data['clothing_items'] as List<dynamic>? ?? [],
                compact: true),

            pw.SizedBox(height: 12),

            // B. Toiletries
            pw.Text('B. TOILETRIES', style: PdfStyles.subHeaderStyle),
            pw.SizedBox(height: 4),
            _buildInventoryTable(
                data['toiletries_items'] as List<dynamic>? ?? [],
                compact: true),
          ],
        );
      },
    ));

    // Second page for linen/others and signatures
    pages.add(pw.Page(
      pageFormat: PdfStyles.pageFormat,
      margin: PdfStyles.pageMargin,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // C. Linen
            pw.Text('C. LINEN', style: PdfStyles.subHeaderStyle),
            pw.SizedBox(height: 4),
            _buildInventoryTable(data['linen_items'] as List<dynamic>? ?? [],
                compact: true),

            pw.SizedBox(height: 12),

            // D. Others
            pw.Text('D. OTHERS', style: PdfStyles.subHeaderStyle),
            pw.SizedBox(height: 4),
            _buildInventoryTable(data['others_items'] as List<dynamic>? ?? [],
                compact: true),

            pw.Spacer(),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Prepared By:', style: PdfStyles.normalStyle),
                    PdfStyles.signatureBlock(
                      role: 'HOUSEPARENT II',
                      name: data['prepared_by'],
                      width: 150,
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Submitted By:', style: PdfStyles.normalStyle),
                    PdfStyles.signatureBlock(
                      role: 'SUPERVISING HOUSEPARENT III',
                      name: data['submitted_by'],
                      width: 180,
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Noted By:', style: PdfStyles.normalStyle),
                PdfStyles.signatureBlock(
                  role: 'CENTER HEAD',
                  name: data['noted_by'],
                  width: 150,
                ),
              ],
            ),
          ],
        );
      },
    ));

    return pages;
  }

  // ============ PROGRESS NOTES ============
  static List<pw.Page> _buildProgressNotes(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    final entries = (data['progress_entries'] as List<dynamic>?) ?? [];

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
                  'Name of client', data['client_name'] ?? residentName),
              pw.SizedBox(height: 16),

              // Progress table
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfStyles.headerBgColor),
                    children: [
                      _tableCell('DATE', isHeader: true),
                      _tableCell('ACTIVITIES UNDERTAKEN', isHeader: true),
                      _tableCell('SUPERVISORY REMARKS', isHeader: true),
                    ],
                  ),
                  // Data rows
                  ...entries.map((entry) {
                    final e = entry as Map<String, dynamic>;
                    return pw.TableRow(
                      children: [
                        _tableCell(PdfStyles.formatDate(e['date'])),
                        _tableCell(e['activities'] ?? '', minHeight: 40),
                        _tableCell(e['remarks'] ?? '', minHeight: 40),
                      ],
                    );
                  }),
                  // Empty rows if needed
                  if (entries.length < 5)
                    ...List.generate(
                        5 - entries.length,
                        (_) => pw.TableRow(
                              children: [
                                _tableCell('', minHeight: 40),
                                _tableCell('', minHeight: 40),
                                _tableCell('', minHeight: 40),
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
                      pw.Text('Prepared By:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Houseparent I',
                        name: data['prepared_by'],
                        width: 180,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Noted By:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Center Head',
                        name: data['noted_by'],
                        width: 180,
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

  // ============ INCIDENT REPORT ============
  static List<pw.Page> _buildIncidentReport(
    Map<String, dynamic> data,
    String residentName,
    Uint8List? logoBytes,
  ) {
    final actions = (data['action_items'] as List<dynamic>?) ?? [];

    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle('INCIDENT REPORT'),

              // Incident details table
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FixedColumnWidth(20),
                  2: const pw.FlexColumnWidth(5),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _tableCell('TYPE OF INCIDENT', isHeader: true),
                      _tableCell(':', isHeader: true),
                      _tableCell(
                        data['type_of_incident'] == 'Other'
                            ? 'Other: ${data['other_incident_type'] ?? ''}'
                            : data['type_of_incident'] ?? 'Fall / Slip',
                        minHeight: 30,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('WHAT\n(Anong Nangyari)', isHeader: true),
                      _tableCell(':', isHeader: true),
                      _tableCell(data['what_happened'] ?? '', minHeight: 40),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('WHO\n(Sino ang Kasali)', isHeader: true),
                      _tableCell(':', isHeader: true),
                      _tableCell(data['who_involved'] ?? '', minHeight: 40),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell('WHEN\n(Kailan, Anong petsa, Anong oras)',
                          isHeader: true),
                      _tableCell(':', isHeader: true),
                      _tableCell(
                        '${PdfStyles.formatDate(data['when_date'])} ${data['when_time'] ?? ''}',
                        minHeight: 30,
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Action taken table
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfStyles.headerBgColor),
                    children: [
                      _tableCell('ACTION TAKEN', isHeader: true),
                      _tableCell('RECOMMENDATION', isHeader: true),
                      _tableCell('RESPONSIBLE PERSON', isHeader: true),
                    ],
                  ),
                  ...actions.map((action) {
                    final a = action as Map<String, dynamic>;
                    return pw.TableRow(
                      children: [
                        _tableCell(a['action'] ?? '', minHeight: 40),
                        _tableCell(a['recommendation'] ?? '', minHeight: 40),
                        _tableCell(a['responsible_person'] ?? '',
                            minHeight: 40),
                      ],
                    );
                  }),
                  if (actions.isEmpty)
                    pw.TableRow(
                      children: [
                        _tableCell('', minHeight: 50),
                        _tableCell('', minHeight: 50),
                        _tableCell('', minHeight: 50),
                      ],
                    ),
                ],
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Prepared by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'HP on Duty',
                        name: data['prepared_by'],
                        position: data['prepared_by_designation'],
                        signatureBytes: data['_prepared_by_signature_bytes'],
                        width: 150,
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 40),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Attested by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Supervising Houseparent',
                        name: data['attested_by'],
                        position: data['attested_by_designation'],
                        signatureBytes: data['_attested_by_signature_bytes'],
                        width: 180,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              pw.Text('Received by:', style: PdfStyles.normalStyle),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  PdfStyles.signatureBlock(
                    role: 'Social Services',
                    name: data['received_social'],
                    position: data['received_social_designation'],
                    signatureBytes: data['_received_social_signature_bytes'],
                    width: 140,
                  ),
                  PdfStyles.signatureBlock(
                    role: 'Psych. Services',
                    name: data['received_psych'],
                    position: data['received_psych_designation'],
                    signatureBytes: data['_received_psych_signature_bytes'],
                    width: 140,
                  ),
                  PdfStyles.signatureBlock(
                    role: 'Medical Services',
                    name: data['received_medical'],
                    position: data['received_medical_designation'],
                    signatureBytes: data['_received_medical_signature_bytes'],
                    width: 140,
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Noted by:', style: PdfStyles.normalStyle),
                  PdfStyles.signatureBlock(
                    role: 'Center Head',
                    name: data['noted_by'],
                    position: data['noted_by_designation'],
                    signatureBytes: data['_noted_by_signature_bytes'],
                    width: 150,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ];
  }

  // ============ OUT ON PASS ============
  static List<pw.Page> _buildOutOnPass(
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
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Republic of the Philippines',
                        style: PdfStyles.normalStyle),
                    pw.Text(
                      'Department of Social Welfare and Development',
                      style: PdfStyles.headerStyle,
                    ),
                    pw.Text('Field Office XI', style: PdfStyles.normalStyle),
                    pw.Text('HOME FOR THE AGED', style: PdfStyles.headerStyle),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // OUT ON PASS box
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 30, vertical: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 2),
                  ),
                  child: pw.Text(
                    'OUT ON PASS',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              // Date
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Date: ${PdfStyles.formatDate(data['pass_date'])}',
                  style: PdfStyles.normalStyle,
                ),
              ),
              pw.SizedBox(height: 12),

              // Client info
              pw.Row(
                children: [
                  pw.Text('Please allow: ', style: PdfStyles.normalStyle),
                  pw.Expanded(
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                      ),
                      child: pw.Text(
                        data['client_name'] ?? residentName,
                        style: PdfStyles.subHeaderStyle,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Text('years old: ', style: PdfStyles.normalStyle),
                  pw.Container(
                    width: 50,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                    ),
                    child: pw.Text(
                      data['client_age']?.toString() ?? '',
                      style: PdfStyles.normalStyle,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // Time out/in
              pw.Row(
                children: [
                  pw.Expanded(
                    child: PdfStyles.labelWithUnderline(
                        'Time out', data['time_out']),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: PdfStyles.labelWithUnderline(
                        'Time In', data['time_in']),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // Purpose
              PdfStyles.labelWithUnderline('Purpose', data['purpose']),
              pw.SizedBox(height: 8),

              // Escorted by
              pw.Row(
                children: [
                  pw.Expanded(
                    child: PdfStyles.labelWithUnderline(
                        'Escorted by', data['escorted_by']),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: PdfStyles.labelWithUnderline(
                        'Position', data['escort_position']),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              pw.Text('Note: to be monitored', style: PdfStyles.italicStyle),
              pw.SizedBox(height: 12),

              // Nature of outslip
              pw.Text('Nature of outslip:', style: PdfStyles.labelStyle),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  PdfStyles.checkbox(data['nature_personal'] ?? false,
                      label: 'Personal'),
                  pw.SizedBox(width: 30),
                  PdfStyles.checkbox(data['nature_medical'] ?? false,
                      label: 'Medical'),
                  pw.SizedBox(width: 30),
                  PdfStyles.checkbox(data['nature_official'] ?? false,
                      label: 'Official'),
                ],
              ),
              pw.SizedBox(height: 16),

              // Acknowledgments
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  PdfStyles.signatureBlock(
                    role: 'Supervising Houseparent III',
                    name: data['supervising_hp'],
                    width: 160,
                  ),
                  PdfStyles.signatureBlock(
                    role: 'Center Doctor',
                    name: data['center_doctor'],
                    width: 140,
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Notice
              pw.Text('Notice/Reminders:', style: PdfStyles.labelStyle),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfStyles.borderColor),
                ),
                child: pw.Text(
                  data['notices'] ??
                      'The Home for the Aged will not be held liable for any untoward incident affecting the client outside the center.',
                  style: PdfStyles.italicStyle,
                ),
              ),
              pw.SizedBox(height: 12),

              // Social Worker and Client signature
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  PdfStyles.signatureBlock(
                    role: 'Social Worker',
                    name: data['social_worker'],
                    width: 150,
                  ),
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 25),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(width: 0.5)),
                        ),
                      ),
                      pw.Text('Client Signature', style: PdfStyles.smallStyle),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Approval
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Approved:', style: PdfStyles.labelStyle),
                    PdfStyles.signatureBlock(
                      role: 'Center Head',
                      name: data['approved_by'],
                      width: 180,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  // Helper: Build inventory table
  static pw.Widget _buildInventoryTable(List<dynamic> items,
      {bool compact = false}) {
    final rows = items.map((item) {
      final i = item as Map<String, dynamic>;
      return [
        i['particulars']?.toString() ?? '',
        i['qty']?.toString() ?? '',
        i['unit']?.toString() ?? '',
        i['description']?.toString() ?? '',
        i['unit_cost']?.toString() ?? '',
        i['balance']?.toString() ?? '',
      ];
    }).toList();

    // Add empty rows if needed
    final minRows = compact ? 5 : 10;
    while (rows.length < minRows) {
      rows.add(['', '', '', '', '', '']);
    }

    return PdfStyles.simpleTable(
      headers: [
        'PARTICULARS',
        'QTY',
        'UNIT',
        'DESCRIPTION',
        'UNIT COST',
        'BALANCE AS OF'
      ],
      rows: rows,
      columnWidths: [3, 1, 1, 3, 2, 2],
    );
  }

  // Helper: Table cell (Still used by other forms)
  static pw.Widget _tableCell(String text,
      {bool isHeader = false, double? minHeight}) {
    return pw.Container(
      constraints: pw.BoxConstraints(minHeight: minHeight ?? 20),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: isHeader ? PdfStyles.labelStyle : PdfStyles.normalStyle,
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
}
