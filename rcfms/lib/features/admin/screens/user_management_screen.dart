import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/resident_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/widgets/custom_error_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminRepository _adminRepo = AdminRepository();
  List<UserModel> _users = [];
  String _filterStatus = 'active'; // all, active, inactive
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users =
          await _adminRepo.getAllUsers().timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _users = users;
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

  List<UserModel> get _filteredUsers {
    if (_filterStatus == 'all') return _users;
    return _users.where((u) {
      if (_filterStatus == 'active') return u.isActive;
      return !u.isActive;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('User Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: _showAddUserDialog,
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text('Add User'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh List',
            onPressed: _loadUsers,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _FilterTab(
              label: 'Active',
              count: _users.where((u) => u.isActive).length,
              isSelected: _filterStatus == 'active',
              onTap: () => setState(() => _filterStatus = 'active'),
            ),
            const SizedBox(width: 8),
            _FilterTab(
              label: 'Inactive',
              count: _users.where((u) => !u.isActive).length,
              isSelected: _filterStatus == 'inactive',
              onTap: () => setState(() => _filterStatus = 'inactive'),
              isError: true,
            ),
            const SizedBox(width: 8),
            _FilterTab(
              label: 'All',
              count: _users.length,
              isSelected: _filterStatus == 'all',
              onTap: () => setState(() => _filterStatus = 'all'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final filtered = _filteredUsers;

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = filtered[index];
          return _UserCard(
            user: user,
            onTap: () => _showUserDetails(user),
          );
        },
      ),
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
            'No users yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first user to get started',
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
              'No audit logs found',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCenterHeadOccupied({String? excludeUserId}) {
    return _users.any(
        (u) => u.isActive && u.role == 'center_head' && u.id != excludeUserId);
  }

  bool _isUnitHeadOccupied(String unit, {String? excludeUserId}) {
    final headRole = '${unit}_head';
    return _users
        .any((u) => u.isActive && u.role == headRole && u.id != excludeUserId);
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final firstNameController = TextEditingController();
    final middleNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final suffixController = TextEditingController();
    final workIdController = TextEditingController();
    String selectedRole = 'staff';
    String selectedUnit = 'social';
    DateTime? licenseExpiryDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: const Icon(
                              Icons.person_add,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add New User',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  'Create a new staff account',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Email
                      Text('Email',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'user@example.com',
                          prefixIcon: Icon(Icons.mail_outline, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Full Name
                      // Name Fields (FML Format)
                      Text('First Name',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: firstNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Juan',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        validator: (v) => v?.isEmpty == true
                            ? 'First Name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      Text('Middle Name',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: middleNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Miguel (Optional)',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text('Last Name',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Dela Cruz',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Last Name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      Text('Extension Name (e.g. RSW, RPm, Jr.)',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: suffixController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'RSW',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // PRC License Number
                      Text('PRC License Number (Optional)',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: workIdController,
                        decoration: const InputDecoration(
                          hintText: '0012345',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // PRC License Expiry Date
                      Text('PRC License Expiry Date',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: licenseExpiryDate ??
                                DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2050),
                          );
                          if (picked != null) {
                            setDialogState(() => licenseExpiryDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 20),
                            suffixIcon: licenseExpiryDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setDialogState(
                                        () => licenseExpiryDate = null),
                                  )
                                : null,
                          ),
                          child: Text(
                            licenseExpiryDate != null
                                ? DateFormat('MMM d, y')
                                    .format(licenseExpiryDate!)
                                : 'Not set (Optional)',
                            style: TextStyle(
                              color: licenseExpiryDate != null
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Service Unit
                      Text('Service Unit (Required for Staff/Head/Super Admin)',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedUnit,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.business_outlined, size: 20),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'social', child: Text('Social Service')),
                          DropdownMenuItem(
                              value: 'homelife',
                              child: Text('Home Life Service')),
                          DropdownMenuItem(
                              value: 'psych',
                              child: Text('Psychological Service')),
                          DropdownMenuItem(
                              value: 'medical', child: Text('Medical Service')),
                          DropdownMenuItem(
                              value: 'nutrition',
                              child: Text('Nutrition and Dietetics')),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => selectedUnit = v!),
                      ),
                      const SizedBox(height: 20),

                      // Role
                      Text('Role',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 20),
                          errorText: (selectedRole == 'center_head' &&
                                  _isCenterHeadOccupied())
                              ? 'A Center Head already exists'
                              : (selectedRole == 'head' &&
                                      _isUnitHeadOccupied(selectedUnit))
                                  ? 'This unit already has a head'
                                  : null,
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: 'staff', child: Text('Staff')),
                          if (selectedUnit == 'medical')
                            const DropdownMenuItem(
                                value: 'center_doctor',
                                child: Text('Center Doctor')),
                          DropdownMenuItem(
                            value: 'head',
                            enabled: !_isUnitHeadOccupied(selectedUnit),
                            child: Text(
                                'Unit Head${_isUnitHeadOccupied(selectedUnit) ? ' (Occupied)' : ''}'),
                          ),
                          DropdownMenuItem(
                            value: 'center_head',
                            enabled: !_isCenterHeadOccupied(),
                            child: Text(
                                'Center Head${_isCenterHeadOccupied() ? ' (Occupied)' : ''}'),
                          ),
                          const DropdownMenuItem(
                              value: 'super_admin', child: Text('Super Admin')),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => selectedRole = v!),
                      ),
                      const SizedBox(height: 32),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                // Final occupancy check
                                if (selectedRole == 'center_head' &&
                                    _isCenterHeadOccupied()) {
                                  return;
                                }
                                if (selectedRole == 'head' &&
                                    _isUnitHeadOccupied(selectedUnit)) {
                                  return;
                                }

                                Navigator.pop(context);
                                // Pass unit for staff, head, and super_admin roles
                                final unitToSave = (selectedRole == 'staff' ||
                                        selectedRole == 'head' ||
                                        selectedRole == 'center_doctor' ||
                                        selectedRole == 'super_admin')
                                    ? selectedUnit
                                    : null;
                                // Combine names
                                final f = firstNameController.text.trim();
                                final m = middleNameController.text.trim();
                                final l = lastNameController.text.trim();
                                final s = suffixController.text.trim();

                                // Format: "First M. Last, Suffix"
                                final middlePart = m.isNotEmpty ? " $m" : "";
                                final suffixPart = s.isNotEmpty ? ", $s" : "";
                                final combinedName =
                                    "$f$middlePart $l$suffixPart";

                                _createUser(
                                  email: emailController.text.trim(),
                                  fullName: combinedName,
                                  workId: workIdController.text.trim().isEmpty
                                      ? null
                                      : workIdController.text.trim(),
                                  role: selectedRole,
                                  unit: unitToSave,
                                  licenseExpiryDate: licenseExpiryDate,
                                );
                              },
                              child: const Text('Create User'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createUser({
    required String email,
    required String fullName,
    String? workId,
    required String role,
    String? unit,
    DateTime? licenseExpiryDate,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await _adminRepo.provisionUser(
        email: email,
        fullName: fullName,
        workId: workId,
        role: role,
        unit: unit,
        licenseExpiryDate: licenseExpiryDate,
      );

      if (navigator.canPop()) navigator.pop();

      _showCredentialsDialog(
        email: email,
        password: result.tempPassword,
      );

      _loadUsers();
    } catch (e) {
      if (navigator.canPop()) navigator.pop();
      if (mounted) {
        CustomErrorDialog.show(
          context,
          title: 'Failed to create user',
          message: ErrorHandler.getUserFriendlyMessage(e),
        );
      }
    }
  }

  void _showCredentialsDialog({
    required String email,
    required String password,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.success,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'User Created Successfully',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Share these credentials with the new user:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Credentials card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _CredentialRow(
                      label: 'Email',
                      value: email,
                    ),
                    const Divider(height: 24),
                    _CredentialRow(
                      label: 'Password',
                      value: password,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The user should change their password after first login.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warningLight,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(
      UserModel user, StateSetter setSheetState) async {
    final isDeactivating = user.isActive;
    final action = isDeactivating ? 'Deactivate' : 'Reactivate';

    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action User?'),
        content: Text(
            'Are you sure you want to ${action.toLowerCase()} ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDeactivating ? AppColors.error : AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Block reactivation if center head or unit head slot is already occupied
    if (!isDeactivating) {
      if (user.isCenterHead && _isCenterHeadOccupied()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cannot reactivate: There is already an active Center Head. Deactivate them first if you want to reactivate ${user.fullName}.',
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      if (user.isUnitHead &&
          user.unit != null &&
          user.unit!.isNotEmpty &&
          _isUnitHeadOccupied(user.unit!)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cannot reactivate: ${user.unit} unit already has an active Unit Head. Deactivate them first if you want to reactivate ${user.fullName}.',
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
    }

    // Block deactivation if this user has any residents assigned (as houseparent or social worker)
    if (isDeactivating) {
      final residentRepo = ResidentRepository();
      const statuses = ['admitted', 'pre_admission'];
      final asHouseparent = await residentRepo.getResidents(
        houseparentId: user.id,
        pageSize: 1,
        statuses: statuses,
      );
      final asSocialWorker = await residentRepo.getResidents(
        socialWorkerId: user.id,
        pageSize: 1,
        statuses: statuses,
      );
      if ((asHouseparent.isNotEmpty || asSocialWorker.isNotEmpty) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot deactivate: ${user.fullName} still has residents assigned. Reassign them first from Ward Management or Resident details.',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
    }

    setSheetState(() => _isLoadingSheet = true);

    try {
      if (isDeactivating) {
        await _adminRepo.deactivateUser(user.id);
      } else {
        await _adminRepo.reactivateUser(user.id);
      }

      if (mounted) {
        // Safe popping: Check if we can pop before doing so
        final nav = Navigator.of(context);
        if (nav.canPop()) nav.pop(); // Close details sheet

        if (!mounted) return;
        _loadUsers(); // Refresh list

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'User ${isDeactivating ? 'deactivated' : 'reactivated'} successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomErrorDialog.show(context,
            title: '$action Failed',
            error: e,
            message: 'Could not update user status.');
      }
    } finally {
      if (mounted) {
        setSheetState(() => _isLoadingSheet = false);
      } else {
        _isLoadingSheet = false; // Primary state reset if unmounted
      }
    }
  }

  bool _isLoadingSheet = false;

  void _showUserDetails(UserModel user) {
    _isLoadingSheet = false; // Reset state for a new bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(user.fullName),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                _RoleBadge(role: user.role),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Details
                      _DetailRow(
                        icon: Icons.mail_outline,
                        label: 'Email',
                        value: user.email,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.badge_outlined,
                        label: 'PRC License Number',
                        value: user.workId,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.business_outlined,
                        label: 'Unit',
                        value: _formatUnit(user.unit ?? 'N/A'),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Created',
                        value: DateFormat('MMM d, y').format(user.createdAt),
                      ),
                      const SizedBox(height: 32),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditUserDialog(user);
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isLoadingSheet
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () =>
                                        _toggleUserStatus(user, setSheetState),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: user.isActive
                                          ? AppColors.errorSurface
                                          : AppColors.successSurface,
                                      foregroundColor: user.isActive
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                    icon: Icon(user.isActive
                                        ? Icons.block_outlined
                                        : Icons.check_circle_outlined),
                                    label: Text(user.isActive
                                        ? 'Deactivate'
                                        : 'Reactivate'),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Parse a full name into parts (best-effort)
  Map<String, String> _parseFullName(String fullName) {
    // Handle suffix after comma: "First Middle Last, RSW"
    String suffix = '';
    String namePart = fullName;
    if (fullName.contains(',')) {
      final parts = fullName.split(',');
      namePart = parts[0].trim();
      suffix = parts.sublist(1).join(',').trim();
    }

    final words =
        namePart.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) {
      return {'first': '', 'middle': '', 'last': '', 'suffix': suffix};
    }
    if (words.length == 1) {
      return {'first': words[0], 'middle': '', 'last': '', 'suffix': suffix};
    }
    if (words.length == 2) {
      return {
        'first': words[0],
        'middle': '',
        'last': words[1],
        'suffix': suffix
      };
    }

    // 3+ words: first, middle (all between), last
    return {
      'first': words.first,
      'middle': words.sublist(1, words.length - 1).join(' '),
      'last': words.last,
      'suffix': suffix,
    };
  }

  void _showEditUserDialog(UserModel user) {
    final formKey = GlobalKey<FormState>();
    final nameParts = _parseFullName(user.fullName);
    final firstNameController = TextEditingController(text: nameParts['first']);
    final middleNameController =
        TextEditingController(text: nameParts['middle']);
    final lastNameController = TextEditingController(text: nameParts['last']);
    final suffixController = TextEditingController(text: nameParts['suffix']);
    final workIdController = TextEditingController(text: user.workId);
    DateTime? licenseExpiryDate = user.licenseExpiryDate;
    // Normalize compound roles (e.g. 'social_head' -> 'head', 'homelife_staff' -> 'staff')
    String selectedRole = user.role;
    String selectedUnit = user.unit ?? 'social';
    const validRoles = ['staff', 'head', 'center_head', 'super_admin'];
    if (!validRoles.contains(selectedRole)) {
      if (selectedRole.endsWith('_head')) {
        final prefix = selectedRole.replaceAll('_head', '');
        selectedUnit = prefix == 'homelife' ? 'homelife' : prefix;
        selectedRole = 'head';
      } else if (selectedRole.endsWith('_staff')) {
        final prefix = selectedRole.replaceAll('_staff', '');
        selectedUnit = prefix == 'homelife' ? 'homelife' : prefix;
        selectedRole = 'staff';
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit User',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  'Update staff account details',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Email (read-only)
                      Text('Email',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: user.email,
                        readOnly: true,
                        enabled: false,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.mail_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // First Name
                      Text('First Name',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: firstNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Juan',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        validator: (v) => v?.isEmpty == true
                            ? 'First Name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      Text('Middle Name',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: middleNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Miguel (Optional)',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text('Last Name',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Dela Cruz',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Last Name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      Text('Extension Name (e.g. RSW, RPm, Jr.)',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: suffixController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'RSW',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // PRC License Number
                      Text('PRC License Number (Optional)',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: workIdController,
                        decoration: const InputDecoration(
                          hintText: '0012345',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // PRC License Expiry Date
                      Text('PRC License Expiry Date',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: licenseExpiryDate ??
                                DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2050),
                          );
                          if (picked != null) {
                            setDialogState(() => licenseExpiryDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 20),
                            suffixIcon: licenseExpiryDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setDialogState(
                                        () => licenseExpiryDate = null),
                                  )
                                : null,
                          ),
                          child: Text(
                            licenseExpiryDate != null
                                ? DateFormat('MMM d, y')
                                    .format(licenseExpiryDate!)
                                : 'Not set (Optional)',
                            style: TextStyle(
                              color: licenseExpiryDate != null
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Service Unit
                      Text('Service Unit (Required for Staff/Head/Super Admin)',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedUnit,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.business_outlined, size: 20),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'social', child: Text('Social Service')),
                          DropdownMenuItem(
                              value: 'homelife',
                              child: Text('Home Life Service')),
                          DropdownMenuItem(
                              value: 'psych',
                              child: Text('Psychological Service')),
                          DropdownMenuItem(
                              value: 'medical', child: Text('Medical Service')),
                          DropdownMenuItem(
                              value: 'nutrition',
                              child: Text('Nutrition and Dietetics')),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => selectedUnit = v!),
                      ),
                      const SizedBox(height: 20),

                      // Role
                      Text('Role',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 20),
                          errorText: (selectedRole == 'center_head' &&
                                  _isCenterHeadOccupied(excludeUserId: user.id))
                              ? 'A Center Head already exists'
                              : (selectedRole == 'head' &&
                                      _isUnitHeadOccupied(selectedUnit,
                                          excludeUserId: user.id))
                                  ? 'This unit already has a head'
                                  : null,
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: 'staff', child: Text('Staff')),
                          if (selectedUnit == 'medical')
                            const DropdownMenuItem(
                                value: 'center_doctor',
                                child: Text('Center Doctor')),
                          DropdownMenuItem(
                            value: 'head',
                            enabled: !_isUnitHeadOccupied(selectedUnit,
                                excludeUserId: user.id),
                            child: Text(
                                'Unit Head${_isUnitHeadOccupied(selectedUnit, excludeUserId: user.id) ? ' (Occupied)' : ''}'),
                          ),
                          DropdownMenuItem(
                            value: 'center_head',
                            enabled:
                                !_isCenterHeadOccupied(excludeUserId: user.id),
                            child: Text(
                                'Center Head${_isCenterHeadOccupied(excludeUserId: user.id) ? ' (Occupied)' : ''}'),
                          ),
                          const DropdownMenuItem(
                              value: 'super_admin', child: Text('Super Admin')),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => selectedRole = v!),
                      ),
                      const SizedBox(height: 32),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                // Final occupancy check
                                if (selectedRole == 'center_head' &&
                                    _isCenterHeadOccupied(
                                        excludeUserId: user.id)) {
                                  return;
                                }
                                if (selectedRole == 'head' &&
                                    _isUnitHeadOccupied(selectedUnit,
                                        excludeUserId: user.id)) {
                                  return;
                                }

                                Navigator.pop(context);
                                final unitToSave = (selectedRole == 'staff' ||
                                        selectedRole == 'head' ||
                                        selectedRole == 'center_doctor' ||
                                        selectedRole == 'super_admin')
                                    ? selectedUnit
                                    : null;
                                // Combine names
                                final f = firstNameController.text.trim();
                                final m = middleNameController.text.trim();
                                final l = lastNameController.text.trim();
                                final s = suffixController.text.trim();

                                final middlePart = m.isNotEmpty ? " $m" : "";
                                final suffixPart = s.isNotEmpty ? ", $s" : "";
                                final combinedName =
                                    "$f$middlePart $l$suffixPart";

                                _updateUser(
                                  userId: user.id,
                                  fullName: combinedName,
                                  workId: workIdController.text.trim().isEmpty
                                      ? null
                                      : workIdController.text.trim(),
                                  role: selectedRole,
                                  unit: unitToSave,
                                  licenseExpiryDate: licenseExpiryDate,
                                );
                              },
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateUser({
    required String userId,
    required String fullName,
    String? workId,
    required String role,
    String? unit,
    DateTime? licenseExpiryDate,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _adminRepo.updateUserProfile(
        userId: userId,
        fullName: fullName,
        workId: workId,
        role: role,
        unit: unit,
        licenseExpiryDate: licenseExpiryDate,
      );

      if (navigator.canPop()) navigator.pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (navigator.canPop()) navigator.pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatUnit(String unit) {
    switch (unit) {
      case 'social':
        return 'Social Service';
      case 'homelife':
        return 'Home Life Service';
      case 'psych':
        return 'Psychological Service';
      case 'medical':
        return 'Medical Service';
      case 'rehab':
        return 'Rehabilitation Service';
      case 'nutrition':
      case 'dietetics':
        return 'Nutrition and Dietetics';
      default:
        return unit;
    }
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Opacity(
          opacity: user.isActive ? 1.0 : 0.85,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: user.isActive
                  ? null
                  : Theme.of(context).hoverColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: user.isActive
                    ? Theme.of(context).dividerColor
                    : Theme.of(context).dividerColor.withValues(alpha: 0.8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? AppColors.primarySurface
                        : Theme.of(context).hintColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(user.fullName),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: user.isActive
                                ? AppColors.primary
                                : Theme.of(context).hintColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    decoration: user.isActive
                                        ? null
                                        : TextDecoration.lineThrough,
                                    color: user.isActive
                                        ? null
                                        : Theme.of(context).hintColor,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!user.isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: const Text(
                                'INACTIVE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: user.isActive
                                  ? null
                                  : Theme.of(context).hintColor,
                            ),
                      ),
                    ],
                  ),
                ),
                _RoleBadge(role: user.role, isActive: user.isActive),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: user.isActive
                      ? Theme.of(context).hintColor
                      : Theme.of(context).hintColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  final bool isActive;

  const _RoleBadge({
    required this.role,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, label) = _getRoleStyle(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? bgColor : bgColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: isActive
            ? null
            : Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isActive ? color : color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  (Color, Color, String) _getRoleStyle(String role) {
    if (role == 'super_admin') {
      return (
        AppColors.primary,
        AppColors.primary.withValues(alpha: 0.08),
        'Super Admin',
      );
    }

    if (role == 'center_head') {
      return (
        AppColors.primary,
        AppColors.primary.withValues(alpha: 0.08),
        'Center Head',
      );
    }

    // Parse role like "social_staff" or "medical_head"
    final parts = role.split('_');
    if (parts.length == 2) {
      final unitKey = parts[0];
      final roleType = parts[1]; // 'head' or 'staff'

      final color = AppColors.getServiceUnitColor(unitKey);
      final bgColor = color.withValues(alpha: 0.08);

      String unitLabel = unitKey[0].toUpperCase() + unitKey.substring(1);
      switch (unitKey) {
        case 'social':
          unitLabel = 'Social';
          break;
        case 'medical':
          unitLabel = 'Medical';
          break;
        case 'psych':
          unitLabel = 'Psychological';
          break;
        case 'rehab':
          unitLabel = 'Rehabilitation';
          break;
        case 'homelife':
          unitLabel = 'Home Life';
          break;
        case 'nutrition':
          unitLabel = 'Nutrition';
          break;
      }

      final label = '$unitLabel ${roleType == 'head' ? 'Head' : 'Staff'}';
      return (color, bgColor, label);
    }

    // Fallback for legacy or untyped roles
    switch (role) {
      case 'head':
        return (
          AppColors.warning,
          AppColors.warningSurface,
          'Unit Head',
        );
      case 'staff':
        return (
          AppColors.primary,
          AppColors.primarySurface,
          'Staff',
        );
      default:
        return (
          AppColors.textSecondary,
          AppColors.surfaceHover,
          role
              .replaceAll('_', ' ')
              .split(' ')
              .map((w) =>
                  w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
              .join(' '),
        );
    }
  }
}

class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;

  const _CredentialRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copied to clipboard'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          icon: Icon(
            Icons.copy,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceHover,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isError;

  const _FilterTab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isError ? AppColors.error : AppColors.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected
                ? (isError ? AppColors.error : AppColors.primary)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Theme.of(context).hoverColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _getInitials(String name) {
  final parts = name.split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}
