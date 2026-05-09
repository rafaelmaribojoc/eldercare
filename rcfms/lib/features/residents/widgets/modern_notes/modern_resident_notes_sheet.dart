import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/resident_note.dart';
import '../../../../data/repositories/resident_note_repository.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../quick_note_bottom_sheet.dart';
import 'modern_notes_sidebar.dart';
import 'note_card.dart';

class ModernResidentNotesSheet extends StatefulWidget {
  final String residentId;
  final String residentName;
  final bool canAddNotes;

  const ModernResidentNotesSheet({
    super.key,
    required this.residentId,
    required this.residentName,
    this.canAddNotes = true,
  });

  @override
  State<ModernResidentNotesSheet> createState() =>
      _ModernResidentNotesSheetState();
}

class _ModernResidentNotesSheetState extends State<ModernResidentNotesSheet> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State
  List<ResidentNote> _allNotes = [];
  List<ResidentNote> _filteredNotes = [];
  bool _isLoading = true;

  // Filters
  NoteFilter _currentFilter = const NoteFilter(type: NoteFilterType.all);
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Selection Mode
  bool _selectionMode = false;
  final Set<String> _selectedNoteIds = {};

  // Permissions
  String? _currentUserId;

  // Advanced Filters
  String? _selectedService; // 'Medical', 'Social', etc.
  final bool _onlyMyNotes = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchNotes();
  }

  Future<void> _fetchCurrentUser() async {
    final user = await AuthRepository().getCurrentUser(); // Use Repository
    if (mounted) {
      setState(() => _currentUserId = user?.id);
    }
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      // Fetch ALL notes including archived, we will filter in memory
      // Note: Repository update required to support includeArchived=true.
      // Assuming it's done or I'll just fetch normally and manage archived separately?
      // For now assuming getNotesByResident(includeArchived: true) exists.
      final notes = await ResidentNoteRepository()
          .getNotesByResident(widget.residentId, includeArchived: true);

      if (mounted) {
        setState(() {
          _allNotes = notes;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var temp = List<ResidentNote>.from(_allNotes);

    // 0. Date Range Filter
    if (_startDate != null && _endDate != null) {
      temp = temp.where((n) {
        final date = n.createdAt;
        // Inclusive check
        return date.isAfter(_startDate!.subtract(const Duration(seconds: 1))) &&
            date.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // 1. Service Filter (Quick Chips)
    if (_selectedService != null) {
      if (_selectedService == 'My Notes') {
        temp = temp.where((n) => n.authorId == _currentUserId).toList();
      } else {
        temp = temp
            .where(
                (n) => _getServiceForCategory(n.category) == _selectedService)
            .toList();
      }
    }

    // 2. Explicit My Notes Toggle
    if (_onlyMyNotes && _selectedService != 'My Notes') {
      temp = temp.where((n) => n.authorId == _currentUserId).toList();
    }

    // 3. Sidebar Filter
    switch (_currentFilter.type) {
      case NoteFilterType.all:
        temp = temp.where((n) => !n.isArchived).toList();
        break;
      case NoteFilterType.locked:
        temp = temp.where((n) => n.isConfidential && !n.isArchived).toList();
        break;
      case NoteFilterType.favorites:
        temp = temp.where((n) => n.isFavorite && !n.isArchived).toList();
        break;
      case NoteFilterType.trash:
        temp = temp.where((n) => n.isArchived).toList();
        break;
      case NoteFilterType.folder:
        if (_currentFilter.folderName != null) {
          final folder = _currentFilter.folderName!.toLowerCase();
          temp = temp.where((n) {
            return _getServiceForCategory(n.category).toLowerCase() == folder &&
                !n.isArchived;
          }).toList();
        }
        break;
    }

    // 4. Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      temp = temp
          .where((n) =>
              (n.title?.toLowerCase().contains(q) ?? false) ||
              n.content.toLowerCase().contains(q))
          .toList();
    }

    setState(() {
      _filteredNotes = temp;
    });
  }

  // Duplicate logic from QuickNote for Filter grouping
  // Ideal: Refactor to shared utility. For now, inline for speed.
  String _getServiceForCategory(String category) {
    // Basic mapping
    final cat = category.toLowerCase();
    if ([
      'vitals',
      'medication',
      'physical',
      'body_map',
      'complaint',
      'treatment',
      'dietary',
      'medical'
    ].contains(cat)) {
      return 'Medical';
    }

    // Psych specific
    if (['behavior', 'counseling', 'psychology', 'behavioral'].contains(cat)) {
      return 'Psychology';
    }

    // Social (and shared terms that act as Social by default)
    if (['social', 'interaction', 'case_note', 'goal'].contains(cat)) {
      return 'Social';
    }

    if (['homelife', 'activity', 'hygiene', 'inventory', 'incident', 'movement']
        .contains(cat)) {
      return 'Homelife';
    }

    if (['nutrition', 'dietetics', 'dietary', 'diet'].contains(cat)) {
      return 'Nutrition';
    }

    return 'Other';
  }

  void _onFilterChanged(NoteFilter filter) {
    setState(() {
      _currentFilter = filter;
      _applyFilters();
      // Close drawer
      Navigator.pop(context);
    });
  }

  Future<void> _deleteOrRestore(ResidentNote note,
      {bool restore = false}) async {
    if (restore) {
      await ResidentNoteRepository().restoreNote(note.id);
    } else {
      await ResidentNoteRepository().archiveNote(note.id);
    }
    _fetchNotes();
  }

  Future<void> _permanentDelete(ResidentNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await ResidentNoteRepository().deleteNote(note.id);
      _fetchNotes();
    }
  }

  Widget _buildQuickChip(String label, bool isSelected,
      {bool isSpecial = false}) {
    final color = isSpecial && isSelected
        ? AppColors.primary
        : (isSelected ? Colors.black87 : Colors.grey.shade200);
    final textColor = isSelected ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == 'All') {
            _selectedService = null;
          } else if (_selectedService == label) {
            _selectedService = null;
          } else {
            _selectedService = label;
          }
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92, // Almost full screen
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          drawer: Drawer(
            child: ModernNotesSidebar(
              currentFilter: _currentFilter,
              onFilterChanged: _onFilterChanged,
            ),
          ),
          body: Column(
            children: [
              // Custom App Bar (Context Aware)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _selectionMode
                    // Selection Mode AppBar
                    ? Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.x),
                            onPressed: () {
                              setState(() {
                                _selectionMode = false;
                                _selectedNoteIds.clear();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedNoteIds.length} Selected',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(LucideIcons.scan),
                            tooltip: 'Select All',
                            onPressed: _selectAll,
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.star,
                                color: Colors.amber),
                            tooltip: 'Favorite Selected',
                            onPressed: _bulkFavorite,
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2,
                                color: Colors.red),
                            tooltip: 'Delete Selected',
                            onPressed: _bulkDelete,
                          ),
                        ],
                      )
                    // Normal AppBar
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.menu),
                                onPressed: () =>
                                    _scaffoldKey.currentState?.openDrawer(),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Resident Notes',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              const Spacer(),
                              if (widget.canAddNotes)
                                IconButton(
                                  icon: const Icon(LucideIcons.circlePlus,
                                      color: AppColors.primary, size: 32),
                                  onPressed: () async {
                                    await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) =>
                                          QuickNoteBottomSheet(
                                        residentId: widget.residentId,
                                        residentName: widget.residentName,
                                      ),
                                    );
                                    _fetchNotes();
                                  },
                                ),
                              IconButton(
                                icon: Icon(
                                  _startDate != null
                                      ? LucideIcons.calendarDays
                                      : LucideIcons.calendar,
                                  color: _startDate != null
                                      ? AppColors.primary
                                      : Colors.grey.shade600,
                                ),
                                onPressed: () async {
                                  final range = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    initialDateRange:
                                        _startDate != null && _endDate != null
                                            ? DateTimeRange(
                                                start: _startDate!,
                                                end: _endDate!)
                                            : null,
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: AppColors.primary,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );

                                  if (range != null) {
                                    setState(() {
                                      _startDate = range.start;
                                      _endDate = range.end;
                                      _applyFilters();
                                    });
                                  }
                                },
                                tooltip: 'Filter by Date',
                              ),
                              if (_startDate != null)
                                IconButton(
                                  icon: const Icon(LucideIcons.x, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _startDate = null;
                                      _endDate = null;
                                      _applyFilters();
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Search bar on its own row for better visibility
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() => _searchQuery = val);
                                  _applyFilters();
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Search notes...',
                                  prefixIcon: Icon(LucideIcons.search),
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              // Quick Filter Chips
              if (!_selectionMode)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // "All" Chip
                      _buildQuickChip('All', _selectedService == null),
                      const SizedBox(width: 8),
                      // Service Chips
                      _buildQuickChip('Medical', _selectedService == 'Medical'),
                      const SizedBox(width: 8),
                      _buildQuickChip('Social', _selectedService == 'Social'),
                      const SizedBox(width: 8),
                      _buildQuickChip(
                          'Psychology', _selectedService == 'Psychology'),
                      const SizedBox(width: 8),
                      _buildQuickChip(
                          'Homelife', _selectedService == 'Homelife'),
                      const SizedBox(width: 8),
                      _buildQuickChip(
                          'Nutrition', _selectedService == 'Nutrition'),
                      const SizedBox(width: 8),
                      // My Notes
                      _buildQuickChip(
                          'My Notes', _selectedService == 'My Notes',
                          isSpecial: true),
                    ],
                  ),
                ),
              const SizedBox(height: 8),

              // Filter Title Header
              if (_currentFilter.type != NoteFilterType.all)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        _getFilterTitle(),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit'),
                      ),
                      const Spacer(),
                      if (_currentFilter.type == NoteFilterType.trash)
                        TextButton.icon(
                          icon: const Icon(LucideIcons.trash2,
                              size: 16, color: Colors.red),
                          label: const Text('Empty',
                              style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            // TODO: Implement Empty Trash
                          },
                        ),
                    ],
                  ),
                ),

              // Recycle Bin Disclaimer
              if (_currentFilter.type == NoteFilterType.trash)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info,
                          size: 20, color: Colors.orange.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Items in the recycle bin are permanently deleted after 30 days.',
                          style: TextStyle(
                              color: Colors.orange.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Content List (Masonry-ish)
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredNotes.isEmpty
                        ? _buildEmptyState()
                        : _buildMasonryGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFilterTitle() {
    switch (_currentFilter.type) {
      case NoteFilterType.all:
        return 'All notes';
      case NoteFilterType.locked:
        return 'Locked notes';
      case NoteFilterType.favorites:
        return 'Favorites';
      case NoteFilterType.trash:
        return 'Recycle bin';
      case NoteFilterType.folder:
        return _currentFilter.folderName ?? 'Folder';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.notebookTabs, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'No notes found',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildMasonryGrid() {
    // Split into two columns
    final leftNotes = <ResidentNote>[];
    final rightNotes = <ResidentNote>[];

    for (var i = 0; i < _filteredNotes.length; i++) {
      if (i % 2 == 0) {
        leftNotes.add(_filteredNotes[i]);
      } else {
        rightNotes.add(_filteredNotes[i]);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: leftNotes
                  .map((note) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NoteCard(
                          note: note,
                          selectionMode: _selectionMode,
                          isSelected: _selectedNoteIds.contains(note.id),
                          onTap: () => _onNoteTap(note),
                          onLongPress: () => _onNoteLongPress(note),
                          onFavoriteToggle: () => _toggleFavorite(note),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: rightNotes
                  .map((note) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NoteCard(
                          note: note,
                          selectionMode: _selectionMode,
                          isSelected: _selectedNoteIds.contains(note.id),
                          onTap: () => _onNoteTap(note),
                          onLongPress: () => _onNoteLongPress(note),
                          onFavoriteToggle: () => _toggleFavorite(note),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _onNoteTap(ResidentNote note) async {
    // 1. Selection Mode Handling
    if (_selectionMode) {
      // Permission Check: Can only select own notes
      if (note.authorId != _currentUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only select your own notes.'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      setState(() {
        if (_selectedNoteIds.contains(note.id)) {
          _selectedNoteIds.remove(note.id);
          if (_selectedNoteIds.isEmpty) {
            _selectionMode = false; // Auto-exit if empty
          }
        } else {
          _selectedNoteIds.add(note.id);
        }
      });
      return;
    }

    // 2. Normal Mode - Trash Handling
    if (note.isArchived) {
      final action = await showDialog<String>(
          context: context,
          builder: (ctx) => SimpleDialog(
                title: const Text('Recycle Bin'),
                children: [
                  if (note.authorId == _currentUserId) ...[
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, 'restore'),
                      child: const Row(children: [
                        Icon(LucideIcons.rotateCcw),
                        SizedBox(width: 10),
                        Text('Restore')
                      ]),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, 'delete'),
                      child: const Row(children: [
                        Icon(LucideIcons.trash2, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Delete Permanently')
                      ]),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                          'Only the author can restore/delete this note.',
                          style: TextStyle(color: Colors.grey)),
                    )
                ],
              ));

      if (action == 'restore') _deleteOrRestore(note, restore: true);
      if (action == 'delete') _permanentDelete(note);
      return;
    }

    // 3. Normal Mode - Edit/View
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickNoteBottomSheet(
        residentId: widget.residentId,
        residentName: widget.residentName,
        existingNote: note,
      ),
    );
    _fetchNotes();
  }

  void _onNoteLongPress(ResidentNote note) {
    // Permission Check
    if (note.authorId != _currentUserId) {
      // Quietly ignore or show toast
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only select your own notes.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if (!_selectionMode) {
      setState(() {
        _selectionMode = true;
        _selectedNoteIds.add(note.id);
      });
    }
  }

  // Bulk Actions
  void _selectAll() {
    setState(() {
      // Only select OWN notes
      final ownNotes =
          _filteredNotes.where((n) => n.authorId == _currentUserId);
      _selectedNoteIds.addAll(ownNotes.map((n) => n.id));
    });
  }

  Future<void> _bulkFavorite() async {
    final ids = _selectedNoteIds.toList();
    if (ids.isEmpty) return;

    // Optimistic Update (Prevent UI Pause)
    // 1. Clear selection immediately
    setState(() {
      _selectionMode = false;
      _selectedNoteIds.clear();

      // Update local state immediately
      for (final id in ids) {
        final index = _allNotes.indexWhere((n) => n.id == id);
        if (index != -1) {
          _allNotes[index] = _allNotes[index].copyWith(isFavorite: true);
        }
      }
      _applyFilters();
    });

    // 2. Parallel Background Request
    try {
      await Future.wait(
          ids.map((id) => ResidentNoteRepository().toggleFavorite(id, true)));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ids.length} notes favorited')),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Action Failed'),
            content: Text(
                'Could not update favorites: $e\n\nPlease try restarting the app or contact support.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    }
    // Sync fully in background
    _fetchNotes();
  }

  Future<void> _bulkDelete() async {
    final ids = _selectedNoteIds.toList();
    final count = ids.length;
    if (count == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $count Notes?'),
        content: const Text('Move selected notes to Recycle Bin?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      // Optimistic
      setState(() {
        _selectionMode = false;
        _selectedNoteIds.clear();
        for (final id in ids) {
          final index = _allNotes.indexWhere((n) => n.id == id);
          if (index != -1) {
            _allNotes[index] = _allNotes[index].copyWith(isArchived: true);
          }
        }
        _applyFilters();
      });

      try {
        await Future.wait(
            ids.map((id) => ResidentNoteRepository().archiveNote(id)));
        if (mounted) {
          // Optional: Success feedback could still be a small toast/snackbar,
          // but for "errors" user wants Dialogs.
          // Let's keep success subtle or remove it if "duplicate" refers to success messages too.
          // Assuming "errors/bottom pop ups" refers to the red error bars.
          // Keep success as SnackBar but ensure we clear previous ones.
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count notes moved to Recycle Bin')),
          );
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Failed'),
              content: Text('$e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                )
              ],
            ),
          );
        }
      }
      _fetchNotes();
    }
  }

  Future<void> _toggleFavorite(ResidentNote note) async {
    // 1. Optimistic Update
    final newStatus = !note.isFavorite;

    setState(() {
      final index = _allNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _allNotes[index] = _allNotes[index].copyWith(isFavorite: newStatus);
      }
      _applyFilters();
    });

    try {
      // 2. Perform DB Update
      await ResidentNoteRepository().toggleFavorite(note.id, newStatus);
    } catch (e) {
      // 3. Revert on failure
      if (mounted) {
        setState(() {
          final index = _allNotes.indexWhere((n) => n.id == note.id);
          if (index != -1) {
            _allNotes[index] =
                _allNotes[index].copyWith(isFavorite: !newStatus);
          }
          _applyFilters();
        });

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Update Failed'),
            content: Text('Could not update favorite: $e'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
            ],
          ),
        );
      }
    }
  }
}
