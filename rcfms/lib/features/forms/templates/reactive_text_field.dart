import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/responsive.dart';

class ReactiveTextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool required;
  final TextInputType keyboardType;
  final int maxLines;
  final String? hint;
  final bool enabled;
  final bool readOnly;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;

  const ReactiveTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.style,
  });

  @override
  State<ReactiveTextField> createState() => _ReactiveTextFieldState();
}

class _ReactiveTextFieldState extends State<ReactiveTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant ReactiveTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller if value changes from outside (and mismatch)
    // We check if controller.text != widget.value to avoid treating
    // cursor movement or identical updates as changes, but primarily
    // to accept programmatic changes.
    // CAUTION: If user is typing, widget.value updates via onChanged.
    // If we re-set text, cursor might jump to end.
    // But here, the value comes from parent.
    // If parent value != controller text, it means parent wants to OVERRIDE.
    if (widget.value != _controller.text) {
      // To avoid cursor jumping when the user is typing (which triggers parent update -> widget update),
      // usually we check if the change is "significant" or verify if it matches.
      // But here, since we want to support "Length of Stay" reacting to "Date",
      // that is an external change.
      // If the user *types* in this field, _controller.text updates -> calls onChanged -> parent updates value -> widget.value updates.
      // In that loop, widget.value == _controller.text. So we WON'T reset it.
      // So this logic safely handles external overrides!
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = ScreenInfo.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
      ),
      child: TextFormField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.required ? '${widget.label} *' : widget.label,
          hintText: widget.hint,
          suffixIcon: widget.suffixIcon,
          contentPadding: const EdgeInsets.all(12),
        ),
        style: widget.style ??
            TextStyle(
              fontSize: screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
            ),
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        maxLines: widget.maxLines,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        onChanged: widget.onChanged,
        inputFormatters: widget.inputFormatters,
        validator: widget.required
            ? (v) => (v == null || v.isEmpty) ? 'This field is required' : null
            : null,
      ),
    );
  }
}
