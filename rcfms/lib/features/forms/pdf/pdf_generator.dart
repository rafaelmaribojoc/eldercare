import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

import '../templates/form_templates.dart';
import 'social_service_pdf.dart';
import 'homelife_service_pdf.dart';
import 'psychological_service_pdf.dart';
import 'medical_service_pdf.dart';
import 'nutrition_service_pdf.dart';
import '../../../core/utils/backend_config.dart';

/// Main PDF Generator service
class PdfGenerator {
  PdfGenerator._();

  static bool _isInitialized = false;
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static pw.Font? _italicFont;
  static Uint8List? _logoBytes;

  /// Initialize fonts and assets
  static Future<void> initialize() async {
    // If already initialized, skip
    if (_isInitialized) return;

    try {
      // Load all assets in parallel for faster startup
      final assets = await Future.wait([
        rootBundle.load('assets/fonts/Outfit-Regular.ttf'),
        rootBundle.load('assets/fonts/Outfit-Bold.ttf'),
        rootBundle.load('assets/fonts/Outfit-Medium.ttf'),
        rootBundle.load('assets/images/dswd_logo.png').catchError(
            (_) => ByteData(0)), // Handle missing logo gracefully in parallel
      ]);

      _regularFont = pw.Font.ttf(assets[0]);
      _boldFont = pw.Font.ttf(assets[1]);
      _italicFont = pw.Font.ttf(assets[2]);

      final logoData = assets[3];
      if (logoData.lengthInBytes > 0) {
        _logoBytes = logoData.buffer.asUint8List();
      }

      _isInitialized = true;
    } catch (e) {
      // Fallback to default fonts only if assets fail
      _regularFont ??= pw.Font.times();
      _boldFont ??= pw.Font.timesBold();
      _italicFont ??= pw.Font.timesItalic();
      // We don't set _isInitialized to true here to allow retrying if it's a transient failure
    }
  }

  /// Generate PDF for a form submission
  static Future<Uint8List> generatePdf({
    required FormTemplate template,
    required Map<String, dynamic> data,
    required String residentName,
    String? caseNumber,
    String outputFormat = 'pdf',
  }) async {
    await initialize();

    // CHECK FOR SERVER-SIDE TEMPLATES
    // List of templates that are now handled by the backend (Word Templates)
    final serverSideTemplates = [
      'pre_admission_checklist',
      'requirements_checklist',
      'general_intake_sheet',
      'admission_case_conference',
      'case_conference',
      'clients_contract',
      'admission_slip',
      'progress_notes',
      'running_notes',
      'intervention_plan',
      'social_case_study',
      'termination_report',
      'closing_summary',
      'quarterly_narrative',
      'discharge_slip',
      'discharge_conference',
      'pre_discharge_conference',
      'pre_donation_conference',
      'pre_termination_plan',
      'after_care_plan',
      'case_transfer_summary',
      'pre_admission_conference',
      'emergency_conference',
      'kasunduan',
      'updated_social_case_study',
      'group_sessions',
      'inter_service_referral',
      'individual_sessions',
      'initial_assessment',
      'psychometrician_report',
      'inventory_admission',
      'inventory_discharge',
      'inventory_monthly',
      'incident_report',
      'out_on_pass',
      'client_photo',
      'progress_notes',
      // Nutrition Service Forms
      'nt_screening',
      'nt_meal_plan',
      'nt_diet_diary',
      'nt_diet_orders',
      'nt_malnourished_list',
      'nt_ncp_mnt',
      'nt_status_summary',
      'nt_progress_notes',
      'nt_bmi_summary',
    ];

    if (serverSideTemplates.contains(template.templateType)) {
      try {
        final serviceUnitMap = {
          ServiceUnit.socialService: 'Social Service',
          ServiceUnit.medicalService: 'Medical Service',
          ServiceUnit.homeLifeService: 'Home Life Service',
          ServiceUnit.psychologicalService: 'Psychological Service',
          ServiceUnit.nutritionService: 'Nutrition and Dietetics Services',
        };

        // Determine specific template name (especially for Case Conferences)
        String templateName = template.templateType;
        if (template.templateType == 'case_conference' &&
            data['conference_type'] != null) {
          final type = data['conference_type'].toString().toLowerCase();
          if (type.contains('emergency')) {
            templateName = 'emergency_conference';
          } else if (type.contains('pre-discharge') ||
              type.contains('predischarge')) {
            templateName = 'pre_discharge_conference';
          } else if (type.contains('discharge')) {
            templateName = 'discharge_conference';
          } else if (type.contains('pre-admission') ||
              type.contains('preadmission')) {
            templateName = 'pre_admission_conference';
          } else if (type.contains('pre-donation') ||
              type.contains('predonation')) {
            templateName = 'pre_donation_conference';
          } else if (type.contains('admission')) {
            templateName = 'admission_case_conference';
          }

          // Default remains 'case_conference' (Regular)
        }

        // --- PSYCHOLOGICAL SERVICE MAPPINGS ---
        if (template.serviceUnit == ServiceUnit.psychologicalService) {
          if (template.templateType == 'progress_notes') {
            templateName = 'Psych Service Progress Notes';
          } else if (template.templateType ==
              'initial_psychological_assessment') {
            templateName = 'Initial Psychological Assessment';
          } else if (template.templateType == 'psychometrician_report') {
            templateName = 'Psychometricians Report';
          } else if (template.templateType == 'inter_service_referral') {
            templateName = 'Inter-Service Referral (1)';
          } else if (template.templateType == 'group_sessions') {
            templateName = 'Psych Service Group Session I Activity';
          } else if (template.templateType == 'individual_sessions') {
            templateName = 'Individual Sessions Report Blank Template';
          } else if (template.templateType == 'initial_assessment') {
            // Added
            templateName = 'Initial Psychological Assessment'; // Added
          }
        }

        // --- HOME LIFE SERVICE MAPPINGS ---
        if (template.serviceUnit == ServiceUnit.homeLifeService) {
          if (template.templateType == 'progress_notes') {
            templateName = 'progress_notes';
          } else if (template.templateType == 'incident_report') {
            templateName = 'incident_report';
          } else if (template.templateType == 'inventory_admission') {
            templateName = 'inventory_admission';
          } else if (template.templateType == 'inventory_discharge') {
            templateName = 'inventory_discharge';
          } else if (template.templateType == 'inventory_monthly') {
            templateName = 'inventory_monthly';
          }
        }

        // --- NUTRITION SERVICE MAPPINGS ---
        if (template.serviceUnit == ServiceUnit.nutritionService) {
          if (template.templateType == 'nt_screening') {
            templateName = 'DSWD 11 Nutrition Screening Form';
          } else if (template.templateType == 'nt_meal_plan') {
            templateName = 'DSWD HA_Meal Plan';
          } else if (template.templateType == 'nt_diet_diary') {
            templateName = 'Diet Diary_DSWD 11 HA';
          } else if (template.templateType == 'nt_diet_orders') {
            templateName = 'List of Diet Orders of Clients_Form';
          } else if (template.templateType == 'nt_malnourished_list') {
            templateName = 'List of Malnourished Clients_Form';
          } else if (template.templateType == 'nt_ncp_mnt') {
            templateName = 'MNT Form_Nutrition Care Plan';
          } else if (template.templateType == 'nt_status_summary') {
            templateName = 'Summary of Client Nutrition Status Form';
          } else if (template.templateType == 'nt_progress_notes') {
            templateName = 'Nutrition Progress Notes';
          } else if (template.templateType == 'nt_bmi_summary') {
            templateName = 'Summary of Client Nutrition Status Form';
          }

          // Debug format
          print('Resolved Nutrition template to: $templateName');
        }

        // --- DATA TRANSFORMATION FOR WORD TEMPLATES ---
        Map<String, dynamic> processedData = Map<String, dynamic>.from(data);

        // Default approved_by if not present (since field is hidden)
        if ((template.templateType == 'out_on_pass' ||
                template.templateType == 'homelife_out_on_pass') &&
            (processedData['approved_by'] == null ||
                processedData['approved_by'].toString().isEmpty)) {
          processedData['approved_by'] = 'CANDELARIA C. TINGSON, RSW';
          processedData['approved_by_designation'] = 'SWO IV / CENTER HEAD';
        }

        // Default noted_by for details (since field is hidden)
        if ((template.templateType == 'incident_report' ||
                template.templateType == 'inventory_admission' ||
                template.templateType == 'inventory_discharge') &&
            (processedData['noted_by'] == null ||
                processedData['noted_by'].toString().isEmpty)) {
          processedData['noted_by'] = 'CANDELARIA C. TINGSON, RSW';
          processedData['noted_by_designation'] = 'SWO IV / CENTER HEAD';
        }

        // Helper to formatting dates
        String formatDate(String? dateStr) {
          if (dateStr == null || dateStr.isEmpty) return '';
          try {
            // Handle ISO string or simple YYYY-MM-DD
            final date = DateTime.tryParse(dateStr);
            if (date == null) return dateStr;

            return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
          } catch (_) {
            return dateStr;
          }
        }

        if (template.templateType == 'admission_slip' ||
            template.templateType == 'ss_admission_slip') {
          // Concatenate Clearance into Medical Findings for the Word Template
          final findings = processedData['medical_findings'] ?? '';
          final clearance = processedData['clearance'] ?? '';
          if (clearance.isNotEmpty) {
            processedData['medical_findings'] =
                "$findings\n\nClearance:\n$clearance";
          }
        }

        // Helper to formatting dates (Long Format: JANUARY 01, 2026)
        String formatDateLong(String? dateStr) {
          if (dateStr == null || dateStr.isEmpty) return '';
          try {
            final date = DateTime.tryParse(dateStr);
            if (date == null) return dateStr;

            final months = [
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
            return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
          } catch (_) {
            return dateStr;
          }
        }

        if (template.templateType == 'nt_progress_notes') {
          if (processedData.containsKey('notes_list') &&
              processedData['notes_list'] is List) {
            final list = List<Map<String, dynamic>>.from(
                (processedData['notes_list'] as List)
                    .map((e) => Map<String, dynamic>.from(e)));
            for (var item in list) {
              item['date'] = formatDate(item['date']);
            }
            processedData['notes_list'] = list;
          }
        }

        // Helper to format time (HH:mm -> h:mm a)
        String formatTime(String? timeStr) {
          if (timeStr == null || timeStr.isEmpty) return '';
          try {
            final parts = timeStr.split(':');
            if (parts.length < 2) return timeStr;
            final hour = int.parse(parts[0]);
            final minute = parts[1];
            final period = hour >= 12 ? 'PM' : 'AM';
            final h = hour > 12
                ? hour - 12
                : hour == 0
                    ? 12
                    : hour;
            return '$h:$minute $period';
          } catch (_) {
            return timeStr;
          }
        }

        // Helper to format items
        List<Map<String, dynamic>> formatItems(List<dynamic>? items) {
          if (items == null) return [];
          return items.map((i) {
            final item = Map<String, dynamic>.from(i as Map);
            // Format inventory fields
            final unit = item['unit']?.toString() ?? '';
            if (unit.isNotEmpty && !unit.toLowerCase().contains('pc')) {
              if (unit.trim() == '1') {
                item['unit'] = '$unit pc';
              } else {
                item['unit'] = '$unit pcs';
              }
            }
            final costRaw = item['unit_cost']?.toString() ?? '0';
            final cost = double.tryParse(costRaw) ?? 0.0;
            if (cost > 0) {
              item['unit_cost'] = '₱ ${cost.toStringAsFixed(2)}';
            } else {
              item['unit_cost'] = '0.00';
            }

            final balanceRaw = item['balance']?.toString() ?? '0';
            final balance = double.tryParse(balanceRaw) ?? 0.0;
            if (balance > 0) {
              item['balance'] = '₱ ${balance.toStringAsFixed(2)}';
            } else {
              item['balance'] = '0.00';
            }
            return item;
          }).toList();
        }

        // Apply formatting based on template type
        if (template.serviceUnit == ServiceUnit.homeLifeService) {
          // Root level dates
          if (processedData['date'] != null) {
            processedData['date'] =
                formatDateLong(processedData['date'].toString());
          }
          if (processedData['inventory_date'] != null) {
            processedData['inventory_date'] =
                formatDateLong(processedData['inventory_date'].toString());
          }
          if (processedData['when_date'] != null) {
            processedData['when_date'] =
                formatDateLong(processedData['when_date'].toString());
          }
          if (processedData['pass_date'] != null) {
            processedData['pass_date'] =
                formatDateLong(processedData['pass_date'].toString());
          }

          if (template.templateType == 'out_on_pass' ||
              template.templateType == 'homelife_out_on_pass') {
            // Convert boolean nature fields to checkmarks for Word template
            final natureFields = [
              'nature_personal',
              'nature_medical',
              'nature_official'
            ];
            for (final field in natureFields) {
              final val = processedData[field];
              if (val == true ||
                  val.toString().toLowerCase() == 'true' ||
                  val == 1) {
                processedData[field] = '\u2611'; // Box with check
              } else {
                processedData[field] = '\u2610'; // Empty box
              }
            }

            // Format times
            if (processedData['time_out'] != null) {
              processedData['time_out'] =
                  formatTime(processedData['time_out'].toString());
            }
            if (processedData['time_in'] != null) {
              processedData['time_in'] =
                  formatTime(processedData['time_in'].toString());
            }
          }
        }

        // --- NUTRITION SERVICE MAPPINGS ---
        if (template.serviceUnit == ServiceUnit.nutritionService) {
          // Format specific dates
          if (processedData['date_screening'] != null) {
            processedData['date_screening'] =
                formatDateLong(processedData['date_screening'].toString());
          }
          if (processedData['week_of'] != null) {
            processedData['week_of'] =
                formatDateLong(processedData['week_of'].toString());
          }
          // Generic date is handled later, but we ensure it's long format if present here
          if (processedData['date'] != null) {
            // If not progress notes (which uses short date), force long date
            if (template.templateType != 'nt_progress_notes') {
              processedData['date'] =
                  formatDateLong(processedData['date'].toString());
            }
          }

          // checkboxes for nutritional status
          final status = (processedData['nutritional_status'] ?? '')
              .toString()
              .toLowerCase();
          processedData['chk_normal'] = status == 'normal' ? '☑' : '☐';
          processedData['chk_underweight'] =
              status == 'underweight' ? '☑' : '☐';
          processedData['chk_overweight'] = status == 'overweight' ? '☑' : '☐';
          processedData['chk_obese'] = status == 'obese' ? '☑' : '☐';
          processedData['chk_severely_wasted'] =
              status.contains('severely') ? '☑' : '☐';

          // checkboxes for semi-annual period
          final period =
              (processedData['period'] ?? '').toString().toLowerCase();
          processedData['chk_1st_sem'] = period.contains('1st') ? '☑' : '☐';
          processedData['chk_2nd_sem'] = period.contains('2nd') ? '☑' : '☐';

          // checkboxes for quarter
          final quarter =
              (processedData['quarter'] ?? '').toString().toLowerCase();
          processedData['chk_1st_qtr'] = quarter.contains('1st') ? '☑' : '☐';
          processedData['chk_2nd_qtr'] = quarter.contains('2nd') ? '☑' : '☐';
          processedData['chk_3rd_qtr'] = quarter.contains('3rd') ? '☑' : '☐';
          processedData['chk_4th_qtr'] = quarter.contains('4th') ? '☑' : '☐';

          // --- DIET DIARY SPECIFICS ---
          if (template.templateType == 'nt_diet_diary') {
            // Ensure numeric fields are strings
            final numericFields = [
              'height',
              'weight',
              'dbw',
              'cho_adequacy',
              'chon_adequacy',
              'fat_adequacy',
              'cal_adequacy'
            ];
            for (var field in numericFields) {
              if (processedData[field] != null) {
                processedData[field] = processedData[field].toString();
              }
            }

            // Map meal fields directly (already in data, but ensure strings)
            final prefixes = ['bf', 'am', 'lun', 'pm', 'din', 'bed'];
            final suffixes = ['food', 'amount', 'cho', 'chon', 'fat', 'cal'];
            for (var pre in prefixes) {
              for (var suf in suffixes) {
                final key = '${pre}_$suf';
                if (processedData[key] != null) {
                  processedData[key] = processedData[key].toString();
                } else {
                  processedData[key] = ''; // Ensure empty string if null
                }
              }
            }
          }
          if (template.templateType == 'nt_diet_orders') {
            // Construct the diet_census list for the docxtpl tabular loop
            List<Map<String, dynamic>> dietCensus = [];

            void addDietRow(String dietOrder, String prefix) {
              final clientsRaw = data['${prefix}_clients'];
              String clients = '';
              if (clientsRaw is List) {
                clients = clientsRaw.map((e) => e.toString()).join('\n');
              } else {
                clients = clientsRaw?.toString() ?? '';
              }

              final remarks = data['${prefix}_remarks']?.toString() ?? '';
              final total = data['${prefix}_total']?.toString() ?? '';

              if (clients.isNotEmpty ||
                  remarks.isNotEmpty ||
                  total.isNotEmpty) {
                dietCensus.add({
                  'diet_order': dietOrder,
                  'client_names': clients,
                  'remarks': remarks,
                  'total': total,
                });
              } else {
                dietCensus.add({
                  'diet_order': dietOrder,
                  'client_names': '',
                  'remarks': '',
                  'total': '',
                });
              }
            }

            addDietRow('Diabetic Diet', 'diabetic');
            addDietRow('Soft Diet', 'soft');
            addDietRow(
                'Hypoallergenic Diet (no egg, no chicken, crustaceans and mollusks and other identified food allergies like nuts and beans)',
                'hypoallergenic');
            addDietRow('Low Purine Diet', 'low_purine');
            addDietRow('No Pork (Islam and Adventist)', 'no_pork');
            addDietRow('Low salt, low fat', 'low_salt_fat');
            addDietRow('Enteral Feeding (Blenderized)', 'enteral');
            addDietRow('Full Diet', 'full');

            processedData['diet_census'] = dietCensus;
          }
        }

        // --- GLOBAL FORMATTING FOR PROGRESS NOTES (ALL SERVICES) ---
        // Handle root-level 'progress_date' (used in Social Service forms sometimes)
        if (processedData['progress_date'] != null) {
          processedData['progress_date'] =
              formatDate(processedData['progress_date'].toString());
        }
        if (template.templateType == 'progress_notes') {
          if (data['progress_entries'] != null) {
            processedData['progress_entries'] =
                (data['progress_entries'] as List).map((e) {
              final entry = Map<String, dynamic>.from(e as Map);
              if (entry['date'] != null) {
                entry['date'] = formatDate(entry['date'].toString());
              }
              // Handle potential 'progress_date' key used in Social Service forms
              if (entry['progress_date'] != null) {
                entry['progress_date'] =
                    formatDate(entry['progress_date'].toString());
                // Ensure 'date' is also set for consistency if missing
                if (entry['date'] == null) {
                  entry['date'] = entry['progress_date'];
                }
              }
              return entry;
            }).toList();
          }
        }

        // --- SPECIFIC TEMPLATE DATES ---
        if (template.templateType == 'intervention_plan') {
          if (processedData['goal_start_date'] != null) {
            processedData['goal_start_date'] =
                formatDateLong(processedData['goal_start_date'].toString());
          }
          if (processedData['goal_end_date'] != null) {
            processedData['goal_end_date'] =
                formatDateLong(processedData['goal_end_date'].toString());
          }
        }

        if (template.templateType == 'clients_contract') {
          // Map civil_status (from Resident) to status (expected by PDF for this legacy field)
          if (processedData['civil_status'] != null) {
            processedData['status'] = processedData['civil_status'];
          }

          // Flatten witnesses for Word template tags (as requested by user)
          final witnesses = processedData['witnesses'];
          if (witnesses is List) {
            for (int i = 0; i < witnesses.length; i++) {
              final w = witnesses[i];
              if (w is Map) {
                final index = i + 1;
                // Only set if not already present at top level (from digitalSignature fields)
                processedData['witness${index}_name'] ??=
                    (w['name'] ?? '').toString().toUpperCase();
                processedData['witness${index}_designation'] ??=
                    _formatDesignation(w['designation'] ?? '');

                final signatureUrl = (w['signature_url'] ?? '').toString();
                if (signatureUrl.isNotEmpty) {
                  processedData['witness${index}_signature_url'] = signatureUrl;
                }
              }
            }
          }

          // Ensure custodian signature is available if under common keys
          if (processedData['custodian_signature_url'] == null) {
            processedData['custodian_signature_url'] =
                processedData['guardian_signature_url'] ??
                    processedData['relative_signature_url'];
          }

          // Ensure client signature is available if under common keys
          if (processedData['client_signature_url'] == null) {
            processedData['client_signature_url'] =
                processedData['resident_signature_url'] ??
                    processedData['applicant_signature_url'];
          }
        }

        // --- GLOBAL FORMATTING FOR RUNNING NOTES ---
        if (processedData['running_date'] != null) {
          processedData['running_date'] =
              formatDate(processedData['running_date'].toString());
        }

        if (template.templateType == 'inventory_admission') {
          processedData['admission_items'] = formatItems(
              data['admission_items'] is List
                  ? data['admission_items'] as List
                  : null);
        } else if (template.templateType == 'inventory_discharge') {
          processedData['discharge_items'] = formatItems(
              data['discharge_items'] is List
                  ? data['discharge_items'] as List
                  : null);
        } else if (template.templateType == 'inventory_monthly') {
          processedData['clothing_items'] = formatItems(
              data['clothing_items'] is List
                  ? data['clothing_items'] as List
                  : null);
          processedData['toiletries_items'] = formatItems(
              data['toiletries_items'] is List
                  ? data['toiletries_items'] as List
                  : null);
          processedData['linen_items'] = formatItems(
              data['linen_items'] is List ? data['linen_items'] as List : null);
          processedData['others_items'] = formatItems(
              data['others_items'] is List
                  ? data['others_items'] as List
                  : null);
        }

        final backendUrl = await BackendConfig.getBackendUrl();
        final response = await http.post(
          Uri.parse('$backendUrl/generate-document'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'template_type': templateName, // Use resolved name
            'service_unit': serviceUnitMap[template.serviceUnit],
            'output_format': outputFormat,
            'data': {
              ...processedData,
              'resident_name': residentName,
              // Prioritize manually entered case_no, fall back to resident profile's caseNumber
              'case_no': data['case_no'] != null &&
                      data['case_no'].toString().isNotEmpty
                  ? data['case_no']
                  : caseNumber,

              // --- STANDARDIZED FIELDS (For all templates) ---
              'age': data['age'] ?? data['client_age'],
              'client_age': data['client_age'] ?? data['age'],
              'gender': data['gender'] ?? data['sex'],
              'sex': (data['sex'] ?? data['gender'] ?? '')
                  .toString()
                  .toUpperCase(),

              // --- IDENTIFYING DATA (UPPERCASE) ---
              'nickname': (data['nickname'] ?? '').toString().toUpperCase(),
              'cmswdo_name':
                  (data['cmswdo_name'] ?? '').toString().toUpperCase(),
              'received_by':
                  (data['received_by'] ?? '').toString().toUpperCase(),
              'division_chief_name':
                  (data['division_chief_name'] ?? '').toString().toUpperCase(),
              'regional_director_name': (data['regional_director_name'] ?? '')
                  .toString()
                  .toUpperCase(),
              'address': (data['address'] ?? '').toString().toUpperCase(),
              'religious_affiliation': (data['religious_affiliation'] ?? '')
                  .toString()
                  .toUpperCase(),
              'educational_attainment': (data['educational_attainment'] ?? '')
                  .toString()
                  .toUpperCase(),
              'ward_room': (data['ward_room'] ?? '').toString().toUpperCase(),
              'date_conducted': (template.templateType == 'progress_notes' ||
                      template.templateType == 'running_notes')
                  ? formatDate(data['date']?.toString() ??
                      data['checklist_date']?.toString() ??
                      DateTime.now().toString().split(' ')[0])
                  : formatDateLong(data['date']?.toString() ??
                      data['checklist_date']?.toString() ??
                      DateTime.now().toString().split(' ')[0]),
              'referral_source': data['referral_source'] ??
                  data['referred_by'] ??
                  'CSWDO', // Fallback as seen in screenshot
              'client_photo': data['photo_url'] ?? '',

              // --- UNIFIED FIELDS ---
              'coverage':
                  '${data['coverage_month'] ?? 'JANUARY'}, ${data['coverage_year'] ?? DateTime.now().year}'
                      .trim()
                      .toUpperCase(),
              'ways_forward_remarks':
                  (data['ways_forward_remarks'] ?? '').toString(),
              'supervisory_remarks':
                  (data['supervisory_remarks'] ?? '').toString(),
              'supervisor_remarks':
                  (data['supervisor_remarks'] ?? '').toString(),
              'remarks': (data['remarks'] ?? '').toString(),

              // --- PROGRESS NOTES ENTRIES ---
              // Map to both keys for compatibility with various templates
              'progress_entries': (data['progress_entries'] is List
                      ? (data['progress_entries'] as List)
                      : (data['progress_notes'] is List
                          ? (data['progress_notes'] as List)
                          : []))
                  .map((e) => {
                        'date': formatDate(e['date']?.toString()),
                        'activities': (e['activities'] ?? '').toString(),
                        'remarks': (e['remarks'] ?? '').toString(),
                      })
                  .toList(),
              'notes_list': (data['progress_entries'] is List
                      ? (data['progress_entries'] as List)
                      : (data['progress_notes'] is List
                          ? (data['progress_notes'] as List)
                          : []))
                  .map((e) => {
                        'date': formatDate(e['date']?.toString()),
                        'activities': (e['activities'] ?? '').toString(),
                        'remarks': (e['remarks'] ?? '').toString(),
                      })
                  .toList(),

              // --- PSYCH INDIVIDUAL SESSIONS ALIASES ---
              'client_name_upper': residentName.toUpperCase(),
              'reason_for_session':
                  (data['reason_for_session'] ?? '').toString(),
              'objectives': (data['objectives'] ?? '').toString(),
              'session_narrative': (data['session_narrative'] ?? '').toString(),
              'agreements': (data['agreements'] ?? '').toString(),
              'recommendations': (data['recommendations'] ?? '').toString(),

              // --- INITIAL ASSESSMENT MAPPINGS ---
              'reason_for_referral':
                  (data['reason_for_referral'] ?? '').toString(),
              'brief_history': (data['brief_history'] ?? '').toString(),
              'behavioral_observation':
                  (data['behavioral_observation'] ?? '').toString(),
              'assessment_tools': (data['assessment_tools'] ?? '').toString(),
              'mental_status_exam':
                  (data['mental_status_exam'] ?? '').toString(),
              'results_discussion':
                  (data['results_discussion'] ?? '').toString(),
              'interventions_list': (data['intervention_items'] is List
                      ? (data['intervention_items'] as List)
                      : [])
                  .map((i) => {
                        'objectives': (i['objectives'] ?? '').toString(),
                        'activity': (i['activity'] ?? '').toString(),
                        'responsible_person':
                            (i['responsible_person'] ?? '').toString(),
                        'time_frame': (i['time_frame'] ?? '').toString(),
                        'outcome': (i['outcome'] ?? '').toString(),
                      })
                  .toList(),

              // --- PSYCH INDIVIDUAL SESSIONS MAPPING ---
              'type_referral': (data['session_type'] ?? '') == 'By Referral' ||
                  (data['type_referral'] == true),
              'type_walkin': (data['session_type'] ?? '') == 'Walk-in' ||
                  (data['type_walkin'] == true),
              'type_as_needed':
                  (data['session_type'] ?? '') == 'As Need Arises' ||
                      (data['type_as_needed'] == true),

              // --- FORMATTED DATES ---
              // Use Short date for Progress/Running notes, Long date for others
              'date_prepared': (template.templateType == 'progress_notes' ||
                      template.templateType == 'running_notes')
                  ? formatDate(data['date_prepared']?.toString())
                  : formatDateLong(data['date_prepared']?.toString()),
              'date_submitted': (template.templateType == 'progress_notes' ||
                      template.templateType == 'running_notes')
                  ? formatDate(data['date_submitted']?.toString())
                  : formatDateLong(data['date_submitted']?.toString()),
              'session_date': (template.templateType == 'progress_notes' ||
                      template.templateType == 'running_notes')
                  ? formatDate(data['session_date']?.toString())
                  : formatDateLong(data['session_date']?.toString()),
              'report_date': (template.templateType == 'progress_notes' ||
                      template.templateType == 'running_notes')
                  ? formatDate(data['report_date']?.toString())
                  : formatDateLong(data['report_date']?.toString()),
              'referral_date':
                  formatDateLong(data['referral_date']?.toString()),
              'date_of_birth':
                  formatDateLong(data['date_of_birth']?.toString()),
              'date_of_admission':
                  formatDateLong(data['date_of_admission']?.toString()),
              'date_of_assessment':
                  formatDateLong(data['date_of_assessment']?.toString()),
              'date_of_report':
                  formatDateLong(data['date_of_report']?.toString()),
              // Add missing date fields
              'date_admitted':
                  formatDateLong(data['date_admitted']?.toString()),
              'admission_date':
                  formatDateLong(data['admission_date']?.toString()),
              'date_discharged':
                  formatDateLong(data['date_discharged']?.toString()),
              'date_picture_taken':
                  formatDateLong(data['date_picture_taken']?.toString()),
              'conference_date':
                  formatDateLong(data['conference_date']?.toString()),
              // Generic fallback date if used (Consolidated)
              'date': (template.templateType == 'progress_notes' ||
                      template.templateType == 'running_notes')
                  ? formatDate(data['date']?.toString() ??
                      data['progress_date']?.toString() ??
                      data['checklist_date']?.toString() ??
                      data['date_prepared']?.toString() ??
                      data['report_date']?.toString() ??
                      DateTime.now().toString().split(' ')[0])
                  : formatDateLong(data['date']?.toString() ??
                      data['progress_date']?.toString() ??
                      data['checklist_date']?.toString() ??
                      data['date_prepared']?.toString() ??
                      data['report_date']?.toString() ??
                      DateTime.now().toString().split(' ')[0]),

              'prepared_by': (data['referring_person'] ??
                      data['prepared_by'] ??
                      (template.serviceUnit == ServiceUnit.nutritionService
                          ? 'Jason O. Molina, RND'
                          : data['user_name'] ?? 'Social Worker'))
                  .toString()
                  .toUpperCase(),
              'prepared_by_designation': _formatDesignation(
                  data['referring_position'] ??
                      data['prepared_by_designation'] ??
                      (template.serviceUnit == ServiceUnit.nutritionService
                          ? 'Nutritionist-Dietitian II'
                          : data['user_title'] ??
                              (template.serviceUnit ==
                                      ServiceUnit.psychologicalService
                                  ? 'Psychometrician'
                                  : (template.serviceUnit ==
                                          ServiceUnit.homeLifeService
                                      ? 'Houseparent I'
                                      : 'Social Worker')))),
              'prepared_by_license':
                  (data['license_no']?.toString().isNotEmpty == true)
                      ? data['license_no'].toString()
                      : (data['user_license']?.toString() ?? ''),
              'referring_unit':
                  data['referring_unit']?.toString().replaceAll('_', ' ') ?? '',

              // --- HOMELIFE SPECIFIC ALIASES ---
              'clothing_items': formatItems(data['clothing_items']),
              'toiletries_items': formatItems(data['toiletries_items']),
              'linen_items': formatItems(data['linen_items']),
              'others_items': formatItems(data['others_items']),
              'admission_items': formatItems(data['admission_items']),
              'discharge_items': formatItems(data['discharge_items']),
              'referring_party':
                  (data['turned_over_by'] ?? data['referring_party'] ?? '')
                      .toString()
                      .toUpperCase(),
              'referring_party_signature_url':
                  data['turned_over_by_signature_url'] ??
                      data['referring_party_signature_url'],
              'inspected_by':
                  (data['inspected_by'] ?? data['received_by'] ?? '')
                      .toString()
                      .toUpperCase(),
              'inspected_by_designation': _formatDesignation(
                  data['inspected_by_designation'] ??
                      data['received_by_designation'] ??
                      'HOUSEPARENT I'),
              'inspected_by_signature_url':
                  data['inspected_by_signature_url'] ??
                      data['received_by_signature_url'],
              'receiving_party':
                  (data['receiving_party'] ?? data['received_by'] ?? '')
                      .toString()
                      .toUpperCase(),
              'receiving_party_designation': _formatDesignation(
                  data['receiving_party_designation'] ??
                      data['received_by_designation'] ??
                      'HOUSEPARENT I'),
              'receiving_party_signature_url':
                  data['receiving_party_signature_url'] ??
                      data['received_by_signature_url'],
              'attested_by':
                  (data['attested_by'] ?? '').toString().toUpperCase(),
              'attested_by_designation': _formatDesignation(
                  data['attested_by_designation'] ??
                      'SUPERVISING HOUSEPARENT I'),
              'attested_by_signature_url': data['attested_by_signature_url'],
              'submitted_by':
                  (data['submitted_by'] ?? '').toString().toUpperCase(),
              'submitted_by_designation': _formatDesignation(
                  data['submitted_by_designation'] ??
                      'SUPERVISING HOUSEPARENT I'),
              'submitted_by_signature_url': data['submitted_by_signature_url'],
              'supervising_hp':
                  (data['supervising_hp'] ?? '').toString().toUpperCase(),
              'supervising_hp_designation': _formatDesignation(
                  data['supervising_hp_designation'] ??
                      'SUPERVISING HOUSEPARENT I'),
              'supervising_hp_signature_url':
                  data['supervising_hp_signature_url'],
              'center_doctor':
                  (data['center_doctor'] ?? '').toString().toUpperCase(),
              'center_doctor_designation': _formatDesignation(
                  data['center_doctor_designation'] ?? 'DOCTOR'),
              'center_doctor_signature_url':
                  data['center_doctor_signature_url'],
              'social_worker':
                  (data['social_worker'] ?? '').toString().toUpperCase(),
              'social_worker_designation': _formatDesignation(
                  data['social_worker_designation'] ?? 'SOCIAL WORKER'),
              'social_worker_signature_url':
                  data['social_worker_signature_url'],
              'approved_by': (data['approved_by'] ?? data['noted_by'] ?? '')
                  .toString()
                  .toUpperCase(),
              'approved_by_designation': _formatDesignation(
                  data['approved_by_designation'] ??
                      data['noted_by_designation'] ??
                      'CENTER HEAD'),
              'approved_by_signature_url': data['approved_by_signature_url'] ??
                  data['noted_by_signature_url'],

              // Specific Receipt roles for Incident Report
              'received_social':
                  (data['received_social'] ?? '').toString().toUpperCase(),
              'received_social_designation':
                  _formatDesignation(data['received_social_designation']),
              'received_social_signature_url':
                  data['received_social_signature_url'],
              'received_psych':
                  (data['received_psych'] ?? '').toString().toUpperCase(),
              'received_psych_designation':
                  _formatDesignation(data['received_psych_designation']),
              'received_psych_signature_url':
                  data['received_psych_signature_url'],
              'received_medical':
                  (data['received_medical'] ?? '').toString().toUpperCase(),
              'received_medical_designation':
                  _formatDesignation(data['received_medical_designation']),
              'received_medical_signature_url':
                  data['received_medical_signature_url'],

              // Specific Receipt roles for After Care Plan
              'received_homelife':
                  (data['received_homelife'] ?? '').toString().toUpperCase(),
              'received_homelife_signature_url':
                  data['received_homelife_signature_url'],
              // (Note: received_medical and received_psych are already mapped above for Incident Report)

              // Out On Pass Checkmarks
              'chk_nature_personal':
                  data['nature_personal'] == true ? '☑' : '☐',
              'chk_nature_medical': data['nature_medical'] == true ? '☑' : '☐',
              'chk_nature_official':
                  data['nature_official'] == true ? '☑' : '☐',
              // Template might use just the name for true/false or a checkmark
              'nature_personal_chk':
                  data['nature_personal'] == true ? '☑' : '☐',
              'nature_medical_chk': data['nature_medical'] == true ? '☑' : '☐',
              'nature_official_chk':
                  data['nature_official'] == true ? '☑' : '☐',

              // Noted By (Default to Center Head if not set, Physician for Nutrition)
              'noted_by': (data['noted_by'] ??
                      (template.serviceUnit == ServiceUnit.nutritionService
                          ? 'Dr. Justine Tan'
                          : 'Candelaria C. Tingson, RSW'))
                  .toString()
                  .toUpperCase(), // Default or from Constants
              'noted_by_designation': _formatDesignation(
                  data['noted_by_designation'] ??
                      (template.serviceUnit == ServiceUnit.nutritionService
                          ? 'Physician'
                          : 'Center Head / SWO IV')),

              // --- DYNAMIC LIST PARSING ---
              // Convert bullet strings to lists for {% for %} loops in Word
              'attendees_list': _parseBulletList(data['attendees']),
              'objective_list': _parseBulletList(data['objective']),
              'discussions_list': _parseBulletList(data['discussions']),
              'agreement_recommendations_list':
                  _parseBulletList(data['agreement_recommendations']),
              'reason_for_referral_list':
                  _parseBulletList(data['reason_for_referral']),
              'challenges_presented_list':
                  _parseBulletList(data['challenges_presented']),

              // --- CORRELATED MATRIX FOR DISCUSSIONS & AGREEMENTS ---
              'discussion_matrix': _zipLists(
                _parseBulletList(data['discussions']),
                _parseBulletList(data['agreement_recommendations']),
              ),

              // --- PRE-ADMISSION CHECKLIST LOGIC ---
              // Auto-calculate check marks for the Categories table
              // We'll generate keys like: chk_abandoned_60_70_m, chk_neglected_80_plus_f
              ..._generateChecklistData(
                category: data['case_category'] ?? data['category'],
                ageRaw: data['client_age'] ?? data['age'],
                gender: data['gender'] ?? data['sex'],
              ),

              // --- REQUIREMENTS LIST LOGIC ---
              // Convert boolean 'true' to '✓' for requirements checklist (req_..._yes/no)
              ..._convertRequirementsData(data),

              // --- SESSION TYPE CHECKBOXES ---
              'chk_referral': (data['session_type'] ?? '') == 'By Referral' ||
                      data['type_referral'] == true
                  ? '☑'
                  : '☐',
              'chk_walkin': (data['session_type'] ?? '') == 'Walk-in' ||
                      data['type_walkin'] == true
                  ? '☑'
                  : '☐',
              'chk_as_needed':
                  (data['session_type'] ?? '') == 'As Need Arises' ||
                          (data['type_as_needed'] == true)
                      ? '☑'
                      : '☐',

              // --- COMMON CHECKBOXES (Gender, Status) ---
              'chk_male': (data['sex'] ?? data['gender'] ?? '')
                      .toString()
                      .toLowerCase()
                      .startsWith('m')
                  ? '☑'
                  : '☐',
              'chk_female': (data['sex'] ?? data['gender'] ?? '')
                      .toString()
                      .toLowerCase()
                      .startsWith('f')
                  ? '☑'
                  : '☐',
              'chk_single':
                  (data['civil_status'] ?? '').toString().toUpperCase() ==
                          'SINGLE'
                      ? '☑'
                      : '☐',
              'chk_married':
                  (data['civil_status'] ?? '').toString().toUpperCase() ==
                          'MARRIED'
                      ? '☑'
                      : '☐',
              'chk_widowed':
                  (data['civil_status'] ?? '').toString().toUpperCase() ==
                          'WIDOWED'
                      ? '☑'
                      : '☐',
              'chk_separated':
                  (data['civil_status'] ?? '').toString().toUpperCase() ==
                          'SEPARATED'
                      ? '☑'
                      : '☐',

              // --- SIGNATURE IMAGES (URLs) ---
              // The backend word template engine needs the direct URL strings to download and inject into placeholders
              ...Map.fromEntries(
                data.entries.where((e) => e.key.endsWith('_signature_url')),
              ),

              // --- DYNAMIC DESIGNATION FORMATTING (Catch-all) ---
              ...Map.fromEntries(
                data.entries
                    .where((e) => e.key.endsWith('_designation'))
                    .map((e) => MapEntry(e.key, _formatDesignation(e.value))),
              ),

              // --- PARTICIPANT DETAILS ---
              'participant_details': (data['participant_details'] is List
                      ? (data['participant_details'] as List)
                      : [])
                  .map((p) => {
                        ...p,
                        'name': (p['name'] ?? '').toString().toUpperCase(),
                      })
                  .toList(),
            }
          }),
        );

        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          print('Server Generation Failed: ${response.body}');
          // Fallback to local generation if server fails?
          // For now, let's fall through or throw error.
          throw Exception('Backend PDF generation failed: ${response.body}');
        }
      } catch (e) {
        print('Backend PDF Error: $e');
        // CRITICAL: Rethrow to see the error.
        throw Exception('Server Connection Failed: $e');
      }
    }

    // For client-side PDFs, pre-fetch signature images if URLs are provided
    Future<void> attachSignatureBytes(
      Map<String, dynamic> data,
      String urlKey,
      String bytesKey,
    ) async {
      try {
        final rawUrl = data[urlKey]?.toString();
        if (rawUrl == null || rawUrl.isEmpty) {
          debugPrint('[PdfGenerator] No signature URL found for key $urlKey');
          return;
        }

        debugPrint('[PdfGenerator] Fetching signature from: $rawUrl');
        final res = await http.get(Uri.parse(rawUrl));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          data[bytesKey] = res.bodyBytes;
          debugPrint(
              '[PdfGenerator] Successfully attached signature bytes for $bytesKey');
        } else {
          debugPrint(
              '[PdfGenerator] Failed to fetch signature for $urlKey: HTTP ${res.statusCode}');
        }
      } catch (e) {
        debugPrint('[PdfGenerator] Error fetching signature for $urlKey: $e');
      }
    }

    // Dynamically find all signature URLs and convert them to bytes
    final signatureFutures = <Future<void>>[];
    final signatureKeys =
        data.keys.where((k) => k.endsWith('_signature_url')).toList();
    for (final urlKey in signatureKeys) {
      final baseName = urlKey.replaceAll('_signature_url', '');
      final bytesKey = '_${baseName}_signature_bytes';
      signatureFutures.add(attachSignatureBytes(data, urlKey, bytesKey));
    }

    // Also explicitly add the standard ones just in case they were set without the prefix pattern
    signatureFutures.addAll([
      attachSignatureBytes(
          data, 'prepared_by_signature_url', '_prepared_by_signature_bytes'),
      attachSignatureBytes(
          data, 'noted_by_signature_url', '_noted_by_signature_bytes'),
      attachSignatureBytes(
          data, 'center_head_signature_url', '_center_head_signature_bytes'),
    ]);

    await Future.wait(signatureFutures);

    // Default Local Generation
    final pdf = pw.Document(
      theme: pw.ThemeData(
        defaultTextStyle: pw.TextStyle(
          font: _regularFont,
          fontSize: 11,
        ),
      ),
    );

    // For client photo template, pre-fetch the image
    if (template.templateType == 'client_photo' && data['photo_url'] != null) {
      try {
        final photoUrl = data['photo_url'].toString();
        if (photoUrl.isNotEmpty) {
          final provider = await networkImage(photoUrl);
          data['_photo_provider'] = provider;
        }
      } catch (e) {
        // Ignore image loading errors, PDF will show placeholder
        print('Error loading client photo for PDF: $e');
      }
    }

    // Get the appropriate PDF builder based on service unit
    final pages = _buildFormPages(template, data, residentName, caseNumber);

    for (final page in pages) {
      pdf.addPage(page);
    }

    return pdf.save();
  }

  /// Build form pages based on template
  static List<pw.Page> _buildFormPages(
    FormTemplate template,
    Map<String, dynamic> data,
    String residentName,
    String? caseNumber,
  ) {
    switch (template.serviceUnit) {
      case ServiceUnit.socialService:
        return SocialServicePdf.buildPages(
          template: template,
          data: data,
          residentName: residentName,
          caseNumber: caseNumber,
          logoBytes: _logoBytes,
        );
      case ServiceUnit.homeLifeService:
        return HomeLifeServicePdf.buildPages(
          template: template,
          data: data,
          residentName: residentName,
          caseNumber: caseNumber,
          logoBytes: _logoBytes,
        );
      case ServiceUnit.psychologicalService:
        return PsychologicalServicePdf.buildPages(
          template: template,
          data: data,
          residentName: residentName,
          caseNumber: caseNumber,
          logoBytes: _logoBytes,
        );
      case ServiceUnit.medicalService:
        return MedicalServicePdf.buildPages(
          template: template,
          data: data,
          residentName: residentName,
          caseNumber: caseNumber,
          logoBytes: _logoBytes,
        );
      case ServiceUnit.nutritionService:
        return NutritionServicePdf.buildPages(
          template: template,
          data: data,
          residentName: residentName,
          caseNumber: caseNumber,
          logoBytes: _logoBytes,
        );
    }
  }

  /// Print the PDF directly
  static Future<void> printPdf({
    required FormTemplate template,
    required Map<String, dynamic> data,
    required String residentName,
    String? caseNumber,
  }) async {
    final pdfBytes = await generatePdf(
      template: template,
      data: data,
      residentName: residentName,
      caseNumber: caseNumber,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: '${template.name} - $residentName',
    );
  }

  /// Share/Save the PDF
  static Future<void> sharePdf({
    required FormTemplate template,
    required Map<String, dynamic> data,
    required String residentName,
    String? caseNumber,
  }) async {
    final pdfBytes = await generatePdf(
      template: template,
      data: data,
      residentName: residentName,
      caseNumber: caseNumber,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          '${template.name.replaceAll(' ', '_')}_${residentName.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Generate a Word document (.docx) from the backend
  static Future<Uint8List> generateDocx({
    required FormTemplate template,
    required Map<String, dynamic> data,
    required String residentName,
    String? caseNumber,
  }) async {
    return generatePdf(
      template: template,
      data: data,
      residentName: residentName,
      caseNumber: caseNumber,
      outputFormat: 'docx',
    );
  }

  /// Helper to split bulleted or newline-separated strings into a list
  static List<String> _parseBulletList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      if (value.isEmpty) return [];
      // Split by newline
      final lines = value.split('\n');
      // Clean up bullets
      return lines
          .map((line) {
            return line
                .replaceAll(
                    RegExp(r'^[•\-\*]\s*'), '') // Remove leading bullets
                .trim();
          })
          .where((line) => line.isNotEmpty)
          .toList();
    }
    return [];
  }

  /// Zip two lists into a list of maps for matrix table generation
  static List<Map<String, String>> _zipLists(
      List<String> list1, List<String> list2) {
    int maxLen = list1.length > list2.length ? list1.length : list2.length;
    List<Map<String, String>> matrix = [];

    for (int i = 0; i < maxLen; i++) {
      matrix.add({
        'discussion': i < list1.length ? list1[i] : '',
        'agreement': i < list2.length ? list2[i] : '',
      });
    }
    return matrix;
  }

  /// Helper to generate checkmark data for the Pre-Admission Checklist
  static Map<String, dynamic> _generateChecklistData({
    required String? category,
    required dynamic ageRaw,
    required String? gender,
  }) {
    final result = <String, dynamic>{};
    if (category == null || ageRaw == null || gender == null) return result;

    // Parse Age
    int? age;
    if (ageRaw is int) {
      age = ageRaw;
    } else if (ageRaw is String) {
      age = int.tryParse(ageRaw);
    }
    if (age == null) return result;

    // Normalize inputs
    final sex = gender.toLowerCase().startsWith('m') ? 'm' : 'f';
    final cat = category.toLowerCase().trim();

    // Determine Age Range suffix based on TEMPLATE tags
    // Tags observed: below_60, 60_70, 71_79, 80_up
    String? rangeSuffix;
    if (age < 60) {
      rangeSuffix = 'below_60';
    } else if (age >= 60 && age <= 70) {
      rangeSuffix = '60_70';
    } else if (age >= 71 && age <= 79) {
      rangeSuffix = '71_79';
    } else if (age >= 80) {
      rangeSuffix = '80_up';
    }

    if (rangeSuffix == null) return result;

    // Determine Category prefix based on TEMPLATE tags
    // Tags observed: ab (Abandoned), ne (Neglected), un (Unattached), ho (Homeless)
    String? catPrefix;
    if (cat.contains('abandoned')) {
      catPrefix = 'ab';
    } else if (cat.contains('neglected')) {
      catPrefix = 'ne';
    } else if (cat.contains('unattached')) {
      catPrefix = 'un';
    } else if (cat.contains('homeless')) {
      catPrefix = 'ho';
    }

    if (catPrefix != null) {
      // Key format: {prefix}_{range}_{sex}
      // Example: ne_60_70_m
      final key = '${catPrefix}_${rangeSuffix}_$sex';
      result[key] = '✓';
    }

    return result;
  }

  /// Helper to convert boolean requirements to "✓" strings
  static Map<String, dynamic> _convertRequirementsData(
      Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    // Look for keys starting with 'req_' and ending with '_yes' or '_no'
    // E.g. req_referral_letter_yes
    for (final key in data.keys) {
      if (key.startsWith('req_') &&
          (key.endsWith('_yes') || key.endsWith('_no'))) {
        final val = data[key];
        if (val == true || val.toString().toLowerCase() == 'true') {
          result[key] = '✓';
        } else {
          result[key] = ''; // Send empty string for false/null
        }
      }
    }
    return result;
  }

  /// Helper to format designations in Title Case while preserving specific abbreviations
  static String _formatDesignation(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'none') return '';

    // List of words that should always be UPPERCASE (abbreviations/ranks)
    final uppercaseWords = {
      'SWO',
      'RSW',
      'MD',
      'RN',
      'LPT',
      'MSW',
      'CMSWDO',
      'CSWDO',
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X' // Roman numerals
    };

    // Words with specific mixed casing or abbreviations
    final specificCasing = {
      'rpm': 'RPm',
      'rpsy': 'RPsy',
      'hp': 'HP',
    };

    // Remove underscores (standard normalize)
    final words = text.replaceAll('_', ' ').split(RegExp(r'\s+'));
    final results = <String>[];

    for (var word in words) {
      if (word.isEmpty) continue;

      final upperWord = word.toUpperCase();
      final lowerWord = word.toLowerCase();

      // Check if it's a known uppercase word (exactly as uppercase)
      if (uppercaseWords.contains(upperWord)) {
        results.add(upperWord);
      } else if (specificCasing.containsKey(lowerWord)) {
        results.add(specificCasing[lowerWord]!);
      } else {
        // Standard Title Case: capitalize first letter, lowercase the rest
        if (word.length > 1) {
          results.add(word[0].toUpperCase() + word.substring(1).toLowerCase());
        } else {
          // Single character word (like "/")
          results.add(word.toUpperCase());
        }
      }
    }

    return results.join(' ');
  }
}
