import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'form_field_builders.dart';

/// Home Life Service Form Templates
class HomeLifeServiceForms {
  HomeLifeServiceForms._();

  /// Get form fields for home life service templates
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
    bool ro(String key) =>
        readOnly || (readOnlyFieldKeys?.contains(key) ?? false);
    switch (templateType) {
      case 'inventory_admission':
        return _inventoryUponAdmission(data, onChanged, ro: ro);
      case 'inventory_discharge':
        return _inventoryUponDischarge(data, onChanged, ro: ro);
      case 'inventory_monthly':
        return _inventoryMonthly(data, onChanged);
      case 'progress_notes':
        return _progressNotes(data, onChanged, ro: ro);
      case 'incident_report':
        return _incidentReport(data, onChanged,
            residentNames: residentNames, ro: ro);
      case 'out_on_pass':
        return _outOnPass(data, onChanged, ro: ro);
      default:
        return [const Text('Unknown form type')];
    }
  }

  static bool _defaultRo(String key) => false;

  // INVENTORY UPON ADMISSION
  static List<Widget> _inventoryUponAdmission(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('INVENTORY OF BELONGINGS'),
      FormFieldBuilders.infoText(
          'Record all belongings of the client upon admission'),
      FormFieldBuilders.textField(
        label: 'Name of Client',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
        readOnly: ro('client_name'),
      ),
      FormFieldBuilders.datePicker(
        label: 'Date',
        value: data['inventory_date'],
        onChanged: (v) => onChanged('inventory_date', v?.toIso8601String()),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Belongings Inventory'),
      _inventoryTable(data, onChanged, 'admission'),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('Signatures'),
      const SizedBox(height: 16),
      const SizedBox(height: 16),
      FormFieldBuilders.digitalSignature(
        label: 'Turned Over By — Signature',
        fieldName: 'referring_party_signature_url',
        value: data['referring_party_signature_url']?.toString(),
        formId: data['_submission_id']?.toString(),
        onChanged: (url) => onChanged('referring_party_signature_url', url),
        required: true,
      ),
      const SizedBox(height: 12),
      const SizedBox(height: 12),
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

  // INVENTORY UPON DISCHARGE
  static List<Widget> _inventoryUponDischarge(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('INVENTORY OF BELONGINGS'),
      FormFieldBuilders.infoText(
          'Record all belongings being released to the client upon discharge'),
      FormFieldBuilders.textField(
        label: 'Name of Client',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
        readOnly: ro('client_name'),
      ),
      FormFieldBuilders.datePicker(
        label: 'Date',
        value: data['inventory_date'],
        onChanged: (v) => onChanged('inventory_date', v?.toIso8601String()),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Belongings Inventory'),
      _inventoryTable(data, onChanged, 'discharge'),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('Signatures'),
      const SizedBox(height: 16),
      const SizedBox(height: 16),
      FormFieldBuilders.digitalSignature(
        label: 'Receiving Party — Signature',
        fieldName: 'receiving_party_signature_url',
        value: data['receiving_party_signature_url']?.toString(),
        formId: data['_submission_id']?.toString(),
        onChanged: (url) => onChanged('receiving_party_signature_url', url),
        required: true,
      ),
      const SizedBox(height: 12),
      FormFieldBuilders.digitalSignature(
        label: 'Client Signature',
        fieldName: 'client_signature_url',
        value: data['client_signature_url']?.toString(),
        formId: data['_submission_id']?.toString(),
        onChanged: (url) => onChanged('client_signature_url', url),
        required: true,
      ),
      const SizedBox(height: 12),
    ];
  }

  // MONTHLY INVENTORY
  static List<Widget> _inventoryMonthly(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
  ) {
    return [
      FormFieldBuilders.sectionHeader('INVENTORY OF BELONGINGS'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Month',
              value: data['month'] ?? 'JANUARY',
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
              onChanged: (v) => onChanged('month', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Year',
              value: data['year'] ?? DateTime.now().year.toString(),
              items: List.generate(10, (index) {
                return (DateTime.now().year - 5 + index).toString();
              }),
              onChanged: (v) => onChanged('year', v),
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
      FormFieldBuilders.datePicker(
        label: 'Date',
        value: data['inventory_date'],
        onChanged: (v) => onChanged('inventory_date', v?.toIso8601String()),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('A. Clothing'),
      _inventoryCategoryTable(data, onChanged, 'clothing'),
      FormFieldBuilders.sectionHeader('B. Toiletries'),
      _inventoryCategoryTable(data, onChanged, 'toiletries'),
      FormFieldBuilders.sectionHeader('C. Linen'),
      _inventoryCategoryTable(data, onChanged, 'linen'),
      FormFieldBuilders.sectionHeader('D. Others'),
      _inventoryCategoryTable(data, onChanged, 'others'),
      const SizedBox(height: 16),
    ];
  }

  // Helper: Inventory table
  static Widget _inventoryTable(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
    String prefix,
  ) {
    final items = (data['${prefix}_items'] as List<dynamic>?) ?? [];

    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value as Map<String, dynamic>;
          return InventoryItemCard(
            index: index,
            item: item,
            onChanged: (newItem) {
              final newItems = List<Map<String, dynamic>>.from(items);
              newItems[index] = newItem;
              onChanged('${prefix}_items', newItems);
            },
            onDelete: () {
              final newItems = List<Map<String, dynamic>>.from(items);
              newItems.removeAt(index);
              onChanged('${prefix}_items', newItems);
            },
          );
        }),
        FormFieldBuilders.addRowButton(() {
          final newItems = List<Map<String, dynamic>>.from(items);
          newItems.add({
            'particulars': '',
            'qty': 0,
            'unit': 'pc',
            'description': '',
            'unit_cost': 0.0,
            'balance': 0.0,
          });
          onChanged('${prefix}_items', newItems);
        }),
      ],
    );
  }

  // Helper: Inventory category table (for monthly)
  static Widget _inventoryCategoryTable(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
    String category,
  ) {
    final items = (data['${category}_items'] as List<dynamic>?) ?? [];

    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value as Map<String, dynamic>;
          return InventoryItemCard(
            index: index,
            item: item,
            onChanged: (newItem) {
              final newItems = List<Map<String, dynamic>>.from(items);
              newItems[index] = newItem;
              onChanged('${category}_items', newItems);
            },
            onDelete: () {
              final newItems = List<Map<String, dynamic>>.from(items);
              newItems.removeAt(index);
              onChanged('${category}_items', newItems);
            },
          );
        }),
        FormFieldBuilders.addRowButton(() {
          final newItems = List<Map<String, dynamic>>.from(items);
          newItems.add({
            'particulars': '',
            'qty': 0,
            'unit': 'pc',
            'description': '',
            'unit_cost': 0.0,
            'balance': 0.0,
          });
          onChanged('${category}_items', newItems);
        }),
      ],
    );
  }

  // PROGRESS NOTES
  static List<Widget> _progressNotes(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    final entries = (data['progress_entries'] as List<dynamic>?) ?? [];

    return [
      FormFieldBuilders.sectionHeader('PROGRESS NOTES'),
      FormFieldBuilders.textField(
        label: 'Name of Client',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        required: true,
        readOnly: ro('client_name'),
      ),
      const SizedBox(height: 16),
      ...entries.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value as Map<String, dynamic>;

        return ProgressEntryCard(
          index: index,
          item: item,
          onChanged: (newItem) {
            final newEntries = List<Map<String, dynamic>>.from(entries);
            newEntries[index] = newItem;
            onChanged('progress_entries', newEntries);
          },
          onDelete: () {
            final newEntries = List<Map<String, dynamic>>.from(entries);
            newEntries.removeAt(index);
            onChanged('progress_entries', newEntries);
          },
        );
      }),
      FormFieldBuilders.addRowButton(() {
        final newEntries = List<Map<String, dynamic>>.from(entries);
        newEntries.add({
          'date': DateTime.now().toIso8601String(),
          'activities': '',
          'remarks': '',
        });
        onChanged('progress_entries', newEntries);
      }),
      /*
      // Signatories hidden in form builder as per request (PDF only)
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('Signatures'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Prepared By (Houseparent I)',
              value: data['prepared_by'] ?? '',
              onChanged: (v) => onChanged('prepared_by', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Noted By (Center Head)',
              value: data['noted_by'] ?? '',
              onChanged: (v) => onChanged('noted_by', v),
            ),
          ),
        ],
      ),
      */
    ];
  }

  // INCIDENT REPORT
  static List<Widget> _incidentReport(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    List<String>? residentNames,
    bool Function(String) ro = _defaultRo,
  }) {
    final actions = (data['action_items'] as List<dynamic>?) ?? [];

    return [
      FormFieldBuilders.sectionHeader('INCIDENT REPORT'),
      FormFieldBuilders.dropdown(
        label: 'Type of Incident',
        value: data['type_of_incident'] ?? 'Fall / Slip',
        items: const [
          'Fall / Slip',
          'Medical Emergency',
          'Medication Error / Missed Dose',
          'Behavioral Aggression / Altercation',
          'Absconding / Missing Resident',
          'Self-Harm / Suicide Attempt',
          'Abuse / Neglect Allegation',
          'Property Loss / Theft',
          'Property Damage',
          'Fire / Safety Hazard',
          'Infection Control / Outbreak Concern',
          'Death',
          'Other',
        ],
        onChanged: (v) {
          onChanged('type_of_incident', v);
          if (v != 'Other') {
            onChanged('other_incident_type', null);
          }
        },
        required: true,
        readOnly: ro('type_of_incident'),
      ),
      if (data['type_of_incident'] == 'Other')
        FormFieldBuilders.textField(
          label: 'Please specify other incident type',
          value: data['other_incident_type'] ?? '',
          onChanged: (v) => onChanged('other_incident_type', v),
          required: true,
          readOnly: ro('other_incident_type'),
        ),
      FormFieldBuilders.textArea(
        label: 'WHAT (Anong Nangyari)',
        value: data['what_happened'] ?? '',
        onChanged: (v) => onChanged('what_happened', v),
        required: true,
      ),
      RepeatableFormSection(
        label: 'WHO (Sino ang Kasali)',
        // Convert comma-separated string to list
        values: (data['who_involved'] as String? ?? '')
            .split(',')
            .map((e) => e.trim())
            .toList(),
        onChanged: (List<String> values) {
          // Join list back to comma-separated string
          // We must preserve empty values to keep the "Add Item" row alive
          final joined = values.map((e) => e.trim()).join(',');
          onChanged('who_involved', joined);
        },
        itemBuilder: (index, value, onItemChanged) {
          return FormFieldBuilders.typeAhead(
            label: 'Person ${index + 1}',
            value: value,
            onChanged: onItemChanged,
            required: index == 0, // Only first item is strictly required
            additionalSuggestions: residentNames ?? [],
            useStaffSuggestions: false,
            // Disable the suffix add button inside the repeatable item
            // since we have the main "Add Item" button now
            // We pass a key to ensure proper state preservation
            key: ValueKey('who_involved_$index'),
          );
        },
        addLabel: 'Add Person',
        required: true,
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'WHEN - Date',
              value: data['when_date'],
              onChanged: (v) => onChanged('when_date', v?.toIso8601String()),
              required: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.timePicker(
              label: 'WHEN - Time',
              value: data['when_time'],
              onChanged: (v) => onChanged('when_time', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'WHERE (Saan)',
        value: data['where'] ?? '',
        onChanged: (v) => onChanged('where', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Action Taken & Recommendations'),
      ...actions.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value as Map<String, dynamic>;

        return IncidentActionCard(
          index: index,
          item: item,
          onChanged: (newItem) {
            final newActions = List<Map<String, dynamic>>.from(actions);
            newActions[index] = newItem;
            onChanged('action_items', newActions);
          },
          onDelete: () {
            final newActions = List<Map<String, dynamic>>.from(actions);
            newActions.removeAt(index);
            onChanged('action_items', newActions);
          },
        );
      }),
      FormFieldBuilders.addRowButton(() {
        final newActions = List<Map<String, dynamic>>.from(actions);
        newActions.add({
          'action': '',
          'recommendation': '',
          'responsible_person': '',
        });
        onChanged('action_items', newActions);
      }),
      const SizedBox(height: 16),
      FormFieldBuilders.textArea(
        label: 'Remarks',
        value: data['remarks'] ?? '',
        onChanged: (v) => onChanged('remarks', v),
      ),
      const SizedBox(height: 16),
    ];
  }

  // OUT ON PASS
  static List<Widget> _outOnPass(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('OUT ON PASS'),
      const SizedBox(height: 16),
      FormFieldBuilders.datePicker(
        label: 'Date',
        value: data['pass_date'],
        onChanged: (v) => onChanged('pass_date', v?.toIso8601String()),
        required: true,
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Client Name',
              value: data['client_name'] ?? '',
              onChanged: (v) => onChanged('client_name', v),
              required: true,
              readOnly: ro('client_name'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['client_age']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('client_age', v),
              readOnly: ro('client_age'),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.timePicker(
              label: 'Time Out',
              value: data['time_out'],
              onChanged: (v) => onChanged('time_out', v),
              required: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.timePicker(
              label: 'Time In',
              value: data['time_in'],
              onChanged: (v) => onChanged('time_in', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textArea(
        label: 'Purpose',
        value: data['purpose'] ?? '',
        onChanged: (v) => onChanged('purpose', v),
        required: true,
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.typeAhead(
              label: 'Escorted By',
              value: data['escorted_by'] ?? '',
              onChanged: (v) => onChanged('escorted_by', v),
              useStaffSuggestions: true,
              onSuggestionSelected: (name, extraData) {
                if (extraData != null && extraData.containsKey('role')) {
                  final role = extraData['role']?.toString();
                  if (role != null && role.isNotEmpty) {
                    onChanged('escort_position', role);
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.typeAhead(
              label: 'Position',
              value: data['escort_position'] ?? '',
              onChanged: (v) => onChanged('escort_position', v),
              useStaffSuggestions: false,
              additionalSuggestions: const [
                'Nurse',
                'Houseparent',
                'Social Worker',
                'Other'
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.textArea(
        label: 'Note',
        value: data['note'] ?? '',
        onChanged: (v) => onChanged('note', v),
        maxLines: 2,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Nature of Out-slip'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Personal',
              value: data['nature_personal'] ?? false,
              onChanged: (v) => onChanged('nature_personal', v),
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Medical',
              value: data['nature_medical'] ?? false,
              onChanged: (v) => onChanged('nature_medical', v),
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Official',
              value: data['nature_official'] ?? false,
              onChanged: (v) => onChanged('nature_official', v),
            ),
          ),
        ],
      ),
      /*
      // Notice/Reminders hidden as per request (PDF only)
      FormFieldBuilders.textArea(
        label: 'Notice/Reminders',
        value: data['notices'] ??
            'The Home for the Aged will not be held liable for any untoward incident affecting the client outside the center.',
        onChanged: (v) => onChanged('notices', v),
      ),
      */

      const SizedBox(height: 16),
      FormFieldBuilders.digitalSignature(
        label: 'Client Signature',
        fieldName: 'client_signature_url',
        value: data['client_signature_url']?.toString(),
        formId: data['_submission_id']?.toString(),
        onChanged: (v) => onChanged('client_signature_url', v),
        required: true,
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('Approvals Requested'),
      FormFieldBuilders.infoText(
          'Appropriate signatories will be notified upon submission.'),
    ];
  }
}

class InventoryItemCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> item;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onDelete;

  const InventoryItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<InventoryItemCard> createState() => _InventoryItemCardState();
}

class _InventoryItemCardState extends State<InventoryItemCard> {
  late TextEditingController _particularsCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _balanceCtrl;
  final FocusNode _costFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _particularsCtrl =
        TextEditingController(text: widget.item['particulars'] ?? '');
    _descCtrl = TextEditingController(text: widget.item['description'] ?? '');
    _qtyCtrl = TextEditingController(
        text: widget.item['qty']?.toString() == '0'
            ? ''
            : widget.item['qty']?.toString() ?? '');
    _unitCtrl = TextEditingController(text: widget.item['unit'] ?? '');
    _costCtrl = TextEditingController(
        text: widget.item['unit_cost']?.toString() == '0.0'
            ? ''
            : widget.item['unit_cost']?.toString() ?? '');
    _balanceCtrl = TextEditingController(
        text: widget.item['balance']?.toString() == '0.0'
            ? ''
            : widget.item['balance']?.toString() ?? '');

    _costFocus.addListener(_formatCost);
  }

  void _formatCost() {
    if (!_costFocus.hasFocus) {
      if (_costCtrl.text.isNotEmpty) {
        final val = double.tryParse(_costCtrl.text);
        if (val != null) {
          _costCtrl.text = val.toStringAsFixed(2);
          _updateItem();
        }
      }
    }
  }

  @override
  void dispose() {
    _particularsCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _costCtrl.dispose();
    _balanceCtrl.dispose();
    _costFocus.dispose();
    super.dispose();
  }

  void _updateItem() {
    final newItem = Map<String, dynamic>.from(widget.item);
    newItem['particulars'] = _particularsCtrl.text;
    newItem['description'] = _descCtrl.text;
    newItem['qty'] = int.tryParse(_qtyCtrl.text) ?? 0;
    newItem['unit'] = _unitCtrl.text;
    newItem['unit_cost'] = double.tryParse(_costCtrl.text) ?? 0.0;
    newItem['balance'] = double.tryParse(_balanceCtrl.text) ?? 0.0;
    widget.onChanged(newItem);
  }

  void _selectAll(TextEditingController controller) {
    if (controller.text.isNotEmpty) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item #${widget.index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, color: Colors.red),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _particularsCtrl,
            decoration: const InputDecoration(
              labelText: 'Particulars',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => _updateItem(),
            onTap: () => _selectAll(_particularsCtrl),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description / Remarks',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
            onChanged: (_) => _updateItem(),
            onTap: () => _selectAll(_descCtrl),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => _updateItem(),
                  onTap: () => _selectAll(_qtyCtrl),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _unitCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixText: _unitCtrl.text.isNotEmpty
                        ? (_unitCtrl.text == '1' ? ' pc' : ' pcs')
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {});
                    _updateItem();
                  },
                  onTap: () => _selectAll(_unitCtrl),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _costCtrl,
                  focusNode: _costFocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Unit Cost',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixText: _costCtrl.text.isNotEmpty ? '₱ ' : null,
                  ),
                  onChanged: (val) {
                    setState(() {});
                    _updateItem();
                  },
                  onTap: () => _selectAll(_costCtrl),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _balanceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Balance',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => _updateItem(),
                  onTap: () => _selectAll(_balanceCtrl),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProgressEntryCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> item;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onDelete;

  const ProgressEntryCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<ProgressEntryCard> createState() => _ProgressEntryCardState();
}

class _ProgressEntryCardState extends State<ProgressEntryCard> {
  late TextEditingController _activitiesCtrl;
  late TextEditingController _remarksCtrl;

  @override
  void initState() {
    super.initState();
    _activitiesCtrl =
        TextEditingController(text: widget.item['activities'] ?? '');
    _remarksCtrl = TextEditingController(text: widget.item['remarks'] ?? '');
  }

  @override
  void dispose() {
    _activitiesCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _updateItem() {
    final newItem = Map<String, dynamic>.from(widget.item);
    newItem['activities'] = _activitiesCtrl.text;
    newItem['remarks'] = _remarksCtrl.text;
    widget.onChanged(newItem);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Entry #${widget.index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, color: Colors.red),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _activitiesCtrl,
            decoration: const InputDecoration(
              labelText: 'Significant Activities',
              border: OutlineInputBorder(),
              isDense: true,
              hintText:
                  'E.g., Participated in chores, morning exercise, family visit, medical appointment...',
              hintMaxLines: 2,
            ),
            maxLines: 3,
            onChanged: (_) => _updateItem(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _remarksCtrl,
            decoration: const InputDecoration(
              labelText: 'Remarks',
              border: OutlineInputBorder(),
              isDense: true,
              hintText:
                  'E.g., Cooperative, compliant with rules, observed behavior, specific complaints...',
              hintMaxLines: 2,
            ),
            maxLines: 3,
            onChanged: (_) => _updateItem(),
          ),
        ],
      ),
    );
  }
}

class IncidentActionCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> item;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onDelete;

  const IncidentActionCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<IncidentActionCard> createState() => _IncidentActionCardState();
}

class _IncidentActionCardState extends State<IncidentActionCard> {
  late TextEditingController _actionCtrl;
  late TextEditingController _recommendationCtrl;

  @override
  void initState() {
    super.initState();
    _actionCtrl = TextEditingController(text: widget.item['action'] ?? '');
    _recommendationCtrl =
        TextEditingController(text: widget.item['recommendation'] ?? '');
  }

  @override
  void dispose() {
    _actionCtrl.dispose();
    _recommendationCtrl.dispose();
    super.dispose();
  }

  void _updateItem() {
    final newItem = Map<String, dynamic>.from(widget.item);
    newItem['action'] = _actionCtrl.text;
    newItem['recommendation'] = _recommendationCtrl.text;
    widget.onChanged(newItem);
  }

  void _selectAll(TextEditingController controller) {
    if (controller.text.isNotEmpty) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Action #${widget.index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, color: Colors.red),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _actionCtrl,
            decoration: const InputDecoration(
              labelText: 'Action Taken',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 3,
            onChanged: (_) => _updateItem(),
            onTap: () => _selectAll(_actionCtrl),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _recommendationCtrl,
            decoration: const InputDecoration(
              labelText: 'Recommendation',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 3,
            onChanged: (_) => _updateItem(),
            onTap: () => _selectAll(_recommendationCtrl),
          ),
          const SizedBox(height: 12),
          FormFieldBuilders.typeAhead(
            key: ValueKey('action_responsible_${widget.index}'),
            label: 'Responsible Unit/Person',
            value: widget.item['responsible_person'] ?? '',
            onChanged: (v) {
              final newItem = Map<String, dynamic>.from(widget.item);
              newItem['responsible_person'] = v;
              widget.onChanged(newItem);
            },
            useStaffSuggestions: true,
          ),
        ],
      ),
    );
  }
}
