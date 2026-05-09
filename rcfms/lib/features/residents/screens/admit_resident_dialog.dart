import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/resident_model.dart';
import '../../../data/models/ward_model.dart';
import '../../../data/repositories/resident_repository.dart';
import '../../../core/utils/responsive.dart';

class AdmitResidentDialog extends StatefulWidget {
  final ResidentModel resident;

  const AdmitResidentDialog({super.key, required this.resident});

  @override
  State<AdmitResidentDialog> createState() => _AdmitResidentDialogState();
}

class _AdmitResidentDialogState extends State<AdmitResidentDialog> {
  final _formKey = GlobalKey<FormState>();
  // _bedNumberController removed in favor of dropdown

  WardModel? _selectedWard;
  List<WardModel> _wards = [];

  List<String> _availableBeds = [];
  String? _selectedBed;
  bool _loadingBeds = false;

  DateTime _admissionDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWards();
    // Pre-fill if already set (rare but possible) or default to now
    if (widget.resident.admissionDate != null) {
      _admissionDate = widget.resident.admissionDate!;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadWards() async {
    try {
      final repository = context.read<ResidentRepository>();
      final wards = await repository.getWards();
      setState(() {
        _wards = wards;
        // If resident already has a ward assigned (maybe tentative), pre-select it
        if (widget.resident.wardId != null) {
          try {
            _selectedWard =
                wards.firstWhere((w) => w.id == widget.resident.wardId);
          } catch (_) {}
        }
        if (_selectedWard == null && wards.isNotEmpty) {
          _selectedWard = wards.first;
        }
      });
      // Load beds for selected ward immediately
      if (_selectedWard != null) {
        _loadBeds(_selectedWard!);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadBeds(WardModel ward) async {
    setState(() {
      _loadingBeds = true;
      _selectedBed = null; // Reset selection on ward change
    });

    try {
      final repository = context.read<ResidentRepository>();
      final beds = await repository.getAvailableBeds(ward,
          excludeResidentId: widget.resident.id);

      setState(() {
        _availableBeds = beds;
        // Pre-select if keeping same bed (unlikely for admit, but consistency)
        if (widget.resident.wardId == ward.id &&
            widget.resident.bedNumber != null &&
            _availableBeds.contains(widget.resident.bedNumber)) {
          _selectedBed = widget.resident.bedNumber;
        }
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _loadingBeds = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _admissionDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (date != null) {
      setState(() {
        _admissionDate = date;
      });
    }
  }

  Future<void> _confirmAdmission() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a ward')),
      );
      return;
    }
    if (_selectedBed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bed')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = context.read<ResidentRepository>();

      // Generate new Case Number (C-YYMM)
      // Format: C-YYMM + Sequence
      final datePart = DateFormat('yyMM').format(_admissionDate);
      final prefix = 'C-$datePart';

      final latestCaseNumber = await repository.getLatestCaseNumber(prefix);
      int nextSequence = 1;

      if (latestCaseNumber != null) {
        // Extract sequence part (assuming format C-YYMM-XX or C-YYMMXX)
        // Let's assume standard format is C-YYMMXX (e.g., C-250501)
        try {
          final sequencePart = latestCaseNumber.substring(prefix.length);
          nextSequence = int.parse(sequencePart) + 1;
        } catch (_) {
          // Fallback if parsing fails
          nextSequence = 1;
        }
      }

      final newCaseNumber = '$prefix${nextSequence.toString().padLeft(2, '0')}';

      await repository.updateResident(
        id: widget.resident.id,
        status: 'admitted',
        caseNumber: newCaseNumber, // Assign new C- number
        wardId: _selectedWard!.id,
        roomNumber: null,
        bedNumber: _selectedBed,
        admissionDate: _admissionDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${widget.resident.firstName} successfully admitted.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to admit resident: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Admit ${widget.resident.firstName}'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.tablet),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completing admission process will formally admit the resident into the facility and assign them to a ward.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
                const SizedBox(height: 16),

                // Ward selection
                DropdownButtonFormField<WardModel>(
                  initialValue:
                      _selectedWard, // Use value instead of initialValue for dynamic updates
                  decoration: const InputDecoration(
                    labelText: 'WARD *',
                    prefixIcon: Icon(LucideIcons.mapPin),
                  ),
                  items: _wards
                      .map((ward) => DropdownMenuItem(
                            value: ward,
                            child: Text(ward.name.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedWard = value;
                    });
                    if (value != null) {
                      _loadBeds(value);
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Please select a ward' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedBed,
                  decoration: const InputDecoration(
                    labelText: 'BED *',
                    prefixIcon: Icon(LucideIcons.bed),
                  ),
                  items: _availableBeds
                      .map((bed) =>
                          DropdownMenuItem(value: bed, child: Text(bed)))
                      .toList(),
                  onChanged: _loadingBeds
                      ? null
                      : (value) => setState(() => _selectedBed = value),
                  validator: (value) => value == null ? 'Required' : null,
                  hint: _loadingBeds ? const Text('Loading...') : null,
                ),
                const SizedBox(height: 16),

                // Admission date
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'ADMISSION DATE *',
                      prefixIcon: Icon(LucideIcons.calendar),
                    ),
                    child: Text(
                      DateFormat('MMMM d, yyyy')
                          .format(_admissionDate)
                          .toUpperCase(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirmAdmission,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('ADMIT RESIDENT'),
        ),
      ],
    );
  }
}
