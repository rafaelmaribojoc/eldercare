import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/models/form_submission_model.dart';
import '../../../data/repositories/form_repository.dart';
import '../../auth/bloc/auth_bloc.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  List<FormSubmissionModel> _pendingForms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingApprovals();
  }

  Future<void> _loadPendingApprovals() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final formRepo = context.read<FormRepository>();
      final unit = authState.user.unit;

      if (!AppConstants.canApproveforms(authState.user.role)) {
        setState(() {
          _error =
              'Access Denied: You do not have permission to approve forms.';
          _isLoading = false;
        });
        return;
      }

      // Now uses form_approvals.recipient_id to only show forms sent to this user
      final forms = await formRepo.getPendingApprovals(
        unit: unit ?? 'all',
      );

      setState(() {
        _pendingForms = forms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandler.getUserFriendlyMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Forms for Review'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loadPendingApprovals,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          children: [
            const Icon(LucideIcons.circleAlert,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadPendingApprovals, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_pendingForms.isEmpty) {
      return const Center(child: Text('No pending approvals'));
    }

    return RefreshIndicator(
      onRefresh: _loadPendingApprovals,
      child: ListView.builder(
        padding:
            const EdgeInsets.only(bottom: 80, top: 16, left: 16, right: 16),
        itemCount: _pendingForms.length,
        itemBuilder: (context, index) {
          final form = _pendingForms[index];
          return _ApprovalCard(
            form: form,
            onView: () => context
                .push('/forms/view/${form.id}?mode=review')
                .then((result) {
              if (result == true && mounted) _loadPendingApprovals();
            }),
          );
        },
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final FormSubmissionModel form;
  final VoidCallback onView;

  const _ApprovalCard({
    required this.form,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: form.unitColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.fileText, color: form.unitColor),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.templateDisplayName,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('${form.residentName} • ${form.unit.toUpperCase()}'),
                    const SizedBox(height: 8),
                    Text(
                      'Submitted by ${form.submitterName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
