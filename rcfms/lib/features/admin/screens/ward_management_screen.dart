import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/ward_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/resident_repository.dart';
import '../../../core/services/nfc_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/ward_id_card_generator.dart';

class WardManagementScreen extends StatefulWidget {
  const WardManagementScreen({super.key});

  @override
  State<WardManagementScreen> createState() => _WardManagementScreenState();
}

class _WardManagementScreenState extends State<WardManagementScreen> {
  final _adminRepo = AdminRepository();
  List<WardModel> _wards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWards();
  }

  Future<void> _loadWards() async {
    setState(() => _isLoading = true);
    try {
      final wards = await _adminRepo.getAllWards();
      setState(() {
        _wards = wards.where((w) => w.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddWardDialog([WardModel? ward]) {
    final nameController = TextEditingController(text: ward?.name);
    final descriptionController =
        TextEditingController(text: ward?.description);
    final capacityController = TextEditingController(
      text: ward?.capacity.toString() ?? '10',
    );
    final buildingController = TextEditingController(text: ward?.building);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ward == null ? 'Add New Ward' : 'Edit Ward'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ward Name *',
                  prefixIcon: Icon(LucideIcons.mapPin),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(LucideIcons.fileText),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  prefixIcon: Icon(LucideIcons.users),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: buildingController,
                decoration: const InputDecoration(
                  labelText: 'Building',
                  prefixIcon: Icon(LucideIcons.building2),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ward name is required'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              final navigator = Navigator.of(context, rootNavigator: true);
              // Show loading if needed, but here it's just the dialog itself being popped
              try {
                if (ward == null) {
                  await _adminRepo.createWard(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    capacity: int.tryParse(capacityController.text) ?? 10,
                    building: buildingController.text.trim().isEmpty
                        ? null
                        : buildingController.text.trim(),
                  );
                } else {
                  await _adminRepo.updateWard(
                    id: ward.id,
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    capacity: int.tryParse(capacityController.text),
                    building: buildingController.text.trim(),
                  );
                }

                if (navigator.canPop()) navigator.pop(); // Close dialog
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(ward == null ? 'Ward created' : 'Ward updated'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadWards();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(ward == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showAssignNfcDialog(WardModel ward) {
    final nfcController = TextEditingController(text: ward.nfcTagId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign NFC Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign an NFC tag to ${ward.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nfcController,
              decoration: InputDecoration(
                labelText: 'NFC Tag ID',
                prefixIcon: const Icon(LucideIcons.nfc),
                hintText: 'e.g., AA:BB:CC:DD',
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.scanQrCode),
                  tooltip: 'Scan Tag',
                  onPressed: () async {
                    final nfcService = context.read<NfcService>();
                    if (!await nfcService.isAvailable()) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('NFC not available')));
                      }
                      return;
                    }
                    // Show scanning dialog
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.nfc,
                                size: 50, color: AppColors.primary),
                            SizedBox(height: 16),
                            Text('Hold phone to tag...'),
                          ],
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                nfcService.stopSession();
                                Navigator.pop(ctx);
                              },
                              child: Text('Cancel'))
                        ],
                      ),
                    );

                    final id = await nfcService.scanTag();

                    if (context.mounted) {
                      Navigator.pop(context); // close scan dialog
                    }

                    if (id != null) {
                      nfcController.text = id;
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: Scan a tag on a device to get its ID',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context, rootNavigator: true);
              try {
                await _adminRepo.assignNfcTag(
                  wardId: ward.id,
                  nfcTagId: nfcController.text.trim().toUpperCase(),
                );

                if (navigator.canPop()) navigator.pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('NFC tag assigned'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadWards();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showQrDialog(WardModel ward) {
    showDialog(
      context: context,
      builder: (context) => _WardIdCardDialog(ward: ward),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Ward Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Ward'),
              onPressed: () => _showAddWardDialog(),
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWards,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _wards.length,
                itemBuilder: (context, index) {
                  final ward = _wards[index];
                  return _WardCard(
                    ward: ward,
                    onEdit: () => _showAddWardDialog(ward),
                    onAssignNfc: () => _showAssignNfcDialog(ward),
                    onShowQr: () => _showQrDialog(ward),
                    onDelete: () async {
                      // Check if ward has assigned residents first
                      try {
                        final residents = await ResidentRepository()
                            .getResidentsByWardId(ward.id);
                        if (residents.isNotEmpty && mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cannot Delete Ward'),
                              content: Text(
                                '${ward.name} has ${residents.length} active '
                                'resident(s) assigned. Please transfer them '
                                'to another ward before deleting.',
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                      } catch (e) {
                        // If check fails, allow deletion with warning
                        debugPrint('Ward resident check failed: $e');
                      }

                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Ward'),
                          content: Text(
                              'Are you sure you want to delete ${ward.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          await _adminRepo.deleteWard(ward.id);
                          _loadWards();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        }
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _WardCard extends StatelessWidget {
  final WardModel ward;
  final VoidCallback onEdit;
  final VoidCallback onAssignNfc;
  final VoidCallback onShowQr;
  final VoidCallback onDelete;

  const _WardCard({
    required this.ward,
    required this.onEdit,
    required this.onAssignNfc,
    required this.onShowQr,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.mapPin,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ward.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (ward.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              ward.description!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ward.isActive
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ward.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: ward.isActive
                              ? AppColors.success
                              : AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoChip(
                      icon: LucideIcons.users,
                      label: '${ward.currentOccupancy}/${ward.capacity}',
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: LucideIcons.nfc,
                      label: ward.hasNfcTag ? 'NFC Assigned' : 'No NFC',
                      color: ward.hasNfcTag
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onShowQr,
                    icon: const Icon(LucideIcons.qrCode, size: 18),
                    label: const Text('QR'),
                  ),
                  TextButton.icon(
                    onPressed: onAssignNfc,
                    icon: const Icon(LucideIcons.nfc, size: 18),
                    label: const Text('NFC'),
                  ),
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(LucideIcons.pencil, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    label: const Text('Delete'),
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondaryLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ward ID Card Dialog — Premium card-style preview with flip animation
// ---------------------------------------------------------------------------
class _WardIdCardDialog extends StatefulWidget {
  final WardModel ward;
  const _WardIdCardDialog({required this.ward});

  @override
  State<_WardIdCardDialog> createState() => _WardIdCardDialogState();
}

class _WardIdCardDialogState extends State<_WardIdCardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showingFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_showingFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _showingFront = !_showingFront);
  }

  @override
  Widget build(BuildContext context) {
    final ward = widget.ward;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flip Card
          GestureDetector(
            onTap: _toggleCard,
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value * 3.14159;
                final isFront = angle < 1.5708; // pi/2
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: isFront
                      ? _buildFrontCard(ward)
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(3.14159),
                          child: _buildBackCard(),
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Hint text
          Text(
            _showingFront
                ? 'Tap card to see the back side'
                : 'Tap card to see the front side',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: LucideIcons.download,
                label: 'Download',
                onTap: () => WardIdCardGenerator.downloadCard(ward),
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: LucideIcons.printer,
                label: 'Print',
                onTap: () => WardIdCardGenerator.printCard(ward),
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: LucideIcons.x,
                label: 'Close',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard(WardModel ward) {
    return Container(
      width: 340,
      height: 214,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF1565C0)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle pattern overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(painter: _CardPatternPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Left — Info
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Icon(LucideIcons.hospital,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RCFMS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'WARD IDENTIFICATION',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 8,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Ward Name
                      Text(
                        ward.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CAPACITY: ${ward.capacity}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      // NFC Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.circle,
                                size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'NFC ENABLED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right — QR Code
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: 'rcfms:ward:${ward.id}',
                        version: QrVersions.auto,
                        size: 90,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SCAN ME',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      width: 340,
      height: 214,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF263238), Color(0xFF37474F), Color(0xFF455A64)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Left — Instructions
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'STAFF INSTRUCTIONS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _instructionStep('1', 'Open the RCFMS mobile app'),
                  const SizedBox(height: 6),
                  _instructionStep('2', 'Select NFC Scan or Scan QR'),
                  const SizedBox(height: 6),
                  _instructionStep('3',
                      'Hold phone flat against the card\nor scan the front QR code'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right — NFC Tag Placement
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.circle,
                      size: 24, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(height: 4),
                  Text(
                    'PLACE NFC\nTAG HERE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _instructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a subtle decorative pattern on the card background
class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    // Large circle top-right
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * -0.1),
      size.height * 0.6,
      paint,
    );

    // Small circle bottom-left
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 1.1),
      size.height * 0.4,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
