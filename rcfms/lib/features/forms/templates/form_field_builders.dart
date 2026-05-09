import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/repositories/form_repository.dart';
import '../widgets/form_image_picker.dart';
import '../widgets/signature_pad_dialog.dart';
import 'reactive_text_field.dart';

/// Helper class for building responsive form fields
class FormFieldBuilders {
  FormFieldBuilders._();

  /// Helper to safely convert any value to String
  /// Handles List, Map, and other types gracefully
  static String _toSafeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List) {
      // Convert List to readable string
      return value
          .map((item) {
            if (item is Map) {
              // Extract meaningful text from map
              final parts = [
                item['objective'],
                item['activity'],
                item['output'],
                item['responsible_person'],
              ].where((s) => s != null && s.toString().isNotEmpty);
              return parts.join(' - ');
            }
            return item.toString();
          })
          .where((s) => s.isNotEmpty)
          .join('\n');
    }
    return value.toString();
  }

  /// TypeAhead input with suggestions
  static Widget typeAhead({
    Key? key,
    required String label,
    required String value,
    required void Function(String) onChanged,
    List<String> additionalSuggestions = const [],
    bool useStaffSuggestions = true,
    bool required = false,
    bool readOnly = false,
    String? filterUnit, // Added filter
    InputBorder? inputBorder,
    EdgeInsetsGeometry? padding,
    void Function(String, Map<String, dynamic>?)? onSuggestionSelected,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    if (readOnly) {
      return textField(
        key: key,
        label: label,
        value: value,
        onChanged: onChanged,
        required: required,
        readOnly: true,
      );
    }
    return Builder(
      builder: (context) {
        return TypeAheadInput(
          key: key,
          label: label,
          value: value,
          onChanged: onChanged,
          additionalSuggestions: additionalSuggestions,
          useStaffSuggestions: useStaffSuggestions,
          required: required,
          filterUnit: filterUnit,
          inputBorder: inputBorder,
          padding: padding,
          onSuggestionSelected: onSuggestionSelected,
          textCapitalization: textCapitalization,
        );
      },
    );
  }

  /// Section header
  static Widget sectionHeader(String title, {bool showUnderline = false}) {
    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);
        return Padding(
          padding: EdgeInsets.only(
            top: screen.value(mobile: 20.0, tablet: 24.0, desktop: 28.0),
            bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize:
                      screen.value(mobile: 16.0, tablet: 17.0, desktop: 18.0),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (showUnderline) ...[
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  width:
                      screen.value(mobile: 50.0, tablet: 55.0, desktop: 60.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Signatory banner info (Ultra-Minimalist)
  static Widget signatoryBanner({
    required List<String> names,
    required Color serviceColor,
    String? centerHeadName,
    bool disablePadding = false,
  }) {
    // Filter out null/empty names and deduplicate
    final uniqueNames = names
        .where((n) => n.trim().isNotEmpty && n.toLowerCase() != 'null')
        .map((n) => n.toUpperCase())
        .toSet()
        .toList();

    final hasCenterHead = centerHeadName != null &&
        centerHeadName.trim().isNotEmpty &&
        centerHeadName.toLowerCase() != 'null';

    if (uniqueNames.isEmpty && !hasCenterHead) return const SizedBox.shrink();

    final wrap = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...uniqueNames.map((name) => _buildTag(name, serviceColor)),
        if (hasCenterHead)
          _buildTag(centerHeadName.toUpperCase(), AppColors.primary),
      ],
    );

    if (disablePadding) return wrap;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: wrap,
    );
  }

  static Widget _buildTag(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }

  /// Selectable Signatory Tag (Interactive Empty/Filled state)
  static Widget selectableSignatoryTag({
    required BuildContext context,
    required String label,
    required String value,
    required Color serviceColor,
    required void Function(String) onChanged,
    String? filterUnit,
    bool useStaffSuggestions = true,
    VoidCallback? onManualTap, // Optional override for manual entry
  }) {
    if (value.trim().isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 2), // Adjusted for alignment
        decoration: BoxDecoration(
          color: serviceColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: serviceColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                color: serviceColor,
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => onChanged(''),
              child: Icon(LucideIcons.x, size: 14, color: serviceColor),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onManualTap ??
          () {
            showDialog(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: Text(
                    'Select $label',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  content: SizedBox(
                    width: 400,
                    child: FormFieldBuilders.typeAhead(
                      label: label,
                      value: '',
                      useStaffSuggestions: useStaffSuggestions,
                      filterUnit: filterUnit,
                      onChanged: (v) {},
                      onSuggestionSelected: (name, profile) {
                        onChanged(name);
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                );
              },
            );
          },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 2), // Adjusted for alignment
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Theme.of(context).unselectedWidgetColor.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Select $label',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold, // Match standard tags
                letterSpacing: 0.3,
                color: Theme.of(context).unselectedWidgetColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown,
                size: 16, color: Theme.of(context).unselectedWidgetColor),
          ],
        ),
      ),
    );
  }

  /// Signatory info display (Tag-style)
  static Widget signatoryInfo({
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.shieldCheck,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value.isEmpty ? 'NOT SET' : value.toUpperCase(),
                        style: TextStyle(
                          fontSize: screen.value(
                              mobile: 13.0, tablet: 14.0, desktop: 15.0),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'AUTO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Standard text field - responsive
  static Widget textField({
    Key? key,
    required String label,
    required dynamic value, // Changed to dynamic for type safety
    required void Function(String) onChanged,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
    bool enabled = true,
    bool readOnly = false,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    // Type guard: safely convert value to String
    final stringValue = _toSafeString(value);
    final isReadOnly = readOnly || !enabled;

    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);
        return ReactiveTextField(
          key: key,
          label: label,
          value: stringValue,
          onChanged: onChanged,
          required: required,
          keyboardType: keyboardType,
          maxLines: maxLines,
          hint: hint,
          enabled: enabled && !readOnly,
          readOnly: isReadOnly,
          suffixIcon: suffixIcon,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontSize: screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        );
      },
    );
  }

  /// Text area (multiline) - responsive
  static Widget textArea({
    Key? key,
    required String label,
    required dynamic value, // Changed to dynamic for type safety
    required void Function(String) onChanged,
    bool required = false,
    int maxLines = 4,
    String? hint,
    bool readOnly = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    // Type guard: safely convert value to String
    final stringValue = _toSafeString(value);

    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);
        return ReactiveTextField(
          key: key,
          label: label,
          value: stringValue,
          onChanged: onChanged,
          required: required,
          maxLines: screen.isMobile ? (maxLines - 1).clamp(2, 6) : maxLines,
          hint: hint,
          readOnly: readOnly,
          enabled: !readOnly,
          textCapitalization: textCapitalization,
          style: TextStyle(
            fontSize: screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        );
      },
    );
  }

  /// Dropdown selector - responsive
  static Widget dropdown({
    Key? key,
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool required = false,
    bool readOnly = false,
  }) {
    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);

        // Read-only: render as a non-interactive InputDecorator so it looks like
        // other read-only fields (no dropdown arrow, no focus/ink behavior).
        if (readOnly) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
            ),
            child: InputDecorator(
              // Non-interactive, but text uses normal body color like other
              // read-only text fields (e.g. Name).
              isEmpty: (value == null || value.toString().isEmpty),
              decoration: InputDecoration(
                labelText: required ? '$label *' : label,
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal:
                      screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
                  vertical:
                      screen.value(mobile: 10.0, tablet: 11.0, desktop: 12.0),
                ),
              ),
              child: Text(
                value?.toString() ?? '',
                style: TextStyle(
                  fontSize:
                      screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          child: DropdownButtonFormField<String>(
            key: key,
            initialValue: (value != null &&
                    items
                        .map((e) => e.toLowerCase())
                        .contains(value.toLowerCase()))
                ? items
                    .firstWhere((e) => e.toLowerCase() == value.toLowerCase())
                : null, // Allow null if not in list
            decoration: InputDecoration(
              labelText: required ? '$label *' : label,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              border: const OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal:
                    screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
                vertical:
                    screen.value(mobile: 10.0, tablet: 11.0, desktop: 12.0),
              ),
            ),
            style: TextStyle(
              fontSize: screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            isExpanded: true,
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
            onChanged: readOnly ? null : onChanged,
          ),
        );
      },
    );
  }

  /// Editable Dropdown (Combo Box) - allows selection or typing
  static Widget editableDropdown({
    Key? key,
    required String label,
    required String value,
    required List<String> items,
    required void Function(String) onChanged,
    bool required = false,
    bool readOnly = false,
  }) {
    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          child: readOnly
              ? InputDecorator(
                  decoration: InputDecoration(
                    labelText: required ? '$label *' : label,
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screen.value(
                          mobile: 12.0, tablet: 14.0, desktop: 16.0),
                      vertical: screen.value(
                          mobile: 10.0, tablet: 11.0, desktop: 12.0),
                    ),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: screen.value(
                          mobile: 14.0, tablet: 15.0, desktop: 16.0),
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                )
              : LayoutBuilder(builder: (context, constraints) {
                  return Autocomplete<String>(
                    key: key,
                    initialValue: TextEditingValue(text: value),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '' ||
                          items.any((item) =>
                              item.toLowerCase() ==
                              textEditingValue.text.toLowerCase())) {
                        return items;
                      }
                      return items.where((String option) {
                        return option
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      onChanged(selection);
                    },
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted) {
                      // Ensure controller is in sync if parent rebuilds value
                      if (fieldTextEditingController.text != value &&
                          !fieldFocusNode.hasFocus) {
                        // Only sync if not focused to avoid cursor jumping
                        fieldTextEditingController.text = value;
                      }

                      return TextFormField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        decoration: InputDecoration(
                          labelText: required ? '$label *' : label,
                          border: const OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screen.value(
                                mobile: 12.0, tablet: 14.0, desktop: 16.0),
                            vertical: screen.value(
                                mobile: 10.0, tablet: 11.0, desktop: 12.0),
                          ),
                          suffixIcon: const Icon(LucideIcons.chevronDown),
                        ),
                        style: TextStyle(
                          fontSize: screen.value(
                              mobile: 14.0, tablet: 15.0, desktop: 16.0),
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onChanged: onChanged,
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return InkWell(
                                  onTap: () {
                                    onSelected(option);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(option),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
        );
      },
    );
  }

  /// Date picker - responsive
  static Widget datePicker({
    Key? key,
    required String label,
    required dynamic value,
    required void Function(DateTime?) onChanged,
    bool required = false,
    bool readOnly = false,
  }) {
    DateTime? dateValue;
    if (value is DateTime) {
      dateValue = value;
    } else if (value is String && value.isNotEmpty) {
      dateValue = DateTime.tryParse(value);
    }

    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          child: InkWell(
            onTap: readOnly
                ? null
                : () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dateValue ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      onChanged(date);
                    }
                  },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: required ? '$label *' : label,
                border: const OutlineInputBorder(),
                suffixIcon: Icon(
                  LucideIcons.calendar,
                  size: screen.value(mobile: 20.0, tablet: 22.0, desktop: 24.0),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal:
                      screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
                  vertical:
                      screen.value(mobile: 10.0, tablet: 11.0, desktop: 12.0),
                ),
              ),
              child: Text(
                dateValue != null
                    ? '${dateValue.month}/${dateValue.day}/${dateValue.year}'
                    : 'Select date',
                style: TextStyle(
                  color: dateValue != null
                      ? Theme.of(context).textTheme.bodyMedium?.color
                      : Theme.of(context).hintColor,
                  fontSize:
                      screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Time picker - responsive
  static Widget timePicker({
    Key? key,
    required String label,
    required dynamic value,
    required void Function(String?) onChanged,
    bool required = false,
    bool readOnly = false,
  }) {
    TimeOfDay? timeValue;
    if (value is String && value.isNotEmpty) {
      final parts = value.split(':');
      if (parts.length >= 2) {
        timeValue = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          child: InkWell(
            onTap: readOnly
                ? null
                : () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: timeValue ?? TimeOfDay.now(),
                      initialEntryMode: TimePickerEntryMode.input,
                    );
                    if (time != null) {
                      onChanged(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                    }
                  },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: required ? '$label *' : label,
                border: const OutlineInputBorder(),
                suffixIcon: Icon(
                  LucideIcons.clock,
                  size: screen.value(mobile: 20.0, tablet: 22.0, desktop: 24.0),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal:
                      screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
                  vertical:
                      screen.value(mobile: 10.0, tablet: 11.0, desktop: 12.0),
                ),
              ),
              child: Text(
                timeValue != null ? timeValue.format(context) : 'Select time',
                style: TextStyle(
                  color: timeValue != null
                      ? Theme.of(context).textTheme.bodyMedium?.color
                      : Theme.of(context).hintColor,
                  fontSize:
                      screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Responsive row - becomes column on mobile
  static Widget responsiveRow({
    required List<Widget> children,
    double spacing = 16,
  }) {
    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);

        if (screen.isMobile) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children.asMap().entries.map((entry) {
            final isLast = entry.key == children.length - 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : spacing),
                child: entry.value,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Checkbox with remarks - responsive
  static Widget checkboxWithRemarks({
    required String label,
    required bool checked,
    required String remarks,
    required void Function(bool?) onCheckedChanged,
    required void Function(String) onRemarksChanged,
    bool readOnly = false,
  }) {
    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);

        if (screen.isMobile) {
          // Stack vertically on mobile
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: checked,
                        onChanged: readOnly ? null : onCheckedChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8),
                  child: TextFormField(
                    initialValue: remarks,
                    readOnly: readOnly,
                    decoration: const InputDecoration(
                      hintText: 'Remarks',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: onRemarksChanged,
                  ),
                ),
              ],
            ),
          );
        }

        // Side by side on larger screens
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: checked,
                  onChanged: readOnly ? null : onCheckedChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: remarks,
                  readOnly: readOnly,
                  decoration: const InputDecoration(
                    hintText: 'Remarks',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: onRemarksChanged,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Simple checkbox
  static Widget checkbox({
    required String label,
    required bool value,
    required void Function(bool?) onChanged,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: readOnly ? null : onChanged,
          ),
          Flexible(child: Text(label)),
        ],
      ),
    );
  }

  /// Radio group - responsive
  static Widget radioGroup({
    required String label,
    required String groupValue,
    required List<String> options,
    required void Function(String?) onChanged,
  }) {
    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize:
                      screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 0,
                children: options
                    .map(
                      (option) => SizedBox(
                        width: screen.isMobile ? double.infinity : null,
                        child: RadioListTile<String>(
                          title: Text(
                            option,
                            style: TextStyle(
                              fontSize: screen.value(
                                  mobile: 14.0, tablet: 15.0, desktop: 16.0),
                            ),
                          ),
                          value: option.toLowerCase(),
                          groupValue: groupValue.toLowerCase(),
                          onChanged: onChanged,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Digital signature capture field for external signatories.
  ///
  /// Opens a [SignaturePadDialog] for on-device drawing or image upload.
  /// The captured PNG is uploaded via [FormRepository.uploadExternalSignature]
  /// and the resulting URL is stored in form_data via [onChanged].
  ///
  /// [fieldName] - the form_data key for the signature URL (e.g. 'custodian_signature_url')
  /// [value]     - the current URL from form_data (null if not yet captured)
  /// [formId]    - the submission ID, used for storage path (pass null for unsaved drafts)
  /// [onChanged] - callback receiving the public URL string after upload
  static Widget digitalSignature({
    required String label,
    required String fieldName,
    required String? value,
    required String? formId,
    required void Function(String) onChanged,
    bool required = false,
  }) {
    return _DigitalSignatureField(
      label: label,
      fieldName: fieldName,
      value: value,
      formId: formId,
      onChanged: onChanged,
      required: required,
    );
  }

  /// Responsive table header
  static Widget tableHeader(List<String> columns, {List<int>? flexValues}) {
    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);

        // On mobile, show as card header
        if (screen.isMobile && columns.length > 3) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              'Form Entries',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: screen.value(mobile: 8.0, tablet: 10.0, desktop: 12.0),
            horizontal: screen.value(mobile: 6.0, tablet: 7.0, desktop: 8.0),
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: columns.asMap().entries.map((entry) {
              final flex = flexValues != null && entry.key < flexValues.length
                  ? flexValues[entry.key]
                  : 1;
              return Expanded(
                flex: flex,
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize:
                        screen.value(mobile: 11.0, tablet: 12.0, desktop: 13.0),
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Responsive table row
  static Widget tableRow({
    required List<Widget> cells,
    List<int>? flexValues,
    VoidCallback? onDelete,
  }) {
    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);

        // On mobile with many columns, show as card
        if (screen.isMobile && cells.length > 3) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...cells.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: entry.value,
                    );
                  }),
                  if (onDelete != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(LucideIcons.trash2,
                            size: 18, color: Colors.red),
                        label: const Text('Remove',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: screen.value(mobile: 6.0, tablet: 7.0, desktop: 8.0),
            horizontal: screen.value(mobile: 6.0, tablet: 7.0, desktop: 8.0),
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Theme.of(context).dividerColor),
              right: BorderSide(color: Theme.of(context).dividerColor),
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...cells.asMap().entries.map((entry) {
                final flex = flexValues != null && entry.key < flexValues.length
                    ? flexValues[entry.key]
                    : 1;
                return Expanded(
                  flex: flex,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: entry.value,
                  ),
                );
              }),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(LucideIcons.trash2,
                      size: 20, color: Colors.red),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Dynamic list builder (bullet points)
  static Widget dynamicList({
    required String label,
    required List<String> values,
    required void Function(List<String>) onChanged,
    String? hint,
  }) {
    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);
        final controllers =
            values.map((e) => TextEditingController(text: e)).toList();

        return Padding(
          padding: EdgeInsets.only(
            bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize:
                      screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < controllers.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 12.0, right: 8.0),
                                child: const Icon(LucideIcons.circle, size: 8),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: controllers[i],
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    hintText: hint ?? 'Enter item...',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (_) {
                                    // Update values on change
                                    final newValues = controllers
                                        .where((c) => c.text.isNotEmpty)
                                        .map((c) => c.text)
                                        .toList();
                                    onChanged(newValues);
                                  },
                                  minLines: 1,
                                  maxLines: 3,
                                ),
                              ),
                              IconButton(
                                icon: Icon(LucideIcons.x,
                                    size: 20,
                                    color: Theme.of(context).disabledColor),
                                onPressed: () {
                                  setState(() {
                                    controllers.removeAt(i);
                                    final newValues = controllers
                                        .where((c) => c.text.isNotEmpty)
                                        .map((c) => c.text)
                                        .toList();
                                    onChanged(newValues);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                      // Add Item Button
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              controllers.add(TextEditingController());
                            });
                          },
                          icon: const Icon(LucideIcons.plus, size: 18),
                          label: const Text('Add Item'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Multi-select field with dialog
  static Widget multiSelect({
    required String label,
    required List<String> values,
    required List<String> options,
    required void Function(List<String>) onChanged,
    bool required = false,
    bool allowCustom = false,
    Future<List<String>> Function()? fetchOptions,
  }) {
    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                required ? '$label *' : label,
                style: TextStyle(
                  fontSize:
                      screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final selected = List<String>.from(values);

                  // Show dialog
                  final result = await showDialog<List<String>>(
                    context: context,
                    builder: (context) => _MultiSelectDialog(
                      label: label,
                      initialSelected: selected,
                      options: options, // Pass explicit options
                      fetchOptions: fetchOptions,
                      allowCustom: allowCustom,
                    ),
                  );
                  if (result != null) {
                    onChanged(result);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: values.isEmpty
                      ? Text(
                          'Select entries...',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: values
                              .map((v) => Chip(
                                    label: Text(v,
                                        style: const TextStyle(fontSize: 12)),
                                    onDeleted: () {
                                      final newValues =
                                          List<String>.from(values)..remove(v);
                                      onChanged(newValues);
                                    },
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Add row button
  static Widget addRowButton(VoidCallback onPressed) {
    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);
        return Padding(
          padding: EdgeInsets.only(
            top: screen.value(mobile: 8.0, tablet: 10.0, desktop: 12.0),
            bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          child: screen.isMobile
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Add Entry'),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Add Row'),
                ),
        );
      },
    );
  }

  /// Divider
  static Widget divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(),
    );
  }

  /// Info text - responsive
  static Widget infoText(String text) {
    return Builder(
      builder: (context) {
        final screen = ScreenInfo.of(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          child: Container(
            padding: EdgeInsets.all(
              screen.value(mobile: 10.0, tablet: 11.0, desktop: 12.0),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.info,
                  color: Theme.of(context).colorScheme.primary,
                  size: screen.value(mobile: 18.0, tablet: 19.0, desktop: 20.0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: screen.value(
                          mobile: 13.0, tablet: 14.0, desktop: 15.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Image picker - responsive
  static Widget imagePicker({
    required String label,
    required String? value,
    required void Function(String) onChanged,
    bool readOnly = false,
  }) {
    return Builder(
      builder: (context) {
        return FormImagePicker(
          label: label,
          value: value,
          onChanged: onChanged,
          readOnly: readOnly,
        );
      },
    );
  }

  static Widget bulletList({
    required String label,
    required String value,
    required void Function(String) onChanged,
    bool required = false,
    bool useStaffSuggestions = false,
  }) {
    return Builder(
      builder: (context) {
        return BulletListInput(
          label: label,
          value: value,
          onChanged: onChanged,
          required: required,
          useStaffSuggestions: useStaffSuggestions,
        );
      },
    );
  }
}

class BulletListInput extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool required;
  final bool useStaffSuggestions;

  const BulletListInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.useStaffSuggestions = false,
  });

  @override
  State<BulletListInput> createState() => _BulletListInputState();
}

class _BulletListInputState extends State<BulletListInput> {
  late List<TextEditingController> _controllers;
  List<String> _staffOptions = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (widget.useStaffSuggestions) {
      _fetchStaffOptions();
    }
  }

  static List<String>? _cachedStaffOptions;

  Future<void> _fetchStaffOptions() async {
    if (_cachedStaffOptions != null) {
      if (mounted) {
        setState(() {
          _staffOptions = _cachedStaffOptions!;
        });
      }
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .order('full_name');

      if (mounted) {
        final options = (response as List)
            .map((e) {
              return e['full_name']?.toString().toUpperCase() ?? '';
            })
            .where((s) => s.isNotEmpty)
            .toList();

        setState(() {
          _staffOptions = options;
          _cachedStaffOptions = options;
        });
      }
    } catch (e) {
      debugPrint('Error fetching staff options: $e');
    }
  }

  // Simplified fetch using context read in optionsBuilder (lazy load)

  void _initControllers() {
    final List<String> items =
        widget.value.isEmpty ? [''] : widget.value.split('\n');
    _controllers = items.map((e) => TextEditingController(text: e)).toList();
  }

  @override
  void didUpdateWidget(BulletListInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final newItems = widget.value.isEmpty ? [''] : widget.value.split('\n');
      final currentItems = _controllers.map((c) => c.text).toList();

      bool needsUpdate = newItems.length != currentItems.length;
      if (!needsUpdate) {
        for (int i = 0; i < newItems.length; i++) {
          if (newItems[i] != currentItems[i]) {
            needsUpdate = true;
            break;
          }
        }
      }

      if (needsUpdate) {
        for (var c in _controllers) {
          c.dispose();
        }
        _initControllers();
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _emitChange() {
    final text = _controllers.map((c) => c.text).join('\n');
    widget.onChanged(text);
  }

  void _addItem() {
    setState(() {
      _controllers.add(TextEditingController());
      _emitChange();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      _emitChange();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.required ? '${widget.label} *' : widget.label,
            style: TextStyle(
              fontSize: screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ..._controllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;

            Widget inputField;

            if (widget.useStaffSuggestions) {
              // Autocomplete for staff
              inputField = LayoutBuilder(builder: (context, constraints) {
                return Autocomplete<String>(
                  initialValue: TextEditingValue(text: controller.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (_staffOptions.isEmpty) {
                      return const Iterable<String>.empty();
                    }

                    if (textEditingValue.text == '') {
                      return _staffOptions;
                    }
                    return _staffOptions.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    controller.text = selection;
                    _emitChange();
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted) {
                    return TextFormField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.all(12),
                        suffixIcon: _controllers.length > 1
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 18),
                                onPressed: () => _removeItem(index),
                                tooltip: 'Remove item',
                              )
                            : null,
                      ),
                      onChanged: (v) {
                        controller.text = v;
                        _emitChange();
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(option),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              });
            } else {
              // Standard Text Field
              inputField = TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(12),
                  suffixIcon: _controllers.length > 1
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () => _removeItem(index),
                          tooltip: 'Remove item',
                        )
                      : null,
                ),
                maxLines: null,
                onChanged: (v) => _emitChange(),
              );
            }

            return Padding(
              key: ObjectKey(controller),
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14.0, right: 8.0),
                    child: Icon(LucideIcons.circle,
                        size: 6,
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Expanded(child: inputField),
                ],
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: _addItem,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Item'),
          ),
        ],
      ),
    );
  }
}

class TypeAheadInput extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> additionalSuggestions;
  final bool useStaffSuggestions;
  final bool required;
  final String? filterUnit;
  final InputBorder? inputBorder;
  final EdgeInsetsGeometry? padding;
  final TextCapitalization textCapitalization;

  const TypeAheadInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.additionalSuggestions = const [],
    this.useStaffSuggestions = true,
    this.required = false,
    this.filterUnit,
    this.inputBorder,
    this.padding,
    this.onSuggestionSelected,
    this.textCapitalization = TextCapitalization.none,
  });

  // Callback passing (selectedValue, extraDataMap)
  final void Function(String, Map<String, dynamic>?)? onSuggestionSelected;

  @override
  State<TypeAheadInput> createState() => _TypeAheadInputState();
}

class _TypeAheadInputState extends State<TypeAheadInput> {
  late TextEditingController _controller;
  List<String> _staffOptions = [];
  final Map<String, String> _staffRoles = {};
  final Map<String, String> _staffUnits = {};
  final Map<String, String> _staffTitles = {};
  final FocusNode _focusNode = FocusNode();
  bool _wasTapped = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    if (widget.useStaffSuggestions) {
      _fetchStaffOptions();
    }
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      widget.onChanged(_controller.text);
    }
  }

  @override
  void didUpdateWidget(covariant TypeAheadInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  static List<String>? _cachedStaffOptions;
  static Map<String, String>? _cachedStaffRoles;
  static Map<String, String>? _cachedStaffUnits;
  static Map<String, String>? _cachedStaffTitles;

  Future<void> _fetchStaffOptions() async {
    // If we have globally cached staff, try to use it to filter synchronously!
    if (_cachedStaffOptions != null) {
      if (mounted) {
        setState(() {
          _staffOptions.clear();
          _staffRoles.addAll(_cachedStaffRoles ?? {});
          _staffUnits.addAll(_cachedStaffUnits ?? {});
          if (_cachedStaffTitles != null) {
            _staffTitles.addAll(_cachedStaffTitles!);
          }

          if (widget.filterUnit != null) {
            // Filter the existing cache synchronously avoiding network race-conditions!
            final targetUnit =
                widget.filterUnit!.toUpperCase().replaceAll('_', ' ');
            for (final name in _cachedStaffOptions!) {
              if (_staffUnits[name] == targetUnit) {
                _staffOptions.add(name);
              }
            }
          } else {
            _staffOptions = List.from(_cachedStaffOptions!);
          }
        });
        // If the user already focused during a microsecond lag, force show dropdown
        if (_focusNode.hasFocus) {
          _triggerDropdownRefresh();
        }
      }
      return;
    }

    try {
      var query = Supabase.instance.client
          .from('profiles')
          .select('full_name, role, unit, title')
          .eq('is_active', true); // Only fetch active personnel

      if (widget.filterUnit != null) {
        query = query.eq('unit', widget.filterUnit!);
      }

      final response = await query.order('full_name');

      if (mounted) {
        setState(() {
          _staffOptions.clear();
          _staffRoles.clear();
          _staffUnits.clear();

          for (var item in (response as List)) {
            final name = item['full_name']?.toString().toUpperCase() ?? '';
            final role =
                item['role']?.toString().replaceAll('_', ' ').toUpperCase() ??
                    '';
            final unit =
                item['unit']?.toString().replaceAll('_', ' ').toUpperCase() ??
                    '';
            final title = item['title']?.toString() ?? '';

            if (name.isNotEmpty) {
              _staffOptions.add(name);
              _staffRoles[name] = role;
              _staffUnits[name] = unit;
              if (title.isNotEmpty) {
                _staffTitles[name] = title;
              }
            }
          }

          if (widget.filterUnit == null) {
            _cachedStaffOptions = List.from(_staffOptions);
            _cachedStaffRoles = Map.from(_staffRoles);
            _cachedStaffUnits = Map.from(_staffUnits);
            _cachedStaffTitles = Map.from(_staffTitles);
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching staff options: $e');
    }
  }

  List<String> _getSuggestions(String query) {
    // Multi-select logic: filter based on the last comma-separated value
    final parts = query.split(',');
    final currentQuery = parts.last.trim().toLowerCase();

    final allOptions = <String>{
      ..._staffOptions,
      ...widget.additionalSuggestions,
    }.toList();

    // If query is empty, ends with comma, or was just tapped, show all
    if (currentQuery.isEmpty || _wasTapped) {
      _wasTapped = false; // Reset after one use
      // Only show specific number if truly empty, otherwise if user typed comma we show options
      return allOptions.take(10).toList();
    }

    final filtered = allOptions
        .where((option) => option.toLowerCase().contains(currentQuery))
        .take(5)
        .toList();

    // Allow adding custom value if it's not an exact match
    if (currentQuery.isNotEmpty &&
        !allOptions.any((o) => o.toLowerCase() == currentQuery)) {
      filtered.add('Add "${parts.last.trim()}"');
    }

    return filtered;
  }

  void _triggerDropdownRefresh() {
    setState(() {
      _wasTapped = true;
    });
    final text = _controller.text;
    // Force triggering the dropdown by briefly clearing and resetting the value
    // RawAutocomplete only recalculates when the text value changes.
    _controller.value = const TextEditingValue(text: '');
    Future.microtask(() {
      if (mounted) {
        _controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);

    return Padding(
      padding: widget.padding ??
          EdgeInsets.only(
            bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
      child: LayoutBuilder(builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            return _getSuggestions(textEditingValue.text);
          },
          onSelected: (String selection) {
            // Handle "Add" logic
            String valueToAdd = selection;
            if (selection.startsWith('Add "') && selection.endsWith('"')) {
              valueToAdd = selection.substring(5, selection.length - 1);
            }

            // Multi-select logic: Append to existing text
            final currentText = _controller.text;
            final lastCommaIndex = currentText.lastIndexOf(',');

            String newText;
            if (lastCommaIndex == -1) {
              // No commas yet, just replace
              newText = valueToAdd.toUpperCase();
            } else {
              // Replace everything after last comma
              newText =
                  '${currentText.substring(0, lastCommaIndex + 1)} ${valueToAdd.toUpperCase()}';
            }

            widget.onChanged(newText);

            // Trigger extra data callback if available
            if (widget.onSuggestionSelected != null) {
              final role = _staffRoles[valueToAdd];
              final unit = _staffUnits[valueToAdd];
              final title = _staffTitles[valueToAdd];
              widget.onSuggestionSelected!(valueToAdd, {
                if (role != null) 'role': role,
                if (unit != null) 'unit': unit,
                if (title != null) 'title': title,
              });
            }

            // Verify controller update happens via listener or parent update,
            // but we can also force it here to be responsive immediate
            _controller.text = newText;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: newText.length),
            );
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              onChanged: (v) {
                final upper = v.toUpperCase();
                if (v != upper) {
                  textEditingController.value =
                      textEditingController.value.copyWith(
                    text: upper,
                    selection: textEditingController.selection,
                  );
                }
                widget.onChanged(upper);
              },
              textCapitalization: widget.textCapitalization,
              onTap: _triggerDropdownRefresh,
              decoration: InputDecoration(
                labelText: widget.required ? '${widget.label} *' : widget.label,
                border: widget.inputBorder ?? const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
                suffixIcon: const Icon(LucideIcons.chevronDown, size: 20),
              ),
              validator: widget.required
                  ? (v) =>
                      (v == null || v.isEmpty) ? 'This field is required' : null
                  : null,
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  // Constrain width to the parent input field
                  width: constraints.maxWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return InkWell(
                        onTap: () {
                          onSelected(option);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(option),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _MultiSelectDialog extends StatefulWidget {
  final String label;
  final List<String> initialSelected;
  final List<String> options;
  final Future<List<String>> Function()? fetchOptions;
  final bool allowCustom;

  const _MultiSelectDialog({
    // ignore: unused_element
    required this.label,
    required this.initialSelected,
    required this.options,
    this.fetchOptions,
    required this.allowCustom,
  });

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late List<String> _selected;
  List<String> _loadedOptions = [];
  bool _isLoading = false;
  final TextEditingController _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _loadedOptions = List.from(widget.options);
    if (widget.fetchOptions != null) {
      _loadOptions();
    }
  }

  Future<void> _loadOptions() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await widget.fetchOptions!();
      if (mounted) {
        setState(() {
          // Merge avoiding duplicates
          final set = <String>{..._loadedOptions, ...fetched};
          _loadedOptions = set.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Combine loaded options with any selected options that might not be in the list
    // (though usually they should be, unless custom)
    final allOptions = {..._loadedOptions, ..._selected}.toList();

    return AlertDialog(
      title: Text('Select ${widget.label}'),
      content: SizedBox(
        // Use max width for dialog
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            if (widget.allowCustom)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customController,
                        decoration: const InputDecoration(
                          hintText: 'Add custom...',
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.plus),
                      onPressed: () {
                        if (_customController.text.isNotEmpty) {
                          final val = _customController.text.trim();
                          if (val.isNotEmpty && !_selected.contains(val)) {
                            setState(() {
                              _selected.add(val);
                              _customController.clear();
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...allOptions.map((option) => CheckboxListTile(
                        title: Text(option),
                        value: _selected.contains(option),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selected.add(option);
                            } else {
                              _selected.remove(option);
                            }
                          });
                        },
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class RepeatableFormSection extends StatefulWidget {
  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final Widget Function(int index, String value, ValueChanged<String> onChanged)
      itemBuilder;
  final String? addLabel;
  final bool required;

  const RepeatableFormSection({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    required this.itemBuilder,
    this.addLabel,
    this.required = false,
  });

  @override
  State<RepeatableFormSection> createState() => _RepeatableFormSectionState();
}

class _RepeatableFormSectionState extends State<RepeatableFormSection> {
  late List<String> _values;

  @override
  void initState() {
    super.initState();
    _values = List.from(widget.values);
    if (_values.isEmpty) _values.add('');
  }

  @override
  void didUpdateWidget(RepeatableFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.values.length != _values.length ||
        !widget.values
            .asMap()
            .entries
            .every((e) => e.value == _values[e.key])) {
      if (widget.values.isNotEmpty) {
        _values = List.from(widget.values);
      }
    }
  }

  void _onItemChanged(int index, String newValue) {
    setState(() {
      _values[index] = newValue;
    });
    widget.onChanged(_values);
  }

  void _addItem() {
    setState(() {
      _values.add('');
    });
    widget.onChanged(_values);
  }

  void _removeItem(int index) {
    setState(() {
      _values.removeAt(index);
      if (_values.isEmpty) _values.add('');
    });
    widget.onChanged(_values);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.required ? '${widget.label} *' : widget.label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
        ],
        ..._values.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: widget.itemBuilder(
                      index, value, (v) => _onItemChanged(index, v)),
                ),
                if (_values.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, left: 8.0),
                    child: IconButton(
                      icon: const Icon(LucideIcons.circleMinus,
                          color: Colors.red),
                      onPressed: () => _removeItem(index),
                      tooltip: 'Remove item',
                    ),
                  ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: _addItem,
          icon: const Icon(LucideIcons.plus),
          label: Text(widget.addLabel ?? 'Add Item'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Stateful widget for the digital signature capture field.
/// Handles opening the [SignaturePadDialog], uploading the result,
/// and displaying the captured signature.
class _DigitalSignatureField extends StatefulWidget {
  final String label;
  final String fieldName;
  final String? value;
  final String? formId;
  final void Function(String) onChanged;
  final bool required;

  const _DigitalSignatureField({
    required this.label,
    required this.fieldName,
    required this.value,
    required this.formId,
    required this.onChanged,
    this.required = false,
  });

  @override
  State<_DigitalSignatureField> createState() => _DigitalSignatureFieldState();
}

class _DigitalSignatureFieldState extends State<_DigitalSignatureField> {
  bool _isUploading = false;

  Future<void> _capture() async {
    final bytes = await SignaturePadDialog.show(
      context,
      title: widget.label,
    );
    if (bytes == null || !mounted) return;

    // If we have a formId, upload to Supabase Storage and get a URL.
    // Otherwise, store as a base64 data URI (unsaved draft).
    setState(() => _isUploading = true);
    try {
      String url;
      if (widget.formId != null) {
        url = await FormRepository().uploadExternalSignature(
          formId: widget.formId!,
          fieldName: widget.fieldName.replaceAll('_signature_url', ''),
          bytes: bytes,
        );
      } else {
        url = 'data:image/png;base64,${base64Encode(bytes)}';
      }
      widget.onChanged(url);
    } catch (e) {
      debugPrint('[DigitalSignature] Upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save signature: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);
    final hasSignature = widget.value != null && widget.value!.isNotEmpty;
    final isRequiredAndEmpty = widget.required && !hasSignature;

    return Padding(
      padding: EdgeInsets.only(
        bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.required ? '${widget.label} *' : widget.label,
            style: TextStyle(
              fontSize: screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
              fontWeight: FontWeight.w500,
              color: isRequiredAndEmpty ? AppColors.error : null,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: screen.value(mobile: 80.0, tablet: 90.0, desktop: 100.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasSignature
                    ? AppColors.primary
                    : isRequiredAndEmpty
                        ? AppColors.error
                        : Theme.of(context).dividerColor,
                width: hasSignature || isRequiredAndEmpty ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: _isUploading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : hasSignature
                    ? Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: _buildSignatureImage(widget.value!),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(LucideIcons.pencil, size: 18),
                              onPressed: _capture,
                              tooltip: 'Re-capture signature',
                            ),
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: _capture,
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.penLine,
                                color: Theme.of(context).hintColor,
                                size: screen.value(
                                    mobile: 24.0, tablet: 28.0, desktop: 32.0),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to capture signature',
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: screen.value(
                                      mobile: 12.0,
                                      tablet: 13.0,
                                      desktop: 14.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureImage(String url) {
    if (url.startsWith('data:image')) {
      final base64Str = url.split(',').last;
      return Image.memory(
        base64Decode(base64Str),
        fit: BoxFit.contain,
      );
    }
    return Image.network(url, fit: BoxFit.contain);
  }
}
