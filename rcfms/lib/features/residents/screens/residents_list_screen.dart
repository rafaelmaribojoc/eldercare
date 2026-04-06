import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/form_options.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/widgets/main_bottom_nav.dart';
import '../../../data/models/resident_model.dart';
import '../../../data/models/ward_model.dart';
import '../../../data/repositories/resident_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'add_resident_screen.dart'; // Import AddResidentScreen
import '../widgets/resident_sidebar.dart';
import 'transfer_resident_dialog.dart';
import '../../../core/widgets/custom_error_dialog.dart';

class ResidentsListScreen extends StatefulWidget {
  final String? initialFilter;

  const ResidentsListScreen({
    super.key,
    this.initialFilter,
  });

  @override
  State<ResidentsListScreen> createState() => _ResidentsListScreenState();
}

class _ResidentsListScreenState extends State<ResidentsListScreen> {
  final ResidentRepository _residentRepo = ResidentRepository();
  final TextEditingController _searchController = TextEditingController();

  List<ResidentModel> _residents = [];
  bool _isLoading = true;
  String? _error;

  // Sidebar Selection State
  Map<String, dynamic> _sidebarSelection = {'type': 'all', 'value': 'All'};

  // Local Filter State (synced with sidebar or independent)
  String _selectedWard = 'All'; // Kept for mobile filter sheet compatibility
  List<String>? _targetStatuses; // Explicit statuses from sidebar

  // Filter State
  String _sortOrder = 'name_asc';
  String _selectedGender = 'All';
  String _selectedAgeGroup = 'All';
  String _selectedCategory = 'All';
  DateTimeRange? _selectedDateRange;
  bool _showOnlyMyResidents = true;

  // Debounce Timer
  Timer? _debounce;

  // View State
  bool _isGridView = true;
  final Set<String> _selectedResidentIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedResidentIds.contains(id)) {
        _selectedResidentIds.remove(id);
      } else {
        _selectedResidentIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedResidentIds.length == _filteredResidents.length) {
        _selectedResidentIds.clear();
      } else {
        _selectedResidentIds.addAll(_filteredResidents.map((r) => r.id));
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Age Group Logic
  (int?, int?) _getAgeRange(String group) {
    if (group == '<60') return (null, 59);
    if (group == '60-69') {
      return (60, 69); // Changed to 60-69 for standard decades
    }
    if (group == '70-79') return (70, 79);
    if (group == '80+') return (80, null);
    return (null, null);
  }

  // Store Ward Objects
  List<WardModel> _availableWards = [];

  @override
  void initState() {
    super.initState();
    _handleInitialFilter();
    _loadWards();
    _loadResidents();
  }

  void _handleInitialFilter() {
    if (widget.initialFilter == 'pre_admission') {
      _sidebarSelection = {
        'type': 'status',
        'value': 'pre_admission',
        'label': 'Pre-admission'
      };
      _selectedWard = 'Pre-admission';
      _targetStatuses = ['pre_admission'];
    }
  }

  Future<void> _loadWards() async {
    try {
      final wards = await _residentRepo.getWards();
      if (mounted) {
        setState(() {
          _availableWards = wards;
        });
      }
    } catch (e) {
      // debugPrint('Error loading wards: $e');
    }
  }

  Future<void> _loadResidents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final (minAge, maxAge) = _getAgeRange(_selectedAgeGroup);

      // Determine Ward ID
      String? targetWardId;
      if (_selectedWard == 'Pre-admission') {
        targetWardId = null;
      } else if (_selectedWard == 'All') {
        targetWardId = null; // No ward filter
      } else {
        // Find ID for the selected Ward Name
        try {
          final ward =
              _availableWards.firstWhere((w) => w.name == _selectedWard);
          targetWardId = ward.id;
        } catch (_) {
          // If ward name matches nothing (shouldn't happen if list is sync), ignore or treat as All
          targetWardId = null;
        }
      }

      // Houseparent Filter
      String? houseparentId;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final isHomelife = authState.user.unit == AppConstants.unitHomelife ||
            authState.user.role.startsWith('homelife');
        if (isHomelife) {
          if (authState.user.isStaff) {
            houseparentId = authState.user.id;
          } else if (authState.user.isUnitHead && _showOnlyMyResidents) {
            houseparentId = authState.user.id;
          }
        }
      }

      // Determine Statuses
      // Priority: explicit _targetStatuses (Sidebar) > _selectedWard inference (Mobile/Old)
      List<String> statuses;
      if (_targetStatuses != null) {
        statuses = _targetStatuses!;
      } else {
        // Fallback or Mobile Filter Sheet logic
        if (_selectedWard == 'Pre-admission') {
          statuses = ['pre_admission'];
        } else if (_selectedWard == 'All') {
          statuses = ['admitted', 'pre_admission'];
        } else {
          statuses = ['admitted'];
        }
      }

      final residents = await _residentRepo.getResidents(
        statuses: statuses,
        wardId: targetWardId, // Pass actual UUID
        searchQuery: _searchController.text, // Pass search query to server
        sortOrder: _sortOrder,
        gender: _selectedGender,
        caseCategory: _selectedCategory,
        minAge: minAge,
        maxAge: maxAge,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
        houseparentId: houseparentId,
        socialWorkerId: authState is AuthAuthenticated &&
                (authState.user.unit == AppConstants.unitSocial ||
                    authState.user.role == 'social_worker')
            // Staff-level social workers ALWAYS filter by assignment;
            // Unit heads only filter when "My Residents" is toggled on
            ? (authState.user.isStaff
                ? authState.user.id
                : (_showOnlyMyResidents ? authState.user.id : null))
            : null,
      );

      if (!mounted) return;

      setState(() {
        _residents = residents;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getUserFriendlyMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  List<ResidentModel> get _filteredResidents {
    // Server-side filtering is now used in _loadResidents
    return _residents;
  }

  @override
  Widget build(BuildContext context) {
    final showSidebar = MediaQuery.of(context).size.width >= 800;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _loadResidents();
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;
          final canManage =
              AppConstants.canManageResidents(user?.role, user?.unit);

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: showSidebar
                ? null
                : AppBar(
                    automaticallyImplyLeading: false,
                    title: const Text('Residents'),
                    actions: [
                      if (canManage && !showSidebar)
                        IconButton(
                          icon: const Icon(Icons.person_add_outlined),
                          tooltip: 'Add Resident',
                          onPressed: () async {
                            await context.push('/residents/add');
                            _loadResidents();
                          },
                        ),
                      if (!showSidebar)
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: _showFilterSheet,
                        ),
                      const SizedBox(width: 6),
                    ],
                  ),
            body: Column(
              children: [
                // Search and filters
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Desktop Layout: Inline Search + Filters + Toggles
                      if (showSidebar)
                        Row(
                          children: [
                            // Search Bar
                            Expanded(
                              flex: 2,
                              child: _buildSearchBar(),
                            ),
                            const SizedBox(width: 4),

                            // Filters (Scrollable)
                            Expanded(
                              flex: 8,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: _buildDesktopFilters(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // View Toggles
                            _buildViewToggles(),
                          ],
                        )
                      else ...[
                        // Mobile Layout: Stacked
                        _buildSearchBar(),
                        if (MediaQuery.of(context).size.width < 800) ...[
                          const SizedBox(height: 12),
                          _buildMobileFilters(),
                        ]
                      ],
                    ],
                  ),
                ),
                // Results count / Selection Bar
                Container(
                  color: _selectedResidentIds.isNotEmpty
                      ? AppColors.primarySurface // Keep highlighted state
                      : Theme.of(context).cardColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      if (_selectedResidentIds.isNotEmpty) ...[
                        // Selection Mode UI
                        Text(
                          '${_selectedResidentIds.length} selected',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: _selectAll,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _selectedResidentIds.length ==
                                    _filteredResidents.length
                                ? 'Deselect All'
                                : 'Select All',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                      ] else ...[
                        // Normal Mode UI
                        Text(
                          '${_filteredResidents.length} resident${_filteredResidents.length != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        if (showSidebar) ...[
                          Text(
                            'Sort by name',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                // Residents list
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
            // bottomNavigationBar: handled by ShellScaffold
            floatingActionButton: MediaQuery.of(context).size.width < 800
                ? const MainScanFab()
                : null,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          );
        },
      ),
    );
  }

  void _handleSidebarSelection(Map<String, dynamic> selection) {
    setState(() {
      _sidebarSelection = selection;

      final type = selection['type'];
      final value = selection['value'];

      if (type == 'all') {
        _selectedWard = 'All';
        _targetStatuses = ['admitted', 'pre_admission'];
      } else if (type == 'status') {
        if (value == 'pre_admission') {
          _selectedWard = 'Pre-admission';
          _targetStatuses = ['pre_admission'];
        } else if (value == 'admitted') {
          _selectedWard = 'All';
          _targetStatuses = ['admitted'];
        } else if (value == 'discharged') {
          _selectedWard = 'All';
          _targetStatuses = ['discharged'];
        } else if (value == 'deceased') {
          _selectedWard = 'All';
          _targetStatuses = ['deceased'];
        }
      } else if (type == 'ward') {
        _selectedWard = value;
        _targetStatuses = ['admitted'];
      }
    });
    _loadResidents();
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showSidebar = width >= 800; // Show sidebar on Tablet+

        final authState = context.read<AuthBloc>().state;
        final user = authState is AuthAuthenticated ? authState.user : null;
        final canManage =
            AppConstants.canManageResidents(user?.role, user?.unit);

        if (showSidebar) {
          return Row(
            children: [
              ResidentSidebar(
                selectedFilter: _sidebarSelection,
                onFilterSelected: _handleSidebarSelection,
                wards: _availableWards,
                canAddResident: canManage,
                onAddResident: () async {
                  await context.push('/residents/add');
                  _loadResidents();
                },
              ),
              Expanded(
                child: _isGridView
                    ? _buildGrid(width - 250)
                    : _buildListView(width - 250),
              ),
            ],
          );
        } else {
          return _buildListView(width);
        }
      },
    );
  }

  Widget _buildListView(double availableWidth) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildErrorState();
    if (_filteredResidents.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadResidents,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredResidents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final resident = _filteredResidents[index];
          final isSelected = _selectedResidentIds.contains(resident.id);

          return Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            color: isSelected
                ? AppColors.primarySurface
                : Theme.of(context).cardColor,
            child: InkWell(
              onTap: () async {
                if (_selectedResidentIds.isNotEmpty) {
                  _toggleSelection(resident.id);
                } else {
                  final result = await context
                      .push<bool?>('/residents/${resident.id}?mode=view');
                  if (result == true) {
                    _loadResidents();
                  }
                }
              },
              onLongPress: availableWidth >= 800
                  ? () => _toggleSelection(resident.id)
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Checkbox (desktop/tablet only)
                    if (availableWidth >= 800)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (v) => _toggleSelection(resident.id),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),

                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceHover,
                      backgroundImage: resident.photoUrl != null
                          ? NetworkImage(resident.photoUrl!)
                          : null,
                      child: resident.photoUrl == null
                          ? Text(
                              _getInitials(
                                  '${resident.firstName} ${resident.lastName}'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Info
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  resident.fullName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (resident.nickname != null &&
                                  resident.nickname!.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${resident.nickname})',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${resident.age} yrs • ${resident.gender.toUpperCase()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                if (resident.caseCategory != null) ...[
                                  TextSpan(
                                    text: ' • ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textTertiary),
                                  ),
                                  TextSpan(
                                    text: resident.caseCategory!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              children: [
                                const WidgetSpan(
                                    child: Icon(Icons.meeting_room_outlined,
                                        size: 12,
                                        color: AppColors.textTertiary),
                                    alignment: PlaceholderAlignment.middle),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: resident.displayLocation,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Status
                    if (availableWidth > 600)
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _StatusBadge(status: resident.status),
                        ),
                      ),

                    // Actions
                    if (availableWidth > 400) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: AppColors.textSecondary,
                        onPressed: () =>
                            _handleResidentAction('edit', resident),
                        tooltip: 'Edit',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(double availableWidth) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_filteredResidents.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadResidents,
      child: LayoutBuilder(
        // Nested layout builder for grid sizing
        builder: (context, constraints) {
          // Use availableWidth passed from parent or constraints
          final width = availableWidth;
          int crossAxisCount = 1;

          // Breakpoints (Using adjusted widths)
          if (width >= 1100) {
            // Reduced from 1350 since available width is smaller (sidebar)
            crossAxisCount = 4;
          } else if (width >= 800) {
            crossAxisCount = 3;
          } else if (width >= 550) {
            crossAxisCount = 2;
          }

          if (crossAxisCount == 1) {
            // On mobile/narrow, fallback to list logic but using Grid Item style or just use ListView directly?
            // Let's use ListView for single column grid as it feels more natural
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredResidents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildResidentItem(index),
            );
          }

          // Calculate item width to determine aspect ratio for consistent height
          // Padding (32) + CrossAxisSpacing (16 * (cols - 1))
          final totalHorizontalPadding = 32.0 + (16.0 * (crossAxisCount - 1));
          final itemWidth = (width - totalHorizontalPadding) / crossAxisCount;
          // Target height is ~240px - slightly taller to accommodate checkbox
          final dynamicAspectRatio = itemWidth / 240.0;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: dynamicAspectRatio,
            ),
            itemCount: _filteredResidents.length,
            itemBuilder: (context, index) => _buildResidentItem(index),
          );
        },
      ),
    );
  }

  Widget _buildResidentItem(int index) {
    if (index >= _filteredResidents.length) return const SizedBox.shrink();
    final resident = _filteredResidents[index];

    // Check permissions
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final canManage = AppConstants.canManageResidents(user?.role, user?.unit);

    final currentUri = GoRouterState.of(context).uri;
    final isActionMode = currentUri.queryParameters['mode'] == 'action';
    final mode = isActionMode ? '' : '?mode=view';

    final isSelected = _selectedResidentIds.contains(resident.id);

    return _ResidentCard(
      resident: resident,
      canManage: canManage,
      isSelected: isSelected,
      onSelect: () => _toggleSelection(resident.id),
      onTap: () async {
        if (_selectedResidentIds.isNotEmpty) {
          _toggleSelection(resident.id);
        } else {
          final result =
              await context.push<bool?>('/residents/${resident.id}$mode');
          if (result == true) {
            _loadResidents();
          }
        }
      },
      onAction: (action) => _handleResidentAction(action, resident),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceHover,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: const Icon(
              Icons.people_outline,
              size: 40,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No residents found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An error occurred',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadResidents,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleResidentAction(String action, ResidentModel resident) {
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: AppColors.background,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: AddResidentScreen(resident: resident),
              ),
            ),
          ),
        ).then((_) => _loadResidents());
        break;
      case 'transfer':
        _showTransferDialog(resident);
        break;
      case 'discharge':
        _showDischargeDialog(resident);
        break;
      case 'deceased':
        _showDeceasedDialog(resident);
        break;
      case 'delete':
        _deleteResident(resident);
        break;
    }
  }

  Future<void> _showTransferDialog(ResidentModel resident) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TransferResidentDialog(resident: resident),
    );

    if (result == true && mounted) {
      _loadResidents();
    }
  }

  Future<void> _showDischargeDialog(ResidentModel resident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Discharge'),
        content: Text(
            'Are you sure you want to discharge ${resident.firstName}? This action will mark them as discharged and free up their bed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discharge'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<ResidentRepository>().dischargeResident(resident.id);
        if (mounted) _loadResidents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resident discharged successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          CustomErrorDialog.show(context,
              title: 'Discharge Failed',
              error: e,
              message: 'Failed to discharge resident.');
        }
      }
    }
  }

  Future<void> _showDeceasedDialog(ResidentModel resident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Deceased'),
        content: Text(
            'Are you sure you want to mark ${resident.firstName} as deceased? This will move them to the Deceased archive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<ResidentRepository>().updateResident(
              id: resident.id,
              status: 'deceased',
              isActive: false,
            );
        if (mounted) _loadResidents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resident marked as deceased'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          CustomErrorDialog.show(context,
              title: 'Operation Failed',
              error: e,
              message: 'Failed to mark resident as deceased.');
        }
      }
    }
  }

  Future<void> _deleteResident(ResidentModel resident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application'),
        content: Text(
            'Are you sure you want to permanently delete the application for ${resident.firstName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<ResidentRepository>().deleteResident(resident.id);
        if (mounted) _loadResidents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          CustomErrorDialog.show(context,
              title: 'Deletion Failed',
              error: e,
              message: 'Failed to delete application.');
        }
      }
    }
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: AppColors.textTertiary),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              isDense: true,
              dropdownColor: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              elevation: 8,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters & Sort',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              _selectedWard = 'All';
                              _sortOrder = 'name_asc';
                              _selectedGender = 'All';
                              _selectedAgeGroup = 'All';
                              _selectedCategory = 'All';
                              _selectedDateRange = null;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Sort By
                        _buildFilterSection(context, 'Sort By', [
                          _buildChoiceChip(
                              context,
                              'Last Name (A-Z)',
                              'name_asc',
                              _sortOrder,
                              (v) => setSheetState(() => _sortOrder = v)),
                          _buildChoiceChip(
                              context,
                              'Last Name (Z-A)',
                              'name_desc',
                              _sortOrder,
                              (v) => setSheetState(() => _sortOrder = v)),
                          _buildChoiceChip(
                              context,
                              'First Name (A-Z)',
                              'first_name_asc',
                              _sortOrder,
                              (v) => setSheetState(() => _sortOrder = v)),
                          _buildChoiceChip(
                              context,
                              'First Name (Z-A)',
                              'first_name_desc',
                              _sortOrder,
                              (v) => setSheetState(() => _sortOrder = v)),
                          _buildChoiceChip(
                              context,
                              'Newest',
                              'date_newest',
                              _sortOrder,
                              (v) => setSheetState(() => _sortOrder = v)),
                          _buildChoiceChip(
                              context,
                              'Oldest',
                              'date_oldest',
                              _sortOrder,
                              (v) => setSheetState(() => _sortOrder = v)),
                        ]),
                        const SizedBox(height: 24),

                        // Ward / Status
                        _buildFilterSection(context, 'Ward / Status', [
                          _buildChoiceChip(context, 'All', 'All', _selectedWard,
                              (v) => setSheetState(() => _selectedWard = v)),
                          _buildChoiceChip(
                              context,
                              'Pre-admission',
                              'Pre-admission',
                              _selectedWard,
                              (v) => setSheetState(() => _selectedWard = v)),
                          ..._availableWards.map((w) => _buildChoiceChip(
                              context,
                              w.name,
                              w.name,
                              _selectedWard,
                              (v) => setSheetState(() => _selectedWard = v))),
                        ]),
                        const SizedBox(height: 24),

                        // Gender
                        _buildFilterSection(context, 'Sex', [
                          _buildChoiceChip(
                              context,
                              'All',
                              'All',
                              _selectedGender,
                              (v) => setSheetState(() => _selectedGender = v)),
                          _buildChoiceChip(
                              context,
                              'Male',
                              'Male',
                              _selectedGender,
                              (v) => setSheetState(() => _selectedGender = v)),
                          _buildChoiceChip(
                              context,
                              'Female',
                              'Female',
                              _selectedGender,
                              (v) => setSheetState(() => _selectedGender = v)),
                        ]),
                        const SizedBox(height: 24),

                        // Age Group
                        _buildFilterSection(context, 'Age Group', [
                          _buildChoiceChip(
                              context,
                              'All',
                              'All',
                              _selectedAgeGroup,
                              (v) =>
                                  setSheetState(() => _selectedAgeGroup = v)),
                          _buildChoiceChip(
                              context,
                              '<60',
                              '<60',
                              _selectedAgeGroup,
                              (v) =>
                                  setSheetState(() => _selectedAgeGroup = v)),
                          _buildChoiceChip(
                              context,
                              '60-69',
                              '60-69',
                              _selectedAgeGroup,
                              (v) =>
                                  setSheetState(() => _selectedAgeGroup = v)),
                          _buildChoiceChip(
                              context,
                              '70-79',
                              '70-79',
                              _selectedAgeGroup,
                              (v) =>
                                  setSheetState(() => _selectedAgeGroup = v)),
                          _buildChoiceChip(
                              context,
                              '80+',
                              '80+',
                              _selectedAgeGroup,
                              (v) =>
                                  setSheetState(() => _selectedAgeGroup = v)),
                        ]),
                        const SizedBox(height: 24),

                        // Case Category
                        Text('Case Category',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory == 'All' ||
                                  FormOptions.caseCategories
                                      .contains(_selectedCategory)
                              ? _selectedCategory
                              : 'All',
                          items: ['All', ...FormOptions.caseCategories]
                              .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c,
                                      style: const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: (v) => setSheetState(
                              () => _selectedCategory = v ?? 'All'),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Date Range
                        Text('Admission Date',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              initialDateRange: _selectedDateRange,
                            );
                            if (picked != null) {
                              setSheetState(() => _selectedDateRange = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.date_range,
                                    size: 20, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedDateRange != null
                                      ? '${DateFormat('MMM d, y').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, y').format(_selectedDateRange!.end)}'
                                      : 'Select Date Range',
                                  style: TextStyle(
                                    color: _selectedDateRange != null
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                if (_selectedDateRange != null)
                                  InkWell(
                                    onTap: () => setSheetState(
                                        () => _selectedDateRange = null),
                                    child: const Icon(Icons.close, size: 16),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Apply Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadResidents();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Apply Filters',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }

  Widget _buildChoiceChip(BuildContext context, String label, String value,
      String groupValue, Function(String) onSelected) {
    final isSelected = groupValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onSelected(value);
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppColors.primary.withAlpha(50),
      side: BorderSide(
          color:
              isSelected ? AppColors.primary : Theme.of(context).dividerColor),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  Widget _buildChip(String label) {
    final isSelected = _selectedWard == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedWard = label;
          _loadResidents();
        });
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppColors.primarySurface,
      checkmarkColor: AppColors.primary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Theme.of(context).dividerColor,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onSubmitted: (_) {
        _debounce?.cancel();
        _loadResidents();
      },
      onChanged: (value) {
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () {
          _loadResidents();
        });
        setState(() {});
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search residents...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _loadResidents();
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildDesktopFilters() {
    final user = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;
    // Only show "My Residents" toggle for unit heads who can optionally filter.
    // Staff-level SW/HP are always forced to see only their assigned residents.
    final canToggleMyResidents = (user?.isUnitHead == true) &&
        (user?.unit == AppConstants.unitSocial ||
            user?.unit == AppConstants.unitHomelife ||
            user?.role.startsWith('social') == true ||
            user?.role == 'homelife_head');

    return Row(
      children: [
        if (canToggleMyResidents) ...[
          FilterChip(
            label: const Text('My Residents'),
            selected: _showOnlyMyResidents,
            onSelected: (bool selected) {
              setState(() {
                _showOnlyMyResidents = selected;
              });
              _loadResidents();
            },
            selectedColor: AppColors.primary.withOpacity(0.2),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              color: _showOnlyMyResidents ? AppColors.primary : Colors.black87,
              fontWeight:
                  _showOnlyMyResidents ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 24,
            width: 1,
            color: Theme.of(context).dividerColor,
          ),
          const SizedBox(width: 8),
        ],
        _buildFilterDropdown<String>(
          label: 'Sort',
          value: _sortOrder,
          items: const [
            DropdownMenuItem(value: 'name_asc', child: Text('Name (A-Z)')),
            DropdownMenuItem(value: 'name_desc', child: Text('Name (Z-A)')),
            DropdownMenuItem(
                value: 'first_name_asc', child: Text('Given Name (A-Z)')),
            DropdownMenuItem(
                value: 'first_name_desc', child: Text('Given Name (Z-A)')),
            DropdownMenuItem(value: 'date_newest', child: Text('Newest')),
            DropdownMenuItem(value: 'date_oldest', child: Text('Oldest')),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() => _sortOrder = v);
              _loadResidents();
            }
          },
        ),
        const SizedBox(width: 8),
        _buildFilterDropdown<String>(
          label: 'Sex',
          value: _selectedGender,
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All')),
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() => _selectedGender = v);
              _loadResidents();
            }
          },
        ),
        const SizedBox(width: 8),
        _buildFilterDropdown<String>(
          label: 'Age',
          value: _selectedAgeGroup,
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All')),
            DropdownMenuItem(value: '<60', child: Text('<60')),
            DropdownMenuItem(value: '60-69', child: Text('60-69')),
            DropdownMenuItem(value: '70-79', child: Text('70-79')),
            DropdownMenuItem(value: '80+', child: Text('80+')),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() => _selectedAgeGroup = v);
              _loadResidents();
            }
          },
        ),
        const SizedBox(width: 8),
        _buildFilterDropdown<String>(
          label: 'Category',
          value: _selectedCategory,
          items: ['All', ...FormOptions.caseCategories]
              .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _selectedCategory = v);
              _loadResidents();
            }
          },
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              initialDateRange: _selectedDateRange,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                        ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedDateRange = picked);
              _loadResidents();
            }
          },
          icon: const Icon(Icons.calendar_today_rounded, size: 16),
          label: Text(
            _selectedDateRange == null
                ? 'Date'
                : '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}',
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
            side: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.6),
                width: 1.5),
            backgroundColor: _selectedDateRange != null
                ? AppColors.primary.withOpacity(0.05)
                : Colors.transparent,
            foregroundColor: _selectedDateRange != null
                ? AppColors.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggles() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => setState(() => _isGridView = true),
            icon: const Icon(Icons.grid_view),
            color: _isGridView
                ? AppColors.primary
                : Theme.of(context).iconTheme.color?.withOpacity(0.5),
            tooltip: 'Grid View',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            iconSize: 20,
          ),
          Container(
              width: 1, height: 24, color: Theme.of(context).dividerColor),
          IconButton(
            onPressed: () => setState(() => _isGridView = false),
            icon: const Icon(Icons.view_list),
            color: !_isGridView
                ? AppColors.primary
                : Theme.of(context).iconTheme.color?.withOpacity(0.5),
            tooltip: 'List View',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilters() {
    final user = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;
    // Only show "My Residents" toggle for unit heads who can optionally filter.
    // Staff-level SW/HP are always forced to see only their assigned residents.
    final canToggleMyResidents = (user?.isUnitHead == true) &&
        (user?.unit == AppConstants.unitSocial ||
            user?.unit == AppConstants.unitHomelife ||
            user?.role.startsWith('social') == true ||
            user?.role == 'homelife_head');

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (canToggleMyResidents) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('My Residents'),
                      selected: _showOnlyMyResidents,
                      onSelected: (bool selected) {
                        setState(() {
                          _showOnlyMyResidents = selected;
                        });
                        _loadResidents();
                      },
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _showOnlyMyResidents
                            ? AppColors.primary
                            : Colors.black87,
                        fontWeight: _showOnlyMyResidents
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Container(
                    height: 20,
                    width: 1,
                    color: Theme.of(context).dividerColor,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                ],
                _buildChip('All'),
                const SizedBox(width: 6),
                _buildChip('Pre-admission'),
                const SizedBox(width: 6),
                ..._availableWards.map((w) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildChip(w.name))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResidentCard extends StatelessWidget {
  final ResidentModel resident;
  final bool canManage;
  final VoidCallback onTap;
  final Function(String) onAction;
  final bool isSelected;
  final VoidCallback onSelect;

  const _ResidentCard({
    required this.resident,
    required this.canManage,
    required this.onTap,
    required this.onAction,
    this.isSelected = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status color
    // Replaced by _StatusBadge widget

    final isPreAdmission = resident.status == 'pre_admission';
    final isAdmitted =
        resident.status == 'admitted' || resident.status == 'active';

    // Format dates
    final dateFormat = DateFormat('MMM d, yyyy');
    String dateLabel = 'Admitted';
    String displayDate = '';

    if (resident.admissionDate != null) {
      displayDate = dateFormat.format(resident.admissionDate!);
    } else if (resident.applicationDate != null) {
      dateLabel = 'Applied';
      displayDate = dateFormat.format(resident.applicationDate!);
    }

    // Ward/Room info
    String location = 'Unassigned';
    if (resident.wardName != null && resident.wardName!.isNotEmpty) {
      location = resident.wardName!;
      if (resident.bedNumber != null) {
        location += ' • Bed ${resident.bedNumber}';
      }
    }

    // Case Ref format
    final caseRef = resident.residentCode;

    return Stack(
      fit: StackFit.expand,
      children: [
        Material(
          color: isSelected
              ? AppColors.primarySurface
              : Theme.of(context).cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            onLongPress: onSelect,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: Avatar + Name + Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Hero(
                            tag: 'avatar_grid_${resident.id}',
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: isSelected
                                  ? AppColors.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              backgroundImage: resident.photoUrl != null
                                  ? NetworkImage(resident.photoUrl!)
                                  : null,
                              child: resident.photoUrl == null
                                  ? Text(
                                      _getInitials(
                                          '${resident.firstName} ${resident.lastName}'),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          // Selection Checkbox Overlay (Visible if selected)
                          if (isSelected)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle,
                                    size: 16, color: AppColors.primary),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resident.fullName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.1,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            _StatusBadge(status: resident.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nickname (Optional)
                  if (resident.nickname != null &&
                      resident.nickname!.isNotEmpty)
                    Text(
                      '"${resident.nickname}"',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  const SizedBox(height: 8),

                  // Info Row 1: Age • Gender • Category
                  Row(
                    children: [
                      _buildInfoIcon(Icons.person_outline),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${resident.age} yrs • ${resident.gender.toUpperCase()}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (resident.caseCategory != null) ...[
                                TextSpan(
                                  text: ' • ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.textTertiary),
                                ),
                                TextSpan(
                                  text: resident.caseCategory!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Info Row 2: Location
                  Row(
                    children: [
                      _buildInfoIcon(Icons.meeting_room_outlined),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Divider(color: AppColors.border.withOpacity(0.5), height: 8),

                  // Footer
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildInfoIcon(Icons.tag),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                caseRef,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Monospace',
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.calendar_today,
                                size: 12, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '$dateLabel: $displayDate',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        fontSize: 10,
                                        color: AppColors.textTertiary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Action Menu
        if (canManage)
          Positioned(
            top: 4,
            right: 0,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: AppColors.textSecondary, size: 20),
              onSelected: onAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: AppColors.textPrimary),
                      SizedBox(width: 12),
                      Text('Edit Profile'),
                    ],
                  ),
                ),
                if (isAdmitted) ...[
                  const PopupMenuItem(
                    value: 'transfer',
                    child: Row(
                      children: [
                        Icon(Icons.bed, size: 18, color: AppColors.primary),
                        SizedBox(width: 12),
                        Text('Transfer Ward'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'discharge',
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app,
                            size: 18, color: AppColors.warning),
                        SizedBox(width: 12),
                        Text('Discharge'),
                      ],
                    ),
                  ),
                ],
                if (resident.status == 'discharged')
                  const PopupMenuItem(
                    value: 'deceased',
                    child: Row(
                      children: [
                        Icon(Icons.person_off_outlined,
                            size: 18, color: AppColors.textPrimary),
                        SizedBox(width: 12),
                        Text('Mark as Deceased'),
                      ],
                    ),
                  ),
                if (isPreAdmission)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Delete Request'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoIcon(IconData icon) {
    return Icon(
      icon,
      size: 14,
      color: AppColors.textTertiary,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, label) = _getStatusStyle(status, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
      ),
    );
  }

  (Color, Color, String) _getStatusStyle(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'admitted':
        return (
          AppColors.success,
          AppColors.successSurface,
          'Admitted',
        );
      case 'discharged':
      case 'deceased':
        return (
          AppColors.textSecondary,
          Theme.of(context).colorScheme.surfaceContainerHighest,
          status,
        );
      case 'pre_admission':
        return (
          AppColors.warning,
          AppColors.warningSurface,
          'Pending',
        );
      case 'on_pass':
        return (
          Colors.blue,
          Colors.blue.shade50,
          'On Pass',
        );
      default:
        return (
          AppColors.textSecondary,
          Theme.of(context).colorScheme.surfaceContainerHighest,
          status,
        );
    }
  }
}

String _getInitials(String name) {
  final parts = name.split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}
