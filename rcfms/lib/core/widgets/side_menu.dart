import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../theme/app_colors.dart';
import '../../data/models/user_model.dart';
import 'nav_item.dart'; // For NavItem definition

class SideMenu extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavItem> navItems;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.navItems,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  bool _isCollapsed = false;

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access user for profile info
    final user = context.select((AuthBloc bloc) {
      final state = bloc.state;
      return state is AuthAuthenticated ? state.user : null;
    });

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isCollapsed ? 70 : 250,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header: Hamburger + Logo
              _buildHeader(context),

              const Divider(height: 1),

              // Navigation Items
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: widget.navItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    return _SideMenuItem(
                      item: widget.navItems[index],
                      isSelected: index == widget.selectedIndex,
                      isCollapsed: _isCollapsed,
                      onTap: () => widget.onDestinationSelected(index),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // Footer: User Profile / Logout
              _buildFooter(context, user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 64,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          // Ensure container matches parent width or minimum to allow centering
          width: _isCollapsed ? 70 : 250,
          // But wait, SingleChildScrollView wraps content.
          // If we force width, constraints might conflict during animation?
          // Actually, easiest is to just let the Row be itself and clip.
          padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 0 : 16),
          child: Row(
            mainAxisAlignment: _isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // shrink wrap
            children: [
              // Hamburger Icon as Trigger
              IconButton(
                onPressed: _toggleCollapse,
                icon: Icon(
                  Icons.menu,
                  color: Theme.of(context).iconTheme.color,
                ),
                tooltip: _isCollapsed ? 'Expand menu' : 'Collapse menu',
              ),

              // Only show text if NOT collapsed (logical) AND width allows it (visual)
              if (!_isCollapsed) ...[
                const SizedBox(width: 12),
                // App Logo / Title
                InkWell(
                  onTap: () => context.go('/dashboard'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _AppLogo(),
                        const SizedBox(width: 12),
                        Text(
                          'RCFMS',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, UserModel? user) {
    if (_isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          children: [
            InkWell(
              onTap: () => context.go('/settings/profile'),
              customBorder: const CircleBorder(),
              child: Tooltip(
                message: 'My Profile',
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primarySurface,
                  backgroundImage: user?.avatarUrl != null
                      ? CachedNetworkImageProvider(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          user != null && user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              splashRadius: 20,
              tooltip: 'Logout',
              color: AppColors.error,
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/settings/profile'),
            customBorder: const CircleBorder(),
            child: Tooltip(
              message: 'My Profile',
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primarySurface,
                backgroundImage: user?.avatarUrl != null
                    ? CachedNetworkImageProvider(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? Text(
                        user != null && user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.fullName ?? 'User',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user?.role ?? 'Role',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            splashRadius: 20,
            color: AppColors.error,
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.elderly,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _SideMenuItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SideMenuItem({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Icons & Colors
    final icon = isSelected ? (item.activeIcon ?? item.icon) : item.icon;
    final primaryColor = AppColors.primary;
    final unselectedIconColor =
        Theme.of(context).iconTheme.color?.withOpacity(0.7);
    final unselectedTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Tooltip(
      message: isCollapsed ? item.label : '',
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 48,
            decoration: isSelected
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(width: 4, color: primaryColor),
                    ),
                    color: primaryColor.withOpacity(0.05),
                  )
                : null, // Fixed height for consistency
            // Use SingleChildScrollView to prevent overflow during width animation
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                // Ensure the container fills available width if possible (up to max constraint),
                // but Min constraint allows it to be small
                // We fake "left alignment" with padding
                padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 20),
                constraints: BoxConstraints(minWidth: isCollapsed ? 70 : 250),
                child: Row(
                  mainAxisAlignment: isCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? primaryColor : unselectedIconColor,
                      size: 24,
                    ),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 16),
                      // Text needs constraints? SingleChildScrollView gives infinite width.
                      // But Row in SingleChildScrollView also allows intrinsic width.
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isSelected
                                  ? primaryColor
                                  : unselectedTextColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                        // overflow: TextOverflow.ellipsis, // pointless in infinite scroll view
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
