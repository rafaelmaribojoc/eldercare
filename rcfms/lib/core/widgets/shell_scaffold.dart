import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'nav_item.dart';
import 'side_menu.dart';
import 'top_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shell scaffold with responsive navigation
class ShellScaffold extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const ShellScaffold({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final navItems = _getNavItems(context, authState);
          final selectedIndex = _getSelectedIndex(state.uri.path, navItems);

          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = screenWidth >= 1100;
          final isTablet = screenWidth >= 800 && screenWidth < 1100;

          // Build layout structure regardless of nav items
          // This prevents layout shifts when state is loading
          // If nav items are empty (e.g. loading), we'll show a loading state or empty sidebar

          if (isDesktop) {
            return _buildDesktopLayout(context, navItems, selectedIndex);
          } else if (isTablet) {
            return _buildTabletLayout(context, navItems, selectedIndex);
          } else {
            return _buildMobileLayout(context, navItems, selectedIndex);
          }
        },
      ),
    );
  }

  List<NavItem> _getNavItems(BuildContext context, AuthState state) {
    if (state is! AuthAuthenticated) return [];

    final userRole = state.user.role.toLowerCase();
    final isSuperAdmin = userRole == 'super_admin';
    final isAdmin = userRole == 'super_admin' || userRole == 'center_head';

    if (isSuperAdmin) {
      return [
        const NavItem(
          label: 'Home',
          icon: LucideIcons.house,
          activeIcon: LucideIcons.house,
          route: '/dashboard',
        ),
        const NavItem(
          label: 'Users',
          icon: LucideIcons.usersRound,
          activeIcon: LucideIcons.usersRound,
          route: '/admin/users',
        ),
        const NavItem(
          label: 'Wards',
          icon: LucideIcons.doorOpen,
          activeIcon: LucideIcons.doorOpen,
          route: '/admin/wards',
        ),
        const NavItem(
          label: 'Audit Logs',
          icon: LucideIcons.history,
          activeIcon: LucideIcons.history,
          route: '/admin/audit-logs',
        ),
        const NavItem(
          label: 'Analytics',
          icon: LucideIcons.chartColumn,
          activeIcon: LucideIcons.chartColumn,
          route: '/analytics',
        ),
        const NavItem(
          label: 'Settings',
          icon: LucideIcons.settings,
          activeIcon: LucideIcons.settings,
          route: '/settings',
        ),
      ];
    }

    return [
      const NavItem(
        label: 'Home',
        icon: LucideIcons.house,
        activeIcon: LucideIcons.house,
        route: '/dashboard',
      ),
      const NavItem(
        label: 'Residents',
        icon: LucideIcons.users,
        activeIcon: LucideIcons.users,
        route: '/residents',
      ),
      const NavItem(
        label: 'Forms',
        icon: LucideIcons.fileText,
        activeIcon: LucideIcons.fileText,
        route: '/forms',
      ),
      const NavItem(
        label: 'Wards',
        icon: LucideIcons.doorOpen,
        activeIcon: LucideIcons.doorOpen,
        route: '/wards',
      ),
      if (isAdmin)
        const NavItem(
          label: 'Analytics',
          icon: LucideIcons.chartColumn,
          activeIcon: LucideIcons.chartColumn,
          route: '/analytics',
        ),
      if (isAdmin && !isSuperAdmin)
        const NavItem(
          label: 'Admin',
          icon: LucideIcons.shield,
          activeIcon: LucideIcons.shield,
          route: '/admin',
        ),
    ];
  }

  int _getSelectedIndex(String currentPath, List<NavItem> items) {
    // Exact match first
    for (int i = 0; i < items.length; i++) {
      if (currentPath == items[i].route) return i;
    }
    // Prefix match for sub-routes (e.g. /residents/add -> /residents)
    for (int i = 0; i < items.length; i++) {
      if (items[i].route != '/' && currentPath.startsWith(items[i].route)) {
        return i;
      }
    }
    return 0; // Default to first item
  }

  Widget _buildDesktopLayout(
      BuildContext context, List<NavItem> navItems, int selectedIndex) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          SideMenu(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => context.go(navItems[index].route),
            navItems: navItems,
          ),
          Expanded(
            child: Column(
              children: [
                if (state.uri.path != '/forms' && navItems.isNotEmpty)
                  TopBar(title: navItems[selectedIndex].label),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
      BuildContext context, List<NavItem> navItems, int selectedIndex) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          SideMenu(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => context.go(navItems[index].route),
            navItems: navItems,
          ),
          Expanded(
            child: Column(
              children: [
                if (state.uri.path != '/forms' && navItems.isNotEmpty)
                  TopBar(title: navItems[selectedIndex].label),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, List<NavItem> navItems, int selectedIndex) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: Drawer(
        width: 260,
        child: SideMenu(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            Navigator.pop(context); // Close drawer
            context.go(navItems[index].route);
          },
          navItems: navItems,
        ),
      ),
      body: child,
      // Pass nav items to bottom nav only if not empty
      bottomNavigationBar: navItems.isNotEmpty
          ? _buildBottomNav(context, navItems, selectedIndex)
          : null,
    );
  }

  Widget _buildBottomNav(
      BuildContext context, List<NavItem> navItems, int selectedIndex) {
    // Show the centered NFC scan FAB for any user that has the residents
    // route in their nav (i.e. clinical users, not super admin).
    final showScanFab = navItems.any((n) => n.route == '/residents');
    final isCompact = navItems.length > 4;

    final children = <Widget>[];
    final insertAt = showScanFab ? (navItems.length / 2).ceil() : -1;

    for (var i = 0; i < navItems.length; i++) {
      if (i == insertAt) {
        children.add(_BottomScanItem(
          compact: isCompact,
          onTap: () => context.push('/scan'),
        ));
      }
      final item = navItems[i];
      children.add(Flexible(
        child: _BottomNavItem(
          item: item,
          isSelected: i == selectedIndex,
          compact: isCompact,
          onTap: () => context.go(item.route),
        ),
      ));
    }
    if (showScanFab && insertAt == navItems.length) {
      children.add(_BottomScanItem(
        compact: isCompact,
        onTap: () => context.push('/scan'),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: isCompact ? 4 : 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _BottomScanItem extends StatelessWidget {
  final bool compact;
  final VoidCallback onTap;

  const _BottomScanItem({
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 48.0 : 56.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: size,
        height: size,
        child: GestureDetector(
          onLongPress: () => _showScanModes(context),
          child: FloatingActionButton(
            heroTag: 'shell-bottom-scan-fab',
            onPressed: onTap,
            backgroundColor: AppColors.primary,
            elevation: 6,
            shape: const CircleBorder(),
            tooltip: 'Tap to scan • Long-press for scan modes',
            child: const Icon(
              LucideIcons.nfc,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  void _showScanModes(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      context.push('/scan');
      return;
    }
    final user = authState.user;
    final unit = (user.unit ?? '').toLowerCase();
    final isPsych = unit == 'psych';
    final isMedical = unit == 'medical';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final tiles = <Widget>[
          _ScanModeTile(
            icon: LucideIcons.user,
            color: AppColors.primary,
            label: 'View Resident Profile',
            description: 'Scan to open the resident\'s case file',
            onTap: () {
              Navigator.pop(sheetContext);
              context.push('/scan');
            },
          ),
          const SizedBox(height: 16),
          _ScanModeTile(
            icon: LucideIcons.filePlus,
            color: AppColors.warning,
            label: 'Quick Note',
            description: 'Scan to immediately add a note',
            onTap: () {
              Navigator.pop(sheetContext);
              context.push('/scan?mode=note');
            },
          ),
          if (isPsych) ...[
            const SizedBox(height: 16),
            _ScanModeTile(
              icon: LucideIcons.brain,
              color: Colors.purple,
              label: 'MoCA Assessment',
              description: 'Scan to start a MoCA test',
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/scan?mode=moca');
              },
            ),
          ],
          if (isMedical) ...[
            const SizedBox(height: 16),
            _ScanModeTile(
              icon: LucideIcons.heartPulse,
              color: Colors.teal,
              label: 'Quick Vitals',
              description: 'Scan to log vitals for the resident',
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/scan?mode=vitals');
              },
            ),
          ],
        ];

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).cardColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Select Scan Mode',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose what to do after scanning the NFC card.',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 20),
                ...tiles,
              ],
            ),
          ),
        );
      },
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
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
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isSelected ? (item.activeIcon ?? item.icon) : item.icon;
    final selectedColor = AppColors.primary;
    final unselectedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySurface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: compact ? 20 : 24,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? selectedColor : unselectedColor,
                      fontSize: compact ? 9 : null,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
