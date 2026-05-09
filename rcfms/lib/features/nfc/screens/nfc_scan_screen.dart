import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/nfc_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../residents/widgets/resident_action_sheet.dart';
import '../../residents/widgets/modern_notes/modern_resident_notes_sheet.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/resident_model.dart';
import '../../../data/models/ward_model.dart';
import '../../../data/repositories/resident_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../moca/bloc/moca_assessment_bloc.dart';
import '../../moca/constants/moca_colors.dart';

class NFCScanScreen extends StatefulWidget {
  final String? mode; // 'vitals', 'note', 'moca', etc.

  const NFCScanScreen({
    super.key,
    this.mode,
  });

  @override
  State<NFCScanScreen> createState() => _NFCScanScreenState();
}

class _NFCScanScreenState extends State<NFCScanScreen>
    with SingleTickerProviderStateMixin {
  bool _isNfcAvailable = false;
  bool _isScanning = false;
  WardModel? _scannedWard;
  List<ResidentModel> _residents = [];
  String? _error;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isLoopMode = false;

  // QR Fallback State
  bool _isQrScanning = false;
  final MobileScannerController _qrController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stopNfcSession();
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      setState(() {
        _isNfcAvailable = isAvailable;
      });
      // Do not auto-start session
    } catch (e) {
      setState(() {
        _isNfcAvailable = false;
      });
    }
  }

  Future<void> _startNfcSession() async {
    if (!_isNfcAvailable) return;

    _pulseController.repeat(reverse: true);
    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      // Use the centralized NfcService to scan
      final tagIdHex = await NfcService().scanTag();

      if (!mounted) return;

      _pulseController.stop();
      _pulseController.reset();

      if (tagIdHex == null) {
        setState(() => _isScanning = false);
        return;
      }

      final residentRepo = context.read<ResidentRepository>();

      // 1. Check if Tag is a Ward
      final ward = await residentRepo.getWardByNfcTag(tagIdHex);

      if (ward != null) {
        // It's a Ward -> Show Resident List
        final residents = await residentRepo.getResidentsByWardId(ward.id);
        setState(() {
          _scannedWard = ward;
          _residents = residents;
          _error = null;
          _isScanning = false;
        });
        return;
      }

      final resident = await residentRepo.getResidentByNfcTag(tagIdHex);

      if (resident != null) {
        // Resident Found - Check for Mode or Show Action Sheet
        setState(() {
          _isScanning = false;
          _error = null;
        });

        if (!mounted) return;

        // Loop Mode Handling (Rapid Scanning)
        if (_isLoopMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.circleCheck, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Identified: ${resident.fullName}'),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Restart scan loop
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted && _isLoopMode) {
            _startNfcSession();
          }
          return;
        }

        // Handle specific modes (Intent-First)
        if (widget.mode == 'note') {
          final authState = context.read<AuthBloc>().state;
          final noteUser =
              authState is AuthAuthenticated ? authState.user : null;
          final canMakeNotes = AppConstants.canMakeNotesForResident(
            role: noteUser?.role,
            unit: noteUser?.unit,
            userId: noteUser?.id,
            residentSocialWorkerId: resident.socialWorkerId,
            residentHouseparentId: resident.houseparentId,
          );
          if (!canMakeNotes) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'You are not assigned to this resident and cannot create notes.'),
                backgroundColor: AppColors.warning,
              ),
            );
            return;
          }
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ModernResidentNotesSheet(
              residentId: resident.id,
              residentName: resident.fullName,
              canAddNotes: canMakeNotes,
            ),
          );
          return;
        } else if (widget.mode == 'moca') {
          final authState = context.read<AuthBloc>().state;
          final isPsych =
              authState is AuthAuthenticated && authState.user.unit == 'psych';

          if (!isPsych) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Only Psychological Services can conduct MoCA assessments.'),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }
          _startMocaAssessment(context, resident);
          return;
        } else if (widget.mode == 'vitals') {
          // Go to profile/forms for now
          // Ideally open specific Vitals form directly
          context.push('/residents/${resident.id}');
          return;
        }

        // Default: Show Action Sheet (Scan-First)
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ResidentActionSheet(resident: resident),
        );
        return;
      }

      // 3. Not Recognized
      setState(() {
        _isScanning = false;
        _error = 'Tag not recognized (Not a Ward or Resident)';
        _scannedWard = null;
        _residents = [];
      });
    } catch (e) {
      if (!mounted) return;
      _pulseController.stop();
      _pulseController.reset();
      setState(() {
        _isScanning = false;
        _error = ErrorHandler.getUserFriendlyMessage(e);
      });
    }
  }

  Future<void> _stopNfcSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      // Ignore
    }
  }

  void _resetScan() {
    setState(() {
      _scannedWard = null;
      _residents = [];
      _error = null;
      _isQrScanning = false;
    });
    if (_isNfcAvailable) {
      _startNfcSession();
    }
  }

  // =========================================================================
  // QR CODE SCANNING FALLBACK
  // =========================================================================

  Future<void> _startQrScan() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _stopNfcSession(); // Stop NFC if it was running
      setState(() {
        _isQrScanning = true;
        _error = null;
      });
      // Do not manually start the controller; the MobileScanner widget handles it.
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to scan QR codes.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _stopQrScan() async {
    await _qrController.stop();
    if (!mounted) return;
    setState(() {
      _isQrScanning = false;
    });
    if (_isNfcAvailable && !_isScanning) {
      _startNfcSession();
    }
  }

  Future<void> _handleQrDetected(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || !rawValue.startsWith('rcfms:ward:')) return;

    // We got a match, stop scanner
    await _stopQrScan();
    setState(() {
      _error = null;
    });

    final wardId = rawValue.replaceFirst('rcfms:ward:', '');

    try {
      final residentRepo = context.read<ResidentRepository>();
      final ward = await residentRepo.getWardById(wardId);

      if (ward != null) {
        final residents = await residentRepo.getResidentsByWardId(ward.id);
        if (!mounted) return;
        setState(() {
          _scannedWard = ward;
          _residents = residents;
          _error = null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = 'Ward not found from QR code.';
        });
        if (_isNfcAvailable) _startNfcSession();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorHandler.getUserFriendlyMessage(e);
      });
      if (_isNfcAvailable) _startNfcSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Scan Ward'),
        actions: [
          if (widget.mode == null)
            Row(
              children: [
                const Text('Loop', style: TextStyle(fontSize: 12)),
                Switch(
                  value: _isLoopMode,
                  onChanged: (val) {
                    setState(() => _isLoopMode = val);
                    if (val && !_isScanning) {
                      _startNfcSession();
                    }
                  },
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          if (_scannedWard != null)
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: _resetScan,
              tooltip: 'Scan Again',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_scannedWard != null) {
      return _buildResidentsList();
    }

    if (_isQrScanning) {
      return _buildQrScanView();
    }

    if (!_isNfcAvailable) {
      return _buildNfcUnavailable();
    }

    return _buildScanView();
  }

  Widget _buildNfcUnavailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.nfc,
                size: 50,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'NFC Not Available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'This device does not support NFC or NFC is disabled. '
              'Please enable NFC in your device settings or use a different device.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startQrScan,
              icon: const Icon(LucideIcons.scanQrCode),
              label: const Text('Scan QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanView() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated NFC icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isScanning ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: _isScanning
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isScanning
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.nfc,
                        size: 70,
                        color: _isScanning ? AppColors.primary : Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                _isScanning ? 'Scanning...' : 'Ready to Scan',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                _isScanning
                    ? 'Hold your device near the Ward NFC tag'
                    : 'Tap the button below to start scanning',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.circleAlert,
                          color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (!_isScanning) ...[
                ElevatedButton.icon(
                  onPressed: _startNfcSession,
                  icon: const Icon(LucideIcons.nfc),
                  label: const Text('Start Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              OutlinedButton.icon(
                onPressed: _startQrScan,
                icon: const Icon(LucideIcons.qrCode),
                label: const Text('Scan QR Code Instead'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrScanView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _qrController,
          onDetect: _handleQrDetected,
        ),
        // Overlay styling
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 4),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Column(
            children: [
              const Text(
                'Scan Ward QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _stopQrScan,
                icon: const Icon(LucideIcons.x),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResidentsList() {
    return Column(
      children: [
        // Ward header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.mapPin,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scannedWard!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.mode != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            widget.mode == 'note'
                                ? 'Tap resident to Add Note'
                                : widget.mode == 'moca'
                                    ? 'Tap resident to Start MoCA'
                                    : 'Tap resident to View',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      Text(
                        '${_residents.length} residents',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
                  onPressed: _resetScan,
                ),
              ],
            ),
          ),
        ),
        // Residents list
        Expanded(
          child: _residents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 64,
                        color: AppColors.textSecondaryLight.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No residents in this ward',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _residents.length,
                  itemBuilder: (context, index) {
                    final resident = _residents[index];
                    return _ResidentTile(
                      resident: resident,
                      onTap: () {
                        // Intent-First Handling for Ward Residents
                        if (widget.mode == 'note') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ModernResidentNotesSheet(
                              residentId: resident.id,
                              residentName: resident.fullName,
                            ),
                          );
                        } else if (widget.mode == 'moca') {
                          final authState = context.read<AuthBloc>().state;
                          final isPsych = authState is AuthAuthenticated &&
                              authState.user.unit == 'psych';

                          if (isPsych) {
                            _startMocaAssessment(context, resident);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Only Psychological Services can conduct MoCA assessments.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } else if (widget.mode == 'vitals') {
                          context.push('/residents/${resident.id}');
                        } else {
                          // Default Scan-First Behavior
                          context.push('/residents/${resident.id}');
                        }
                      },
                      onNewForm: () => _showFormOptions(context, resident),
                      onNewAssessment: () =>
                          _startMocaAssessment(context, resident),
                      showActions: widget.mode == null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showFormOptions(BuildContext context, ResidentModel resident) {
    context.push('/residents/${resident.id}');
  }

  /// Start MoCA-P assessment with auto-filled resident data
  void _startMocaAssessment(BuildContext context, ResidentModel resident) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    // Default education years to 0 (will trigger adjustment if < 12 years)
    const educationYears = 0;

    // Start assessment with resident data auto-filled
    context.read<MocaAssessmentBloc>().add(
          MocaStartAssessment(
            residentId: resident.id,
            clinicianId: user?.id,
            residentName: resident.fullName,
            residentSex: resident.gender,
            residentBirthday: resident.dateOfBirth,
            educationYears: educationYears,
            educationAdjustment: educationYears < 12,
          ),
        );

    // Navigate directly to first assessment section
    // Skip MoCA home screen - assessments start immediately from resident selection
    context.go('/moca/visuospatial');
  }
}

class _ResidentTile extends StatelessWidget {
  final ResidentModel resident;
  final VoidCallback onTap;
  final VoidCallback? onNewForm;
  final VoidCallback? onNewAssessment;
  final bool showActions;

  const _ResidentTile({
    required this.resident,
    required this.onTap,
    this.onNewForm,
    this.onNewAssessment,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    // Check if user is from psych unit
    final authState = context.read<AuthBloc>().state;
    final userUnit =
        authState is AuthAuthenticated ? authState.user.unit : null;
    final isPsychUnit = userUnit == 'psych';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                    child: Text(
                      resident.firstName[0] + resident.lastName[0],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resident.fullName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.cake,
                              size: 14,
                              color: AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${resident.age} years',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (resident.roomNumber != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                LucideIcons.doorOpen,
                                size: 14,
                                color: AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Room ${resident.roomNumber}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondaryLight,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.textSecondaryLight,
                  ),
                ],
              ),
              // Quick action buttons
              if (showActions) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onNewForm,
                        icon: const Icon(LucideIcons.fileText, size: 16),
                        label: const Text('New Form'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                              color: AppColors.primary.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    if (isPsychUnit) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onNewAssessment,
                          icon: const Icon(LucideIcons.brain, size: 16),
                          label: const Text('Assessment'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MocaColors.primary,
                            side: BorderSide(
                                color: MocaColors.primary.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
