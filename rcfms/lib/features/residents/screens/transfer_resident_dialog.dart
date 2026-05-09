import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/resident_model.dart';
import '../../../data/models/ward_model.dart';
import '../../../data/repositories/resident_repository.dart';
import '../../../core/utils/responsive.dart';

class TransferResidentDialog extends StatefulWidget {
  final ResidentModel resident;

  const TransferResidentDialog({super.key, required this.resident});

  @override
  State<TransferResidentDialog> createState() => _TransferResidentDialogState();
}

class _TransferResidentDialogState extends State<TransferResidentDialog> {
  final _formKey = GlobalKey<FormState>();

  WardModel? _selectedWard;
  List<WardModel> _wards = [];

  List<String> _availableBeds = [];
  String? _selectedBed;
  bool _loadingBeds = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWards();
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
        // Pre-select current ward
        if (widget.resident.wardId != null) {
          try {
            _selectedWard =
                wards.firstWhere((w) => w.id == widget.resident.wardId);
          } catch (_) {}
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
      // If switching to a new ward, reset bed. If same ward, try keep bed (for editing)
      // proper transfer usually implies moving out of current bed, but let's allow re-assigning if moving room.
      if (ward.id != widget.resident.wardId) {
        _selectedBed = null;
      } else {
        _selectedBed = widget.resident.bedNumber;
      }
    });

    try {
      final repository = context.read<ResidentRepository>();
      final beds = await repository.getAvailableBeds(ward,
          excludeResidentId: widget.resident.id);

      setState(() {
        _availableBeds = beds;
        // Ensure current bed is in list if selected (since we excluded our own ID in query, our bed IS available to us)
        if (_selectedBed != null && !_availableBeds.contains(_selectedBed)) {
          _availableBeds.add(_selectedBed!);
          _availableBeds.sort(
              (a, b) => int.tryParse(a)?.compareTo(int.tryParse(b) ?? 0) ?? 0);
        }
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _loadingBeds = false);
    }
  }

  Future<void> _confirmTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWard == null) return;
    if (_selectedBed == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = context.read<ResidentRepository>();

      await repository.updateResident(
        id: widget.resident.id,
        wardId: _selectedWard!.id,
        roomNumber: null,
        bedNumber: _selectedBed,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${widget.resident.firstName} transferred successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to transfer resident: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Transfer ${widget.resident.firstName}'),
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
                  'Assign resident to a new ward or bed.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
                const SizedBox(height: 16),

                // Ward selection
                DropdownButtonFormField<WardModel>(
                  initialValue: _selectedWard,
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
                    if (value != null) {
                      setState(() => _selectedWard = value);
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
          onPressed: _isLoading ? null : _confirmTransfer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
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
              : const Text('TRANSFER'),
        ),
      ],
    );
  }
}
