import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/widgets/custom_error_dialog.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _fullNameController = TextEditingController();
  final _titleController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _fullNameController.text = authState.user.fullName;
      _titleController.text = authState.user.title ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Designation / Job Title'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (authState.user.signatureUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set up your digital signature first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = context.read<AuthRepository>();

      // Update profile and set completed flag
      final updatedUser = await authRepo.updateProfile(
        userId: authState.user.id,
        title: _titleController.text.trim(),
        profileCompleted: true,
      );

      if (!mounted) return;

      debugPrint(
          '[ProfileCompletion] Profile updated. isProfileComplete: ${updatedUser.isProfileComplete}');
      context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile completed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Manual push as backup, though redirect should handle it
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        CustomErrorDialog.show(context,
            title: 'Completion Failed',
            error: e,
            message: 'Could not finalize profile.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          // If we're logging out, showing nothing is better than a hang spinner
          // while the router transitions to /login
          return const Scaffold(body: SizedBox.shrink());
        }

        final user = state.user;

        final isDesktop = MediaQuery.of(context).size.width > 900;

        return Scaffold(
          backgroundColor:
              isDesktop ? AppColors.surface : Theme.of(context).cardColor,
          appBar: AppBar(
            title: const Text('Complete Your Profile'),
            centerTitle: isDesktop,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthLogoutRequested()),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: isDesktop ? 48 : 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 40 : 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDesktop
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
                    border: isDesktop
                        ? Border.all(color: AppColors.border.withOpacity(0.5))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person_pin_rounded,
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'Welcome to the system!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Please review and complete your profile information before proceeding to the dashboard. This ensures all your future forms and signatures are accurate.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Divider(),
                      const SizedBox(height: 32),

                      // Full Name (Locked but visible)
                      TextFormField(
                        controller: _fullNameController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Full Name (Locked)',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText:
                              'Contact your Admin if your name is incorrect.',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Designation / Title (Required)
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Designation / Job Title *',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          hintText:
                              'e.g., Social Worker I, Houseparent II, Nurse',
                          helperText: 'This will appear on all forms you sign.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Digital Signature Section (Required)
                      _buildSignatureSection(context, user),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _completeProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Confirm & Continue to Dashboard',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignatureSection(BuildContext context, UserModel user) {
    final hasSignature =
        user.signatureUrl != null && user.signatureUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasSignature
            ? AppColors.success.withOpacity(0.05)
            : AppColors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (hasSignature ? AppColors.success : AppColors.warning)
              .withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSignature ? Icons.check_circle : Icons.warning_rounded,
                color: hasSignature ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 12),
              const Text(
                'Digital Signature *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasSignature)
            Center(
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: user.signatureUrl!,
                    fit: BoxFit.contain,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image),
                  ),
                ),
              ),
            )
          else
            const Text(
              'You must set up your digital signature to proceed. It will be used for official form signings.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/setup-signature'),
              icon: Icon(hasSignature ? Icons.edit : Icons.add_rounded),
              label: Text(
                  hasSignature ? 'Update Signature' : 'Setup Signature Now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
