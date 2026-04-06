import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Common PDF styles and helper widgets
class PdfStyles {
  PdfStyles._();

  // Page format - Letter size with proper margins for printing
  static const pageFormat = PdfPageFormat.letter;
  static const pageMargin = pw.EdgeInsets.all(40);

  // Colors
  static const primaryColor = PdfColor.fromInt(0xFF1565C0);
  static const textColor = PdfColor.fromInt(0xFF212121);
  static const borderColor = PdfColor.fromInt(0xFFBDBDBD);
  static const headerBgColor = PdfColor.fromInt(0xFFE3F2FD);
  static const contentBgColor = PdfColor.fromInt(0xFFFFFFFF);

  // Text Styles
  static pw.TextStyle get titleStyle => pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      );

  static pw.TextStyle get headerStyle => pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      );

  static pw.TextStyle get subHeaderStyle => pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
      );

  static pw.TextStyle get normalStyle => const pw.TextStyle(
        fontSize: 10,
      );

  static pw.TextStyle get smallStyle => const pw.TextStyle(
        fontSize: 9,
      );

  static pw.TextStyle get boldStyle => pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      );

  static pw.TextStyle get labelStyle => pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      );

  static pw.TextStyle get valueStyle => const pw.TextStyle(
        fontSize: 10,
      );

  static pw.TextStyle get italicStyle => pw.TextStyle(
        fontSize: 10,
        fontStyle: pw.FontStyle.italic,
      );

  /// DSWD Header with logo and text
  static pw.Widget buildDswdHeader(
      {Uint8List? logoBytes, bool compact = false}) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoBytes != null) ...[
              pw.Image(
                pw.MemoryImage(logoBytes),
                width: compact ? 40 : 50,
                height: compact ? 40 : 50,
              ),
              pw.SizedBox(width: 12),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Republic of the Philippines',
                  style: compact ? smallStyle : normalStyle,
                ),
                pw.Text(
                  'Department of Social Welfare and Development',
                  style: compact ? subHeaderStyle : headerStyle,
                ),
                pw.Text(
                  'Field Office XI',
                  style: compact ? smallStyle : normalStyle,
                ),
                pw.Text(
                  'HOME FOR THE AGED',
                  style: headerStyle,
                ),
                if (!compact)
                  pw.Text(
                    'Visayan Village, Tagum City, Davao del Norte',
                    style: smallStyle,
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: compact ? 8 : 16),
        pw.Divider(thickness: 1.5, color: primaryColor),
        pw.SizedBox(height: compact ? 8 : 12),
      ],
    );
  }

  /// Section header
  static pw.Widget sectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const pw.EdgeInsets.only(top: 12, bottom: 8),
      decoration: pw.BoxDecoration(
        color: headerBgColor,
        border: pw.Border.all(color: primaryColor, width: 0.5),
      ),
      child: pw.Text(title, style: subHeaderStyle),
    );
  }

  /// Form title (centered, bold)
  static pw.Widget formTitle(String title) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Text(
        title,
        style: titleStyle,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Label-Value pair (horizontal)
  static pw.Widget labelValue(String label, String? value,
      {int flex1 = 1, int flex2 = 2}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: flex1,
            child: pw.Text('$label:', style: labelStyle),
          ),
          pw.Expanded(
            flex: flex2,
            child: pw.Text(value ?? '', style: valueStyle),
          ),
        ],
      ),
    );
  }

  /// Label with underline for value
  static pw.Widget labelWithUnderline(String label, String? value,
      {double? width}) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: width != null ? pw.MainAxisSize.min : pw.MainAxisSize.max,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('$label: ', style: labelStyle),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
              ),
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(value ?? '', style: valueStyle),
            ),
          ),
        ],
      ),
    );
  }

  /// Multi-line text area with border
  static pw.Widget textArea(String? content, {double? minHeight}) {
    return pw.Container(
      width: double.infinity,
      constraints: pw.BoxConstraints(minHeight: minHeight ?? 60),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 0.5),
      ),
      child: pw.Text(content ?? '', style: normalStyle),
    );
  }

  /// Labeled text area
  static pw.Widget labeledTextArea(String label, String? content,
      {double? minHeight}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: labelStyle),
        pw.SizedBox(height: 4),
        textArea(content, minHeight: minHeight),
      ],
    );
  }

  /// Simple table with borders
  static pw.Widget simpleTable({
    required List<String> headers,
    required List<List<String>> rows,
    List<int>? columnWidths,
  }) {
    final flexValues = columnWidths ?? List.filled(headers.length, 1);

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: headerBgColor),
          children: headers.asMap().entries.map((entry) {
            return pw.Expanded(
              flex: flexValues[entry.key],
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  entry.value,
                  style: labelStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
            );
          }).toList(),
        ),
        // Data rows
        ...rows.map((row) => pw.TableRow(
              children: row.asMap().entries.map((entry) {
                return pw.Expanded(
                  flex: flexValues[entry.key],
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      entry.value,
                      style: normalStyle,
                    ),
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }

  /// Table with custom cell widgets
  static pw.Widget customTable({
    required List<String> headers,
    required List<List<pw.Widget>> rows,
    List<int>? columnWidths,
  }) {
    final flexValues = columnWidths ?? List.filled(headers.length, 1);

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: headerBgColor),
          children: headers.asMap().entries.map((entry) {
            return pw.Expanded(
              flex: flexValues[entry.key],
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  entry.value,
                  style: labelStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
            );
          }).toList(),
        ),
        // Data rows
        ...rows.map((row) => pw.TableRow(
              children: row.asMap().entries.map((entry) {
                return pw.Expanded(
                  flex: flexValues[entry.key],
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: entry.value,
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }

  /// Signature line
  static pw.Widget signatureLine(String label,
      {String? name, double width = 150}) {
    return pw.Container(
      width: width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(height: 30), // Space for signature
          if (name != null && name.isNotEmpty)
            pw.Text(name, style: subHeaderStyle),
          pw.Container(
            width: width - 20,
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(width: 0.5)),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(label, style: smallStyle, textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  /// Signature block with role
  static pw.Widget signatureBlock({
    required String role,
    Uint8List? signatureBytes,
    String? name,
    String? position,
    String? licenseNo,
    double width = 200,
  }) {
    return pw.Container(
      width: width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (signatureBytes != null && signatureBytes.isNotEmpty)
            pw.Image(
              pw.MemoryImage(signatureBytes),
              height: 35,
              fit: pw.BoxFit.contain,
            )
          else
            pw.SizedBox(height: 25),
          if (name != null && name.isNotEmpty) ...[
            pw.Text(name, style: subHeaderStyle),
            pw.SizedBox(height: 2),
          ],
          pw.Container(
            width: width - 20,
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(width: 0.5)),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(position ?? role, style: smallStyle),
          if (licenseNo != null && licenseNo.isNotEmpty)
            pw.Text('License No.: $licenseNo', style: smallStyle),
        ],
      ),
    );
  }

  /// Two signatures side by side
  static pw.Widget signatureRow(
    String label1,
    String? name1,
    String label2,
    String? name2,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        signatureLine(label1, name: name1),
        signatureLine(label2, name: name2),
      ],
    );
  }

  /// Checkbox (filled or empty)
  static pw.Widget checkbox(bool checked, {String? label}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.5),
          ),
          child: checked
              ? pw.Center(
                  child: pw.Text('✓', style: const pw.TextStyle(fontSize: 10)))
              : null,
        ),
        if (label != null) ...[
          pw.SizedBox(width: 4),
          pw.Text(label, style: normalStyle),
        ],
      ],
    );
  }

  /// Checkbox row
  static pw.Widget checkboxRow(List<MapEntry<String, bool>> items) {
    return pw.Row(
      children: items
          .map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(right: 20),
                child: checkbox(item.value, label: item.key),
              ))
          .toList(),
    );
  }

  /// Confidentiality notice
  static pw.Widget confidentialityNotice() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF8E1),
        border: pw.Border.all(
            color: const PdfColor.fromInt(0xFFFFB300), width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Text('⚠ ', style: const pw.TextStyle(fontSize: 12)),
          pw.Expanded(
            child: pw.Text(
              'Strictly Confidential / Not for Legal Use',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFFFF8F00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Footer with page number
  static pw.Widget pageFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: smallStyle,
      ),
    );
  }

  /// Format date string
  static String formatDate(dynamic date) {
    if (date == null) return '';
    if (date is DateTime) {
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
    final str = date.toString().trim();
    if (str.isEmpty) return '';
    try {
      final d = DateTime.parse(str);
      return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
    } catch (e) {
      return str;
    }
  }

  /// Format date with full month name
  static String formatDateFull(dynamic date) {
    if (date == null) return '';
    if (date is DateTime) {
      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    }
    final str = date.toString().trim();
    if (str.isEmpty) return '';
    try {
      final d = DateTime.parse(str);
      return '${_getMonthName(d.month)} ${d.day}, ${d.year}';
    } catch (e) {
      return str;
    }
  }

  static String _getMonthName(int month) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER'
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  static String formatDateDay(dynamic date) {
    if (date == null) return '';
    if (date is DateTime) {
      return date.day.toString();
    }
    final str = date.toString().trim();
    if (str.isEmpty) return '';
    try {
      return DateTime.parse(str).day.toString();
    } catch (e) {
      return '';
    }
  }

  static String formatDateMonth(dynamic date) {
    if (date == null) return '';
    if (date is DateTime) {
      return _getMonthName(date.month);
    }
    final str = date.toString().trim();
    if (str.isEmpty) return '';
    try {
      return _getMonthName(DateTime.parse(str).month);
    } catch (e) {
      return '';
    }
  }

  /// TextSpan with underline
  static pw.TextSpan spanUnderline(String text, {double? width}) {
    // Note: width is ignored for TextSpan as it is inline
    return pw.TextSpan(
      text: text,
      style: normalStyle.copyWith(decoration: pw.TextDecoration.underline),
    );
  }

  /// Labeled bullet list
  static pw.Widget bulletList(String label, String? content,
      {double? minHeight}) {
    final items =
        (content ?? '').split('\n').where((s) => s.trim().isNotEmpty).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: labelStyle),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          constraints: pw.BoxConstraints(minHeight: minHeight ?? 60),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor, width: 0.5),
          ),
          child: items.isEmpty
              ? pw.Text('', style: normalStyle)
              : pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: items.map((item) {
                    return pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ', style: normalStyle),
                        pw.Expanded(
                          child: pw.Text(item, style: normalStyle),
                        ),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
