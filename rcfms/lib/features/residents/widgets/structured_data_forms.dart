import 'package:flutter/material.dart';

class StructuredDataForms {
  // Returns true if the category has a structured form implementation
  static bool hasForm(String category) {
    const supported = {
      // Medical
      'vitals', 'medication', 'physical', 'dietary',
      // Social/Psych
      'behavior', 'counseling', 'interaction', 'case_note',
      // Homelife
      'incident', 'activity', 'inventory'
    };
    return supported.contains(category);
  }

  // Generates a human-readable summary for the 'content' field
  static String generateSummary(String category, Map<String, dynamic> data) {
    final buffer = StringBuffer();

    switch (category) {
      case 'vitals':
        buffer.writeln('Vitals Taken:');
        if (data['bp_systolic'] != null) {
          buffer.writeln(
              'BP: ${data['bp_systolic']}/${data['bp_diastolic']} mmHg');
        }
        if (data['temperature'] != null) {
          buffer.writeln('Temp: ${data['temperature']}°C');
        }
        if (data['pulse_rate'] != null) {
          buffer.writeln('HR: ${data['pulse_rate']} bpm');
        }
        if (data['respiratory_rate'] != null) {
          buffer.writeln('RR: ${data['respiratory_rate']} cpm');
        }
        if (data['oxygen_saturation'] != null) {
          buffer.writeln('SpO2: ${data['oxygen_saturation']}%');
        }
        break;

      case 'medication':
        buffer.writeln('Medication Administered:');
        buffer.writeln('${data['medication_name']} (${data['dosage']})');
        if (data['route'] != null) buffer.writeln('Route: ${data['route']}');
        if (data['remarks'] != null) {
          buffer.writeln('Remarks: ${data['remarks']}');
        }
        break;

      case 'behavior': // ABC Model
        buffer.writeln('Behavior Observation (ABC):');
        if (data['behavior'] != null) {
          buffer.writeln('Behavior: ${data['behavior']}');
        }
        if (data['antecedent'] != null) {
          buffer.writeln('Antecedent: ${data['antecedent']}');
        }
        if (data['consequence'] != null) {
          buffer.writeln('Consequence: ${data['consequence']}');
        }
        break;

      case 'incident':
        buffer.writeln('Incident Report: ${data['incident_type']}');
        if (data['description'] != null) buffer.writeln(data['description']);
        if (data['immediate_action'] != null) {
          buffer.writeln('Action Taken: ${data['immediate_action']}');
        }
        break;

      default:
        // Generic fallback for other forms
        data.forEach((k, v) {
          if (v != null && v.toString().isNotEmpty) {
            buffer.writeln('${k.replaceAll('_', ' ').toUpperCase()}: $v');
          }
        });
    }

    return buffer.toString().trim();
  }

  static Widget buildForm({
    required String category,
    required Map<String, dynamic> data,
    required Function(String key, dynamic value) onChanged,
  }) {
    switch (category) {
      case 'vitals':
        return _VitalsForm(data: data, onChanged: onChanged);
      case 'medication':
        return _MedicationForm(data: data, onChanged: onChanged);
      case 'physical':
        return _PhysicalForm(data: data, onChanged: onChanged);
      case 'dietary':
        return _DietaryForm(data: data, onChanged: onChanged);
      case 'behavior':
        return _BehaviorForm(data: data, onChanged: onChanged);
      case 'counseling':
      case 'interaction':
      case 'case_note':
        return _SessionForm(data: data, onChanged: onChanged);
      case 'incident':
        return _IncidentForm(data: data, onChanged: onChanged);
      case 'activity':
        return _ActivityForm(data: data, onChanged: onChanged);
      case 'inventory':
        return _InventoryForm(data: data, onChanged: onChanged);
      default:
        return const Center(
            child: Text('No structured form for this category.'));
    }
  }
}

// --- Form Widgets ---

class _VitalsForm extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onChanged;

  const _VitalsForm({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberInput(
                label: 'Systolic (mmHg)',
                value: data['bp_systolic'],
                onChanged: (v) => onChanged('bp_systolic', v),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _NumberInput(
                label: 'Diastolic (mmHg)',
                value: data['bp_diastolic'],
                onChanged: (v) => onChanged('bp_diastolic', v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _NumberInput(
                label: 'Temp (°C)',
                value: data['temperature'],
                onChanged: (v) => onChanged('temperature', v),
                isDecimal: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _NumberInput(
                label: 'Pulse (bpm)',
                value: data['pulse_rate'],
                onChanged: (v) => onChanged('pulse_rate', v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _NumberInput(
                label: 'Resp. Rate (cpm)',
                value: data['respiratory_rate'],
                onChanged: (v) => onChanged('respiratory_rate', v),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _NumberInput(
                label: 'SpO2 (%)',
                value: data['oxygen_saturation'],
                onChanged: (v) => onChanged('oxygen_saturation', v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MedicationForm extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onChanged;

  const _MedicationForm({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TextInput(
          label: 'Medication Name',
          value: data['medication_name'],
          onChanged: (v) => onChanged('medication_name', v),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TextInput(
                label: 'Dosage',
                value: data['dosage'],
                onChanged: (v) => onChanged('dosage', v),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _DropdownInput(
                label: 'Route',
                value: data['route'],
                items: const [
                  'Oral',
                  'IV',
                  'IM',
                  'SubQ',
                  'Topical',
                  'Inhalation'
                ],
                onChanged: (v) => onChanged('route', v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TextInput(
          label: 'Remarks',
          value: data['remarks'],
          onChanged: (v) => onChanged('remarks', v),
          maxLines: 2,
        ),
      ],
    );
  }
}

class _BehaviorForm extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onChanged;

  const _BehaviorForm({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ABC Model Observation',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        const SizedBox(height: 8),
        _TextInput(
          label: 'A - Antecedent (What happened before?)',
          value: data['antecedent'],
          onChanged: (v) => onChanged('antecedent', v),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _TextInput(
          label: 'B - Behavior (Observable action)',
          value: data['behavior'],
          onChanged: (v) => onChanged('behavior', v),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _TextInput(
          label: 'C - Consequence (What happened after?)',
          value: data['consequence'],
          onChanged: (v) => onChanged('consequence', v),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DropdownInput(
                label: 'Intensity',
                value: data['intensity'],
                items: const ['Mild', 'Moderate', 'Severe'],
                onChanged: (v) => onChanged('intensity', v),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _TextInput(
                label: 'Duration',
                value: data['duration'],
                onChanged: (v) => onChanged('duration', v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IncidentForm extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onChanged;

  const _IncidentForm({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DropdownInput(
          label: 'Incident Type',
          value: data['incident_type'],
          items: const [
            'Fall',
            'Aggression',
            'Medical Emergency',
            'Property Damage',
            'Absconding',
            'Other'
          ],
          onChanged: (v) => onChanged('incident_type', v),
        ),
        const SizedBox(height: 12),
        _TextInput(
          label: 'Location',
          value: data['location'],
          onChanged: (v) => onChanged('location', v),
        ),
        const SizedBox(height: 12),
        _TextInput(
          label: 'Witnesses',
          value: data['witnesses'],
          onChanged: (v) => onChanged('witnesses', v),
        ),
        const SizedBox(height: 12),
        _TextInput(
          label: 'Description of Incident',
          value: data['description'],
          onChanged: (v) => onChanged('description', v),
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        _TextInput(
          label: 'Immediate Action Taken',
          value: data['immediate_action'],
          onChanged: (v) => onChanged('immediate_action', v),
          maxLines: 2,
        ),
      ],
    );
  }
}

// Minimal versions for others
class _SessionForm extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onChanged;
  const _SessionForm({required this.data, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DropdownInput(
          label: 'Session Type',
          value: data['session_type'],
          items: const ['Individual', 'Group', 'Casual Interaction'],
          onChanged: (v) => onChanged('session_type', v),
        ),
        const SizedBox(height: 12),
        _TextInput(
            label: 'Topic/Subject',
            value: data['topic'],
            onChanged: (v) => onChanged('topic', v)),
        const SizedBox(height: 12),
        _DropdownInput(
          label: 'Observed Mood',
          value: data['mood_observed'],
          items: const [
            'Happy',
            'Anxious',
            'Sad',
            'Angry',
            'Withdrawn',
            'Cooperative'
          ],
          onChanged: (v) => onChanged('mood_observed', v),
        ),
        const SizedBox(height: 12),
        _TextInput(
            label: 'Detailed Narrative',
            value: data['narrative'],
            onChanged: (v) => onChanged('narrative', v),
            maxLines: 4),
        const SizedBox(height: 12),
        _TextInput(
            label: 'Outcome/Plan',
            value: data['outcome'],
            onChanged: (v) => onChanged('outcome', v),
            maxLines: 2),
      ],
    );
  }
}

class _ActivityForm extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onChanged;
  const _ActivityForm({required this.data, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _TextInput(
          label: 'Activity Name',
          value: data['activity_name'],
          onChanged: (v) => onChanged('activity_name', v)),
      const SizedBox(height: 12),
      _DropdownInput(
          label: 'Participation',
          value: data['participation_level'],
          items: const ['Active', 'Passive', 'Refused'],
          onChanged: (v) => onChanged('participation_level', v)),
      const SizedBox(height: 12),
      _TextInput(
          label: 'Remarks',
          value: data['remarks'],
          onChanged: (v) => onChanged('remarks', v),
          maxLines: 2),
    ]);
  }
}

class _PhysicalForm extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onChanged;
  const _PhysicalForm({required this.data, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _TextInput(
          label: 'Body Part',
          value: data['body_part'],
          onChanged: (v) => onChanged('body_part', v)),
      const SizedBox(height: 12),
      _TextInput(
          label: 'Observation',
          value: data['observation'],
          onChanged: (v) => onChanged('observation', v),
          maxLines: 3),
      const SizedBox(height: 12),
      _NumberInput(
          label: 'Pain Scale (1-10)',
          value: data['pain_scale'],
          onChanged: (v) => onChanged('pain_scale', v)),
    ]);
  }
}

class _DietaryForm extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onChanged;
  const _DietaryForm({required this.data, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _DropdownInput(
          label: 'Meal Type',
          value: data['meal_type'],
          items: const ['Breakfast', 'Lunch', 'Dinner', 'Snack'],
          onChanged: (v) => onChanged('meal_type', v)),
      const SizedBox(height: 12),
      _DropdownInput(
          label: 'Intake Amount',
          value: data['intake_percentage'],
          items: const ['0%', '25%', '50%', '75%', '100%'],
          onChanged: (v) => onChanged('intake_percentage', v)),
      const SizedBox(height: 12),
      _TextInput(
          label: 'Diet Type/Restrictions',
          value: data['diet_type'],
          onChanged: (v) => onChanged('diet_type', v)),
    ]);
  }
}

class _InventoryForm extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onChanged;
  const _InventoryForm({required this.data, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _TextInput(
          label: 'Item Name',
          value: data['item_name'],
          onChanged: (v) => onChanged('item_name', v)),
      const SizedBox(height: 12),
      _DropdownInput(
          label: 'Status',
          value: data['status'],
          items: const ['New', 'Used', 'Damaged', 'Lost'],
          onChanged: (v) => onChanged('status', v)),
      const SizedBox(height: 12),
      _NumberInput(
          label: 'Quantity',
          value: data['quantity'],
          onChanged: (v) => onChanged('quantity', v)),
    ]);
  }
}

// --- Basic Form Components ---

class _TextInput extends StatelessWidget {
  final String label;
  final String? value;
  final Function(String) onChanged;
  final int maxLines;

  const _TextInput(
      {required this.label,
      this.value,
      required this.onChanged,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}

class _NumberInput extends StatelessWidget {
  final String label;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool isDecimal;

  const _NumberInput(
      {required this.label,
      this.value,
      required this.onChanged,
      this.isDecimal = false});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString(),
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (v) {
        if (v.isEmpty) {
          onChanged(null);
          return;
        }
        if (isDecimal) {
          onChanged(double.tryParse(v));
        } else {
          onChanged(int.tryParse(v));
        }
      },
    );
  }
}

class _DropdownInput extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String) onChanged;

  const _DropdownInput(
      {required this.label,
      this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(label), // Force fresh state if label changes
      initialValue: items.contains(value) ? value : null, // Controlled input
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => onChanged(v!),
    );
  }
}
