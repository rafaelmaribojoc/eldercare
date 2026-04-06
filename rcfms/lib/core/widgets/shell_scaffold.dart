import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'nav_item.dart';
import 'side_menu.dart';
import 'top_bar.dart';

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
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          route: '/dashboard',
        ),
        const NavItem(
          label: 'Users',
          icon: Icons.manage_accounts_outlined,
          activeIcon: Icons.manage_accounts_rounded,
          route: '/admin/users',
        ),
        const NavItem(
          label: 'Wards',
          icon: Icons.meeting_room_outlined,
          activeIcon: Icons.meeting_room_rounded,
          route: '/admin/wards',
        ),
        const NavItem(
          label: 'Audit Logs',
          icon: Icons.history_outlined,
          activeIcon: Icons.history_rounded,
          route: '/admin/audit-logs',
        ),
        const NavItem(
          label: 'Analytics',
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics_rounded,
          route: '/analytics',
        ),
        const NavItem(
          label: 'Settings',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          route: '/settings',
        ),
      ];
    }

    return [
      const NavItem(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        route: '/dashboard',
      ),
      const NavItem(
        label: 'Residents',
        icon: Icons.people_outline,
        activeIcon: Icons.people_rounded,
        route: '/residents',
      ),
      const NavItem(
        label: 'Forms',
        icon: Icons.description_outlined,
        activeIcon: Icons.description_rounded,
        route: '/forms',
      ),
      const NavItem(
        label: 'Wards',
        icon: Icons.meeting_room_outlined,
        activeIcon: Icons.meeting_room_rounded,
        route: '/wards',
      ),
      if (isAdmin)
        const NavItem(
          label: 'Analytics',
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics_rounded,
          route: '/analytics',
        ),
      if (isAdmin && !isSuperAdmin)
        const NavItem(
          label: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings_rounded,
          route: '/admin',
        )
      else
        const NavItem(
          label: 'More',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          route: '/settings',
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
    final isCompact = navItems.length > 5;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Subtle shadow
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == selectedIndex;

              return Flexible(
                child: _BottomNavItem(
                  item: item,
                  isSelected: isSelected,
                  compact: isCompact,
                  onTap: () => context.go(item.route),
                ),
              );
            }).toList(),
          ),
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
