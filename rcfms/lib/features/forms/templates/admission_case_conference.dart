import 'package:flutter/material.dart';
import '../../../../core/constants/form_options.dart';

import 'form_field_builders.dart';

class AdmissionCaseConferenceForm {
  // Static helper for date formatting
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  static bool _defaultRo(String key) => false;

  static List<Widget> build(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    // Capitalize identifying info for display
    final clientName = (data['client_name'] ?? '').toString().toUpperCase();
    final clientAge = (data['client_age'] ?? '').toString();

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
            readOnly: ro(key),
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
                readOnly: ro(key),
              ),
            ),
        ],
      );
    }

    // Helper to calculate and format time range
    void updateTimeAllotted(String? newStart, String? newEnd) {
      final start = newStart ?? data['time_started'] as String?;
      final end = newEnd ?? data['time_ended'] as String?;

      onChanged('time_started', start);
      onChanged('time_ended', end);

      if (start == null || start.isEmpty || end == null || end.isEmpty) {
        // Partial update if only one is available
        // Note: We can't easily format just one without the other if we want the range format
        // But let's try to format what we have

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

        // Handle overnight? Assuming same day for now as per typical business logic
        // If end is before start, maybe user made mistake or it crossed midnight
        // Let's assume strict same day for valid duration

        var diff = eDate.difference(sDate);
        if (diff.isNegative) {
          // End time is before start time, possibly next day?
          // Or just invalid. Let's just show range without duration if negative
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

    return [
      FormFieldBuilders.sectionHeader('ADMISSION CASE CONFERENCE'),
      // System Generated / Read Only Fields
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'DATE SUBMITTED',
              value: formatDate(data['date_submitted']),
              onChanged: (_) {}, // Read-only
              enabled: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'DATE ADMITTED',
              value: data['date_admitted']?.toString().split('T')[0] ?? '',
              onChanged: (_) {},
              enabled: false,
            ),
          ),
        ],
      ),

      FormFieldBuilders.textField(
        label: 'NAME OF CLIENT',
        value: clientName,
        onChanged: (v) => onChanged('client_name', v.toUpperCase()),
        required: true,
        textCapitalization: TextCapitalization.characters,
        readOnly: ro('client_name'),
      ),
      FormFieldBuilders.textField(
        label: 'AGE',
        value: clientAge,
        onChanged: (v) => onChanged('client_age', v),
        readOnly: ro('client_age'),
      ),

      FormFieldBuilders.dropdown(
        label: 'CASE CATEGORY',
        value: data['case_category']?.toString().toUpperCase() ?? 'ABANDONED',
        items: FormOptions.caseCategories,
        onChanged: (v) => onChanged('case_category', v),
        readOnly: ro('case_category'),
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

      // Enahnced Attendees using "Smart Dropdown" logic but for Multi-Select
      // Since standard multi-select mock for system users:
      // Enhanced with BulletList and Staff Suggestions
      FormFieldBuilders.bulletList(
        label: 'PRESENT / ATTENDEES',
        value: data['attendees'] ?? '',
        onChanged: (v) => onChanged('attendees', v),
        useStaffSuggestions: true,
      ),

      const SizedBox(height: 16),
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
      ),

      FormFieldBuilders.bulletList(
        label: 'AGREEMENT REACHED / RECOMMENDATIONS',
        value: data['agreement_recommendations'] ?? '',
        onChanged: (v) => onChanged('agreement_recommendations', v),
      ),
    ];
  }
}
