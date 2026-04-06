import 'package:flutter/material.dart';

import 'form_field_builders.dart';

/// Used for optional ro parameter so analyzer recognizes the named parameter.
typedef _FieldReadOnlyChecker = bool Function(String);

/// Psychological Service Form Templates
class PsychologicalServiceForms {
  PsychologicalServiceForms._();

  /// Get form fields for psychological service templates
  /// [readOnly] - If true, all fields will be disabled (for approval view)
  /// [readOnlyFieldKeys] - When non-null, fields whose key is in this set are read-only (e.g. resident-sourced).
  static List<Widget> getFormFields(
    String templateType,
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool readOnly = false,
    Set<String>? readOnlyFieldKeys,
    List<String>? residentNames,
    List<dynamic>? residents,
  }) {
    bool ro(String key) => readOnly || (readOnlyFieldKeys?.contains(key) ?? false);
    switch (templateType) {
      case 'progress_notes':
        return _progressNotes(data, onChanged, ro: ro);
      case 'group_sessions':
        return _groupSessionsReport(data, onChanged,
            residentNames: residentNames);
      case 'individual_sessions':
        return _individualSessionsReport(data, onChanged);
      case 'inter_service_referral':
        return _interServiceReferral(data, onChanged, ro: ro);
      case 'initial_assessment':
        return _initialPsychologicalAssessment(data, onChanged, ro: ro);
      case 'psychometrician_report':
        return _psychometricianReport(data, onChanged, ro: ro);
      default:
        return [const Text('Unknown form type')];
    }
  }

  static bool _defaultRo(String key) => false;

  // PROGRESS NOTES
  static List<Widget> _progressNotes(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    _FieldReadOnlyChecker ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('PROGRESS NOTES'),
      FormFieldBuilders.infoText(
          'MONTHLY PROGRESS REPORT FOR PSYCHOLOGICAL SERVICES'),
      FormFieldBuilders.textField(
        label: 'NAME OF CLIENT',
        value: (data['client_name'] ?? '').toString().toUpperCase(),
        onChanged: (v) => onChanged('client_name', v.toUpperCase()),
        required: true,
        textCapitalization: TextCapitalization.characters,
        readOnly: ro('client_name'),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'COVERAGE MONTH',
              value: (data['coverage_month'] ?? 'JANUARY')
                  .toString()
                  .toUpperCase(),
              items: const [
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
              ],
              onChanged: (v) => onChanged('coverage_month', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'YEAR',
              value: data['coverage_year']?.toString() ??
                  DateTime.now().year.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('coverage_year', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.datePicker(
        label: 'DATE SUBMITTED',
        value: data['date_submitted'],
        onChanged: (v) => onChanged('date_submitted', v?.toIso8601String()),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('OBSERVATIONS / FINDINGS'),
      FormFieldBuilders.textArea(
        label: 'MENTAL HEALTH STATUS',
        value: (data['mental_health_status'] ?? '').toString(),
        onChanged: (v) => onChanged('mental_health_status', v),
        required: true,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        hint:
            'E.g., Mood (euthymic, depressed), affect, thought process, orientation, sleep/appetite patterns...',
      ),
      FormFieldBuilders.textArea(
        label: 'ACTIVITIES OF DAILY LIVING (ADL)',
        value: (data['adl_status'] ?? '').toString(),
        onChanged: (v) => onChanged('adl_status', v),
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        hint:
            'E.g., Self-care skills, hygiene, dressing, mobility, eating habits, instrumental ADLs...',
      ),
      FormFieldBuilders.textArea(
        label: 'SOCIO-EMOTIONAL (DEMONSTRATES)',
        value: (data['socio_emotional'] ?? '').toString(),
        onChanged: (v) => onChanged('socio_emotional', v),
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        hint:
            'E.g., Interpersonal skills, emotional regulation, response to stress, cooperation...',
      ),
      FormFieldBuilders.textArea(
        label: 'SUPERVISORY REMARKS',
        value: (data['supervisory_remarks'] ?? '').toString(),
        onChanged: (v) => onChanged('supervisory_remarks', v),
        textCapitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('WAYS FORWARD'),
      FormFieldBuilders.textArea(
        label: 'RECOMMENDATIONS / NEXT STEPS',
        value: (data['ways_forward'] ?? '').toString(),
        onChanged: (v) => onChanged('ways_forward', v),
        required: true,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
      ),
      FormFieldBuilders.textArea(
        label: 'SUPERVISORY REMARKS',
        value: (data['ways_forward_remarks'] ?? '').toString(),
        onChanged: (v) => onChanged('ways_forward_remarks', v),
        textCapitalization: TextCapitalization.sentences,
      ),
    ];
  }

  // GROUP SESSIONS REPORT
  static List<Widget> _groupSessionsReport(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    List<String>? residentNames,
  }) {
    final participants = (data['participant_details'] as List<dynamic>?) ?? [];

    return [
      FormFieldBuilders.sectionHeader('GROUP SESSIONS REPORT'),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Strictly Confidential / Not for Legal Use',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Session Type'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'By Referral',
              value: data['type_referral'] ?? false,
              onChanged: (v) {
                onChanged('type_referral', v);
                if (v == true) {
                  onChanged('type_walkin', false);
                  onChanged('type_as_needed', false);
                }
              },
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Walk-in',
              value: data['type_walkin'] ?? false,
              onChanged: (v) {
                // Maintenance: existing data key might be 'type_walkin' but let's check
                // Actually the standard is type_walkin based on pdf_generator.
                onChanged('type_walkin', v);
                if (v == true) {
                  onChanged('type_referral', false);
                  onChanged('type_as_needed', false);
                }
              },
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'As Need Arises',
              value: data['type_as_needed'] ?? false,
              onChanged: (v) {
                onChanged('type_as_needed', v);
                if (v == true) {
                  onChanged('type_referral', false);
                  onChanged('type_walkin', false);
                }
              },
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of Session',
              value: data['session_date'],
              onChanged: (v) => onChanged('session_date', v?.toIso8601String()),
              required: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of Report',
              value: data['report_date'],
              onChanged: (v) => onChanged('report_date', v?.toIso8601String()),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Session Details'),
      FormFieldBuilders.textArea(
        label: 'Reason for Session',
        value: data['reason_for_session'] ?? '',
        onChanged: (v) => onChanged('reason_for_session', v),
        required: true,
        hint: 'Insert brief and specific reason',
        textCapitalization: TextCapitalization.characters,
      ),
      FormFieldBuilders.textArea(
        label: 'Participants',
        value: data['participants'] ?? '',
        onChanged: (v) => onChanged('participants', v),
        required: true,
        hint: 'Insert names / names per batch (if done in batches)',
        textCapitalization: TextCapitalization.characters,
      ),
      FormFieldBuilders.textArea(
        label: 'Objectives of the Session',
        value: data['objectives'] ?? '',
        onChanged: (v) => onChanged('objectives', v),
        hint: 'Enumerate using SMART technique',
        textCapitalization: TextCapitalization.characters,
      ),
      FormFieldBuilders.textArea(
        label: 'Session Narrative',
        value: data['session_narrative'] ?? '',
        onChanged: (v) => onChanged('session_narrative', v),
        required: true,
        maxLines: 6,
        hint:
            'Describe how the session happened, behavioral observations (FIDS format if possible)',
        textCapitalization: TextCapitalization.characters,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader(
          'Participant-Specific Agreements (Optional)'),
      FormFieldBuilders.infoText(
        'Use this table if participants have unique needs requiring individual agreements or lessons.',
      ),
      FormFieldBuilders.tableHeader(
        ['Participant', 'Challenges', 'Agreements/Lessons Imparted'],
        flexValues: [2, 3, 3],
      ),
      ...participants.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value as Map<String, dynamic>;
        return FormFieldBuilders.tableRow(
          cells: [
            FormFieldBuilders.typeAhead(
              key: ValueKey('participant_$index'),
              label: '',
              value: item['name'] ?? '',
              onChanged: (v) {
                final newParticipants =
                    List<Map<String, dynamic>>.from(participants);
                newParticipants[index]['name'] = v;
                onChanged('participant_details', newParticipants);
              },
              additionalSuggestions: residentNames ?? [],
              useStaffSuggestions: false,
              inputBorder: InputBorder.none,
              padding: EdgeInsets.zero,
              textCapitalization: TextCapitalization.characters,
            ),
            TextFormField(
              initialValue: item['challenges'] ?? '',
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Challenges...',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) {
                final newParticipants =
                    List<Map<String, dynamic>>.from(participants);
                newParticipants[index]['challenges'] = v;
                onChanged('participant_details', newParticipants);
              },
            ),
            TextFormField(
              initialValue: item['agreements'] ?? '',
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Agreements...',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) {
                final newParticipants =
                    List<Map<String, dynamic>>.from(participants);
                newParticipants[index]['agreements'] = v;
                onChanged('participant_details', newParticipants);
              },
            ),
          ],
          flexValues: [2, 3, 3],
          onDelete: () {
            final newParticipants =
                List<Map<String, dynamic>>.from(participants);
            newParticipants.removeAt(index);
            onChanged('participant_details', newParticipants);
          },
        );
      }),
      FormFieldBuilders.addRowButton(() {
        final newParticipants = List<Map<String, dynamic>>.from(participants);
        newParticipants.add({
          'name': '',
          'challenges': '',
          'agreements': '',
        });
        onChanged('participant_details', newParticipants);
      }),
      FormFieldBuilders.textArea(
        label: 'General Agreements/Lessons Imparted',
        value: data['general_agreements'] ?? '',
        onChanged: (v) => onChanged('general_agreements', v),
        hint:
            'Common agreements/lessons for all. Provide concluding statement(s).',
        textCapitalization: TextCapitalization.characters,
      ),
      FormFieldBuilders.textArea(
        label: 'Recommendations',
        value: data['recommendations'] ?? '',
        onChanged: (v) => onChanged('recommendations', v),
        required: true,
        hint: 'SMART recommendations in line with the reason for session',
        textCapitalization: TextCapitalization.characters,
      ),
    ];
  }

  // INDIVIDUAL SESSIONS REPORT
  static List<Widget> _individualSessionsReport(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
  ) {
    return [
      FormFieldBuilders.sectionHeader('INDIVIDUAL SESSIONS REPORT'),
      // Header and Confidentiality label hidden in form builder as per request (PDF only)
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Session Type'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'By Referral',
              value: data['session_type'] == 'By Referral',
              onChanged: (v) {
                if (v == true) {
                  onChanged('session_type', 'By Referral');
                }
              },
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Walk-in',
              value: data['session_type'] == 'Walk-in',
              onChanged: (v) {
                if (v == true) {
                  onChanged('session_type', 'Walk-in');
                }
              },
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'As Need Arises',
              value: data['session_type'] == 'As Need Arises',
              onChanged: (v) {
                if (v == true) {
                  onChanged('session_type', 'As Need Arises');
                }
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.textField(
        label: 'Client Name',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
        textCapitalization: TextCapitalization.characters,
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of Session',
              value: data['session_date'],
              onChanged: (v) => onChanged('session_date', v?.toIso8601String()),
              required: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of Report',
              value: data['report_date'],
              onChanged: (v) => onChanged('report_date', v?.toIso8601String()),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Session Details'),
      FormFieldBuilders.textArea(
        label: 'Reason for Session',
        value: data['reason_for_session'] ?? '',
        onChanged: (v) => onChanged('reason_for_session', v),
        required: true,
        textCapitalization: TextCapitalization.sentences,
      ),
      FormFieldBuilders.textArea(
        label: 'Objectives of the Session',
        value: data['objectives'] ?? '',
        onChanged: (v) => onChanged('objectives', v),
        textCapitalization: TextCapitalization.sentences,
      ),
      FormFieldBuilders.textArea(
        label: 'Session Narrative',
        value: data['session_narrative'] ?? '',
        onChanged: (v) => onChanged('session_narrative', v),
        required: true,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
      ),
      FormFieldBuilders.textArea(
        label: 'Agreements/Lessons Imparted',
        value: data['agreements'] ?? '',
        onChanged: (v) => onChanged('agreements', v),
        textCapitalization: TextCapitalization.sentences,
      ),
      FormFieldBuilders.textArea(
        label: 'Recommendations',
        value: data['recommendations'] ?? '',
        onChanged: (v) => onChanged('recommendations', v),
        required: true,
        textCapitalization: TextCapitalization.sentences,
      ),
    ];
  }

  // INTER-SERVICE REFERRAL
  static List<Widget> _interServiceReferral(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    _FieldReadOnlyChecker ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('INTER-SERVICE REFERRAL FORM'),
      FormFieldBuilders.datePicker(
        label: 'Date of Referral',
        value: data['referral_date'] ?? DateTime.now().toIso8601String(),
        onChanged: (v) => onChanged('referral_date', v?.toIso8601String()),
        required: true,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Client Information'),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: FormFieldBuilders.textField(
              label: 'Name',
              value: data['client_name'] ?? '',
              onChanged: (v) => onChanged('client_name', v),
              required: true,
              textCapitalization: TextCapitalization.characters,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Nickname',
              value: data['nickname'] ?? '',
              onChanged: (v) => onChanged('nickname', v),
            ),
          ),
        ],
      ),
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
              label: 'Age',
              value: data['age']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('age', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Ward/Room',
        value: data['ward_room'] ?? '',
        onChanged: (v) => onChanged('ward_room', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Referral Details'),
      FormFieldBuilders.bulletList(
        label: 'Reason for Referral',
        value: data['reason_for_referral'] ?? '',
        onChanged: (v) => onChanged('reason_for_referral', v),
        required: true,
      ),
      FormFieldBuilders.bulletList(
        label: 'Challenges Presented',
        value: data['challenges_presented'] ?? '',
        onChanged: (v) => onChanged('challenges_presented', v),
        required: true,
      ),
    ];
  }

  // INITIAL PSYCHOLOGICAL ASSESSMENT
  static List<Widget> _initialPsychologicalAssessment(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    _FieldReadOnlyChecker ro = _defaultRo,
  }) {
    final interventions = (data['intervention_items'] as List<dynamic>?) ?? [];

    return [
      FormFieldBuilders.sectionHeader('INITIAL PSYCHOLOGICAL ASSESSMENT'),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Strictly Confidential / Not for Legal Use',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Identifying Data'),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: FormFieldBuilders.textField(
              label: 'Name',
              value: data['name'] ?? '',
              onChanged: (v) => onChanged('name', v),
              required: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Nickname',
              value: data['nickname'] ?? '',
              onChanged: (v) => onChanged('nickname', v),
            ),
          ),
        ],
      ),
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
              label: 'Age',
              value: data['age']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('age', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Sex',
              value: (data['sex'] ?? 'MALE').toString().toUpperCase(),
              items: const ['MALE', 'FEMALE'],
              onChanged: (v) => onChanged('sex', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textArea(
        label: 'Address',
        value: data['address'] ?? '',
        onChanged: (v) => onChanged('address', v),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Religious Affiliation',
              value: data['religious_affiliation'] ?? '',
              onChanged: (v) => onChanged('religious_affiliation', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Educational Attainment',
              value: data['educational_attainment'] ?? '',
              onChanged: (v) => onChanged('educational_attainment', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of Admission',
              value: data['date_of_admission'],
              onChanged: (v) =>
                  onChanged('date_of_admission', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of Assessment',
              value: data['date_of_assessment'],
              onChanged: (v) =>
                  onChanged('date_of_assessment', v?.toIso8601String()),
            ),
          ),
        ],
      ),
      FormFieldBuilders.datePicker(
        label: 'Date of Report',
        value: data['date_of_report'],
        onChanged: (v) => onChanged('date_of_report', v?.toIso8601String()),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Reason for Referral'),
      FormFieldBuilders.textArea(
        label: 'Reason for Referral',
        value: data['reason_for_referral'] ?? '',
        onChanged: (v) => onChanged('reason_for_referral', v),
        required: true,
        maxLines: 4,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Assessment Tools and Other Procedures'),
      FormFieldBuilders.textArea(
        label: 'Assessment Tools Used',
        value: data['assessment_tools'] ?? '',
        onChanged: (v) => onChanged('assessment_tools', v),
        maxLines: 4,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Results and Discussion'),
      FormFieldBuilders.textArea(
        label: 'Results and Discussion',
        value: data['results_discussion'] ?? '',
        onChanged: (v) => onChanged('results_discussion', v),
        required: true,
        maxLines: 8,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Recommendations / Intervention Plan'),
      ...interventions.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value as Map<String, dynamic>;
        return InterventionItemCard(
          index: index,
          item: item,
          onChanged: (newItem) {
            final newItems = List<Map<String, dynamic>>.from(interventions);
            newItems[index] = newItem;
            onChanged('intervention_items', newItems);
          },
          onDelete: () {
            final newItems = List<Map<String, dynamic>>.from(interventions);
            newItems.removeAt(index);
            onChanged('intervention_items', newItems);
          },
        );
      }),
      FormFieldBuilders.addRowButton(() {
        final newItems = List<Map<String, dynamic>>.from(interventions);
        newItems.add({
          'objectives': '',
          'activity': '',
          'responsible_person': '',
          'time_frame': '',
          'outcome': '',
        });
        onChanged('intervention_items', newItems);
      }),
    ];
  }

  // PSYCHOMETRICIAN'S REPORT
  static List<Widget> _psychometricianReport(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    _FieldReadOnlyChecker ro = _defaultRo,
  }) {
    final interventions = (data['intervention_items'] as List<dynamic>?) ?? [];

    return [
      FormFieldBuilders.sectionHeader('PSYCHOMETRICIAN\'S REPORT'),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Strictly Confidential / Not for Legal Use',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Identifying Data'),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: FormFieldBuilders.textField(
              label: 'Name',
              value: data['name'] ?? '',
              onChanged: (v) => onChanged('name', v),
              required: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Nickname',
              value: data['nickname'] ?? '',
              onChanged: (v) => onChanged('nickname', v),
            ),
          ),
        ],
      ),
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
              label: 'Age',
              value: data['age']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('age', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Sex',
              value: (data['sex'] ?? 'MALE').toString().toUpperCase(),
              items: const ['MALE', 'FEMALE'],
              onChanged: (v) => onChanged('sex', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textArea(
        label: 'Address',
        value: data['address'] ?? '',
        onChanged: (v) => onChanged('address', v),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Religious Affiliation',
              value: data['religious_affiliation'] ?? '',
              onChanged: (v) => onChanged('religious_affiliation', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Educational Attainment',
              value: data['educational_attainment'] ?? '',
              onChanged: (v) => onChanged('educational_attainment', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.dropdown(
        label: 'Category',
        value: data['category'] ?? 'abandoned',
        items: const ['Abandoned', 'Neglected', 'Unattached', 'Homeless'],
        onChanged: (v) => onChanged('category', v),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of Admission',
              value: data['date_of_admission'],
              onChanged: (v) =>
                  onChanged('date_of_admission', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of Assessment',
              value: data['date_of_assessment'],
              onChanged: (v) =>
                  onChanged('date_of_assessment', v?.toIso8601String()),
            ),
          ),
        ],
      ),
      FormFieldBuilders.datePicker(
        label: 'Date of Report',
        value: data['date_of_report'],
        onChanged: (v) => onChanged('date_of_report', v?.toIso8601String()),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Reason for Referral'),
      FormFieldBuilders.textArea(
        label: 'Reason for Referral',
        value: data['reason_for_referral'] ?? '',
        onChanged: (v) => onChanged('reason_for_referral', v),
        required: true,
        maxLines: 4,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Brief History'),
      FormFieldBuilders.textArea(
        label: 'Brief History',
        value: data['brief_history'] ?? '',
        onChanged: (v) => onChanged('brief_history', v),
        maxLines: 6,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Behavioral Observation'),
      FormFieldBuilders.textArea(
        label: 'Behavioral Observation',
        value: data['behavioral_observation'] ?? '',
        onChanged: (v) => onChanged('behavioral_observation', v),
        maxLines: 6,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Assessment Tools and Other Procedures'),
      FormFieldBuilders.textArea(
        label: 'Assessment Tools Used',
        value: data['assessment_tools'] ?? '',
        onChanged: (v) => onChanged('assessment_tools', v),
        maxLines: 4,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Mental Status Examination'),
      FormFieldBuilders.textArea(
        label: 'Mental Status Examination Results',
        value: data['mental_status_exam'] ?? '',
        onChanged: (v) => onChanged('mental_status_exam', v),
        maxLines: 6,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Results and Discussion'),
      FormFieldBuilders.textArea(
        label: 'Results and Discussion',
        value: data['results_discussion'] ?? '',
        onChanged: (v) => onChanged('results_discussion', v),
        required: true,
        maxLines: 8,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Recommendations / Intervention Plan'),
      ...interventions.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value as Map<String, dynamic>;
        return InterventionItemCard(
          index: index,
          item: item,
          onChanged: (newItem) {
            final newItems = List<Map<String, dynamic>>.from(interventions);
            newItems[index] = newItem;
            onChanged('intervention_items', newItems);
          },
          onDelete: () {
            final newItems = List<Map<String, dynamic>>.from(interventions);
            newItems.removeAt(index);
            onChanged('intervention_items', newItems);
          },
        );
      }),
      FormFieldBuilders.addRowButton(() {
        final newItems = List<Map<String, dynamic>>.from(interventions);
        newItems.add({
          'objectives': '',
          'activity': '',
          'responsible_person': '',
          'time_frame': '',
          'outcome': '',
        });
        onChanged('intervention_items', newItems);
      }),
    ];
  }
}

class InterventionItemCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> item;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onDelete;

  const InterventionItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<InterventionItemCard> createState() => _InterventionItemCardState();
}

class _InterventionItemCardState extends State<InterventionItemCard> {
  late TextEditingController _manualTimeController;
  bool _isManualTime = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _manualTimeController = TextEditingController();
    _parseTimeFrame(widget.item['time_frame'] ?? '');
  }

  @override
  void dispose() {
    _manualTimeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InterventionItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item['time_frame'] != oldWidget.item['time_frame']) {
      // Only update if the external value changed significantly differently from our local state
      // (Simple check to avoid loops, though usually local state drives this)
    }
  }

  void _parseTimeFrame(String val) {
    if (val.isEmpty) {
      _isManualTime = false;
      return;
    }
    final parts = val.split(' - ');
    if (parts.length == 2) {
      final start = _parseDate(parts[0]);
      final end = _parseDate(parts[1]);
      if (start != null && end != null) {
        _startDate = start;
        _endDate = end;
        _isManualTime = false;
        return;
      }
    }
    _isManualTime = true;
    _manualTimeController.text = val;
  }

  DateTime? _parseDate(String s) {
    try {
      final p = s.split('/');
      if (p.length == 3) {
        return DateTime(int.parse(p[2]), int.parse(p[0]), int.parse(p[1]));
      }
    } catch (_) {}
    return null;
  }

  String _formatDate(DateTime d) {
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  void _updateTimeFrame() {
    String newVal;
    if (_isManualTime) {
      newVal = _manualTimeController.text;
    } else {
      if (_startDate != null && _endDate != null) {
        newVal = '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
      } else if (_startDate != null) {
        newVal = _formatDate(_startDate!);
      } else {
        newVal = '';
      }
    }
    if (newVal != widget.item['time_frame']) {
      final newItem = Map<String, dynamic>.from(widget.item);
      newItem['time_frame'] = newVal;
      widget.onChanged(newItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Intervention ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const Divider(),

            // Objectives
            TextFormField(
              initialValue: widget.item['objectives'] ?? '',
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Objectives',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                final newItem = Map<String, dynamic>.from(widget.item);
                newItem['objectives'] = v;
                widget.onChanged(newItem);
              },
            ),
            const SizedBox(height: 16),

            // Activity
            TextFormField(
              initialValue: widget.item['activity'] ?? '',
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Activity',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                final newItem = Map<String, dynamic>.from(widget.item);
                newItem['activity'] = v;
                widget.onChanged(newItem);
              },
            ),
            const SizedBox(height: 16),

            // Responsible Person
            FormFieldBuilders.typeAhead(
              label: 'Responsible Unit/Person',
              value: widget.item['responsible_person'] ?? '',
              useStaffSuggestions: true,
              inputBorder: const OutlineInputBorder(),
              onChanged: (v) {
                final newItem = Map<String, dynamic>.from(widget.item);
                newItem['responsible_person'] = v;
                widget.onChanged(newItem);
              },
            ),
            const SizedBox(height: 16),

            // Time Frame Section
            Builder(
              builder: (context) => Text(
                'Time Frame',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.titleSmall?.color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _isManualTime,
                  onChanged: (v) {
                    setState(() {
                      _isManualTime = v ?? false;
                      _updateTimeFrame(); // Update immediately on toggle if needed or just wait for input
                    });
                  },
                ),
                const Text('Specify manually'),
              ],
            ),
            if (_isManualTime)
              TextField(
                controller: _manualTimeController,
                decoration: const InputDecoration(
                  labelText: 'Enter time frame text',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _updateTimeFrame(),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) {
                          setState(() => _startDate = d);
                          _updateTimeFrame();
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today, size: 16),
                        ),
                        child: Text(
                          _startDate != null
                              ? _formatDate(_startDate!)
                              : 'Select',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) {
                          setState(() => _endDate = d);
                          _updateTimeFrame();
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today, size: 16),
                        ),
                        child: Text(
                          _endDate != null ? _formatDate(_endDate!) : 'Select',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Outcome (Added for completeness though not in pic, acts as footer)
            TextFormField(
              initialValue: widget.item['outcome'] ?? '',
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Outcome / Remarks',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                final newItem = Map<String, dynamic>.from(widget.item);
                newItem['outcome'] = v;
                widget.onChanged(newItem);
              },
            ),
          ],
        ),
      ),
    );
  }
}
