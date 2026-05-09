import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'form_field_builders.dart';
import 'admission_case_conference.dart';
import '../../../core/constants/form_options.dart';

/// Social Service Form Templates
class SocialServiceForms {
  SocialServiceForms._();

  static bool _defaultRo(String key) => false;

  /// Get form fields for social service templates
  /// [readOnly] - If true, all fields will be disabled (for approval view)
  /// [readOnlyFieldKeys] - When non-null, fields whose key is in this set are read-only (e.g. resident-sourced).
  static List<Widget> getFormFields(
    String templateType,
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool readOnly = false,
    Set<String>? readOnlyFieldKeys,
  }) {
    bool ro(String key) =>
        readOnly || (readOnlyFieldKeys?.contains(key) ?? false);
    switch (templateType) {
      case 'pre_admission_checklist':
        return _preAdmissionChecklist(data, onChanged, ro: ro);
      case 'requirements_checklist':
        return _requirementsChecklist(data, onChanged, ro: ro);
      case 'general_intake_sheet':
        return _generalIntakeSheet(data, onChanged, ro: ro);
      case 'admission_case_conference':
        return _admissionCaseConference(data, onChanged, ro: ro);
      case 'clients_contract':
        return _clientsContract(data, onChanged, ro: ro);
      case 'admission_slip':
        return _admissionSlip(data, onChanged, ro: ro);
      case 'progress_notes':
        return _progressNotes(data, onChanged, ro: ro);
      case 'running_notes':
        return _runningNotes(data, onChanged, ro: ro);
      case 'intervention_plan':
        return _interventionPlan(data, onChanged, ro: ro);
      case 'social_case_study':
        return _initialSocialCaseStudy(data, onChanged, ro: ro);
      case 'updated_social_case_study':
        return _updatedSocialCaseStudy(data, onChanged, ro: ro);
      case 'case_conference':
        return _caseConference(data, onChanged, ro: ro);
      case 'termination_report':
        return _terminationReport(data, onChanged, ro: ro);
      case 'closing_summary':
        return _closingSummary(data, onChanged, ro: ro);
      case 'quarterly_narrative':
        return _quarterlyNarrative(data, onChanged, ro: ro);
      case 'pre_termination_plan':
        return _preTerminationPlan(data, onChanged, ro: ro);

      case 'after_care_plan':
        return _afterCarePlan(data, onChanged, ro: ro);
      case 'case_transfer_summary':
        return _caseTransferSummary(data, onChanged, ro: ro);
      case 'client_photo':
        return _clientPhoto(data, onChanged, ro: ro);
      case 'pre_admission_conference':
        return _preAdmissionConference(data, onChanged, ro: ro);
      case 'kasunduan':
        return _kasunduan(data, onChanged, ro: ro);

      case 'pre_discharge_conference':
        return _preDischargeConference(data, onChanged, ro: ro);

      case 'discharge_slip':
        return _dischargeSlip(data, onChanged, ro: ro);

      default:
        return [const Text('Unknown form type')];
    }
  }

  // PRE-ADMISSION CHECKLIST
  static List<Widget> _preAdmissionChecklist(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('PRE-ADMISSION CHECKLIST'),
      FormFieldBuilders.textField(
        label: 'Name',
        value: data['name'] ?? '',
        onChanged: (v) => onChanged('name', v),
        required: true,
        readOnly: ro('name'),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['age']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('age', int.tryParse(v)),
              readOnly: ro('age'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date',
              value: data['date'],
              onChanged: (v) => onChanged('date', v?.toIso8601String()),
            ),
          ),
        ],
      ),
      FormFieldBuilders.dropdown(
        label: 'Sex',
        value: data['sex'] ?? data['gender'] ?? 'Male',
        items: const ['Male', 'Female'],
        onChanged: (v) => onChanged('sex', v),
        readOnly: ro('sex'),
      ),
      FormFieldBuilders.dropdown(
        label: 'Category',
        value: data['category'] ?? 'abandoned',
        items: const ['Abandoned', 'Neglected', 'Unattached', 'Homeless'],
        onChanged: (v) => onChanged('category', v),
        readOnly: ro('category'),
      ),
      FormFieldBuilders.textField(
        label: 'Place of Birth',
        value: data['place_of_birth'] ?? '',
        onChanged: (v) => onChanged('place_of_birth', v),
        readOnly: ro('place_of_birth'),
      ),
      FormFieldBuilders.textField(
        label: 'Referred by',
        value: data['referred_by'] ?? '',
        onChanged: (v) => onChanged('referred_by', v),
        readOnly: ro('referred_by'),
      ),
      FormFieldBuilders.textArea(
        label: 'Remarks',
        value: data['remarks'] ?? '',
        onChanged: (v) => onChanged('remarks', v),
      ),
    ];
  }

  // REQUIREMENTS CHECKLIST
  static List<Widget> _requirementsChecklist(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    final requirements = [
      'referral_letter',
      'social_case_study_report',
      'chest_xray',
      'medical_certificate',
      'laboratory_latest',
      'blood_chemistry',
      'urinalysis',
      'stool_exam',
      'ultrasound',
      'psychological_evaluation',
      'vaccination_card',
      'rt_pcr_antigen',
      'osca_id',
    ];

    final labels = {
      'referral_letter': 'Referral Letter',
      'social_case_study_report': 'Social Case Study Report',
      'chest_xray': 'Chest X-Ray',
      'medical_certificate': 'Medical Certificate',
      'laboratory_latest': 'Laboratory (Latest)',
      'blood_chemistry':
          'Blood Chemistry (FBS, SGPT, SGOT, Uric, Creatinine, Cholesterol, BUN, Electrolytes)',
      'urinalysis': 'Urinalysis',
      'stool_exam': 'Stool Exam',
      'ultrasound': 'Ultrasound (if needed)',
      'psychological_evaluation': 'Psychological Evaluation',
      'vaccination_card': 'Vaccination Card',
      'rt_pcr_antigen': 'RT-PCR / Antigen Result',
      'osca_id': 'OSCA ID',
    };

    return [
      FormFieldBuilders.sectionHeader('REQUIREMENTS CHECKLIST'),
      FormFieldBuilders.textField(
        label: 'Name',
        value: data['name'] ?? '',
        onChanged: (v) => onChanged('name', v),
        required: true,
        readOnly: ro('name'),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['age']?.toString() ?? '',
              onChanged: (v) => onChanged('age', v),
              readOnly: ro('age'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date',
              value: data['checklist_date'],
              onChanged: (v) =>
                  onChanged('checklist_date', v?.toIso8601String()),
            ),
          ),
        ],
      ),
      FormFieldBuilders.dropdown(
        label: 'Category',
        value: data['category'] ?? 'abandoned',
        items: const ['Abandoned', 'Neglected', 'Unattached', 'Homeless'],
        onChanged: (v) => onChanged('category', v),
        readOnly: ro('category'),
      ),
      FormFieldBuilders.textField(
        label: 'Place of Birth',
        value: data['place_of_birth'] ?? '',
        onChanged: (v) => onChanged('place_of_birth', v),
        readOnly: ro('place_of_birth'),
      ),
      FormFieldBuilders.textField(
        label: 'Address',
        value: data['address'] ?? '',
        onChanged: (v) => onChanged('address', v),
        readOnly: ro('address'),
      ),
      FormFieldBuilders.textField(
        label: 'Referred by',
        value: data['referred_by'] ?? '',
        onChanged: (v) => onChanged('referred_by', v),
        readOnly: ro('referred_by'),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Requirements Status'),
      ...requirements.map((req) => FormFieldBuilders.checkboxWithRemarks(
            label: labels[req]!,
            checked: data['req_${req}_yes'] ?? false,
            remarks: data['req_${req}_remarks'] ?? '',
            onCheckedChanged: (v) => onChanged('req_${req}_yes', v),
            onRemarksChanged: (v) => onChanged('req_${req}_remarks', v),
          )),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Digital Signatures'),
      FormFieldBuilders.digitalSignature(
        label: 'Endorsed by Signature',
        fieldName: 'endorsed_by_signature_url',
        value: data['endorsed_by_signature_url']?.toString(),
        formId: data['_submission_id']?.toString(),
        onChanged: (url) => onChanged('endorsed_by_signature_url', url),
        required: true,
      ),
      // Received By is now auto-populated by the system (current user)
    ];
  }

  // GENERAL INTAKE SHEET
  static List<Widget> _generalIntakeSheet(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('GENERAL INTAKE SHEET'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              key: const ValueKey('region'),
              label: 'Region',
              value: data['region'] ?? '',
              onChanged: (v) => onChanged('region', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              key: const ValueKey('center'),
              label: 'Center',
              value: data['center'] ?? '',
              onChanged: (v) => onChanged('center', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              key: const ValueKey('case_no'),
              label: 'Case No.',
              value: data['case_no'] ?? '',
              onChanged: (v) => onChanged('case_no', v),
              readOnly: ro('case_no'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date',
              value: data['intake_date'],
              onChanged: (v) => onChanged('intake_date', v?.toIso8601String()),
            ),
          ),
        ],
      ),
      FormFieldBuilders.dropdown(
        label: 'Case Type',
        value: data['case_type'] ?? 'New',
        items: const ['New', 'Re-opened'],
        onChanged: (v) => onChanged('case_type', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Identifying Information'),
      FormFieldBuilders.textField(
        key: const ValueKey('applicant_name'),
        label: 'Name of Applicant',
        value: data['applicant_name'] ?? '',
        onChanged: (v) => onChanged('applicant_name', v),
        required: true,
        readOnly: ro('applicant_name'),
      ),
      FormFieldBuilders.textArea(
        key: const ValueKey('applicant_address'),
        label: 'Address',
        value: data['applicant_address'] ?? '',
        onChanged: (v) => onChanged('applicant_address', v),
        readOnly: ro('applicant_address'),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              key: const ValueKey('birthplace'),
              label: 'Birthplace',
              value: data['birthplace'] ?? '',
              onChanged: (v) => onChanged('birthplace', v),
              readOnly: ro('birthplace'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Birthday',
              value: data['birthday'],
              onChanged: (v) => onChanged('birthday', v?.toIso8601String()),
              readOnly: ro('birthday'),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        key: const ValueKey('nearest_relative_name'),
        label: 'Name of Nearest Relative',
        value: data['nearest_relative_name'] ?? '',
        onChanged: (v) => onChanged('nearest_relative_name', v),
        readOnly: ro('nearest_relative_name'),
      ),
      FormFieldBuilders.textArea(
        key: const ValueKey('nearest_relative_address'),
        label: 'Address of Nearest Relative',
        value: data['nearest_relative_address'] ?? '',
        onChanged: (v) => onChanged('nearest_relative_address', v),
        readOnly: ro('nearest_relative_address'),
      ),
      FormFieldBuilders.textArea(
        key: const ValueKey('disability_nature'),
        label: 'If applicant is disabled, indicate nature of disability',
        value: data['disability_nature'] ?? '',
        onChanged: (v) => onChanged('disability_nature', v),
        readOnly: ro('disability_nature'),
      ),
      FormFieldBuilders.textField(
        key: const ValueKey('referral_source'),
        label: 'Source of Referral',
        value: data['referral_source'] ?? '',
        onChanged: (v) => onChanged('referral_source', v),
        readOnly: ro('referral_source'),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Assessment'),
      FormFieldBuilders.textArea(
        key: const ValueKey('problem_presented'),
        label: 'Problem Presented',
        value: data['problem_presented'] ?? '',
        onChanged: (v) => onChanged('problem_presented', v),
        required: true,
      ),
      FormFieldBuilders.textArea(
        key: const ValueKey('initial_assessment'),
        label:
            'Initial Assessment (Worker\'s impression about the problem and its causes)',
        value: data['initial_assessment'] ?? '',
        onChanged: (v) => onChanged('initial_assessment', v),
      ),
      FormFieldBuilders.textArea(
        key: const ValueKey('action_taken'),
        label: 'Action Taken',
        value: data['action_taken'] ?? '',
        onChanged: (v) => onChanged('action_taken', v),
      ),
      FormFieldBuilders.textArea(
        key: const ValueKey('assessment_recommendation'),
        label: 'Assessment and Recommendation',
        value: data['assessment_recommendation'] ?? '',
        onChanged: (v) => onChanged('assessment_recommendation', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Digital Signatures'),
      FormFieldBuilders.digitalSignature(
        label: 'Applicant Signature',
        fieldName: 'applicant_signature_url',
        value: data['applicant_signature_url']?.toString(),
        formId: data['_submission_id']?.toString(),
        onChanged: (url) => onChanged('applicant_signature_url', url),
        required: true,
      ),
    ];
  }

  // ADMISSION CASE CONFERENCE
  static List<Widget> _admissionCaseConference(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return AdmissionCaseConferenceForm.build(data, onChanged, ro: ro);
  }

  // ignore: unused_element
  static List<Widget> _admissionCaseConference_Legacy(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
  ) {
    // Deserialize attendees from comma-separated string if needed
    List<String> currentAttendees = [];
    if (data['attendees_list'] is List) {
      currentAttendees = List<String>.from(data['attendees_list']);
    } else if (data['attendees'] is String && data['attendees'].isNotEmpty) {
      currentAttendees = (data['attendees'] as String).split(', ');
    }

    return [
      FormFieldBuilders.sectionHeader('ADMISSION CASE CONFERENCE'),
      // System Generated / Read Only Fields
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Date Submitted',
              value: data['date_submitted'] ?? '',
              onChanged: (_) {}, // Read-only
              enabled: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label:
                  'Date Admitted', // Using text field for read-only view of admission date
              value: data['date_admitted']?.toString().split('T')[0] ?? '',
              onChanged: (_) {},
              enabled: false,
            ),
          ),
        ],
      ),

      FormFieldBuilders.textField(
        label: 'Name of Client',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
      ),
      FormFieldBuilders.textField(
        label: 'Age',
        value: data['client_age']?.toString() ?? '',
        onChanged: (v) => onChanged('client_age', v),
        // We allow editing if auto-calc is wrong, but it defaults nicely
      ),

      FormFieldBuilders.dropdown(
        label: 'Case Category',
        value: data['case_category']?.toString().toUpperCase() ?? 'ABANDONED',
        items: FormOptions.caseCategories,
        onChanged: (v) => onChanged('case_category', v),
      ),

      FormFieldBuilders.dropdown(
        label: 'Condition',
        value:
            data['condition']?.toString().toUpperCase() ?? 'NORMAL / HEALTHY',
        items: FormOptions.conditions,
        onChanged: (v) => onChanged('condition', v),
      ),

      FormFieldBuilders.dropdown(
        label: 'Venue',
        value: data['venue'] ?? 'Conference Room',
        items: const [
          'Conference Room',
          'Social Service Unit (SSU) Office',
          'Center Head\'s Office',
          'Multi-Purpose Hall',
          'Psychological Service Unit',
        ],
        onChanged: (v) => onChanged('venue', v),
      ),

      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of Conference',
              value: data['conference_date'],
              onChanged: (v) =>
                  onChanged('conference_date', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.timePicker(
              label: 'Time Allotted',
              value: data['time_allotted'] ?? '',
              onChanged: (v) => onChanged('time_allotted', v),
            ),
          ),
        ],
      ),

      FormFieldBuilders.multiSelect(
        label: 'Present / Attendees',
        values: currentAttendees,
        options: const [
          'Center Head',
          'Social Worker',
          'Houseparent',
          'Nurse',
          'Psychometrician',
          'Dietician',
          'Referring Party',
          'Client/Resident',
          'Guardian/Relative'
        ], // Placeholder roles as we can't easily fetch dynamic users here statically
        allowCustom: true,
        onChanged: (list) {
          onChanged('attendees_list', list);
          onChanged('attendees', list.join(', '));
        },
      ),

      FormFieldBuilders.textArea(
        label: 'Objective',
        value: data['objective'] ?? '',
        onChanged: (v) => onChanged('objective', v),
        hint: '• Objective 1\n• Objective 2',
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Discussions'),
      FormFieldBuilders.textArea(
        label: 'Discussion Points',
        value: data['discussions'] ?? '',
        onChanged: (v) => onChanged('discussions', v),
        required: true,
        hint: '• Point 1\n• Point 2',
      ),
      FormFieldBuilders.textArea(
        label: 'Agreement Reached / Recommendations',
        value: data['agreement_recommendations'] ?? '',
        onChanged: (v) => onChanged('agreement_recommendations', v),
        hint: '• Agreement 1\n• Recommendation 1',
      ),
    ];
  }

  // Case Conference Base (shared layout)
  static List<Widget> _caseConferenceBase(
    String title,
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    // Helper to calculate and format time range
    void updateTimeAllotted(String? newStart, String? newEnd) {
      final start = newStart ?? data['time_started'] as String?;
      final end = newEnd ?? data['time_ended'] as String?;

      onChanged('time_started', start);
      onChanged('time_ended', end);

      if (start == null || start.isEmpty || end == null || end.isEmpty) {
        String formatOne(String? t) {
          if (t == null || t.isEmpty) return '';
          final parts = t.split(':');
          if (parts.length < 2) return t;
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          final period = h >= 12 ? 'PM' : 'AM';
          final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
          return '$h12:${m.toString().padLeft(2, '0')}$period';
        }

        final sFmt = formatOne(start);
        final eFmt = formatOne(end);

        if (sFmt.isNotEmpty && eFmt.isNotEmpty) {
          onChanged('time_allotted', '$sFmt - $eFmt');
        } else if (sFmt.isNotEmpty) {
          onChanged('time_allotted', '$sFmt - ');
        } else if (eFmt.isNotEmpty) {
          onChanged('time_allotted', ' - $eFmt');
        }
        return;
      }

      // Parse and calculate duration
      try {
        final sParts = start.split(':');
        final eParts = end.split(':');
        final sDate =
            DateTime(2020, 1, 1, int.parse(sParts[0]), int.parse(sParts[1]));
        final eDate =
            DateTime(2020, 1, 1, int.parse(eParts[0]), int.parse(eParts[1]));

        var diff = eDate.difference(sDate);
        if (diff.isNegative) {
          // Formatting
          final sH = sDate.hour;
          final sM = sDate.minute;
          final eH = eDate.hour;
          final eM = eDate.minute;

          final sPeriod = sH >= 12 ? 'PM' : 'AM';
          final sH12 = sH > 12 ? sH - 12 : (sH == 0 ? 12 : sH);

          final ePeriod = eH >= 12 ? 'PM' : 'AM';
          final eH12 = eH > 12 ? eH - 12 : (eH == 0 ? 12 : eH);

          final formatted =
              '$sH12:${sM.toString().padLeft(2, '0')}$sPeriod - $eH12:${eM.toString().padLeft(2, '0')}$ePeriod';
          onChanged('time_allotted', formatted);
          return;
        }

        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;

        String durationStr = '';
        if (hours > 0 && minutes > 0) {
          durationStr = '($hours hours $minutes mins)';
        } else if (hours > 0) {
          durationStr = '($hours hours)';
        } else {
          durationStr = '($minutes mins)';
        }

        // Formatting
        final sH = sDate.hour;
        final sM = sDate.minute;
        final eH = eDate.hour;
        final eM = eDate.minute;

        final sPeriod = sH >= 12 ? 'PM' : 'AM';
        final sH12 = sH > 12 ? sH - 12 : (sH == 0 ? 12 : sH);

        final ePeriod = eH >= 12 ? 'PM' : 'AM';
        final eH12 = eH > 12 ? eH - 12 : (eH == 0 ? 12 : eH);

        final formatted =
            '$sH12:${sM.toString().padLeft(2, '0')}$sPeriod - $eH12:${eM.toString().padLeft(2, '0')}$ePeriod $durationStr';

        onChanged('time_allotted', formatted);
      } catch (e) {
        // Fallback
        onChanged('time_allotted', '$start - $end');
      }
    }

    // Helper for "Smart Dropdown" with OTHERS support
    Widget buildSmartDropdown({
      required String label,
      required String key,
      required List<String> items,
      String? defaultValue,
    }) {
      final currentValue = data[key]?.toString() ?? defaultValue ?? '';

      // Check if custom: not distinct in items (case insensitive) and not empty
      final isCustom = currentValue.isNotEmpty &&
          !items.contains(currentValue) &&
          !items
              .map((e) => e.toUpperCase())
              .contains(currentValue.toUpperCase());

      // Determine dropdown value
      String? dropdownValue;
      if (isCustom) {
        dropdownValue = 'OTHERS';
      } else if (items.contains(currentValue)) {
        dropdownValue = currentValue;
      } else {
        // Try case-insensitive match
        try {
          dropdownValue = items
              .firstWhere((e) => e.toUpperCase() == currentValue.toUpperCase());
        } catch (_) {
          dropdownValue = items.first;
        }
      }

      // Ensure OTHERS is in the list
      final dropdownItems = [...items];
      if (!dropdownItems.contains('OTHERS')) {
        dropdownItems.add('OTHERS');
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldBuilders.dropdown(
            label: label,
            value: dropdownValue,
            items: dropdownItems,
            onChanged: (v) {
              if (v == 'OTHERS') {
                // Set to OTHERS triggers text field (and clears value effectively for typing)
                onChanged(key, 'OTHERS');
              } else {
                onChanged(key, v);
              }
            },
          ),
          if (dropdownValue == 'OTHERS' || currentValue == 'OTHERS')
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 0),
              child: FormFieldBuilders.textField(
                label: 'SPECIFY $label',
                value: currentValue == 'OTHERS' ? '' : currentValue,
                hint: 'PLEASE SPECIFY...',
                onChanged: (v) => onChanged(key, v),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
        ],
      );
    }

    return [
      FormFieldBuilders.sectionHeader(title),
      // System Generated / Read Only Fields
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'DATE SUBMITTED',
              // Use formatDate helper or custom format MM/dd/yyyy
              value: AdmissionCaseConferenceForm.formatDate(
                  data['date_submitted']?.toString()),
              onChanged: (_) {}, // Read-only
              enabled: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'DATE ADMITTED',
              value: AdmissionCaseConferenceForm.formatDate(
                  data['date_admitted']?.toString()),
              onChanged: (_) {},
              enabled: false,
            ),
          ),
        ],
      ),

      FormFieldBuilders.textField(
        label: 'NAME OF CLIENT',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v.toUpperCase()),
        required: true,
        textCapitalization: TextCapitalization.characters,
      ),
      FormFieldBuilders.textField(
        label: 'AGE',
        value: data['client_age']?.toString() ?? '',
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged('client_age', v),
      ),
      // Date Admitted is now above as read-only/system field

      FormFieldBuilders.dropdown(
        label: 'CASE CATEGORY',
        value: data['case_category']?.toString().toUpperCase() ?? 'ABANDONED',
        items: FormOptions.caseCategories,
        onChanged: (v) => onChanged('case_category', v),
      ),

      buildSmartDropdown(
        label: 'CONDITION',
        key: 'condition',
        items: FormOptions.conditions,
        defaultValue: 'NORMAL / HEALTHY',
      ),

      buildSmartDropdown(
        label: 'VENUE',
        key: 'venue',
        items: const [
          'CONFERENCE ROOM',
          'SOCIAL SERVICE UNIT (SSU) OFFICE',
          'CENTER HEAD\'S OFFICE',
          'MULTI-PURPOSE HALL',
          'PSYCHOLOGICAL SERVICE UNIT',
        ],
        defaultValue: 'CONFERENCE ROOM',
      ),

      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'DATE OF CONFERENCE',
              value: data['conference_date'],
              onChanged: (v) =>
                  onChanged('conference_date', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: FormFieldBuilders.timePicker(
                    label: 'STARTED',
                    value: data['time_started'] ?? '',
                    onChanged: (v) => updateTimeAllotted(v, null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FormFieldBuilders.timePicker(
                    label: 'ENDED',
                    value: data['time_ended'] ?? '',
                    onChanged: (v) => updateTimeAllotted(null, v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      FormFieldBuilders.bulletList(
        label: 'PRESENT (ATTENDEES)',
        value: data['attendees'] ?? '',
        onChanged: (v) => onChanged('attendees', v),
        useStaffSuggestions: true,
      ),
      FormFieldBuilders.bulletList(
        label: 'OBJECTIVE',
        value: data['objective'] ?? '',
        onChanged: (v) => onChanged('objective', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Discussions'),
      FormFieldBuilders.bulletList(
        label: 'DISCUSSION POINTS',
        value: data['discussions'] ?? '',
        onChanged: (v) => onChanged('discussions', v),
        required: true,
      ),
      FormFieldBuilders.bulletList(
        label: 'AGREEMENT REACHED / RECOMMENDATIONS',
        value: data['agreement_recommendations'] ?? '',
        onChanged: (v) => onChanged('agreement_recommendations', v),
      ),
    ];
  }

  // CLIENT'S CONTRACT
  static List<Widget> _clientsContract(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    // Ensure exactly 2 witnesses for Client's Contract as per user request
    if (data['witnesses'] == null) {
      data['witnesses'] = [
        {'name': '', 'designation': ''},
        {'name': '', 'designation': ''},
      ];
    } else {
      List<dynamic> wl = List.from(data['witnesses']);
      if (wl.length < 2) {
        while (wl.length < 2) {
          wl.add({'name': '', 'designation': ''});
        }
        data['witnesses'] = wl;
      } else if (wl.length > 2) {
        data['witnesses'] = wl.sublist(0, 2);
      }
    }

    return [
      FormFieldBuilders.sectionHeader('CLIENT\'S CONTRACT'),
      FormFieldBuilders.textField(
        label: 'Client Name',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
        readOnly: ro('client_name'),
      ),
      FormFieldBuilders.textField(
        label: 'Age',
        value: data['client_age']?.toString() ?? '',
        onChanged: (v) => onChanged('client_age', v),
        keyboardType: TextInputType.number,
        readOnly: ro('client_age'),
      ),
      // Status field removed as per user request (Auto-populated in PDF)
      /* 
      FormFieldBuilders.textField(
        label: 'Status',
        ...
      ), 
      */
      FormFieldBuilders.textArea(
        label: 'Address',
        value: data['address'] ?? '',
        onChanged: (v) => onChanged('address', v),
        readOnly: ro('address'),
      ),
      // Custodian Name Field Removed as per user request (Auto-populated in PDF)
      /* 
      Builder(builder: (context) { ... } 
      */
      FormFieldBuilders.datePicker(
        label: 'Date Admitted',
        value: data['date_admitted'],
        onChanged: (v) => onChanged('date_admitted', v?.toIso8601String()),
      ),
      FormFieldBuilders.textField(
        label: 'Referred By',
        value: data['referred_by'] ?? '',
        onChanged: (v) => onChanged('referred_by', v),
      ),
      FormFieldBuilders.datePicker(
        label: 'Contract Date',
        value: data['contract_date'],
        onChanged: (v) => onChanged('contract_date', v?.toIso8601String()),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Signed in the presence of:'),
      ...() {
        final witnesses = List<Map<String, dynamic>>.from(data['witnesses'] ??
            [
              {'name': '', 'designation': ''},
              {'name': '', 'designation': ''},
            ]);
        while (witnesses.length < 2) {
          witnesses.add({'name': '', 'designation': ''});
        }
        return [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: FormFieldBuilders.textField(
                  label: 'Witness 1 Name',
                  value: witnesses[0]['name']?.toString() ?? '',
                  onChanged: (v) {
                    witnesses[0]['name'] = v;
                    onChanged('witnesses', witnesses);
                  },
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FormFieldBuilders.editableDropdown(
                  label: 'Designation / Position',
                  value: witnesses[0]['designation']?.toString() ?? '',
                  items: FormOptions.staffDesignations,
                  onChanged: (v) {
                    witnesses[0]['designation'] = v;
                    onChanged('witnesses', witnesses);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: FormFieldBuilders.textField(
                  label: 'Witness 2 Name',
                  value: witnesses[1]['name']?.toString() ?? '',
                  onChanged: (v) {
                    witnesses[1]['name'] = v;
                    onChanged('witnesses', witnesses);
                  },
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FormFieldBuilders.editableDropdown(
                  label: 'Designation / Position',
                  value: witnesses[1]['designation']?.toString() ?? '',
                  items: FormOptions.staffDesignations,
                  onChanged: (v) {
                    witnesses[1]['designation'] = v;
                    onChanged('witnesses', witnesses);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ];
      }(),
      FormFieldBuilders.sectionHeader('Digital Signatures'),
      FormFieldBuilders.digitalSignature(
        label: 'Custodian Signature',
        fieldName: 'custodian_signature_url',
        value: data['custodian_signature_url']?.toString(),
        formId: data['_submission_id']?.toString(),
        onChanged: (url) => onChanged('custodian_signature_url', url),
        required: true,
      ),
      FormFieldBuilders.digitalSignature(
        label: 'Witness 1 Signature',
        fieldName: 'witness1_signature_url',
        value: data['witness1_signature_url']?.toString(),
        formId: data['_submission_id']?.toString(),
        onChanged: (url) => onChanged('witness1_signature_url', url),
        required: true,
      ),
      FormFieldBuilders.digitalSignature(
        label: 'Witness 2 Signature',
        fieldName: 'witness2_signature_url',
        value: data['witness2_signature_url']?.toString(),
        formId: data['_submission_id']?.toString(),
        onChanged: (url) => onChanged('witness2_signature_url', url),
        required: true,
      ),
    ];
  }

  // ADMISSION SLIP
  static List<Widget> _admissionSlip(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('ADMISSION SLIP'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date',
              value: data['admission_date'],
              onChanged: (v) =>
                  onChanged('admission_date', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.timePicker(
              label: 'Time',
              value: data['admission_time'],
              onChanged: (v) => onChanged('admission_time', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Case Control No.',
        value: data['case_control_no'] ?? '',
        onChanged: (v) => onChanged('case_control_no', v),
        readOnly: ro('case_control_no'),
      ),
      FormFieldBuilders.textField(
        label: 'Name of Client',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
        readOnly: ro('client_name'),
      ),
      FormFieldBuilders.textField(
        label: 'Age',
        value: data['client_age']?.toString() ?? '',
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged('client_age', v),
        readOnly: ro('client_age'),
      ),
      FormFieldBuilders.textArea(
        label: 'Complete Address',
        value: data['complete_address'] ?? '',
        onChanged: (v) => onChanged('complete_address', v),
        readOnly: ro('complete_address'),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Civil Status',
              value: data['civil_status'] ?? 'SINGLE',
              items: const ['SINGLE', 'MARRIED', 'WIDOWED', 'SEPARATED'],
              onChanged: (v) => onChanged('civil_status', v),
              readOnly: ro('civil_status'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Religion',
              value: data['religion'] ?? '',
              onChanged: (v) => onChanged('religion', v),
              readOnly: ro('religion'),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Educational Attainment',
        value: data['educational_attainment'] ?? '',
        onChanged: (v) => onChanged('educational_attainment', v),
        readOnly: ro('educational_attainment'),
      ),
      FormFieldBuilders.textField(
        label: 'Referred by',
        value: data['referred_by'] ?? '',
        onChanged: (v) => onChanged('referred_by', v),
        readOnly: ro('referred_by'),
      ),
      FormFieldBuilders.textArea(
        label: 'Complete Address of Referring Party',
        value: data['referring_party_address'] ?? '',
        onChanged: (v) => onChanged('referring_party_address', v),
        readOnly: ro('referring_party_address'),
      ),
      FormFieldBuilders.textArea(
        label: 'Name and Address of Nearest Relative',
        value: data['nearest_relative'] ?? '',
        onChanged: (v) => onChanged('nearest_relative', v),
        readOnly: ro('nearest_relative'),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.multiSelect(
        label: 'Medical Findings/Clearance',
        values: data['medical_findings'] is List
            ? List<String>.from(data['medical_findings'])
            : (data['medical_findings']?.toString().split(', ') ?? []),
        options: const [
          'Fit for Admission',
          'With Maintenance Medication',
          'With Communicable Disease',
          'Physically Disabled',
          'Bedridden',
          'Ambulatory',
        ],
        allowCustom: true,
        onChanged: (v) {
          // Save as comma-separated string for compatibility with text field usage
          onChanged('medical_findings', v.join(', '));
        },
      ),
      FormFieldBuilders.textField(
        label: 'Assigned to Room',
        value: data['assigned_room'] ?? '',
        onChanged: (v) => onChanged('assigned_room', v),
        readOnly: ro('assigned_room'),
      ),
    ];
  }

  // PROGRESS NOTES
  static List<Widget> _progressNotes(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('PROGRESS NOTES'),
      FormFieldBuilders.textField(
        label: 'Name of Client',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
        readOnly: ro('client_name'),
      ),
      FormFieldBuilders.datePicker(
        label: 'Date',
        value: data['progress_date'],
        onChanged: (v) => onChanged('progress_date', v?.toIso8601String()),
      ),
      FormFieldBuilders.textArea(
        label: 'Observations',
        value: data['observations'] ?? '',
        onChanged: (v) => onChanged('observations', v),
        required: true,
        maxLines: 8,
        hint:
            'E.g., Interaction with peers, participation in activities, behavior during social gatherings, relationship with staff/visitors...',
      ),
      FormFieldBuilders.textArea(
        label: 'Supervisory Remarks',
        value: data['supervisory_remarks'] ?? '',
        onChanged: (v) => onChanged('supervisory_remarks', v),
        hint: "E.g., Supervisor's comments, approval, directives...",
      ),
    ];
  }

  // RUNNING NOTES
  static List<Widget> _runningNotes(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('RUNNING NOTES'),
      FormFieldBuilders.textField(
        label: 'Name of Client',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
        readOnly: ro('client_name'),
      ),
      FormFieldBuilders.datePicker(
        label: 'Date',
        value: data['running_date'],
        onChanged: (v) => onChanged('running_date', v?.toIso8601String()),
      ),
      FormFieldBuilders.textArea(
        label: 'Notes / Observations',
        value: data['notes'] ?? '',
        onChanged: (v) => onChanged('notes', v),
        required: true,
        maxLines: 10,
      ),
      FormFieldBuilders.textArea(
        label: 'Supervisory Remarks',
        value: data['supervisory_remarks'] ?? '',
        onChanged: (v) => onChanged('supervisory_remarks', v),
      ),
    ];
  }

  // INTERVENTION PLAN
  static List<Widget> _interventionPlan(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('MODIFIED INTERVENTION PLAN'),
      FormFieldBuilders.datePicker(
        label: 'Date Prepared',
        value: data['date_prepared'],
        onChanged: (v) => onChanged('date_prepared', v?.toIso8601String()),
      ),
      FormFieldBuilders.textField(
        label: 'Name of Client',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
        readOnly: ro('client_name'),
      ),
      FormFieldBuilders.textField(
        label: 'Case Control No.',
        value: data['case_control_no'] ?? '',
        onChanged: (v) => onChanged('case_control_no', v),
        readOnly: ro('case_control_no'),
      ),
      // Goal Section with Date Range
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Goal'),
      const Text(
        'In three (3) months - time:',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Checkbox(
            value: data['goal_use_custom'] ?? false,
            onChanged: (v) => onChanged('goal_use_custom', v),
          ),
          const Text('Specify manually'),
        ],
      ),
      if (data['goal_use_custom'] == true)
        FormFieldBuilders.textField(
          label: 'Goal Period (Manual)',
          value: data['goal_period_text'] ?? '',
          onChanged: (v) => onChanged('goal_period_text', v),
        )
      else
        Row(
          children: [
            Expanded(
              child: FormFieldBuilders.datePicker(
                label: 'Start Date',
                value: data['goal_start_date'],
                onChanged: (v) =>
                    onChanged('goal_start_date', v?.toIso8601String()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormFieldBuilders.datePicker(
                label: 'End Date',
                value: data['goal_end_date'],
                onChanged: (v) =>
                    onChanged('goal_end_date', v?.toIso8601String()),
              ),
            ),
          ],
        ),
      const SizedBox(height: 8),
      const Text(
        'Client\'s social functioning will be sustained.',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Intervention Details'),
      _ActivitiesTable(
        activities: data['activities'] is List ? data['activities'] : [],
        onChanged: (items) => onChanged('activities', items),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Signatory'),
      FormFieldBuilders.digitalSignature(
        label: 'Confirmed by Client',
        fieldName: 'client_signature_url',
        value: data['client_signature_url'],
        formId: data['id'],
        onChanged: (v) => onChanged('client_signature_url', v),
        required: true,
      ),
    ];
  }

  // INITIAL SOCIAL CASE STUDY REPORT
  static List<Widget> _initialSocialCaseStudy(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('SOCIAL CASE STUDY REPORT'),
      ..._socialCaseStudyBase(data, onChanged, ro: ro),
    ];
  }

  // UPDATED SOCIAL CASE STUDY REPORT
  static List<Widget> _updatedSocialCaseStudy(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('UPDATED SOCIAL CASE STUDY REPORT'),
      ..._socialCaseStudyBase(data, onChanged, ro: ro),
    ];
  }

  static List<Widget> _socialCaseStudyBase(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date',
              value: data['report_date'],
              onChanged: (v) => onChanged('report_date', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Year Admitted',
              value: data['year_admitted'] ?? '',
              onChanged: (v) => onChanged('year_admitted', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Case No.',
              value: data['case_no'] ?? '',
              onChanged: (v) => onChanged('case_no', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Length of Stay',
              value: (data['length_of_stay'] ?? '').toString().toUpperCase(),
              onChanged: (v) => onChanged('length_of_stay', v.toUpperCase()),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
        ],
      ),
      FormFieldBuilders.dropdown(
        label: 'Older Person Category',
        value: (data['category'] ?? 'ABANDONED').toString().toUpperCase(),
        items: const ['ABANDONED', 'NEGLECTED', 'UNATTACHED', 'HOMELESS'],
        onChanged: (v) => onChanged('category', v?.toUpperCase()),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Identifying Data'),
      FormFieldBuilders.textField(
        label: 'Name',
        value: data['name'] ?? '',
        onChanged: (v) => onChanged('name', v),
        required: true,
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['age']?.toString() ?? '',
              onChanged: (v) => onChanged('age', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Sex',
              value: (data['sex']?.toString().toUpperCase() == 'FEMALE'
                  ? 'FEMALE'
                  : (data['sex']?.toString().toUpperCase() == 'MALE'
                      ? 'MALE'
                      : null)),
              items: const ['MALE', 'FEMALE'],
              onChanged: (v) => onChanged('sex', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Civil Status',
              value:
                  (data['civil_status'] ?? 'SINGLE').toString().toUpperCase(),
              items: const ['SINGLE', 'MARRIED', 'WIDOWED', 'SEPARATED'],
              onChanged: (v) => onChanged('civil_status', v?.toUpperCase()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Birth Date',
              value: data['birth_date'],
              onChanged: (v) => onChanged('birth_date', v?.toIso8601String()),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Birth Place',
        value: data['birth_place'] ?? '',
        onChanged: (v) => onChanged('birth_place', v),
      ),
      FormFieldBuilders.textField(
        label: 'Educational Attainment',
        value: data['educational_attainment'] ?? '',
        onChanged: (v) => onChanged('educational_attainment', v),
      ),
      FormFieldBuilders.textField(
        label: 'Religion',
        value: data['religion'] ?? '',
        onChanged: (v) => onChanged('religion', v),
      ),
      FormFieldBuilders.textArea(
        label: 'Provincial Address',
        value: data['address'] ?? '',
        onChanged: (v) => onChanged('address', v),
      ),
      FormFieldBuilders.textField(
        label: 'Source of Referral',
        value: data['referral_source'] ?? '',
        onChanged: (v) => onChanged('referral_source', v),
      ),
      FormFieldBuilders.textField(
        label: 'Name of Referring Party',
        value: data['referring_party'] ?? '',
        onChanged: (v) => onChanged('referring_party', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Case Details'),
      _FamilyCompositionTable(
        members: data['family_composition'] is List
            ? data['family_composition']
            : [],
        onChanged: (members) => onChanged('family_composition', members),
      ),
      FormFieldBuilders.textArea(
        label: 'Problem Presented',
        value: data['problem_presented'] ?? '',
        onChanged: (v) => onChanged('problem_presented', v),
        required: true,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Background of the Case'),
      FormFieldBuilders.textArea(
        label: 'Findings',
        value: data['findings'] ?? '',
        onChanged: (v) => onChanged('findings', v),
      ),
      FormFieldBuilders.textArea(
        label: 'Medical and Nutritional Needs',
        value: data['medical_nutritional_needs'] ?? '',
        onChanged: (v) => onChanged('medical_nutritional_needs', v),
      ),
      FormFieldBuilders.textArea(
        label: 'Level of Social Functioning',
        value: data['social_functioning'] ?? '',
        onChanged: (v) => onChanged('social_functioning', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Intervention Plan'),
      FormFieldBuilders.textArea(
        label: 'Plan',
        value: data['intervention_plan'] ?? '',
        onChanged: (v) => onChanged('intervention_plan', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Assessment'),
      FormFieldBuilders.textArea(
        label: 'Social Worker\'s Assessment',
        value: data['assessment'] ?? '',
        onChanged: (v) => onChanged('assessment', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Recommendation'),
      FormFieldBuilders.textArea(
        label: 'Recommendation',
        value: data['recommendation'] ?? '',
        onChanged: (v) => onChanged('recommendation', v),
      ),
    ];
  }

  // CASE CONFERENCE (Regular/Emergency/Discharge)
  static List<Widget> _caseConference(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.dropdown(
        label: 'Conference Type',
        value: data['conference_type'] ?? 'regular',
        items: const ['Regular', 'Emergency', 'Pre-Discharge', 'Discharge'],
        onChanged: (v) => onChanged('conference_type', v),
      ),
      ..._caseConferenceBase('CASE CONFERENCE', data, onChanged, ro: ro),
    ];
  }

  // TERMINATION REPORT
  // TERMINATION REPORT
  static List<Widget> _terminationReport(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('TERMINATION REPORT',
          showUnderline: false),

      // I. Identifying Information (Vertical Stack to match Table format)
      FormFieldBuilders.sectionHeader('IDENTIFYING INFORMATION:',
          showUnderline: false),
      FormFieldBuilders.textField(
        label: 'Name of Resident',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
      ),
      FormFieldBuilders.textField(
        label: 'Age',
        value: data['client_age']?.toString() ?? '',
        onChanged: (v) => onChanged('client_age', v),
      ),
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Sex',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        // style: removed to use default theme
        initialValue: (data['sex']?.toString().toUpperCase() == 'FEMALE'
            ? 'FEMALE'
            : (data['sex']?.toString().toUpperCase() == 'MALE'
                ? 'MALE'
                : null)),
        items: const [
          DropdownMenuItem(value: 'MALE', child: Text('MALE')),
          DropdownMenuItem(value: 'FEMALE', child: Text('FEMALE')),
        ],
        onChanged: (v) => onChanged('sex', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.datePicker(
        label: 'Date of Admission',
        value: data['date_admitted'],
        onChanged: (v) => onChanged('date_admitted', v?.toIso8601String()),
      ),
      FormFieldBuilders.datePicker(
        label: 'Date of Discharged',
        value: data['date_discharged'],
        onChanged: (v) => onChanged('date_discharged', v?.toIso8601String()),
      ),
      FormFieldBuilders.dropdown(
        label: 'Case Category',
        value: (data['case_category'] ?? 'ABANDONED').toString().toUpperCase(),
        items: const ['ABANDONED', 'NEGLECTED', 'UNATTACHED', 'HOMELESS'],
        onChanged: (v) => onChanged('case_category', v),
      ),
      FormFieldBuilders.textField(
        label: 'Length of Stay',
        value: data['length_of_stay'] ?? '',
        onChanged: (v) => onChanged('length_of_stay', v),
      ),
      FormFieldBuilders.textField(
        label: 'Name/ Relation to the person Discharged',
        value: data['custodian_name'] ?? '',
        onChanged: (v) => onChanged('custodian_name', v),
      ),
      FormFieldBuilders.textArea(
        label: 'Address',
        value: data['address'] ?? '',
        onChanged: (v) => onChanged('address', v),
        maxLines: 3,
      ),
      const SizedBox(height: 16),

      // II. Narrative Sections
      FormFieldBuilders.sectionHeader(
          'REASON FOR CLIENT\'S ADMISSION AT THE HOME FOR THE AGED:',
          showUnderline: false),
      FormFieldBuilders.textArea(
        label: 'Reason',
        value: data['admission_reason'] ?? '',
        onChanged: (v) => onChanged('admission_reason', v),
        required: true,
        maxLines: 5,
      ),

      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('INTERVENTION PROVIDED BY THE HA:',
          showUnderline: false),
      FormFieldBuilders.textArea(
        label: 'Intervention Provided',
        value: data['intervention_provided'] ?? '',
        onChanged: (v) => onChanged('intervention_provided', v),
        maxLines: 5,
      ),

      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader(
          'SOCIAL FUNCTIONING OF THE RESIDENT UPON DISCHARGE:',
          showUnderline: false),
      FormFieldBuilders.textArea(
        label: 'Social Functioning',
        value: data['social_functioning'] ?? '',
        onChanged: (v) => onChanged('social_functioning', v),
        maxLines: 5,
      ),

      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('WHY THE CASE IS BEING CLOSED:',
          showUnderline: false),
      FormFieldBuilders.textArea(
        label: 'Reason for Closing',
        value: data['closing_reason'] ?? '',
        onChanged: (v) => onChanged('closing_reason', v),
        maxLines: 5,
      ),

      const SizedBox(height: 16),
      FormFieldBuilders.textArea(
        label: 'Recommendations',
        value: data['recommendations'] ?? '',
        onChanged: (v) => onChanged('recommendations', v),
        maxLines: 5,
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('Digital Signatures',
          showUnderline: false),
      FormFieldBuilders.digitalSignature(
        label: 'Division Chief Signature',
        fieldName: 'division_chief_signature_url',
        value: data['division_chief_signature_url'],
        formId: data['id'],
        onChanged: (v) => onChanged('division_chief_signature_url', v),
        required: true,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.digitalSignature(
        label: 'Regional Director Signature',
        fieldName: 'regional_director_signature_url',
        value: data['regional_director_signature_url'],
        formId: data['id'],
        onChanged: (v) => onChanged('regional_director_signature_url', v),
        required: true,
      ),
    ];
  }

  // CLOSING SUMMARY
  static List<Widget> _closingSummary(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('CLOSING SUMMARY'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date',
              value: data['closing_date'] ?? DateTime.now().toIso8601String(),
              onChanged: (v) => onChanged('closing_date', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Case No.',
              value: data['case_no'] ?? '',
              onChanged: (v) => onChanged('case_no', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Name',
        value: data['name'] ?? '',
        onChanged: (v) => onChanged('name', v),
        required: true,
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['age']?.toString() ?? '',
              onChanged: (v) => onChanged('age', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Gender',
              value: (data['gender'] ?? 'MALE').toString().toUpperCase(),
              items: const ['MALE', 'FEMALE'],
              onChanged: (v) => onChanged('gender', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textArea(
        label: 'Address',
        value: data['address'] ?? '',
        onChanged: (v) => onChanged('address', v),
      ),
      FormFieldBuilders.textField(
        label: 'Source of Referral',
        value: data['referral_source'] ?? '',
        onChanged: (v) => onChanged('referral_source', v),
      ),
      FormFieldBuilders.datePicker(
        label: 'Date Admitted',
        value: data['date_admitted'],
        onChanged: (v) => onChanged('date_admitted', v?.toIso8601String()),
      ),
      FormFieldBuilders.textArea(
        label: 'Summary of Case',
        value: data['case_summary'] ?? '',
        onChanged: (v) => onChanged('case_summary', v),
        required: true,
        maxLines: 8,
      ),
      FormFieldBuilders.textArea(
        label: 'Address of Referring Party',
        value: data['referring_party_address'] ?? '',
        onChanged: (v) => onChanged('referring_party_address', v),
      ),
      FormFieldBuilders.datePicker(
        label: 'Date of Discharge',
        value: data['date_discharged'],
        onChanged: (v) => onChanged('date_discharged', v?.toIso8601String()),
      ),
    ];
  }

  // QUARTERLY PROGRESS NARRATIVE REPORT
  static List<Widget> _quarterlyNarrative(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('QUARTERLY PROGRESS NARRATIVE REPORT'),
      FormFieldBuilders.textField(
        label: 'Name of Client',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
      ),
      FormFieldBuilders.datePicker(
        label: 'Date',
        value: data['report_date'],
        onChanged: (v) => onChanged('report_date', v?.toIso8601String()),
      ),
      FormFieldBuilders.dropdown(
        label: 'Quarter',
        value: data['quarter'] ?? '1st',
        items: const ['1st', '2nd', '3rd', '4th'],
        onChanged: (v) => onChanged('quarter', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Service Reports'),
      FormFieldBuilders.textArea(
        label: 'Social Service',
        value: data['social_service'] ?? '',
        onChanged: (v) => onChanged('social_service', v),
      ),
      FormFieldBuilders.textArea(
        label: 'Medical Service',
        value: data['medical_service'] ?? '',
        onChanged: (v) => onChanged('medical_service', v),
      ),
      FormFieldBuilders.textArea(
        label: 'Psych Service',
        value: data['psych_service'] ?? '',
        onChanged: (v) => onChanged('psych_service', v),
      ),
      FormFieldBuilders.textArea(
        label: 'Homelife Service',
        value: data['homelife_service'] ?? '',
        onChanged: (v) => onChanged('homelife_service', v),
      ),
      FormFieldBuilders.textArea(
        label: 'PSD Service',
        value: data['psd_service'] ?? '',
        onChanged: (v) => onChanged('psd_service', v),
        maxLines: 5,
      ),
    ];
  }

  // PRE-TERMINATION / PRE-DISCHARGE PLAN
  static List<Widget> _preTerminationPlan(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('PRE-TERMINATION/ PRE-DISCHARGE PLAN'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date',
              value: data['date_prepared'],
              onChanged: (v) =>
                  onChanged('date_prepared', v?.toIso8601String()),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: FormFieldBuilders.textField(
              label: 'Name of Client',
              value: data['client_name'] ?? '',
              onChanged: (v) => onChanged('client_name', v),
              required: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['client_age']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('client_age', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date Admitted',
              value: data['date_admitted'],
              onChanged: (v) =>
                  onChanged('date_admitted', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Case Category',
              value: data['case_category'] ?? '',
              onChanged: (v) => onChanged('case_category', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Condition',
        value: data['condition'] ?? '',
        onChanged: (v) => onChanged('condition', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Objectives'),
      FormFieldBuilders.textArea(
        label:
            'Objective (e.g. To come-up with specific plan of client termination)',
        value: data['objective'] ?? '',
        onChanged: (v) => onChanged('objective', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Activities / Plan'),
      Builder(
        builder: (context) {
          // Ensure we have a list of maps, initializing if null or empty
          final activities = (data['activities'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [{}];

          if (activities.isEmpty) activities.add({});

          void updateActivities() {
            onChanged('activities', activities);
          }

          void addActivity() {
            activities.add({});
            updateActivities();
          }

          void removeActivity(int index) {
            activities.removeAt(index);
            if (activities.isEmpty) {
              activities.add({});
            }
            updateActivities();
          }

          void updateField(int index, String key, dynamic value) {
            activities[index][key] = value;
            updateActivities();
          }

          return Column(
            children: [
              for (int i = 0; i < activities.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).cardColor,
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Activity ${i + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            if (activities.length > 1)
                              IconButton(
                                icon: const Icon(LucideIcons.trash2,
                                    color: Colors.red),
                                onPressed: () => removeActivity(i),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FormFieldBuilders.textArea(
                          label: 'Description',
                          value: activities[i]['description'] ?? '',
                          onChanged: (v) => updateField(i, 'description', v),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: FormFieldBuilders.textField(
                                label: 'Responsible Person',
                                value: activities[i]['responsible'] ?? '',
                                onChanged: (v) =>
                                    updateField(i, 'responsible', v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: FormFieldBuilders.datePicker(
                                label: 'Start',
                                value: activities[i]['start'],
                                onChanged: (v) => updateField(
                                    i, 'start', v?.toIso8601String()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: FormFieldBuilders.datePicker(
                                label: 'End',
                                value: activities[i]['end'],
                                onChanged: (v) =>
                                    updateField(i, 'end', v?.toIso8601String()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (activities.length < 50)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: addActivity,
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Add Activity'),
                  ),
                ),
            ],
          );
        },
      ),
    ];
  }

  // PRE-DISCHARGE CASE CONFERENCE

  // AFTER CARE PLAN
  static List<Widget> _afterCarePlan(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('AFTER CARE PLAN'),

      // Identifying Information
      FormFieldBuilders.datePicker(
        label: 'Date',
        value: data['date_prepared'],
        onChanged: (v) => onChanged('date_prepared', v?.toIso8601String()),
      ),
      FormFieldBuilders.textField(
        label: 'Name of Client',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
      ),
      FormFieldBuilders.textField(
        label: 'Age',
        value: data['client_age']?.toString() ?? '',
        onChanged: (v) => onChanged('client_age', v),
      ),
      FormFieldBuilders.datePicker(
        label: 'Date Admitted',
        value: data['date_admitted'],
        onChanged: (v) => onChanged('date_admitted', v?.toIso8601String()),
      ),
      FormFieldBuilders.textField(
        label: 'Case Category',
        value: data['case_category'] ?? '',
        onChanged: (v) => onChanged('case_category', v),
      ),
      FormFieldBuilders.textField(
        label: 'Condition',
        value: data['condition'] ?? '',
        onChanged: (v) => onChanged('condition', v),
      ),
      FormFieldBuilders.datePicker(
        label: 'Date of Discharge',
        value: data['date_discharged'],
        onChanged: (v) => onChanged('date_discharged', v?.toIso8601String()),
      ),
      const SizedBox(height: 16),

      // Objective
      FormFieldBuilders.bulletList(
        label: 'Objective',
        value: data['objective'] ?? '',
        onChanged: (v) => onChanged('objective', v),
      ),
      const SizedBox(height: 16),

      // Activities Table (Dynamic)
      FormFieldBuilders.sectionHeader('Activities / Plan Details'),
      Builder(
        builder: (context) {
          final activities = (data['activities'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [{}];

          if (activities.isEmpty) activities.add({});

          void updateActivities() {
            onChanged('activities', activities);
          }

          void addActivity() {
            activities.add({});
            updateActivities();
          }

          void removeActivity(int index) {
            activities.removeAt(index);
            if (activities.isEmpty) {
              activities.add({});
            }
            updateActivities();
          }

          void updateField(int index, String key, dynamic value) {
            activities[index][key] = value;
            updateActivities();
          }

          return Column(
            children: [
              for (int i = 0; i < activities.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).cardColor,
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Activity ${i + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            if (activities.length > 1)
                              IconButton(
                                icon: const Icon(LucideIcons.trash2,
                                    color: Colors.red),
                                onPressed: () => removeActivity(i),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FormFieldBuilders.textArea(
                          label: 'Activity',
                          value: activities[i]['activity'] ?? '',
                          onChanged: (v) => updateField(i, 'activity', v),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: FormFieldBuilders.timePicker(
                                label: 'STARTED',
                                value: activities[i]['time_started'] ?? '',
                                onChanged: (v) =>
                                    updateField(i, 'time_started', v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: FormFieldBuilders.timePicker(
                                label: 'ENDED',
                                value: activities[i]['time_ended'] ?? '',
                                onChanged: (v) =>
                                    updateField(i, 'time_ended', v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FormFieldBuilders.textArea(
                          label: 'Responsible Person',
                          value: activities[i]['responsible_person'] ?? '',
                          onChanged: (v) =>
                              updateField(i, 'responsible_person', v),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        FormFieldBuilders.textArea(
                          label: 'Remarks',
                          value: activities[i]['remarks'] ?? '',
                          onChanged: (v) => updateField(i, 'remarks', v),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              if (activities.length < 50)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: addActivity,
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Add Activity'),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('Digital Signatures'),
      FormFieldBuilders.digitalSignature(
        label: 'C/MSWDO Signature',
        fieldName: 'cmswdo_signature_url',
        value: data['cmswdo_signature_url']?.toString(),
        formId: data['_submission_id']?.toString(),
        onChanged: (url) => onChanged('cmswdo_signature_url', url),
        required: true,
      ),
    ];
  }

  // CASE TRANSFER SUMMARY
  static List<Widget> _caseTransferSummary(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('CASE TRANSFER SUMMARY'),
      FormFieldBuilders.datePicker(
        label: 'Date Turned-over',
        value: data['date_turnover'],
        onChanged: (v) => onChanged('date_turnover', v?.toIso8601String()),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('I. IDENTIFYING INFORMATION'),
      const SizedBox(height: 8),
      const Text('1. Personal Data',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      FormFieldBuilders.textField(
        label: 'Name',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['age']?.toString() ?? '',
              onChanged: (v) => onChanged('age', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Gender',
              value: data['sex']?.toString().toUpperCase() ??
                  data['gender']?.toString().toUpperCase() ??
                  'MALE',
              items: ['MALE', 'FEMALE'],
              onChanged: (v) => onChanged('sex', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Civil Status',
        value: data['civil_status'] ?? '',
        onChanged: (v) => onChanged('civil_status', v),
      ),
      FormFieldBuilders.textField(
        label: 'Birth Place',
        value: data['place_of_birth'] ?? data['birthplace'] ?? '',
        onChanged: (v) => onChanged('place_of_birth', v),
      ),
      FormFieldBuilders.datePicker(
        label: 'Birth Date',
        value: data['date_of_birth'],
        onChanged: (v) => onChanged('date_of_birth', v?.toIso8601String()),
      ),
      FormFieldBuilders.textField(
        label: 'Educational Attainment',
        value: data['educational_attainment'] ?? '',
        onChanged: (v) => onChanged('educational_attainment', v),
      ),
      FormFieldBuilders.textField(
        label: 'Religion',
        value: data['religion'] ?? '',
        onChanged: (v) => onChanged('religion', v),
      ),
      FormFieldBuilders.textField(
        label: 'Provincial Address',
        value: data['provincial_address'] ?? '',
        onChanged: (v) => onChanged('provincial_address', v),
      ),
      FormFieldBuilders.textField(
        label: 'Source of Referral',
        value: data['source_of_referral'] ?? '',
        onChanged: (v) => onChanged('source_of_referral', v),
      ),
      FormFieldBuilders.datePicker(
        label: 'Date Admitted',
        value: data['date_admitted'],
        onChanged: (v) => onChanged('date_admitted', v?.toIso8601String()),
      ),
      FormFieldBuilders.textField(
        label: 'Case No.',
        value: data['case_no'] ?? '',
        onChanged: (v) => onChanged('case_no', v),
      ),
      FormFieldBuilders.textField(
        label: 'Case Category',
        value: data['case_category'] ?? '',
        onChanged: (v) => onChanged('case_category', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('II. BACKGROUND OF THE CASE'),
      FormFieldBuilders.textArea(
        label: 'Details',
        value: data['background_of_case'] ?? '',
        onChanged: (v) => onChanged('background_of_case', v),
        maxLines: 8,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('III. RECOMMENDATIONS'),
      FormFieldBuilders.textArea(
        label: 'Details',
        value: data['recommendations'] ?? '',
        onChanged: (v) => onChanged('recommendations', v),
        maxLines: 6,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Digital Signatures'),
      FormFieldBuilders.digitalSignature(
        label: 'C/MSWDO Signature',
        fieldName: 'received_by_signature_url',
        value: data['received_by_signature_url'],
        formId: data['id'],
        onChanged: (v) => onChanged('received_by_signature_url', v),
        required: true,
      ),
    ];
  }

  // CLIENT'S PHOTO PAGE
  static List<Widget> _clientPhoto(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    // This is primarily for print, but we show fields here to edit if needed
    return [
      FormFieldBuilders.sectionHeader('CLIENT\'S PHOTO PAGE'),
      Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Builder(
          builder: (context) => Text(
            'This form is a printable cover page with the client\'s photo.',
            style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ),
      ),
      // In a real app, we would show the actual photo here
      FormFieldBuilders.imagePicker(
        label: 'Client Photo',
        value: data['photo_url'],
        onChanged: (v) => onChanged('photo_url', v),
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.textField(
        label: 'Name',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
      ),
      FormFieldBuilders.textField(
        label: 'Age',
        value: data['client_age']?.toString() ?? '',
        onChanged: (v) => onChanged('client_age', v),
      ),
      FormFieldBuilders.textField(
        label: 'Address',
        value: data['address'] ?? '',
        onChanged: (v) => onChanged('address', v),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Gender',
              value: data['gender']?.toString().toUpperCase() ??
                  data['sex']?.toString().toUpperCase() ??
                  'MALE',
              items: ['MALE', 'FEMALE'],
              onChanged: (v) => onChanged('gender', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Civil Status',
              value: data['civil_status']?.toString().toUpperCase() ?? '',
              onChanged: (v) => onChanged('civil_status', v.toUpperCase()),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of Birth',
              value: data['date_of_birth'],
              onChanged: (v) =>
                  onChanged('date_of_birth', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Place of Birth',
              value: data['place_of_birth'] ?? '',
              onChanged: (v) => onChanged('place_of_birth', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Educational Attainment',
        value: data['educ_attainment'] ?? '',
        onChanged: (v) => onChanged('educ_attainment', v),
      ),
      FormFieldBuilders.textField(
        label: 'Category',
        value: data['category'] ?? '',
        onChanged: (v) => onChanged('category', v),
      ),
    ];
  }

  // PRE-ADMISSION CASE CONFERENCE
  static List<Widget> _preAdmissionConference(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('PRE-ADMISSION CASE CONFERENCE'),
      ..._caseConferenceBase('Identifying Information', data, onChanged, ro: ro)
          .sublist(1),
    ];
  }

  // CLIENT'S KASUNDUAN
  static List<Widget> _kasunduan(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('CLIENT\'S KASUNDUAN'),
      Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Builder(
          builder: (context) => Text(
            'Please verify the client details below. These will be used in the generated agreement.',
            style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ),
      ),
      FormFieldBuilders.textField(
        label: 'Name of Client',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
        readOnly: ro('client_name'),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['age']?.toString() ?? '',
              onChanged: (v) => onChanged('age', v),
              readOnly: ro('age'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Status',
              value: data['status']?.toString().toUpperCase() ?? '',
              onChanged: (v) => onChanged('status', v.toUpperCase()),
              readOnly: ro('status'),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Resident of',
        value: data['resident_of'] ?? '',
        onChanged: (v) => onChanged('resident_of', v),
        readOnly: ro('resident_of'),
      ),
      // Let's add a date field just in case.
      const SizedBox(height: 16),
      FormFieldBuilders.datePicker(
        label: 'Date Signed',
        value: data['date_signed'],
        onChanged: (v) => onChanged('date_signed', v?.toIso8601String()),
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('Digital Signatures'),
      FormFieldBuilders.digitalSignature(
        label: 'Client Signature',
        fieldName: 'client_signature_url',
        value: data['client_signature_url']?.toString(),
        formId: data['_submission_id']?.toString(),
        onChanged: (url) => onChanged('client_signature_url', url),
        required: true,
      ),
    ];
  }

  // PRE-DISCHARGE CASE CONFERENCE
  static List<Widget> _preDischargeConference(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('PRE-DISCHARGE CASE CONFERENCE'),
      ..._caseConferenceBase('Identifying Information', data, onChanged, ro: ro)
          .sublist(1),
    ];
  }

  // DISCHARGE SLIP
  static List<Widget> _dischargeSlip(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('DISCHARGED SLIP'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date',
              value: data['discharge_date'],
              onChanged: (v) =>
                  onChanged('discharge_date', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.timePicker(
              label: 'Time',
              value: data['discharge_time'],
              onChanged: (v) => onChanged('discharge_time', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Case No.',
        value: data['case_no'] ?? '',
        onChanged: (v) => onChanged('case_no', v),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Name of Resident',
              value: data['resident_name'] ?? '',
              onChanged: (v) => onChanged('resident_name', v),
              required: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['age']?.toString() ?? '',
              onChanged: (v) => onChanged('age', v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Custodian Information'),
      FormFieldBuilders.textField(
        label: 'Custodian Name',
        value: data['custodian_name'] ?? '',
        onChanged: (v) => onChanged('custodian_name', v),
      ),
      FormFieldBuilders.textField(
        label: 'Relationship',
        value: data['custodian_relationship'] ?? '',
        onChanged: (v) => onChanged('custodian_relationship', v),
      ),
      FormFieldBuilders.textField(
        label: 'Address',
        value: data['custodian_address'] ?? '',
        onChanged: (v) => onChanged('custodian_address', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Medical Findings / Recommendations'),
      Builder(
        builder: (context) {
          final findings = (data['medical_findings'] is List)
              ? List<String>.from(data['medical_findings'])
              : <String>[''];

          if (findings.isEmpty) findings.add('');

          void updateFindings() {
            onChanged('medical_findings', findings);
          }

          return Column(
            children: [
              for (int i = 0; i < findings.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: FormFieldBuilders.textField(
                          label: 'Finding ${i + 1}',
                          value: findings[i],
                          onChanged: (v) {
                            findings[i] = v;
                            updateFindings();
                          },
                        ),
                      ),
                      if (findings.length > 1)
                        IconButton(
                          icon:
                              const Icon(LucideIcons.trash2, color: Colors.red),
                          onPressed: () {
                            findings.removeAt(i);
                            updateFindings();
                          },
                        ),
                    ],
                  ),
                ),
              if (findings.length < 20)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      findings.add('');
                      updateFindings();
                    },
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Add Finding'),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Digital Signatures'),
      FormFieldBuilders.digitalSignature(
        label: 'Receiving Party Signature',
        fieldName: 'receiving_party_signature_url',
        value: data['receiving_party_signature_url']?.toString(),
        formId: data['_submission_id']?.toString(),
        onChanged: (url) => onChanged('receiving_party_signature_url', url),
        required: true,
      ),
      const SizedBox(height: 12),
      FormFieldBuilders.digitalSignature(
        label: 'C/MSWDO Signature',
        fieldName: 'cmswdo_signature_url',
        value: data['cmswdo_signature_url']?.toString(),
        formId: data['_submission_id']?.toString(),
        onChanged: (url) => onChanged('cmswdo_signature_url', url),
        required: true,
      ),
    ];
  }

  // DISCHARGE CASE CONFERENCE

  static Widget _buildWitnessList(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool isFixed = false,
  }) {
    if (data['witnesses'] == null) {
      data['witnesses'] = <Map<String, dynamic>>[];
    }
    List<Map<String, dynamic>> witnesses =
        List<Map<String, dynamic>>.from(data['witnesses']);

    // Filter witnesses for display if exclude_preparer is set
    // Note: We're filtering the DISPLAY, but we're operating on the main list index.
    // This can be tricky. A better approach for the UI is to show all but hide the row if it matches.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        FormFieldBuilders.sectionHeader('Signed in the presence of:'),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: witnesses.length,
          separatorBuilder: (context, index) {
            final isPreparer = _isPreparer(witnesses[index], data);
            if (data['exclude_preparer'] == true && isPreparer) {
              return const SizedBox.shrink();
            }
            return const SizedBox(height: 12);
          },
          itemBuilder: (context, index) {
            final isPreparer = _isPreparer(witnesses[index], data);
            if (data['exclude_preparer'] == true && isPreparer) {
              return const SizedBox.shrink();
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: FormFieldBuilders.typeAhead(
                    label: 'Witness Name',
                    value: witnesses[index]['name'] ?? '',
                    onChanged: (v) {
                      witnesses[index]['name'] = v;

                      // Auto-populate designation
                      final nameLower = v.trim().toLowerCase();
                      final endorsedBy = (data['endorsed_by'] ?? '')
                          .toString()
                          .trim()
                          .toLowerCase();
                      final referredBy = (data['referred_by'] ?? '')
                          .toString()
                          .trim()
                          .toLowerCase();
                      final referringContact =
                          (data['referring_contact_person'] ?? '')
                              .toString()
                              .trim()
                              .toLowerCase();

                      if (nameLower.isNotEmpty) {
                        String designation = '';

                        // Check if witness matches Referring Contact Person
                        if (nameLower == referringContact) {
                          designation = data['referring_contact_designation'] ??
                              data['referred_by'] ??
                              'REFERRING PARTY';
                        }
                        // Fallback logic for Endorsed/Referred By direct match
                        else if (nameLower == endorsedBy ||
                            nameLower == referredBy) {
                          String src = (data['referral_source'] ?? '')
                              .toString()
                              .toUpperCase();
                          if (src.contains('SWDO') ||
                              src.contains('CSWDO') ||
                              src.contains('MSWDO')) {
                            designation = 'SOCIAL WORKER';
                          } else if (src.contains('PNP')) {
                            designation = 'POLICE OFFICER';
                          } else {
                            designation = data['endorsed_by_designation'] ??
                                'REFERRING PARTY';
                          }
                        }

                        if (designation.isNotEmpty) {
                          witnesses[index]['designation'] = designation;
                        }
                      }

                      onChanged('witnesses', witnesses);
                    },
                    useStaffSuggestions: true,
                    additionalSuggestions: [
                      if (data['referred_by'] != null &&
                          data['referred_by'].isNotEmpty)
                        data['referred_by'],
                      if (data['endorsed_by'] != null &&
                          data['endorsed_by'].isNotEmpty)
                        data['endorsed_by'],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FormFieldBuilders.editableDropdown(
                    label: 'Designation / Position',
                    value: witnesses[index]['designation'] ?? '',
                    items: FormOptions.staffDesignations,
                    onChanged: (v) {
                      witnesses[index]['designation'] = v;
                      onChanged('witnesses', witnesses);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (!isFixed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: IconButton(
                      icon: const Icon(LucideIcons.circleMinus,
                          color: Colors.red),
                      onPressed: () {
                        witnesses.removeAt(index);
                        onChanged('witnesses', witnesses);
                      },
                      tooltip: 'Remove witness',
                    ),
                  ),
              ],
            );
          },
        ),
        if (!isFixed) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              witnesses.add({'name': '', 'designation': ''});
              onChanged('witnesses', witnesses);
            },
            icon: const Icon(LucideIcons.userPlus, size: 18),
            label: const Text('Add Witness'),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  static bool _isPreparer(
      Map<String, dynamic> witness, Map<String, dynamic> data) {
    // Current user is often 'received_by' or 'prepared_by'
    // Default witness logic in form_templates.dart adds current user.
    // We check if name matches
    final name = witness['name'];
    if (name == null || name.isEmpty) return false;
    return name == data['prepared_by'] || name == data['received_by'];
  }
}

/// Helper widget to auto-fetch Center Head name
class _AutoFetchCenterHead extends StatefulWidget {
  final String? currentValue;
  final ValueChanged<String> onChanged;

  const _AutoFetchCenterHead({
    this.currentValue,
    required this.onChanged,
  });

  @override
  State<_AutoFetchCenterHead> createState() => _AutoFetchCenterHeadState();
}

class _AutoFetchCenterHeadState extends State<_AutoFetchCenterHead> {
  // Use a future to manage the async fetch operation
  Future<String?>? _fetchFuture;
  // Local state to display the name immediately if available
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);

    // Only fetch if value is empty or default
    if (widget.currentValue == null ||
        widget.currentValue!.isEmpty ||
        widget.currentValue == 'JUAN DELA CRUZ') {
      _fetchFuture = _fetchCenterHead();
    }
  }

  @override
  void didUpdateWidget(_AutoFetchCenterHead oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentValue != oldWidget.currentValue &&
        widget.currentValue != _controller.text) {
      _controller.text = widget.currentValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _fetchCenterHead() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('role', 'center_head')
          .limit(1)
          .maybeSingle();

      if (response != null && response['full_name'] != null) {
        final name = response['full_name'].toString().toUpperCase();

        // Update form data if mounted
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onChanged(name);
          });
        }
        return name;
      }
    } catch (e) {
      debugPrint('Error fetching center head: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _fetchFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.data != null &&
            _controller.text != snapshot.data) {
          _controller.text = snapshot.data!;
        }

        // If we have a value (either passed in or fetched), show it in a readonly field
        return FormFieldBuilders.textField(
          label: 'Center Head (Auto-filled)',
          value: _controller.text,
          onChanged: (v) {}, // Read-only from UI perspective
          enabled: false,
        );
      },
    );
  }
}

class _ActivitiesTable extends StatefulWidget {
  final List<dynamic> activities;
  final ValueChanged<List<dynamic>> onChanged;

  const _ActivitiesTable({
    required this.activities,
    required this.onChanged,
  });

  @override
  State<_ActivitiesTable> createState() => _ActivitiesTableState();
}

class _ActivitiesTableState extends State<_ActivitiesTable> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items =
        widget.activities.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  void didUpdateWidget(covariant _ActivitiesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activities.length != _items.length) {
      _items =
          widget.activities.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  void _emitChange() {
    widget.onChanged(_items);
  }

  void _addItem() {
    setState(() {
      _items.add({
        'objective': '',
        'activity': '',
        'start_date': null,
        'end_date': null,
        'custom_time_frame': '',
        'use_custom_time': false,
        'responsible_person': '',
      });
      _emitChange();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _emitChange();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activities (Interventions)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Activity #${index + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon:
                              const Icon(LucideIcons.trash2, color: Colors.red),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                    FormFieldBuilders.textArea(
                      label: 'Objective',
                      value: item['objective'] ?? '',
                      onChanged: (v) {
                        item['objective'] = v;
                        _emitChange();
                      },
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    FormFieldBuilders.textArea(
                      label: 'Activity',
                      value: item['activity'] ?? '',
                      onChanged: (v) {
                        item['activity'] = v;
                        _emitChange();
                      },
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    // Time Frame Section
                    const Text('Time Frame',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        Checkbox(
                          value: item['use_custom_time'] ?? false,
                          onChanged: (v) {
                            setState(() {
                              item['use_custom_time'] = v;
                              _emitChange();
                            });
                          },
                        ),
                        const Text('Specify manually'),
                      ],
                    ),
                    if (item['use_custom_time'] == true)
                      FormFieldBuilders.textField(
                        label: 'Specific Time Frame',
                        value: item['custom_time_frame'] ?? '',
                        onChanged: (v) {
                          item['custom_time_frame'] = v;
                          _emitChange();
                        },
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: FormFieldBuilders.datePicker(
                              label: 'Start Date',
                              value: item['start_date'],
                              onChanged: (v) {
                                item['start_date'] = v?.toIso8601String();
                                _emitChange();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FormFieldBuilders.datePicker(
                              label: 'End Date',
                              value: item['end_date'],
                              onChanged: (v) {
                                item['end_date'] = v?.toIso8601String();
                                _emitChange();
                              },
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    FormFieldBuilders.typeAhead(
                      label: 'Responsible Unit/Person',
                      value: item['responsible_person'] ?? '',
                      onChanged: (v) {
                        item['responsible_person'] = v;
                        _emitChange();
                      },
                      useStaffSuggestions: true,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        OutlinedButton.icon(
          onPressed: _addItem,
          icon: const Icon(LucideIcons.plus),
          label: const Text('Add Activity'),
        ),
      ],
    );
  }
}

class _FamilyCompositionTable extends StatefulWidget {
  final List<dynamic> members;
  final void Function(List<Map<String, dynamic>>) onChanged;

  const _FamilyCompositionTable({
    required this.members,
    required this.onChanged,
  });

  @override
  State<_FamilyCompositionTable> createState() =>
      _FamilyCompositionTableState();
}

class _FamilyCompositionTableState extends State<_FamilyCompositionTable> {
  late List<Map<String, dynamic>> _members;

  @override
  void initState() {
    super.initState();
    _members =
        widget.members.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  void _addMember() {
    setState(() {
      _members.add({
        'name': '',
        'age': '',
        'relationship': '',
        'occupation': '',
        'address': '',
      });
      widget.onChanged(_members);
    });
  }

  void _removeMember(int index) {
    setState(() {
      _members.removeAt(index);
      widget.onChanged(_members);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Family Composition',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            OutlinedButton.icon(
              onPressed: _addMember,
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Member'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _members.length,
          itemBuilder: (context, index) {
            final member = _members[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Member #${index + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon:
                              const Icon(LucideIcons.trash2, color: Colors.red),
                          onPressed: () => _removeMember(index),
                        ),
                      ],
                    ),
                    FormFieldBuilders.textField(
                      label: 'Name',
                      value: member['name'] ?? '',
                      onChanged: (v) {
                        member['name'] = v;
                        widget.onChanged(_members);
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: FormFieldBuilders.textField(
                            label: 'Age',
                            value: member['age']?.toString() ?? '',
                            onChanged: (v) {
                              member['age'] = v;
                              widget.onChanged(_members);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormFieldBuilders.textField(
                            label: 'Relationship',
                            value: member['relationship'] ?? '',
                            onChanged: (v) {
                              member['relationship'] = v;
                              widget.onChanged(_members);
                            },
                          ),
                        ),
                      ],
                    ),
                    FormFieldBuilders.textField(
                      label: 'Occupation',
                      value: member['occupation'] ?? '',
                      onChanged: (v) {
                        member['occupation'] = v;
                        widget.onChanged(_members);
                      },
                    ),
                    FormFieldBuilders.textField(
                      label: 'Address',
                      value: member['address'] ?? '',
                      onChanged: (v) {
                        member['address'] = v;
                        widget.onChanged(_members);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
