import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/services/nfc_service.dart';
import '../../../data/models/user_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/widgets/custom_error_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _titleController = TextEditingController(); // Added
  final _licenseController = TextEditingController();
  DateTime? _selectedExpiryDate;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _usernameController.text = authState.user.username ?? '';
      _titleController.text = authState.user.title ?? ''; // Added
      _licenseController.text = authState.user.licenseNo ?? '';
      _selectedExpiryDate = authState.user.licenseExpiryDate;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _titleController.dispose(); // Added
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final bytes = await image.readAsBytes();
      final extension = image.name.split('.').last.toLowerCase();

      final authRepo = context.read<AuthRepository>();
      await authRepo.uploadAvatar(
        userId: authState.user.id,
        imageBytes: bytes,
        extension: extension,
      );

      if (!mounted) return;

      // Fetch updated user to ensure local state is synced
      final updatedUser = await authRepo.getUserProfile(authState.user.id);

      if (!mounted) return;

      context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        CustomErrorDialog.show(context,
            title: 'Upload Failed',
            error: e,
            message: 'Could not upload profile picture.');
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = context.read<AuthRepository>();
      final updatedUser = await authRepo.updateProfile(
        userId: authState.user.id,
        username: _usernameController.text.trim(),
        title: _titleController.text.trim(), // Added
        licenseNo: _licenseController.text.trim(),
        licenseExpiryDate: _selectedExpiryDate,
      );

      if (!mounted) return;

      context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        CustomErrorDialog.show(context,
            title: 'Update Failed',
            error: e,
            message: 'Could not save profile changes.');
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
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = state.user;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Edit Profile'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primarySurface,
                          backgroundImage: user.avatarUrl != null
                              ? CachedNetworkImageProvider(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? Text(
                                  user.fullName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: AppColors.primary,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            onTap:
                                _isUploadingImage ? null : _pickAndUploadImage,
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _isUploadingImage
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      LucideIcons.camera,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Locked fields info
                Card(
                  color: AppColors.info.withOpacity(0.1),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(LucideIcons.info, color: AppColors.info, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Full Name is locked for accountability.',
                            style:
                                TextStyle(fontSize: 12, color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Locked: Full Name
                TextFormField(
                  initialValue: user.fullName,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Full Name (Locked)',
                    prefixIcon: Icon(LucideIcons.lockKeyhole),
                  ),
                ),
                const SizedBox(height: 16),

                // Editable: PRC License Number
                TextField(
                  controller: _licenseController,
                  decoration: const InputDecoration(
                    labelText: 'PRC License Number',
                    prefixIcon: Icon(LucideIcons.badge),
                    helperText: 'Enter your valid PRC License No.',
                  ),
                ),
                const SizedBox(height: 16),

                // Editable: PRC License Expiry Date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedExpiryDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _selectedExpiryDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'PRC License Expiry Date',
                      prefixIcon: Icon(LucideIcons.calendar),
                      suffixIcon: Icon(LucideIcons.chevronDown),
                    ),
                    child: Text(
                      _selectedExpiryDate != null
                          ? '${_selectedExpiryDate!.month.toString().padLeft(2, '0')}/${_selectedExpiryDate!.day.toString().padLeft(2, '0')}/${_selectedExpiryDate!.year}'
                          : 'Select Expiry Date',
                      style: TextStyle(
                        color: _selectedExpiryDate != null
                            ? Theme.of(context).textTheme.bodyMedium?.color
                            : Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email (read-only)
                TextFormField(
                  initialValue: user.email,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(LucideIcons.mail),
                  ),
                ),
                const SizedBox(height: 24),

                // Editable: Username
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(LucideIcons.user),
                    helperText: 'This is your display name',
                  ),
                ),
                const SizedBox(height: 24),

                // Editable: Title / Designation
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Designation / Title',
                    prefixIcon: Icon(LucideIcons.badge),
                    helperText: 'e.g., Social Worker I, Houseparent II, Nurse',
                  ),
                ),
                const SizedBox(height: 24),

                // NFC Badge Registration
                _buildNfcSection(context),

                const SizedBox(height: 24),

                // Digital Signature Section
                _buildSignatureSection(context, user),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNfcSection(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    if (state is! AuthAuthenticated) return const SizedBox.shrink();

    final user = state.user;
    final hasBadge = user.nfcCardId != null && user.nfcCardId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.nfc, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text(
                'NFC ID Badge',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (hasBadge) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Connected',
                    style: TextStyle(fontSize: 10, color: AppColors.success),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasBadge
                ? 'Badge ID: ${user.nfcCardId}'
                : 'Link your physical ID badge for Tap-to-Sign and fast login.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (hasBadge)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _registerIdBadge(context),
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Replace'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _unlinkBadge(context),
                    icon: const Icon(LucideIcons.unlink),
                    label: const Text('Unlink'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _registerIdBadge(context),
                icon: const Icon(LucideIcons.badgePlus),
                label: const Text('Register Badge'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _unlinkBadge(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Badge?'),
        content: const Text(
            'This badge will no longer be usable for login or signatures.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Unlink', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = context.read<AuthRepository>();
      final authState = context.read<AuthBloc>().state;

      if (authState is! AuthAuthenticated) return;

      await authRepo.unlinkNfc(authState.user.id);

      // Refresh user profile locally or re-fetch
      final updatedUser = await authRepo.getUserProfile(authState.user.id);

      if (mounted) {
        context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Badge unlinked successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomErrorDialog.show(context,
            title: 'Unlink Failed',
            error: e,
            message: 'Could not unlink badge.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerIdBadge(BuildContext context) async {
    try {
      final nfcService = context.read<NfcService>();
      final isAvailable = await nfcService.isAvailable();
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      if (!context.mounted) return;

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NFC is not supported or enabled on this device.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Scan ID Badge'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.badge, size: 60, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Hold your ID badge to the back of the device.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                nfcService.stopSession();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      final tagId = await nfcService.scanTag();

      if (!context.mounted) return;
      Navigator.pop(context); // Close dialog

      if (tagId != null) {
        final authRepo = context.read<AuthRepository>();
        final updatedUser = await authRepo.updateProfile(
          userId: authState.user.id,
          nfcCardId: tagId,
        );

        context
            .read<AuthBloc>()
            .add(AuthUserUpdated(updatedUser)); // Update local state

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Badge registered! ID: $tagId'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog if open
        CustomErrorDialog.show(context,
            title: 'Registration Failed',
            error: e,
            message: 'Could not register badge.');
      }
    }
  }

  Widget _buildSignatureSection(BuildContext context, UserModel user) {
    final hasSignature =
        user.signatureUrl != null && user.signatureUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.penLine, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text(
                'Digital Signature',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (hasSignature) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(fontSize: 10, color: AppColors.success),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (hasSignature)
            Center(
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildSignatureImage(user.signatureUrl!),
                ),
              ),
            )
          else
            const Text(
              'No digital signature has been set up yet. This is required for signing forms.',
              style: TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/setup-signature'),
              icon: Icon(hasSignature ? LucideIcons.pencil : LucideIcons.plus),
              label:
                  Text(hasSignature ? 'Update Signature' : 'Setup Signature'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureImage(String url) {
    if (url.startsWith('data:image')) {
      try {
        final base64String = url.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.contain,
        );
      } catch (e) {
        return const Center(
          child: Icon(LucideIcons.imageOff, color: AppColors.error),
        );
      }
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(LucideIcons.imageOff, color: AppColors.error),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
