import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/text_formatters.dart'; // Re-added for UpperCaseTextFormatter
import '../../../data/models/resident_model.dart';
import '../../../data/models/ward_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/resident_repository.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_error_dialog.dart';

class AdmitResidentWizard extends StatefulWidget {
  final ResidentModel resident;

  const AdmitResidentWizard({super.key, required this.resident});

  @override
  State<AdmitResidentWizard> createState() => _AdmitResidentWizardState();
}

class _AdmitResidentWizardState extends State<AdmitResidentWizard> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // --- Step 1: Ward & Location ---
  WardModel? _selectedWard;
  String? _selectedBed;
  List<WardModel> _wards = [];
  List<String> _availableBeds = [];
  final _caseNumberController = TextEditingController();
  DateTime _admissionDate = DateTime.now();
  bool _isBedLoading = false;

  // --- Step 2: Supervision ---
  List<UserModel> _houseparents = [];
  String? _selectedHouseparentId;
  List<UserModel> _socialWorkers = []; // Added
  String? _selectedSocialWorkerId; // Added

  @override
  void initState() {
    super.initState();
    _selectedSocialWorkerId = widget.resident.socialWorkerId;
    _loadInitialData();
  }

  @override
  void dispose() {
    _caseNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Load Wards
      final wards = await context.read<ResidentRepository>().getWards();

      // 2. Load Houseparents and Social Workers
      final hps = await AdminRepository().getHouseparents();
      final sws = await AdminRepository().getSocialWorkers();

      if (mounted) {
        setState(() {
          _wards = wards;
          _houseparents = hps;
          _socialWorkers = sws;
        });

        // Auto-generate Case Number (C-...)
        await _suggestCaseNumber();
      }
    } catch (e) {
      debugPrint('Error loading wizard data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _suggestCaseNumber() async {
    final prefix = 'C-${DateFormat('yyMM').format(_admissionDate)}';
    _caseNumberController.text = '$prefix...';

    try {
      final latest =
          await context.read<ResidentRepository>().getLatestCaseNumber(prefix);
      if (!mounted) return;

      if (latest == null) {
        _caseNumberController.text = '${prefix}01';
      } else {
        final sequenceStr = latest.substring(prefix.length);
        final sequence = int.parse(sequenceStr);
        final nextSequence = sequence + 1;
        final padding = sequenceStr.length < 2 ? 2 : sequenceStr.length;
        _caseNumberController.text =
            '$prefix${nextSequence.toString().padLeft(padding, '0')}';
      }
    } catch (e) {
      if (mounted) _caseNumberController.text = '${prefix}01';
    }
  }

  Future<void> _loadBeds(String wardId) async {
    setState(() => _isBedLoading = true);
    try {
      final usedResidents =
          await context.read<ResidentRepository>().getResidentsByWardId(wardId);
      final usedBeds =
          usedResidents.map((r) => r.bedNumber).where((b) => b != null).toSet();

      final ward = _wards.firstWhere((w) => w.id == wardId);

      final allBeds = List.generate(ward.capacity, (i) => (i + 1).toString());
      final available = allBeds.where((b) => !usedBeds.contains(b)).toList();

      if (mounted) {
        setState(() {
          _availableBeds = available;
          if (_selectedBed != null && !_availableBeds.contains(_selectedBed)) {
            _selectedBed = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading beds: $e');
      if (mounted) {
        setState(() {
          _availableBeds = List.generate(50, (i) => (i + 1).toString());
        });
      }
    } finally {
      if (mounted) setState(() => _isBedLoading = false);
    }
  }

  Future<void> _submitAdmission() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = context.read<ResidentRepository>();

      await repo.updateResident(
        id: widget.resident.id,
        status: 'admitted',
        isActive: true, // Set to true to re-activate discharged residents

        // Ward & Location
        wardId: _selectedWard?.id,
        roomNumber: null,
        bedNumber: _selectedBed,
        admissionDate: _admissionDate,
        caseNumber: _caseNumberController.text,

        // Emergency contact fields removed as requested

        // Supervision
        houseparentId: _selectedHouseparentId,
        socialWorkerId: _selectedSocialWorkerId, // Added
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Resident successfully admitted!'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomErrorDialog.show(context,
            title: 'Admission Failed',
            error: e,
            message: 'Could not admit resident.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: isCompact ? double.infinity : 600,
        constraints: BoxConstraints(maxHeight: size.height * 0.9),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Admit Resident: ${widget.resident.fullName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete the following details to finalize admission.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const Divider(height: 32),

            // Wizard Content
            Expanded(
              child: Form(
                key: _formKey,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppColors.primary,
                        ),
                  ),
                  child: Stepper(
                    type: StepperType.vertical, // Changed to Vertical
                    currentStep: _currentStep,
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : details.onStepContinue,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : Text(_currentStep == 1
                                        ? 'COMPLETE ADMISSION'
                                        : 'NEXT STEP'),
                              ),
                            ),
                            if (_currentStep > 0 && !_isLoading) ...[
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: details.onStepCancel,
                                child: const Text('BACK'),
                              ),
                            ] else if (_currentStep == 0 && !_isLoading) ...[
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('CANCEL'),
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                    onStepContinue: () {
                      if (_currentStep < 1) {
                        setState(() => _currentStep += 1);
                      } else {
                        _submitAdmission();
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep -= 1);
                      }
                    },
                    steps: [
                      Step(
                        title: const Text('Location'),
                        content: _buildLocationStep(),
                        isActive: _currentStep >= 0,
                        state: _currentStep > 0
                            ? StepState.complete
                            : StepState.editing,
                      ),
                      Step(
                        title: const Text('Supervision'),
                        content: _buildSupervisionStep(),
                        isActive: _currentStep >= 1,
                        state: _currentStep == 1
                            ? StepState.editing
                            : StepState.complete,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _admissionDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _admissionDate = date;
              });
              _suggestCaseNumber();
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'ADMISSION DATE',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(DateFormat('MMMM d, yyyy').format(_admissionDate)),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _caseNumberController,
          decoration: const InputDecoration(
            labelText: 'CASE NUMBER',
            prefixIcon: Icon(Icons.tag),
            helperText: 'Auto-generated based on date (C-YYMM##)',
          ),
          textCapitalization: TextCapitalization.characters, // Capitalized
          inputFormatters: [UpperCaseTextFormatter()], // Capitalized
          validator: (v) => v?.isNotEmpty == true ? null : 'Required',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<WardModel>(
          initialValue: _selectedWard,
          decoration: const InputDecoration(
            labelText: 'WARD',
            prefixIcon: Icon(Icons.meeting_room),
          ),
          items: _wards
              .map((w) => DropdownMenuItem(value: w, child: Text(w.name)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedWard = val);
              _loadBeds(val.id);
            }
          },
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedBed,
          decoration: const InputDecoration(
            labelText: 'BED NO.',
            prefixIcon: Icon(Icons.bed),
          ),
          items: _availableBeds
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: (val) => setState(() => _selectedBed = val),
          validator: (v) => v == null ? 'Required' : null,
          icon: _isBedLoading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : null,
        ),
      ],
    );
  }

  Widget _buildSupervisionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign a primary houseparent for this resident. This ensures accountability for daily care and supervision.',
          style: TextStyle(
              fontStyle: FontStyle.italic, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: _selectedHouseparentId,
          decoration: InputDecoration(
            labelText: 'ASSIGNED HOUSEPARENT',
            prefixIcon: const Icon(Icons.manage_accounts),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          ),
          items: [
            const DropdownMenuItem(
                value: null, child: Text('None / Unassigned')),
            ..._houseparents.map((u) => DropdownMenuItem(
                value: u.id, child: Text(u.fullName.toUpperCase()))),
          ],
          onChanged: (v) => setState(() => _selectedHouseparentId = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 24),
        const Text(
          'Assign a social worker for case management and intervention.',
          style: TextStyle(
              fontStyle: FontStyle.italic, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedSocialWorkerId,
          decoration: InputDecoration(
            labelText: 'ASSIGNED SOCIAL WORKER',
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          ),
          items: [
            const DropdownMenuItem(
                value: null, child: Text('None / Unassigned')),
            ..._socialWorkers.map((u) => DropdownMenuItem(
                value: u.id, child: Text(u.fullName.toUpperCase()))),
          ],
          onChanged: (v) => setState(() => _selectedSocialWorkerId = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
      ],
    );
  }
}
