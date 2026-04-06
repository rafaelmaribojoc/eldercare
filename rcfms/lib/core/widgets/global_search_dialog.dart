import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/resident_model.dart';
import '../../data/models/form_submission_model.dart';
import '../../data/repositories/resident_repository.dart';
import '../../data/repositories/form_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<ResidentModel> _residentResults = [];
  List<FormSubmissionModel> _formResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _residentResults = [];
          _formResults = [];
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final residentRepo = context.read<ResidentRepository>();
      final formRepo = context.read<FormRepository>();

      final List<Future> futures = [
        residentRepo.getResidents(
          searchQuery: query,
          status: 'All',
          pageSize: 5,
        ),
        formRepo.searchForms(query),
      ];

      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _residentResults = results[0] as List<ResidentModel>;
          _formResults = results[1] as List<FormSubmissionModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.only(top: 80), // Top aligned like a palette
      alignment: Alignment.topCenter,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: InputDecoration(
                  hintText: 'Search residents...',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  suffixIcon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const Divider(height: 1),

            // Results List
            if (_residentResults.isNotEmpty || _formResults.isNotEmpty)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (_residentResults.isNotEmpty) ...[
                      _buildCategoryHeader('Residents'),
                      ..._residentResults.map((resident) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primarySurface,
                              child: Text(
                                resident.firstName[0],
                                style:
                                    const TextStyle(color: AppColors.primary),
                              ),
                            ),
                            title: Text(
                                '${resident.lastName}, ${resident.firstName}'),
                            subtitle: Text(
                              '${resident.wardName ?? 'Unassigned'} • ${resident.status.toUpperCase()}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              context.pop(); // Close dialog
                              context.push('/residents/${resident.id}');
                            },
                          )),
                    ],
                    if (_formResults.isNotEmpty) ...[
                      _buildCategoryHeader('Forms'),
                      ..._formResults.map((form) => ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.getServiceUnitColor(form.unit)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.description_outlined,
                                color: AppColors.getServiceUnitColor(form.unit),
                                size: 20,
                              ),
                            ),
                            title: Text(form.templateDisplayName),
                            subtitle: Text(
                              '${form.residentName} • ${form.status.toUpperCase()}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              context.pop(); // Close dialog
                              context.push('/forms/fill/${form.id}');
                            },
                          )),
                    ],
                  ],
                ),
              )
            else if (_searchController.text.isNotEmpty && !_isLoading)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No results found.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textTertiary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
