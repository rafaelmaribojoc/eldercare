import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/resident_model.dart';
import '../../../data/models/ward_model.dart';
import '../../../data/repositories/resident_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../residents/screens/transfer_resident_dialog.dart';
import '../widgets/reassign_staff_dialog.dart';

class WardDetailScreen extends StatefulWidget {
  final String wardId;

  const WardDetailScreen({super.key, required this.wardId});

  @override
  State<WardDetailScreen> createState() => _WardDetailScreenState();
}

class _WardDetailScreenState extends State<WardDetailScreen> {
  WardModel? _ward;
  List<ResidentModel> _residents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<ResidentRepository>();

      // Load ward info and residents in parallel
      final wards = await repo.getWards();
      final ward = wards.where((w) => w.id == widget.wardId).firstOrNull;

      if (ward == null) {
        setState(() {
          _error = 'Ward not found';
          _isLoading = false;
        });
        return;
      }

      final residents = await repo.getResidents(
        wardId: widget.wardId,
        status: 'admitted',
        pageSize: 200,
      );

      if (!mounted) return;
      setState(() {
        _ward = ward;
        _residents = residents;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorHandler.getUserFriendlyMessage(e);
        _isLoading = false;
      });
    }
  }

  bool get _canManageResidents {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return false;
    return AppConstants.canManageResidents(
        authState.user.role, authState.user.unit);
  }

  bool get _canReassignStaff {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return false;
    final role = authState.user.role.toLowerCase();
    final unit = authState.user.unit?.toLowerCase() ?? '';
    return role == 'super_admin' ||
        role == 'social_head' ||
        role == 'social_staff' ||
        (role == 'head' && unit == 'social') ||
        (role == 'staff' && unit == 'social');
  }

  Future<void> _showTransferDialog(ResidentModel resident) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TransferResidentDialog(resident: resident),
    );
    if (result == true) _loadData();
  }

  Future<void> _showReassignBedDialog(ResidentModel resident) async {
    if (_ward == null) return;

    final repo = context.read<ResidentRepository>();
    final beds =
        await repo.getAvailableBeds(_ward!, excludeResidentId: resident.id);

    if (!mounted) return;

    String? selectedBed = resident.bedNumber;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reassign Bed'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoints.tablet),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign ${resident.firstName} to a different bed in ${_ward!.name}.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedBed,
                  decoration: const InputDecoration(
                    labelText: 'Bed Number',
                    prefixIcon: Icon(Icons.bed),
                  ),
                  items: beds
                      .map((bed) =>
                          DropdownMenuItem(value: bed, child: Text('Bed $bed')))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedBed = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedBed == null
                  ? null
                  : () async {
                      try {
                        await repo.updateResident(
                          id: resident.id,
                          bedNumber: selectedBed,
                        );
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${resident.firstName} moved to Bed $selectedBed'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          Navigator.of(ctx).pop(true);
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Failed: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _showReassignStaffDialog(
      ResidentModel resident, String fieldType) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReassignStaffDialog(
        residentId: resident.id,
        residentName: resident.fullName,
        fieldType: fieldType,
        currentStaffId: fieldType == 'social_worker'
            ? resident.socialWorkerId
            : resident.houseparentId,
        currentStaffName: fieldType == 'social_worker'
            ? resident.socialWorkerName
            : resident.houseparentName,
      ),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/wards');
            }
          },
        ),
        title: Text(_ward?.name ?? 'Ward'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error!, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Ward info header
          SliverToBoxAdapter(child: _buildWardHeader()),

          // Residents list header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Residents (${_residents.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),

          // Residents
          if (_residents.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline,
                        size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'No residents assigned to this ward',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ResidentTile(
                    resident: _residents[index],
                    canManageResidents: _canManageResidents,
                    canReassignStaff: _canReassignStaff,
                    onTransfer: () => _showTransferDialog(_residents[index]),
                    onReassignBed: () =>
                        _showReassignBedDialog(_residents[index]),
                    onReassignSocialWorker: () => _showReassignStaffDialog(
                        _residents[index], 'social_worker'),
                    onReassignHouseparent: () => _showReassignStaffDialog(
                        _residents[index], 'houseparent'),
                    onTap: () async {
                      await context
                          .push('/residents/${_residents[index].id}?mode=view');
                      if (mounted) _loadData();
                    },
                  ),
                  childCount: _residents.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildWardHeader() {
    if (_ward == null) return const SizedBox.shrink();
    final ward = _ward!;
    final pct = ward.occupancyPercentage;
    final color = pct >= 90
        ? AppColors.error
        : pct >= 70
            ? AppColors.warning
            : AppColors.success;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(Icons.meeting_room_rounded, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ward.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (ward.displayLocation != 'N/A')
                      Text(
                        ward.displayLocation,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.people,
                label: 'Occupied',
                value: '${ward.currentOccupancy}',
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.bed,
                label: 'Capacity',
                value: '${ward.capacity}',
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.check_circle_outline,
                label: 'Available',
                value: '${ward.availableBeds}',
                color: ward.availableBeds > 0
                    ? AppColors.success
                    : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Occupancy bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ward.capacity > 0
                  ? (ward.currentOccupancy / ward.capacity).clamp(0.0, 1.0)
                  : 0,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResidentTile extends StatelessWidget {
  final ResidentModel resident;
  final bool canManageResidents;
  final bool canReassignStaff;
  final VoidCallback onTransfer;
  final VoidCallback onReassignBed;
  final VoidCallback onReassignSocialWorker;
  final VoidCallback onReassignHouseparent;
  final VoidCallback onTap;

  const _ResidentTile({
    required this.resident,
    required this.canManageResidents,
    required this.canReassignStaff,
    required this.onTransfer,
    required this.onReassignBed,
    required this.onReassignSocialWorker,
    required this.onReassignHouseparent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main row
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primarySurface,
                    backgroundImage: resident.photoUrl != null
                        ? NetworkImage(resident.photoUrl!)
                        : null,
                    child: resident.photoUrl == null
                        ? Text(
                            resident.firstName.isNotEmpty
                                ? resident.firstName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Name and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resident.fullName,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (resident.bedNumber != null) ...[
                              Icon(Icons.bed,
                                  size: 14, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                'Bed ${resident.bedNumber}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              '${resident.age}y • ${resident.gender[0].toUpperCase()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions menu
                  if (canManageResidents || canReassignStaff)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) {
                        switch (value) {
                          case 'transfer':
                            onTransfer();
                            break;
                          case 'bed':
                            onReassignBed();
                            break;
                          case 'social_worker':
                            onReassignSocialWorker();
                            break;
                          case 'houseparent':
                            onReassignHouseparent();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (canManageResidents) ...[
                          const PopupMenuItem(
                            value: 'transfer',
                            child: ListTile(
                              leading: Icon(Icons.swap_horiz, size: 20),
                              title: Text('Transfer Ward'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'bed',
                            child: ListTile(
                              leading: Icon(Icons.bed, size: 20),
                              title: Text('Reassign Bed'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        if (canReassignStaff) ...[
                          const PopupMenuItem(
                            value: 'social_worker',
                            child: ListTile(
                              leading: Icon(Icons.social_distance, size: 20),
                              title: Text('Reassign Social Worker'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'houseparent',
                            child: ListTile(
                              leading: Icon(Icons.home, size: 20),
                              title: Text('Reassign Houseparent'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),

              // Staff assignments row
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _StaffTag(
                    icon: Icons.social_distance,
                    label: 'SW',
                    name: resident.socialWorkerName ?? 'Unassigned',
                    isAssigned: resident.socialWorkerId != null,
                  ),
                  _StaffTag(
                    icon: Icons.home,
                    label: 'HP',
                    name: resident.houseparentName ?? 'Unassigned',
                    isAssigned: resident.houseparentId != null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final String name;
  final bool isAssigned;

  const _StaffTag({
    required this.icon,
    required this.label,
    required this.name,
    required this.isAssigned,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14,
            color: isAssigned ? AppColors.primary : AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
        ),
        Text(
          name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isAssigned ? AppColors.textPrimary : AppColors.warning,
                fontWeight: isAssigned ? FontWeight.w500 : FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
