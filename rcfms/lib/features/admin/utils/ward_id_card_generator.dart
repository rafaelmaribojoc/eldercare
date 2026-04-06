import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/ward_model.dart';
import 'package:printing/printing.dart';

class WardIdCardGenerator {
  static bool _isInitialized = false;
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static pw.Font? _mediumFont;

  /// CR80 PVC Card Dimensions: 3.375" x 2.125" (landscape)
  /// In points (72 points per inch):
  /// Width = 3.375 * 72 = 243
  /// Height = 2.125 * 72 = 153
  static const PdfPageFormat cr80Format = PdfPageFormat(
    243.0,
    153.0,
    marginAll: 8.0,
  );

  static Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      final assets = await Future.wait([
        rootBundle.load('assets/fonts/Outfit-Regular.ttf').catchError((_) => ByteData(0)),
        rootBundle.load('assets/fonts/Outfit-Bold.ttf').catchError((_) => ByteData(0)),
        rootBundle.load('assets/fonts/Outfit-Medium.ttf').catchError((_) => ByteData(0)),
      ]);

      if (assets[0].lengthInBytes > 0) _regularFont = pw.Font.ttf(assets[0]);
      if (assets[1].lengthInBytes > 0) _boldFont = pw.Font.ttf(assets[1]);
      if (assets[2].lengthInBytes > 0) _mediumFont = pw.Font.ttf(assets[2]);

      _isInitialized = true;
    } catch (e) {
      print('Warning: Failed to load fonts/logos for Ward ID Card: $e');
    }
    
    // Fallbacks
    _regularFont ??= pw.Font.helvetica();
    _boldFont ??= pw.Font.helveticaBold();
    _mediumFont ??= pw.Font.helveticaOblique();
  }

  /// Generates the PDF document for the Ward ID Card
  static Future<Uint8List> generate(WardModel ward, PdfPageFormat format) async {
    await _initialize();

    final pdf = pw.Document(
      title: 'Ward ID - ${ward.name}',
      creator: 'RCFMS',
    );

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('FRONT', style: pw.TextStyle(font: _mediumFont, fontSize: 8, color: PdfColors.grey600)),
                pw.SizedBox(height: 4),
                pw.SizedBox(
                  width: cr80Format.width,
                  height: cr80Format.height,
                  child: _buildFrontPage(ward),
                ),
                pw.SizedBox(height: 16),
                pw.SizedBox(
                  width: cr80Format.width + 40,
                  child: pw.Divider(color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
                ),
                pw.SizedBox(height: 12),
                pw.Text('BACK (FOLD OR CUT ALONG DOTTED LINE)', style: pw.TextStyle(font: _mediumFont, fontSize: 8, color: PdfColors.grey600)),
                pw.SizedBox(height: 4),
                pw.SizedBox(
                  width: cr80Format.width,
                  height: cr80Format.height,
                  child: _buildBackPage(),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // Deep blue color matching the UI card gradient
  static const _frontColor = PdfColor.fromInt(0xFF0D47A1);
  // Dark grey color matching the UI back card gradient
  static const _backColor = PdfColor.fromInt(0xFF37474F);

  static pw.Widget _buildFrontPage(WardModel ward) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        color: _frontColor,
      ),
      padding: const pw.EdgeInsets.all(14),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Left side: Branding & Info
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Header row — icon + RCFMS text
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 22,
                      height: 22,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                      child: pw.Center(
                        child: pw.Text('+', style: pw.TextStyle(
                          font: _boldFont,
                          fontSize: 14,
                          color: _frontColor,
                        )),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RCFMS',
                          style: pw.TextStyle(
                            font: _boldFont,
                            fontSize: 11,
                            color: PdfColors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.Text(
                          'WARD IDENTIFICATION',
                          style: pw.TextStyle(
                            font: _regularFont,
                            fontSize: 5,
                            color: const PdfColor.fromInt(0xFF7E9ACC),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Spacer(),
                // Ward Name
                pw.Text(
                  ward.name.toUpperCase(),
                  style: pw.TextStyle(
                    font: _boldFont,
                    fontSize: 16,
                    color: PdfColors.white,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'CAPACITY: ${ward.capacity}',
                  style: pw.TextStyle(
                    font: _regularFont,
                    fontSize: 8,
                    color: const PdfColor.fromInt(0xFF6D9BD4),
                    letterSpacing: 0.5,
                  ),
                ),
                pw.Spacer(),
                // NFC Badge — use solid blended colors since PDF doesn't support alpha well
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    // Solid lighter blue simulating white@15% on top of the blue background
                    color: const PdfColor.fromInt(0xFF2962FF),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                    border: pw.Border.all(
                      // Solid light blue simulating white@30% border
                      color: const PdfColor.fromInt(0xFF5C8AFF),
                      width: 0.8,
                    ),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        '\u{25CF} ))',
                        style: pw.TextStyle(font: _boldFont, fontSize: 8, color: PdfColors.white),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        'NFC ENABLED',
                        style: pw.TextStyle(
                          font: _boldFont,
                          fontSize: 7,
                          color: PdfColors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(width: 10),

          // Right side: QR Code
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'rcfms:ward:${ward.id}',
                  width: 65,
                  height: 65,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'SCAN ME',
                style: pw.TextStyle(
                  font: _boldFont,
                  fontSize: 6,
                  color: const PdfColor.fromInt(0xFF6889B5),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBackPage() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        color: _backColor,
      ),
      padding: const pw.EdgeInsets.all(14),
      child: pw.Row(
        children: [
          // Left — Instructions
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'STAFF INSTRUCTIONS',
                  style: pw.TextStyle(
                    font: _boldFont,
                    fontSize: 9,
                    color: PdfColors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 8),
                _instructionStep('1', 'Open the RCFMS mobile app.'),
                pw.SizedBox(height: 4),
                _instructionStep('2', 'Select NFC Scan or Scan QR.'),
                pw.SizedBox(height: 4),
                _instructionStep('3', 'Hold phone flat against the card\nor scan the front QR code.'),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          // Right — NFC Tag Placement Area
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(
                color: const PdfColor.fromInt(0xFF8DA4B5),
                width: 1.5,
              ),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    '((•))',
                    style: pw.TextStyle(font: _boldFont, fontSize: 10, color: const PdfColor.fromInt(0xFF8DA4B5)),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'PLACE NFC\nTAG HERE',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: _boldFont,
                      fontSize: 5,
                      color: const PdfColor.fromInt(0xFF6889B5),
                      letterSpacing: 0.3,
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

  static pw.Widget _instructionStep(String number, String text) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 14,
          height: 14,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: const PdfColor.fromInt(0xFF5B7183),
          ),
          child: pw.Center(
            child: pw.Text(
              number,
              style: pw.TextStyle(font: _boldFont, fontSize: 7, color: PdfColors.white),
            ),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text(
            text,
            style: pw.TextStyle(
              font: _regularFont,
              fontSize: 7,
              color: const PdfColor.fromInt(0xFFCCD6DE),
              lineSpacing: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  /// Helper to trigger printing directly
  static Future<void> printCard(WardModel ward) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => generate(ward, format),
      name: 'Ward_ID_${ward.name.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Helper to trigger explicit save/download dialog
  static Future<void> downloadCard(WardModel ward) async {
    // Default to a standard A4 page for downloads
    final pdfBytes = await generate(ward, PdfPageFormat.a4);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Ward_ID_${ward.name.replaceAll(' ', '_')}.pdf',
    );
  }
}
