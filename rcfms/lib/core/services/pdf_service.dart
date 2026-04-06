import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../data/models/resident_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateResidentProfile(ResidentModel resident) async {
    final pdf = pw.Document();

    // Load fonts from assets for consistent look and offline availability
    final regularData =
        await rootBundle.load('assets/fonts/Outfit-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Outfit-Bold.ttf');

    final font = pw.Font.ttf(regularData);
    final fontBold = pw.Font.ttf(boldData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'RESIDENT PROFILE SUMMARY',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 20,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Entry Info
              _buildSectionHeader('ENTRY INFORMATION', fontBold),
              _buildRow(
                  'Type',
                  resident.status == 'admitted'
                      ? 'DIRECT ADMISSION'
                      : 'PRE-ADMISSION',
                  font),
              _buildRow('Application Date',
                  _formatDate(resident.applicationDate), font),
              pw.SizedBox(height: 10),

              // Personal Info
              _buildSectionHeader('PERSONAL INFORMATION', fontBold),
              _buildRow(
                  'Name',
                  '${resident.firstName} ${resident.middleName ?? ""} ${resident.lastName} ${resident.suffix ?? ""}'
                      .toUpperCase(),
                  font),
              _buildRow(
                  'Nickname', resident.nickname?.toUpperCase() ?? '-', font),
              _buildRow('Birthdate', _formatDate(resident.dateOfBirth), font),
              _buildRow('Gender', resident.gender.toUpperCase(), font),
              _buildRow('Place of Birth',
                  resident.placeOfBirth?.toUpperCase() ?? '-', font),
              pw.SizedBox(height: 10),

              // Address
              _buildSectionHeader('ADDRESS', fontBold),
              _buildRow('Home Address', _formatAddress(resident), font),
              pw.SizedBox(height: 10),

              // Referral
              _buildSectionHeader('REFERRAL', fontBold),
              _buildRow(
                  'Source', resident.referredBy?.toUpperCase() ?? '-', font),
              _buildRow('Referral Address',
                  resident.referringPartyAddress?.toUpperCase() ?? '-', font),
              pw.SizedBox(height: 10),

              // Case & Admission
              _buildSectionHeader('CASE & ADMISSION', fontBold),
              _buildRow('Category', resident.caseCategory?.toUpperCase() ?? '-',
                  font),
              _buildRow(
                  'Condition', resident.condition?.toUpperCase() ?? '-', font),
              _buildRow(
                  'Admission Date', _formatDate(resident.admissionDate), font),
              _buildRow(
                  'Ward/Bed',
                  '${resident.wardId ?? "-"} / ${resident.bedNumber ?? "-"}',
                  font),
              pw.SizedBox(height: 10),

              // Social
              _buildSectionHeader('SOCIAL & EDUCATION', fontBold),
              _buildRow('Civil Status',
                  resident.civilStatus?.toUpperCase() ?? '-', font),
              _buildRow(
                  'Religion', resident.religion?.toUpperCase() ?? '-', font),
              _buildRow('Education',
                  resident.educationalAttainment?.toUpperCase() ?? '-', font),
              pw.SizedBox(height: 10),

              // Family
              _buildSectionHeader('FAMILY & CONTACTS', fontBold),
              _buildRow('Nearest Relative',
                  resident.nearestRelativeName?.toUpperCase() ?? '-', font),
              _buildRow('Custodian',
                  resident.custodianName?.toUpperCase() ?? '-', font),
              _buildRow('Emergency Contact',
                  resident.emergencyContactName?.toUpperCase() ?? '-', font),

              pw.Spacer(),

              // Signature Area
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSignatureLine('Prepared By:', font),
                  _buildSignatureLine('Noted By:', font),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Generated on ${DateFormat('MMMM d, yyyy h:mm a').format(DateTime.now())}',
                  style: pw.TextStyle(
                      font: font, fontSize: 8, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Resident_Profile_${resident.lastName}_${resident.firstName}.pdf',
    );
  }

  static pw.Widget _buildSectionHeader(String title, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 5),
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 5),
      color: PdfColors.grey300,
      width: double.infinity,
      child: pw.Text(
        title,
        style: pw.TextStyle(
            font: font, fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text('$label:',
                style: pw.TextStyle(
                    font: font, fontSize: 9, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 9)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureLine(String label, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9)),
        pw.SizedBox(height: 20),
        pw.Container(
          width: 150,
          height: 1,
          color: PdfColors.black,
        ),
      ],
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('MMMM d, yyyy').format(date).toUpperCase();
  }

  static String _formatAddress(ResidentModel resident) {
    final parts = [
      resident.streetAddress,
      resident.barangay,
      resident.city,
      resident.province,
    ].where((e) => e != null && e.isNotEmpty).join(', ');
    return parts.isEmpty ? '-' : parts.toUpperCase();
  }
}
