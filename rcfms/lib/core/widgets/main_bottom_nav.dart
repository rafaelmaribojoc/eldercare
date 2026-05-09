import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../../features/auth/bloc/auth_bloc.dart';

/// Main bottom navigation bar used across all main screens
class MainBottomNav extends StatelessWidget {
  final int currentIndex;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final userRole = state is AuthAuthenticated ? state.user.role : null;
        final isAdmin = userRole == 'super_admin' || userRole == 'center_head';
        final isSuperAdmin = userRole == 'super_admin';

        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 360;

        // Super Admin Navigation
        if (isSuperAdmin) {
          return BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            color: AppColors.surface,
            elevation: 8,
            height: isCompact ? 60 : 68,
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NavItem(
                  icon: LucideIcons.house,
                  activeIcon: LucideIcons.house,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  isCompact: isCompact,
                  onTap: () => context.go('/dashboard'),
                ),
                _NavItem(
                  icon: LucideIcons.usersRound,
                  activeIcon: LucideIcons.usersRound,
                  label: 'Users',
                  isSelected: currentIndex == 1,
                  isCompact: isCompact,
                  onTap: () => context.go('/admin/users'),
                ),
                // Center spacer for consistency or just evenly spaced?
                // Standard users have FAB, SA doesn't usually use FAB for "Scan" in dashboard...
                // But let's leave space if we want consistent layout, OR distribute evenly.
                // The FAB is `MainScanFab`. Does SA need it?
                // SA usually doesn't scan NFC for residents.
                // So maybe purely even distribution without FAB gap.
                // But the `Scaffold` in Dashboard still has `MainScanFab`.
                // Let's assume SA has FAB for now or remove FAB from SA Dashboard.
                // If I remove FAB gap, the FAB might overlay items.
                // Let's keep 4 items evenly spaced.

                _NavItem(
                  icon: LucideIcons.doorOpen,
                  activeIcon: LucideIcons.doorOpen,
                  label: 'Wards',
                  isSelected: currentIndex == 2,
                  isCompact: isCompact,
                  onTap: () => context.go('/admin/wards'),
                ),
                _NavItem(
                  icon: LucideIcons.history,
                  activeIcon: LucideIcons.history,
                  label: 'Audit Logs',
                  isSelected: currentIndex == 3,
                  isCompact: isCompact,
                  onTap: () => context.go('/admin/audit-logs'),
                ),
                _NavItem(
                  icon: LucideIcons.settings,
                  activeIcon: LucideIcons.settings,
                  label: 'Settings', // Explicitly "Settings"
                  isSelected: currentIndex == 4,
                  isCompact: isCompact,
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          );
        }

        // Regular User Navigation
        return BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: AppColors.surface,
          elevation: 8,
          height: isCompact ? 60 : 68,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                icon: LucideIcons.house,
                activeIcon: LucideIcons.house,
                label: 'Home',
                isSelected: currentIndex == 0,
                isCompact: isCompact,
                onTap: () => context.go('/dashboard'),
              ),
              _NavItem(
                icon: LucideIcons.users,
                activeIcon: LucideIcons.users,
                label: 'Residents',
                isSelected: currentIndex == 1,
                isCompact: isCompact,
                onTap: () => context.go('/residents'),
              ),
              // Center spacer for FAB
              SizedBox(width: isCompact ? 40 : 56),
              _NavItem(
                icon: LucideIcons.fileText,
                activeIcon: LucideIcons.fileText,
                label: 'Forms',
                isSelected: currentIndex == 2,
                isCompact: isCompact,
                onTap: () => context.go('/forms'),
              ),
              if (isAdmin && !isSuperAdmin) // Center Head
                _NavItem(
                  icon: LucideIcons.shield,
                  activeIcon: LucideIcons.shield,
                  label: 'Admin',
                  isSelected: currentIndex == 3,
                  isCompact: isCompact,
                  onTap: () => context.go('/admin'),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Floating action button for NFC scan with Long Press modes
class MainScanFab extends StatelessWidget {
  const MainScanFab({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showScanModes(context),
      child: FloatingActionButton(
        onPressed: () => context.push('/scan'),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(LucideIcons.nfc, color: Colors.white, size: 28),
      ),
    );
  }

  void _showScanModes(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isPsych =
        authState is AuthAuthenticated && authState.user.unit == 'psych';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Scan Mode',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            _ScanModeTile(
              icon: LucideIcons.filePlus,
              color: AppColors.warning,
              label: 'Quick Note',
              description: 'Scan to immediately add a note',
              onTap: () {
                Navigator.pop(context);
                context.push('/scan?mode=note');
              },
            ),
            if (isPsych) ...[
              const SizedBox(height: 16),
              _ScanModeTile(
                icon: LucideIcons.brain,
                color: Colors.purple,
                label: 'MoCA Assessment',
                description: 'Scan to start MoCA test',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/scan?mode=moca');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScanModeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _ScanModeTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.grey),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.isCompact ? 22.0 : 24.0;
    final fontSize = widget.isCompact ? 9.0 : 11.0;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon without circle background
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  widget.isSelected ? widget.activeIcon : widget.icon,
                  key: ValueKey(widget.isSelected),
                  color: widget.isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: iconSize,
                ),
              ),
              const SizedBox(height: 4),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
