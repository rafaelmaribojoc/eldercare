import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/timeline_entry_model.dart';
import '../../../data/models/resident_model.dart';
import '../../../data/repositories/form_repository.dart';
import '../../../data/repositories/resident_repository.dart';

class TimelineScreen extends StatefulWidget {
  final String residentId;

  const TimelineScreen({super.key, required this.residentId});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<TimelineEntryModel> _entries = [];
  ResidentModel? _resident;
  bool _isLoading = true;
  String? _selectedUnit;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final residentRepo = context.read<ResidentRepository>();
      final formRepo = context.read<FormRepository>();

      final resident = await residentRepo.getResidentById(widget.residentId);
      final entries = await formRepo.getTimeline(
        residentId: widget.residentId,
        unit: _selectedUnit,
      );

      setState(() {
        _resident = resident;
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _subscribeToRealtime() {
    final formRepo = context.read<FormRepository>();
    _realtimeChannel = formRepo.subscribeToTimeline(
      widget.residentId,
      (entry) {
        setState(() {
          _entries.insert(0, entry);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_resident?.fullName ?? 'Timeline'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.listFilter),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState()
              : _buildTimeline(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.chartNoAxesGantt,
            size: 64,
            color: AppColors.textSecondaryLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No timeline entries yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Approved forms will appear here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final isLast = index == _entries.length - 1;

          return _TimelineItem(
            entry: entry,
            isLast: isLast,
            onTap: entry.formSubmissionId != null
                ? () => context.push('/forms/view/${entry.formSubmissionId}')
                : null,
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Unit',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildFilterOption(null, 'All Units', LucideIcons.infinity),
                _buildFilterOption(
                    'social', 'Social Services', LucideIcons.users),
                _buildFilterOption(
                    'medical', 'Medical', LucideIcons.stethoscope),
                _buildFilterOption('psych', 'Psychology', LucideIcons.brain),
                _buildFilterOption('homelife', 'Homelife', LucideIcons.house),
                _buildFilterOption(
                    'nutrition', 'Nutrition & Dietetics', LucideIcons.utensils),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String? unit, String label, IconData icon) {
    final isSelected = _selectedUnit == unit;
    final color = unit != null ? _getUnitColor(unit) : AppColors.primary;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: isSelected ? Icon(LucideIcons.check, color: color) : null,
      onTap: () {
        setState(() {
          _selectedUnit = unit;
        });
        Navigator.pop(context);
        _loadData();
      },
    );
  }

  Color _getUnitColor(String unit) {
    switch (unit) {
      case 'social':
        return AppColors.unitSocial;
      case 'medical':
        return AppColors.unitMedical;
      case 'psych':
        return AppColors.unitPsych;
      case 'rehab':
        return AppColors.unitRehab;
      case 'homelife':
        return AppColors.unitHomelife;
      default:
        return AppColors.primary;
    }
  }
}

class _TimelineItem extends StatelessWidget {
  final TimelineEntryModel entry;
  final bool isLast;
  final VoidCallback? onTap;

  const _TimelineItem({
    required this.entry,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: entry.unitColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: entry.unitColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.dividerLight,
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: entry.unitColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              entry.unitDisplayName,
                              style: TextStyle(
                                color: entry.unitColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(entry.createdAt),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Row(
                        children: [
                          Icon(
                            entry.icon,
                            size: 18,
                            color: entry.unitColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      // Description
                      if (entry.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          entry.description!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                        ),
                      ],
                      // Creator
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.user,
                            size: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.creatorName ?? 'Unknown',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                          ),
                          if (onTap != null) ...[
                            const Spacer(),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 18,
                              color: AppColors.textSecondaryLight,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
