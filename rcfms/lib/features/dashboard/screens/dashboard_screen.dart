import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/form_submission_model.dart';

import '../../../data/repositories/approval_repository.dart';
import '../../../data/repositories/form_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../../data/repositories/resident_repository.dart';
import '../../../core/services/router_service.dart';
import '../../../core/widgets/notifications_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  final ApprovalRepository _approvalRepository = ApprovalRepository();
  final FormRepository _formRepository = FormRepository();
  final ResidentRepository _residentRepository = ResidentRepository();

  int _unreadNotificationCount = 0;

  int _pendingApprovalsCount = 0;
  int _residentCount = 0;
  int _preAdmissionCount = 0;
  int _completedFormsCount = 0;
  int _wardCount = 0;
  List<FormSubmissionModel> _pendingApprovals = [];

  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    try {
      _subscription = _approvalRepository.subscribeToNotifications(
        onUpdate: () {
          if (mounted) _loadData();
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to notifications: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to RouteObserver
    final route = ModalRoute.of(context);
    if (route != null) {
      RouterService.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    RouterService.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and the current route shows up.
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final notificationCount = await _approvalRepository.getUnreadCount();
      if (!mounted) return;

      final authState = context.read<AuthBloc>().state;
      String? unit;
      if (authState is AuthAuthenticated) {
        unit = authState.user.unit;
      }

      List<FormSubmissionModel> approvals = [];
      if (authState is AuthAuthenticated &&
          AppConstants.canApproveforms(authState.user.role)) {
        approvals = await _formRepository.getPendingApprovals(
          unit: unit ?? 'all',
        );
        if (!mounted) return;
      }

      // Fetch Resident Count
      final residentCount = await _residentRepository.getResidentCount();
      // Fetch Pre-Admission Count
      final preAdmissionCount = await _residentRepository.getResidentCount(
        status: 'pre_admission',
      );

      // Fetch Completed Forms Count
      final completedFormsCount = await _formRepository.getCompletedFormsCount(
        unit: unit ?? 'all',
      );

      final wardCount = await _residentRepository.getActiveWardCount();

      if (!mounted) return;

      setState(() {
        _unreadNotificationCount = notificationCount;
        _pendingApprovalsCount = approvals.length;
        _pendingApprovals = approvals;
        _residentCount = residentCount;
        _preAdmissionCount = preAdmissionCount;
        _completedFormsCount = completedFormsCount;
        _wardCount = wardCount;
      });
    } catch (e) {
      debugPrint('Failed to load dashboard data: $e');
    }
  }

  // Helper to format time
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // ... existing code ...

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        if (user?.isSuperAdmin ?? false) {
          return const AdminDashboardScreen(isMainScreen: true);
        }

        return Scaffold(
          backgroundColor: Colors
              .transparent, // Let parent background show if needed, or use theme
          body: Container(
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(context, user?.fullName ?? 'User'),
                  ),

                  // Quick Stats
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _buildQuickStats(context),
                    ),
                  ),

                  // Forms for Review
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _buildFormsForReview(context),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                      ),
                ),
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width < 800) ...[
            // Notification Bell Icon with Badge
            GestureDetector(
              onTap: () => _showNotificationsPanel(context),
              child: Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest, // specific override or theme?
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      LucideIcons.bell,
                      color: AppColors.primary,
                    ),
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _unreadNotificationCount > 99
                                ? '99+'
                                : _unreadNotificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Settings/Profile Icon
            GestureDetector(
              onTap: () => context.push('/settings'),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface, // Use theme/primary opacity?
                  // Keeping primarySurface for now as it's brand-specific
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: const Icon(
                  LucideIcons.user,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showNotificationsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationsPanel(
        onNotificationRead: () {
          _loadData();
        },
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _buildQuickStats(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final authState = context.read<AuthBloc>().state;
        final isPsych =
            authState is AuthAuthenticated && authState.user.unit == 'psych';
        final canApprove = AppConstants.canApproveforms(
            authState is AuthAuthenticated ? authState.user.role : null);

        final isSuperAdmin = authState is AuthAuthenticated &&
            authState.user.role == AppConstants.roleSuperAdmin;

        // Define cards
        final residentsCard = _StatCard(
          icon: LucideIcons.users,
          iconColor: AppColors.primary,
          label: 'Total Residents',
          value: _residentCount.toString(),
          onTap: isSuperAdmin ? null : () => context.go('/residents'),
        );

        final pendingApprovalsCard = _StatCard(
          icon: LucideIcons.clipboardList,
          iconColor: AppColors.warning,
          label: 'Forms for Review',
          value: _pendingApprovalsCount.toString(),
          onTap: () => context.go('/forms'),
        );

        final completedCard = _StatCard(
          icon: LucideIcons.circleCheck,
          iconColor: AppColors.success,
          label: 'Completed Today',
          value: _completedFormsCount.toString(),
          onTap: () =>
              context.go('/forms?tab=Signed'), // Redirect to Signed tab
        );

        final activeWardsCard = _StatCard(
          icon: LucideIcons.doorOpen,
          iconColor: AppColors.unitPsych,
          label: 'Active Wards',
          value: _wardCount.toString(),
          onTap: isSuperAdmin ? null : () => context.go('/wards'),
        );

        final preAdmissionCard = _StatCard(
          icon: LucideIcons.userPlus,
          iconColor: AppColors.info,
          label: 'Pre-Admission',
          value: _preAdmissionCount.toString(),
          onTap: () => context.go(
              '/residents?filter=pre_admission'), // Filter by pre-admission?
        );

        final mocaAssessmentCard = _StatCard(
          icon: LucideIcons.brain,
          iconColor: AppColors.unitPsych,
          label: 'MoCA Assessment',
          value: 'Start',
          onTap: () => context.push('/residents?intent=moca'),
        );

        final mocaAnalyticsCard = _StatCard(
          icon: LucideIcons.chartColumn,
          iconColor: AppColors.unitPsych,
          label: 'MoCA Analytics',
          value: 'View',
          onTap: () => context.go('/moca/analytics'),
        );

        final caseCompletenessCard = _StatCard(
          icon: LucideIcons.listChecks,
          iconColor: AppColors.unitSocial,
          label: 'Case Files',
          value: '',
          onTap: () => context.go('/case-completeness'),
        );

        final cards = [
          residentsCard,
          if (isPsych) mocaAssessmentCard,
          if (isPsych) mocaAnalyticsCard,
          if (canApprove) pendingApprovalsCard,
          preAdmissionCard,
          completedCard,
          activeWardsCard,
          if (canApprove) caseCompletenessCard,
        ];

        if (isWide) {
          // Desktop: Single row of 3 or 4 or 5 cards
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var card in cards)
                    SizedBox(
                      width: (constraints.maxWidth - (cards.length - 1) * 12) /
                          cards.length,
                      child: card,
                    ),
                ],
              ),
            ],
          );
        } else {
          // Mobile/Tablet: 2-column Grid
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, box) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var card in cards)
                      SizedBox(
                        width: (box.maxWidth - 12) / 2,
                        child: card,
                      ),
                  ],
                );
              }),
            ],
          );
        }
      },
    );
  }

  Widget _buildFormsForReview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Forms for Review',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () => context.go('/forms?tab=For Review'),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: _pendingApprovals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No forms for review',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0;
                        i <
                            (_pendingApprovals.length > 5
                                ? 5
                                : _pendingApprovals.length);
                        i++) ...[
                      Builder(builder: (context) {
                        final form = _pendingApprovals[i];
                        final statusColor =
                            AppColors.warning; // Since it's for review

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              LucideIcons.fileText,
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            form.templateDisplayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${form.residentName} • ${_formatTimeAgo(form.submittedAt ?? form.createdAt)}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              form.statusDisplayText.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            context.push('/forms/view/${form.id}');
                          },
                        );
                      }),
                      if (i <
                          (_pendingApprovals.length > 5
                              ? 4
                              : _pendingApprovals.length - 1))
                        const Divider(height: 1),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: onTap != null
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset:
                      const Offset(0, 2), // Should be shadow color from theme?
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
