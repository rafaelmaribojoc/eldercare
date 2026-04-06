import 'package:flutter/material.dart';
import 'form_field_builders.dart';

/// Medical Service Form Templates
class MedicalServiceForms {
  MedicalServiceForms._();

  /// Get form fields for medical service templates
  /// [readOnly] - If true, all fields will be disabled (for approval view)
  /// [readOnlyFieldKeys] - When non-null, fields whose key is in this set are read-only (e.g. resident-sourced).
  static List<Widget> getFormFields(
    String templateType,
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool readOnly = false,
    Set<String>? readOnlyFieldKeys,
  }) {
    bool ro(String key) => readOnly || (readOnlyFieldKeys?.contains(key) ?? false);
    switch (templateType) {
      case 'md_nursing_care_service':
        return _nursingCareService(data, onChanged, ro: ro);
      case 'md_special_events':
        return _specialEvents(data, onChanged);
      case 'md_quarterly_report':
        return _quarterlyReport(data, onChanged);
      case 'md_monthly_accomplishment_report':
        return _monthlyAccomplishmentReport(data, onChanged);
      default:
        return [const Text('Unknown form type')];
    }
  }

  static bool _defaultRo(String key) => false;

  // MEDICAL NURSING CARE SERVICE
  static List<Widget> _nursingCareService(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('MEDICAL NURSING CARE SERVICE'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Name',
              value: data['name'] ?? '',
              onChanged: (v) => onChanged('name', v),
              required: true,
              readOnly: ro('name'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date Conducted',
              value: data['date_conducted'],
              onChanged: (v) =>
                  onChanged('date_conducted', v?.toIso8601String()),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Birthdate',
              value: data['birthdate'],
              onChanged: (v) => onChanged('birthdate', v?.toIso8601String()),
              readOnly: ro('birthdate'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age/Sex',
              value: data['age_sex'] ?? '',
              onChanged: (v) => onChanged('age_sex', v),
              readOnly: ro('age_sex'),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Weight',
              value: data['weight'] ?? '',
              onChanged: (v) => onChanged('weight', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Height',
              value: data['height'] ?? '',
              onChanged: (v) => onChanged('height', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'BMI',
              value: data['bmi'] ?? '',
              onChanged: (v) => onChanged('bmi', v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('PHYSICAL ASSESSMENT'),
      FormFieldBuilders.textField(
        label: 'SKIN',
        value: data['skin'] ?? '',
        onChanged: (v) => onChanged('skin', v),
      ),
      FormFieldBuilders.textField(
        label: 'HAIR',
        value: data['hair'] ?? '',
        onChanged: (v) => onChanged('hair', v),
      ),
      FormFieldBuilders.textField(
        label: 'EYES',
        value: data['eyes'] ?? '',
        onChanged: (v) => onChanged('eyes', v),
      ),
      FormFieldBuilders.textField(
        label: 'EARS',
        value: data['ears'] ?? '',
        onChanged: (v) => onChanged('ears', v),
      ),
      FormFieldBuilders.textField(
        label: 'MOUTH',
        value: data['mouth'] ?? '',
        onChanged: (v) => onChanged('mouth', v),
      ),
      FormFieldBuilders.textField(
        label: 'NAILS',
        value: data['nails'] ?? '',
        onChanged: (v) => onChanged('nails', v),
      ),
      FormFieldBuilders.textField(
        label: 'CHEST & LUNGS',
        value: data['chest_lungs'] ?? '',
        onChanged: (v) => onChanged('chest_lungs', v),
      ),
      FormFieldBuilders.textField(
        label: 'CARDIO',
        value: data['cardio'] ?? '',
        onChanged: (v) => onChanged('cardio', v),
      ),
      FormFieldBuilders.textField(
        label: 'ABDOMEN',
        value: data['abdomen'] ?? '',
        onChanged: (v) => onChanged('abdomen', v),
      ),
      FormFieldBuilders.textField(
        label: 'GENITALS',
        value: data['genitals'] ?? '',
        onChanged: (v) => onChanged('genitals', v),
      ),
      FormFieldBuilders.textField(
        label: 'EXTREMITIES',
        value: data['extremities'] ?? '',
        onChanged: (v) => onChanged('extremities', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Body Map Assessment'),
      FormFieldBuilders.infoText(
          'Describe any marks, scars, or physical issues noted on the body.'),
      FormFieldBuilders.textArea(
        label: 'Body Map Description',
        value: data['body_map_description'] ?? '',
        onChanged: (v) => onChanged('body_map_description', v),
        maxLines: 5,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Assessment'),
      _bulletList(
        data,
        onChanged,
        'assessment_points',
        'assessment',
        label: 'Assessment Point',
        hint: 'Enter assessment observation...',
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.textArea(
        label: 'Remarks',
        value: data['remarks'] ?? '',
        onChanged: (v) => onChanged('remarks', v),
      ),
    ];
  }

  // REPORT ON SPECIAL EVENTS
  static List<Widget> _specialEvents(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
  ) {
    return [
      FormFieldBuilders.sectionHeader('REPORT ON SPECIAL EVENTS'),
      FormFieldBuilders.textField(
        label: 'Client Name',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
      ),
      FormFieldBuilders.textField(
        label: 'Scheduled Procedure',
        value: data['scheduled_procedure'] ?? '',
        onChanged: (v) => onChanged('scheduled_procedure', v),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date',
              value: data['event_date'],
              onChanged: (v) => onChanged('event_date', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.timePicker(
              label: 'Time',
              value: data['event_time'],
              onChanged: (v) => onChanged('event_time', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Venue',
        value: data['venue'] ?? '',
        onChanged: (v) => onChanged('venue', v),
      ),
      FormFieldBuilders.textField(
        label: 'Planned Anesthesia',
        value: data['planned_anesthesia'] ?? '',
        onChanged: (v) => onChanged('planned_anesthesia', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Summary of Events'),
      FormFieldBuilders.textArea(
        label: 'Summary',
        value: data['summary'] ?? '',
        onChanged: (v) => onChanged('summary', v),
        maxLines: 10,
        required: true,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Plan/Next Steps'),
      FormFieldBuilders.textArea(
        label: 'Plan/Next Steps',
        value: data['next_steps'] ?? '',
        onChanged: (v) => onChanged('next_steps', v),
        maxLines: 5,
      ),
    ];
  }

  // QUARTERLY REPORT
  static List<Widget> _quarterlyReport(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
  ) {
    return [
      FormFieldBuilders.sectionHeader(
          'QUARTERLY REPORT RE: MEDICAL SERVICE REPORT'),
      FormFieldBuilders.infoText('For the Year: ${DateTime.now().year}'),

      // Census
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('CENSUS'),
      _simpleTable(data, onChanged, 'census', [
        'MONTH',
        'CENSUS',
        'MALE',
        'FEMALE',
        'ADMISSION',
        'DISCHARGE',
        'MORTALITY',
        'TOTAL CENSUS AT END OF THE MONTH'
      ], [
        2,
        1,
        1,
        1,
        2,
        2,
        2,
        3
      ]),

      // Referrals
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('TOTAL NUMBER OF REFERRED RESIDENTS'),
      _simpleTable(data, onChanged, 'referrals', [
        'MONTH',
        'DRMC & BUCAS CENTER',
        'SPMC-IPBM',
        'PTSI',
        'GREEN LAB CLINIC AND WELLNESS',
        'PERPETUAL MEDICAL MULTI-SPECIALTY & DIAGNOSTIC'
      ], [
        2,
        3,
        2,
        2,
        3,
        4
      ]),

      // Morbidity
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('MORBIDITY'),
      _simpleTable(data, onChanged, 'morbidity',
          ['NAME', 'DATE ADMITTED', 'ADMITTING DIAGNOSIS'], [3, 2, 3]),

      // Minor/Major Operation
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('MINOR/MAJOR OPERATION'),
      _simpleTable(data, onChanged, 'operations', ['NAME', 'DATE', 'REMARKS'],
          [3, 2, 3]),

      // Mortality
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('MORTALITY'),
      _simpleTable(data, onChanged, 'mortality',
          ['NAME', 'DATE EXPIRED', 'CAUSE OF DEATH'], [3, 2, 3]),

      // Covid Vaccination
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader(
          'TOTAL NUMBER OF COVID VACCINATED RESIDENTS'),
      _simpleTable(data, onChanged, 'covid_vaccination', [
        'GENDER',
        'UNVACCINATED',
        '1ST DOSE',
        '2ND DOSE',
        '1ST BOOSTER',
        '2ND BOOSTER',
        'TOTAL FULLY VACCINATED'
      ], [
        2,
        2,
        2,
        2,
        2,
        2,
        2
      ]),

      // Unvaccinated Reasons
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('TOTAL NUMBER OF RESIDENTS UNVACCINATED'),
      FormFieldBuilders.textArea(
        label: 'Reason (New Admissions)',
        value: data['unvaccinated_reasons'] ?? '',
        onChanged: (v) => onChanged('unvaccinated_reasons', v),
        maxLines: 5,
      ),
    ];
  }

  // MONTHLY ACCOMPLISHMENT REPORT
  static List<Widget> _monthlyAccomplishmentReport(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
  ) {
    return [
      FormFieldBuilders.sectionHeader(
          'MONTHLY ACCOMPLISHMENT REPORT OF MEDICAL SERVICE'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Month',
              value: data['month'] ?? 'January',
              items: const [
                'January',
                'February',
                'March',
                'April',
                'May',
                'June',
                'July',
                'August',
                'September',
                'October',
                'November',
                'December'
              ],
              onChanged: (v) => onChanged('month', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Year',
              value: data['year']?.toString() ?? DateTime.now().year.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('year', v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.tableHeader(
        ['Activity', 'Output', 'Outcome'],
        flexValues: [3, 3, 3],
      ),
      _simpleTable(data, onChanged, 'accomplishments',
          ['Activity', 'Output', 'Outcome'], [3, 3, 3],
          hideHeader: true),
    ];
  }

  // Generic Simple Table Helper
  static Widget _simpleTable(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
    String key,
    List<String> headers,
    List<int> flexValues, {
    bool hideHeader = false,
  }) {
    final items = (data['${key}_items'] as List<dynamic>?) ?? [];

    return Column(
      children: [
        if (!hideHeader)
          FormFieldBuilders.tableHeader(headers, flexValues: flexValues),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value as Map<String, dynamic>;

          List<Widget> cells = [];
          for (int i = 0; i < headers.length; i++) {
            // Create a key for each column based on header name (lowercase, snake_case)
            String colKey = headers[i]
                .toLowerCase()
                .replaceAll(' ', '_')
                .replaceAll('/', '_')
                .replaceAll('&', 'and')
                .replaceAll('-', '_');
            // Handle duplicates if any, though unlikely in these strict forms

            cells.add(
              TextFormField(
                initialValue: item[colKey]?.toString() ?? '',
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                ),
                maxLines: null, // Allow wrapping
                onChanged: (v) {
                  final newItems = List<Map<String, dynamic>>.from(items);
                  newItems[index][colKey] = v;
                  onChanged('${key}_items', newItems);
                },
              ),
            );
          }

          return FormFieldBuilders.tableRow(
            cells: cells,
            flexValues: flexValues,
            onDelete: () {
              final newItems = List<Map<String, dynamic>>.from(items);
              newItems.removeAt(index);
              onChanged('${key}_items', newItems);
            },
          );
        }),
        FormFieldBuilders.addRowButton(() {
          final newItems = List<Map<String, dynamic>>.from(items);
          // Initialize empty object with keys derived from headers
          Map<String, dynamic> newItem = {};
          for (int i = 0; i < headers.length; i++) {
            String colKey = headers[i]
                .toLowerCase()
                .replaceAll(' ', '_')
                .replaceAll('/', '_')
                .replaceAll('&', 'and')
                .replaceAll('-', '_');
            newItem[colKey] = '';
          }
          newItems.add(newItem);
          onChanged('${key}_items', newItems);
        }),
      ],
    );
  }

  // Helper: Bullet list builder
  static Widget _bulletList(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
    String listKey,
    String stringKey, {
    String label = 'Item',
    String hint = 'Enter details...',
  }) {
    // Migration: If list is missing but string exists, split string
    List<dynamic> items = (data[listKey] as List<dynamic>?) ?? [];
    if (items.isEmpty &&
        data[stringKey] is String &&
        (data[stringKey] as String).isNotEmpty) {
      items = (data[stringKey] as String)
          .split('\n')
          .where((e) => e.trim().isNotEmpty)
          .toList();
      // Clean up bullets if they were manually typed
      items =
          items.map((e) => e.toString().replaceAll('•', '').trim()).toList();
    }

    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...items.asMap().entries.map((entry) {
              final index = entry.key;

              // Ensure cursor sets to end if rewritten (managed by Flutter usually, but explicit controller safer for focus?)
              // actually FormFieldBuilders uses initialValue, let's stick to simple TextFormField without controller for stateless feel

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0, right: 8.0),
                      child: Icon(Icons.circle,
                          size: 8,
                          color: Theme.of(context).textTheme.bodySmall?.color ??
                              Theme.of(context).hintColor),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: entry.value.toString(),
                        decoration: InputDecoration(
                          labelText: '$label ${index + 1}',
                          hintText: hint,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: null,
                        onChanged: (v) {
                          final newItems = List<dynamic>.from(items);
                          newItems[index] = v;
                          onChanged(listKey, newItems);
                          // Sync to string for legacy/view support
                          onChanged(stringKey,
                              newItems.map((e) => '• $e').join('\n'));
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: Theme.of(context).disabledColor),
                      onPressed: () {
                        final newItems = List<dynamic>.from(items);
                        newItems.removeAt(index);
                        onChanged(listKey, newItems);
                        onChanged(
                            stringKey, newItems.map((e) => '• $e').join('\n'));
                      },
                    ),
                  ],
                ),
              );
            }),
            FormFieldBuilders.addRowButton(() {
              final newItems = List<dynamic>.from(items);
              newItems.add('');
              onChanged(listKey, newItems);
              // Sync
              onChanged(stringKey, newItems.map((e) => '• $e').join('\n'));
            }),
          ],
        );
      },
    );
  }
}
