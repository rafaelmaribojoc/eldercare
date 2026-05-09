import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/repositories/form_repository.dart';
import '../../../data/repositories/resident_repository.dart';
import '../../../data/models/resident_model.dart';
import '../../forms/templates/form_templates.dart';

class CaseCompletenessScreen extends StatefulWidget {
  const CaseCompletenessScreen({super.key});

  @override
  State<CaseCompletenessScreen> createState() => _CaseCompletenessScreenState();
}

class _CaseCompletenessScreenState extends State<CaseCompletenessScreen> {
  List<_ResidentCompleteness> _items = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'admitted';
  String _sortBy = 'completion_asc';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final residentRepo = context.read<ResidentRepository>();
      final formRepo = FormRepository();

      final residents = await residentRepo.getResidents(status: _statusFilter);
      final filtered = residents;

      final items = <_ResidentCompleteness>[];
      for (final resident in filtered) {
        final forms = await formRepo.getFormsByResident(resident.id);
        final existingIds = forms.map((f) => f.templateId).toSet();

        final expectedTemplates = FormTemplatesRegistry.templates.where((t) {
          return t.allowedResidentStatuses.contains(resident.status) &&
              t.category == CaseFileCategory.admission;
        }).toList();

        final total = expectedTemplates.length;
        final completed =
            expectedTemplates.where((t) => existingIds.contains(t.id)).length;
        final missing = expectedTemplates
            .where((t) => !existingIds.contains(t.id))
            .map((t) => t.name)
            .toList();

        items.add(_ResidentCompleteness(
          resident: resident,
          totalExpected: total,
          totalCompleted: completed,
          missingFormNames: missing,
          totalForms: forms.length,
        ));
      }

      if (_sortBy == 'completion_asc') {
        items.sort((a, b) => a.percentage.compareTo(b.percentage));
      } else {
        items.sort((a, b) => b.percentage.compareTo(a.percentage));
      }

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getUserFriendlyMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Completeness'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.arrowUpDown),
            tooltip: 'Sort',
            onSelected: (value) {
              setState(() => _sortBy = value);
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'completion_asc',
                  child: Text('Most incomplete first')),
              const PopupMenuItem(
                  value: 'completion_desc', child: Text('Most complete first')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatusChip('Pre-Admission', 'pre_admission'),
          const SizedBox(width: 8),
          _buildStatusChip('Admitted', 'admitted'),
          const SizedBox(width: 8),
          _buildStatusChip('Discharged', 'discharged'),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _statusFilter == value,
      onSelected: (_) {
        setState(() => _statusFilter = value);
        _loadData();
      },
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circleAlert, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('Failed to load data'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text('No residents with status "$_statusFilter"'),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _items.length,
        itemBuilder: (context, index) => _buildResidentCard(_items[index]),
      ),
    );
  }

  Widget _buildResidentCard(_ResidentCompleteness item) {
    final pct = item.percentage;
    final color = pct >= 100
        ? AppColors.success
        : pct >= 70
            ? AppColors.warning
            : AppColors.error;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(0.15),
          child: Text(
            '$pct%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        title: Text(
          '${item.resident.firstName} ${item.resident.lastName}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pct >= 100
                  ? 'All admission forms complete'
                  : 'Missing: ${item.missingFormNames.length} form${item.missingFormNames.length > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(LucideIcons.folderOpen, size: 20),
          tooltip: 'View Case Files',
          onPressed: () => context.push(
            '/residents/${item.resident.id}/case-files',
            extra: item.resident,
          ),
        ),
        children: [
          if (item.missingFormNames.isNotEmpty) ...[
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Missing Forms:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ...item.missingFormNames.map(
              (name) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(LucideIcons.square,
                        size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResidentCompleteness {
  final ResidentModel resident;
  final int totalExpected;
  final int totalCompleted;
  final List<String> missingFormNames;
  final int totalForms;

  _ResidentCompleteness({
    required this.resident,
    required this.totalExpected,
    required this.totalCompleted,
    required this.missingFormNames,
    required this.totalForms,
  });

  int get percentage =>
      totalExpected > 0 ? (totalCompleted / totalExpected * 100).round() : 100;
}
