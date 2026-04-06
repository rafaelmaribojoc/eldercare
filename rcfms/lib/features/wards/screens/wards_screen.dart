import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/ward_model.dart';
import '../../../data/repositories/resident_repository.dart';

class WardsScreen extends StatefulWidget {
  const WardsScreen({super.key});

  @override
  State<WardsScreen> createState() => _WardsScreenState();
}

class _WardsScreenState extends State<WardsScreen> {
  List<WardModel> _wards = [];
  List<WardModel> _filteredWards = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  StreamSubscription<List<WardModel>>? _wardsSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToWards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _wardsSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToWards() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<ResidentRepository>();
      _wardsSubscription?.cancel();
      _wardsSubscription = repo.watchWards().listen(
        (wards) {
          if (!mounted) return;
          setState(() {
            _wards = wards;
            _filterWards(_searchController.text);
            _isLoading = false;
          });
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _error = ErrorHandler.getUserFriendlyMessage(e);
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorHandler.getUserFriendlyMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWards() async {
    _subscribeToWards();
  }

  void _filterWards(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredWards = _wards;
      } else {
        _filteredWards = _wards
            .where((w) =>
                w.name.toLowerCase().contains(query.toLowerCase()) ||
                (w.building?.toLowerCase().contains(query.toLowerCase()) ??
                    false))
            .toList();
      }
    });
  }

  Color _occupancyColor(WardModel ward) {
    final pct = ward.occupancyPercentage;
    if (pct >= 90) return AppColors.error;
    if (pct >= 70) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: const Text('Wards'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadWards,
                ),
              ],
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadWards,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _filterWards,
                decoration: InputDecoration(
                  hintText: 'Search wards...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _filterWards('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide:
                        BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide:
                        BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Summary row
            if (!_isLoading && _error == null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${_filteredWards.length} ward${_filteredWards.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${_wards.fold<int>(0, (sum, w) => sum + w.currentOccupancy)} total residents',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load wards',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadWards,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredWards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room_outlined,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No wards match your search'
                  : 'No active wards',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = context.isDesktop
        ? 3
        : context.isTablet
            ? 2
            : 1;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: crossAxisCount == 1 ? 2.2 : 1.6,
      ),
      itemCount: _filteredWards.length,
      itemBuilder: (context, index) => _WardCard(
        ward: _filteredWards[index],
        occupancyColor: _occupancyColor(_filteredWards[index]),
        onTap: () async {
          await context.push('/wards/${_filteredWards[index].id}');
          if (mounted) _loadWards();
        },
      ),
    );
  }
}

class _WardCard extends StatelessWidget {
  final WardModel ward;
  final Color occupancyColor;
  final VoidCallback onTap;

  const _WardCard({
    required this.ward,
    required this.occupancyColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ward.occupancyPercentage;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: occupancyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.meeting_room_rounded,
                      color: occupancyColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ward.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (ward.displayLocation != 'N/A')
                          Text(
                            ward.displayLocation,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                      ],
                    ),
                  ),
                  // Occupancy badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: occupancyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pct.toInt()}%',
                      style: TextStyle(
                        color: occupancyColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Occupancy bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${ward.currentOccupancy} / ${ward.capacity} beds',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        '${ward.availableBeds} available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ward.availableBeds > 0
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ward.capacity > 0
                          ? (ward.currentOccupancy / ward.capacity)
                              .clamp(0.0, 1.0)
                          : 0,
                      backgroundColor: Theme.of(context).dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(occupancyColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Footer
              Row(
                children: [
                  if (ward.hasNfcTag)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.nfc,
                          size: 16, color: AppColors.textTertiary),
                    ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppColors.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
