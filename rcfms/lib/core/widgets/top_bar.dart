import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../utils/responsive.dart';
import 'global_search_dialog.dart';
import 'notifications_panel.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TopBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const TopBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // Only show on Desktop/Tablet (Tablet usually has Sidebar + TopBar combo in this design)
    // Mobile uses standard AppBars in screens.
    if (context.isMobile) return const SizedBox.shrink();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          // Search Bar (Global)
          Expanded(
            child: _buildSearchBar(context),
          ),

          const SizedBox(width: 24),

          // Actions
          if (actions != null) ...actions!,

          // Notifications
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const NotificationsPanel(),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.textSecondary,
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),

          // Profile / Logout
          _buildProfileMenu(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600), // More long
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const GlobalSearchDialog(),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.search,
                    size: 20, color: AppColors.textTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search residents, files, etc...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ), // InkWell
      ), // ConstrainedBox
    ); // Align
  }

  Widget _buildProfileMenu(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        String initials = 'U';
        if (user != null && user.fullName.isNotEmpty) {
          final parts = user.fullName.trim().split(' ');
          if (parts.isNotEmpty) {
            if (parts.length > 1) {
              initials = '${parts[0][0]}${parts[1][0]}';
            } else {
              initials = parts[0][0];
            }
          }
        }
        initials = initials.toUpperCase();

        return PopupMenuButton<String>(
          offset: const Offset(0, 48),
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user != null ? user.fullName : 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user != null ? user.role.toUpperCase() : '',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                  const Divider(),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: const [
                  Icon(Icons.logout, size: 18, color: AppColors.error),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'logout') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                      },
                      child: const Text('Logout',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primarySurface,
                  backgroundImage: user?.avatarUrl != null
                      ? CachedNetworkImageProvider(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }
}
