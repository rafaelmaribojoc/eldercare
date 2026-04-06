import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../templates/form_templates.dart';
import 'pdf_styles.dart';

/// Nutrition Service PDF Templates
class NutritionServicePdf {
  NutritionServicePdf._();

  static List<pw.Page> buildPages({
    required FormTemplate template,
    required Map<String, dynamic> data,
    required String residentName,
    String? caseNumber,
    Uint8List? logoBytes,
  }) {
    switch (template.templateType) {
      case 'nt_screening':
        return _buildNutritionScreening(data, residentName, logoBytes);
      case 'nt_meal_plan':
        return _buildMealPlan(data, logoBytes);
      case 'nt_diet_diary':
        return _buildDietDiary(data, residentName, logoBytes);
      case 'nt_diet_orders':
        return _buildDietOrders(data, logoBytes);
      case 'nt_malnourished_list':
        return _buildMalnourishedList(data, logoBytes);
      case 'nt_ncp_mnt':
        return _buildNcpMnt(data, residentName, caseNumber, logoBytes);
      case 'nt_progress_notes':
        return _buildProgressNotes(data, residentName, logoBytes);
      case 'nt_status_summary':
        return _buildStatusSummary(data, logoBytes);
      default:
        return [_buildPlaceholder(template.name)];
    }
  }

  static pw.Page _buildPlaceholder(String formName) {
    return pw.Page(
      pageFormat: PdfStyles.pageFormat,
      build: (context) => pw.Center(
        child: pw.Text('PDF Template for "$formName" is under development.'),
      ),
    );
  }

  // Helper row builder
  static pw.TableRow _infoRow(
      String label1, String val1, String label2, String val2) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(label1,
              style: PdfStyles.smallStyle
                  .copyWith(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(val1, style: PdfStyles.smallStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(label2,
              style: PdfStyles.smallStyle
                  .copyWith(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(val2, style: PdfStyles.smallStyle),
        ),
      ],
    );
  }

  static pw.TableRow _singleRow(String label, String val) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(label,
              style: PdfStyles.smallStyle
                  .copyWith(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(val, style: PdfStyles.smallStyle),
        ),
      ],
    );
  }

  // 1. Nutrition Screening
  static List<pw.Page> _buildNutritionScreening(
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
              PdfStyles.formTitle('NUTRITION SCREENING FORM'),
              pw.SizedBox(height: 10),

              // Info Table
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                children: [
                  _infoRow('Name', data['client_name'] ?? residentName, 'Date',
                      PdfStyles.formatDate(data['date_screening'])),
                  _infoRow('Age', data['age']?.toString() ?? '', 'Sex',
                      data['sex'] ?? ''),
                ],
              ),
              pw.SizedBox(height: 16),

              PdfStyles.sectionHeader('ANTHROPOMETRIC DATA'),
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                children: [
                  _infoRow('Weight (kg)', data['weight']?.toString() ?? '',
                      'Height (cm)', data['height']?.toString() ?? ''),
                  _infoRow('BMI', data['bmi']?.toString() ?? '', 'Status',
                      data['nutritional_status'] ?? ''),
                ],
              ),
              pw.SizedBox(height: 16),

              PdfStyles.labeledTextArea(
                  'Remarks / Observations', data['remarks'],
                  minHeight: 100),

              pw.Spacer(),

              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Assessed by:', style: PdfStyles.normalStyle),
                      PdfStyles.signatureBlock(
                        role: 'Nutritionist/Dietitian',
                        name: data['user_name'],
                        position: data['user_title'],
                        width: 180,
                      )
                    ])
              ])
            ],
          );
        },
      ),
    ];
  }

  // 2. Meal Plan
  static List<pw.Page> _buildMealPlan(
    Map<String, dynamic> data,
    Uint8List? logoBytes,
  ) {
    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat.landscape,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle('MEAL PLAN'),
              pw.Text(
                  'Date / Week of: ${PdfStyles.formatDate(data['week_of'])}',
                  style: PdfStyles.normalStyle),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                children: [
                  pw.TableRow(
                      decoration: const pw.BoxDecoration(
                          color: PdfStyles.headerBgColor),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child:
                                pw.Text('MEAL', style: PdfStyles.headerStyle)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child:
                                pw.Text('MENU', style: PdfStyles.headerStyle)),
                      ]),
                  _singleRow('Breakfast', data['breakfast'] ?? ''),
                  _singleRow('AM Snack', data['am_snack'] ?? ''),
                  _singleRow('Lunch', data['lunch'] ?? ''),
                  _singleRow('PM Snack', data['pm_snack'] ?? ''),
                  _singleRow('Dinner', data['dinner'] ?? ''),
                ],
              ),
              pw.SizedBox(height: 16),
              PdfStyles.labeledTextArea(
                  'Therapeutic Needs / Modifications', data['modifications'],
                  minHeight: 60),
            ],
          );
        },
      )
    ];
  }

  // 3. NCP Bi-Annual
  static List<pw.Page> _buildNcpBiAnnual(
    Map<String, dynamic> data,
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
              PdfStyles.formTitle('NUTRITION CARE PLAN (BI-ANNUAL REPORT)'),
              pw.Text('Period: ${data['period']} ${data['year']}',
                  style: PdfStyles.subHeaderStyle),
              pw.SizedBox(height: 16),
              PdfStyles.labeledTextArea(
                  'Executive Summary', data['executive_summary'],
                  minHeight: 80),
              pw.SizedBox(height: 10),
              PdfStyles.labeledTextArea(
                  'Developments / Accomplishments', data['accomplishments'],
                  minHeight: 80),
              pw.SizedBox(height: 10),
              PdfStyles.labeledTextArea('Issues / Concerns', data['issues'],
                  minHeight: 80),
              pw.SizedBox(height: 10),
              PdfStyles.labeledTextArea(
                  'Recommendations', data['recommendations'],
                  minHeight: 80),
            ],
          );
        },
      )
    ];
  }

  // 4. Diet Diary
  static List<pw.Page> _buildDietDiary(
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
              PdfStyles.formTitle('DIET DIARY'),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Name: ${data['client_name'] ?? residentName}',
                        style: PdfStyles.normalStyle),
                    pw.Text('Date: ${PdfStyles.formatDate(data['date'])}',
                        style: PdfStyles.normalStyle),
                  ]),
              pw.SizedBox(height: 16),
              pw.Table(
                  border: pw.TableBorder.all(
                      color: PdfStyles.borderColor, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                        decoration: const pw.BoxDecoration(
                            color: PdfStyles.headerBgColor),
                        children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('Time',
                                  style: PdfStyles.headerStyle)),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('Food Items',
                                  style: PdfStyles.headerStyle)),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('Amount',
                                  style: PdfStyles.headerStyle)),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('Comments',
                                  style: PdfStyles.headerStyle)),
                        ]),
                    pw.TableRow(children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(data['time'] ?? '',
                              style: PdfStyles.smallStyle)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(data['food_items'] ?? '',
                              style: PdfStyles.smallStyle)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(data['amount'] ?? '',
                              style: PdfStyles.smallStyle)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(data['comments'] ?? '',
                              style: PdfStyles.smallStyle)),
                    ])
                  ])
            ],
          );
        },
      )
    ];
  }

  static List<pw.Page> _buildDietOrders(
    Map<String, dynamic> data,
    Uint8List? logoBytes,
  ) {
    // Process diet census data from the form
    final List<dynamic> dietCensus = data['diet_census'] ?? [];

    return [
      pw.Page(
        pageFormat: PdfStyles.pageFormat,
        margin: PdfStyles.pageMargin,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfStyles.buildDswdHeader(logoBytes: logoBytes),
              PdfStyles.formTitle('LIST OF DIET ORDERS'),
              pw.Text('As of: ${PdfStyles.formatDate(data['date'])}',
                  style: PdfStyles.normalStyle),
              pw.SizedBox(height: 16),

              // Table Header
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfStyles.borderColor, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5), // Diet Order
                  1: const pw.FlexColumnWidth(3), // Names
                  2: const pw.FlexColumnWidth(2.5), // Remarks
                  3: const pw.FlexColumnWidth(1), // Total
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfStyles.headerBgColor),
                    children: [
                      _tableHeaderPadding(pw.Text('DIET ORDER',
                          style: PdfStyles.headerStyle,
                          textAlign: pw.TextAlign.center)),
                      _tableHeaderPadding(pw.Text('NAME OF CLIENTS',
                          style: PdfStyles.headerStyle,
                          textAlign: pw.TextAlign.center)),
                      _tableHeaderPadding(pw.Text('REMARKS',
                          style: PdfStyles.headerStyle,
                          textAlign: pw.TextAlign.center)),
                      _tableHeaderPadding(pw.Text('TOTAL',
                          style: PdfStyles.headerStyle,
                          textAlign: pw.TextAlign.center)),
                    ],
                  ),

                  // Data Rows
                  ...dietCensus.map((item) {
                    final map = item as Map<String, dynamic>;
                    return pw.TableRow(
                      children: [
                        _tableCellPadding(pw.Text(map['diet_order'] ?? '',
                            style: PdfStyles.smallStyle)),
                        _tableCellPadding(pw.Text(map['client_names'] ?? '',
                            style: PdfStyles.smallStyle)),
                        _tableCellPadding(pw.Text(map['remarks'] ?? '',
                            style: PdfStyles.smallStyle)),
                        _tableCellPadding(pw.Text(
                            map['total']?.toString() ?? '',
                            style: PdfStyles.smallStyle,
                            textAlign: pw.TextAlign.center)),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 32),

              // Signatories
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Prepared by:', style: PdfStyles.normalStyle),
                      pw.SizedBox(height: 8),
                      PdfStyles.signatureBlock(
                        role: 'Nutritionist / RND',
                        name: data['prepared_by'] ?? data['user_name'],
                        position: data['prepared_by_designation'] ??
                            data['user_title'] ??
                            'Nutritionist / RND',
                        width: 180,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Noted by:', style: PdfStyles.normalStyle),
                      pw.SizedBox(height: 8),
                      PdfStyles.signatureBlock(
                        role: 'Center Head',
                        name: data['noted_by'] ?? 'CANDELARIA C. TINGSON, RSW',
                        position: data['noted_by_designation'] ??
                            'Center Head / SWO IV',
                        width: 180,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      )
    ];
  }

  static pw.Widget _tableHeaderPadding(pw.Widget child) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: child,
    );
  }

  static pw.Widget _tableCellPadding(pw.Widget child) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: child,
    );
  }

  // 6. Malnourished List
  static List<pw.Page> _buildMalnourishedList(
    Map<String, dynamic> data,
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
                  PdfStyles.formTitle('LIST OF MALNOURISHED CLIENTS'),
                  pw.Text('As of: ${PdfStyles.formatDate(data['date'])}',
                      style: PdfStyles.normalStyle),
                  pw.SizedBox(height: 16),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfStyles.borderColor)),
                    child: pw.Text(data['content'] ?? '',
                        style: PdfStyles.normalStyle),
                  )
                ]);
          })
    ];
  }

  // 7. NCP MNT
  static List<pw.Page> _buildNcpMnt(
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
                  PdfStyles.formTitle('NUTRITION CARE PLAN (MNT)'),
                  pw.Table(
                      border: pw.TableBorder.all(
                          color: PdfStyles.borderColor, width: 0.5),
                      children: [
                        _infoRow('Name', data['client_name'] ?? residentName,
                            'Case No', data['case_no'] ?? caseNumber ?? ''),
                      ]),
                  pw.SizedBox(height: 16),
                  PdfStyles.labeledTextArea('Assessment', data['assessment'],
                      minHeight: 80),
                  pw.SizedBox(height: 8),
                  PdfStyles.labeledTextArea('Diagnosis', data['diagnosis'],
                      minHeight: 80),
                  pw.SizedBox(height: 8),
                  PdfStyles.labeledTextArea(
                      'Intervention', data['intervention'],
                      minHeight: 80),
                  pw.SizedBox(height: 8),
                  PdfStyles.labeledTextArea(
                      'Monitoring & Evaluation', data['monitoring'],
                      minHeight: 80),
                ]);
          })
    ];
  }

  // 8. Progress Notes
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
                  PdfStyles.formTitle('NUTRITION PROGRESS NOTES'),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Name: ${data['client_name'] ?? residentName}',
                            style: PdfStyles.normalStyle),
                        pw.Text('Date: ${PdfStyles.formatDate(data['date'])}',
                            style: PdfStyles.normalStyle),
                      ]),
                  pw.SizedBox(height: 16),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfStyles.borderColor)),
                    child: pw.Text(data['notes'] ?? '',
                        style: PdfStyles.normalStyle),
                  ),
                  pw.Spacer(),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text('Prepared by:',
                                  style: PdfStyles.normalStyle),
                              PdfStyles.signatureBlock(
                                role: 'Nutritionist/Dietitian',
                                name: data['user_name'],
                                position: data['user_title'],
                                width: 180,
                              )
                            ])
                      ])
                ]);
          })
    ];
  }

  // 9. Status Summary
  static List<pw.Page> _buildStatusSummary(
    Map<String, dynamic> data,
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
                  PdfStyles.formTitle('SUMMARY OF CLIENT NUTRITION STATUS'),
                  pw.Text('Period: ${data['quarter']} Quarter ${data['year']}',
                      style: PdfStyles.subHeaderStyle),
                  pw.SizedBox(height: 16),
                  pw.Table(
                      border: pw.TableBorder.all(
                          color: PdfStyles.borderColor, width: 0.5),
                      children: [
                        _singleRow('Total Clients',
                            data['total_clients']?.toString() ?? ''),
                        _singleRow(
                            'Normal', data['total_normal']?.toString() ?? ''),
                        _singleRow('Underweight',
                            data['total_underweight']?.toString() ?? ''),
                        _singleRow('Overweight/Obese',
                            data['total_overweight']?.toString() ?? ''),
                      ]),
                  pw.SizedBox(height: 16),
                  PdfStyles.labeledTextArea(
                      'Analysis / Interpretation', data['analysis'],
                      minHeight: 150),
                ]);
          })
    ];
  }
}
