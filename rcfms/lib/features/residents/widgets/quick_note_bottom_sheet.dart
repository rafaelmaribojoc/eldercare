import 'package:flutter/material.dart';
import '../../../../data/models/resident_note.dart';
import '../../../../data/repositories/resident_note_repository.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import 'structured_data_forms.dart';

class QuickNoteBottomSheet extends StatefulWidget {
  final String residentId;
  final String residentName;
  final ResidentNote? existingNote;

  const QuickNoteBottomSheet({
    super.key,
    required this.residentId,
    required this.residentName,
    this.existingNote,
  });

  @override
  State<QuickNoteBottomSheet> createState() => _QuickNoteBottomSheetState();
}

class _QuickNoteBottomSheetState extends State<QuickNoteBottomSheet> {
  late TextEditingController _contentController;
  late TextEditingController _titleController;
  String _selectedCategory = 'general';
  bool _isSaving = false;
  bool _isConfidential = false;
  bool _useStructuredForm = false;
  Map<String, dynamic> _structuredData = {};

  bool _isLoadingUser = true;
  UserModel? _currentUser;
  List<String> _allowedServices = ['Medical', 'Social', 'Homelife', 'Other'];

  // Map of Service -> List of Data Types
  final Map<String, List<String>> _serviceCategories = {
    'Medical': [
      'vitals',
      'medication',
      'physical',
      'body_map',
      'complaint',
      'treatment',
      'dietary'
    ],
    'Psychology': [
      'behavior',
      'interaction',
      'counseling',
      'case_note',
      'goal'
    ],
    'Social': ['interaction', 'case_note', 'goal'],
    'Homelife': ['activity', 'hygiene', 'inventory', 'incident', 'movement'],
    'Other': ['general'],
  };

  String _selectedService = 'Medical';

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _titleController = TextEditingController();

    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!.title ?? '';
      _contentController.text = widget.existingNote!.content;
      _selectedCategory = widget.existingNote!.category;
      _isConfidential = widget.existingNote!.isConfidential;

      // Load structured data if present
      if (widget.existingNote!.structuredData != null &&
          widget.existingNote!.structuredData!.isNotEmpty) {
        _structuredData =
            Map<String, dynamic>.from(widget.existingNote!.structuredData!);
        _useStructuredForm = true;
      } else {
        // If old note didn't use it, don't force it unless category changes
        _useStructuredForm = false;
      }

      // Determine service from category
      _selectedService = _getServiceFromCategory(_selectedCategory);
    } else {
      _selectedCategory = _serviceCategories['Medical']!.first;
      // Default to structured if available for this category
      _useStructuredForm = StructuredDataForms.hasForm(_selectedCategory);
    }

    _fetchUserAndFilterServices();
  }

  Future<void> _fetchUserAndFilterServices() async {
    try {
      final user = await AuthRepository().getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
          _allowedServices = _determineAllowedServices(user);

          // If editing an existing note, refine the service selection now that we know the user
          if (widget.existingNote != null) {
            // Re-evaluate service based on user role to fix ambiguity (e.g. Social vs Psych)
            _selectedService = _getServiceFromCategory(_selectedCategory, user);
          }
          // If new note, ensure selected service is allowed
          else if (!_allowedServices.contains(_selectedService)) {
            _selectedService = _allowedServices.first;
            _selectedCategory = _serviceCategories[_selectedService]!.first;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  List<String> _determineAllowedServices(UserModel? user) {
    if (user == null) return ['Other']; // Safety fallback

    // Admins and Heads see all
    if (user.isSuperAdmin || user.isCenterHead || user.role == 'admin') {
      return ['Medical', 'Psychology', 'Social', 'Homelife', 'Other'];
    }

    // Role-based restrictions
    final role = user.role.toLowerCase();
    final unit = user.unit?.toLowerCase() ?? '';

    if (role.contains('medical') || unit == 'medical' || role == 'nurse') {
      return ['Medical'];
    }
    if (role.contains('psych') || unit == 'psychology') {
      return ['Psychology'];
    }
    if (role.contains('social') || unit == 'social') {
      return ['Social'];
    }
    if (role.contains('homelife') ||
        unit == 'homelife' ||
        role.contains('houseparent')) {
      return ['Homelife'];
    }

    // Default/Fallback
    return ['Other'];
  }

  // Updated logic: Determine service from category, prioritizing user's allowed services
  String _getServiceFromCategory(String category, [UserModel? user]) {
    // 1. Find all services that contain this category
    List<String> matchingServices = [];
    for (var entry in _serviceCategories.entries) {
      if (entry.value.contains(category)) {
        matchingServices.add(entry.key);
      }
    }

    if (matchingServices.isEmpty) return 'Other';

    // 2. If only one match, return it
    if (matchingServices.length == 1) return matchingServices.first;

    // 3. If multiple matches, check if user's Role/Unit aligns with one of them
    if (user != null) {
      final allowed = _determineAllowedServices(user);
      // Find the intersection
      final preferred = matchingServices
          .where((service) => allowed.contains(service))
          .toList();

      if (preferred.isNotEmpty) {
        return preferred.first; // Return the first one that matches user's role
      }
    }

    // 4. Fallback (return first found match, e.g. Psychology over Social if both have it)
    return matchingServices.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    // If using structured form, ensure we have content or data
    String contentToSave = _contentController.text.trim();

    if (_useStructuredForm) {
      // Generate summary string from structured data
      final summary = StructuredDataForms.generateSummary(
          _selectedCategory, _structuredData);
      if (summary.isNotEmpty) {
        contentToSave = summary;
      }
    }

    if (contentToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter content or fill the form')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Auto-Title Logic
      debugPrint('--- Auto-Title Debug ---');
      debugPrint('Use Structured Form: $_useStructuredForm');
      debugPrint('Structured Data Keys: ${_structuredData.keys.toList()}');
      debugPrint('Topic Value: ${_structuredData['topic']}');

      String? titleToSave = _titleController.text.trim();
      debugPrint('Initial Title Controller: "$titleToSave"');
      if (titleToSave.isEmpty) {
        // 1. Try to get from Structured Data 'topic'
        if (_useStructuredForm && _structuredData.containsKey('topic')) {
          final topic = _structuredData['topic']?.toString().trim();
          if (topic != null && topic.isNotEmpty) {
            titleToSave = topic;
          }
        }

        // 2. Fallback to Category Label if still empty
        if (titleToSave.isEmpty) {
          titleToSave = _getCategoryLabel(_selectedCategory);
        }
      }

      if (widget.existingNote != null) {
        await ResidentNoteRepository().updateNote(
          noteId: widget.existingNote!.id,
          title: titleToSave,
          content: contentToSave,
          category: _selectedCategory,
          isConfidential: _isConfidential,
          structuredData: _useStructuredForm ? _structuredData : null,
        );
      } else {
        await ResidentNoteRepository().createNote(
          residentId: widget.residentId,
          content: contentToSave,
          category: _selectedCategory,
          title: titleToSave,
          isConfidential: _isConfidential,
          structuredData: _useStructuredForm ? _structuredData : null,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingNote != null
                ? 'Note updated successfully'
                : 'Note saved successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        // Show error in a Dialog so it is visible
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Save Failed'),
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
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
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Move this note to the Recycle Bin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ResidentNoteRepository().archiveNote(widget.existingNote!.id);
        if (mounted) {
          Navigator.pop(context, true); // Return success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note moved to Recycle Bin')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorHandler.getUserFriendlyMessage(e)), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  String _getCategoryLabel(String key) {
    switch (key) {
      // Medical
      case 'vitals':
        return 'Vitals';
      case 'medication':
        return 'Meds';
      case 'physical':
        return 'Physical';
      case 'body_map':
        return 'Body Map';
      case 'complaint':
      case 'medical_complaint':
        return 'Complaint';
      case 'treatment':
        return 'Treatment';
      case 'dietary':
        return 'Dietary';

      // Social
      case 'behavior':
        return 'Behavior';
      case 'interaction':
        return 'Interaction';
      case 'counseling':
        return 'Counseling';
      case 'case_note':
        return 'Case Note';
      case 'goal':
        return 'Goal/Plan';

      // Homelife
      case 'activity':
        return 'Activity';
      case 'hygiene':
        return 'Hygiene';
      case 'inventory':
        return 'Inventory';
      case 'incident':
        return 'Incident';
      case 'movement':
        return 'Movement';

      case 'general':
      case 'other':
        return 'General';
      default:
        return key.toUpperCase();
    }
  }

  bool get _canEdit {
    if (widget.existingNote == null) return true; // Creating new note
    if (_currentUser == null) return false;
    // Only author can edit
    return widget.existingNote!.authorId == _currentUser!.id;
  }

  Color _getCategoryColor(String key) {
    // 1. Check if it belongs to the currently selected service (Contextual Color)
    if (_serviceCategories[_selectedService] != null &&
        _serviceCategories[_selectedService]!.contains(key)) {
      switch (_selectedService) {
        case 'Medical':
          return Colors.pink;
        case 'Psychology':
          return Colors.purple;
        case 'Social':
          return Colors.indigo;
        case 'Homelife':
          return Colors.teal;
        default:
          return Colors.blueGrey;
      }
    }

    // 2. Global Fallback
    if (_serviceCategories['Medical']!.contains(key)) return Colors.pink;
    if (_serviceCategories['Psychology']!.contains(key)) return Colors.purple;
    if (_serviceCategories['Social']!.contains(key)) return Colors.indigo;
    if (_serviceCategories['Homelife']!.contains(key)) return Colors.teal;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    // Filter services available to this user
    final availableServices = _serviceCategories.keys
        .where((key) => _allowedServices.contains(key))
        .toList();

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existingNote != null ? 'Edit Note' : 'New Note',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  if (widget.existingNote != null && _canEdit)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete Note',
                      onPressed: _deleteNote,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Info
          if (_currentUser != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Writing as: ${_currentUser!.displayNameWithTitle} (${_currentUser!.role})',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),

          // 1. Service & Category Selectors (Editable Mode)
          if (_canEdit) ...[
            if (availableServices.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availableServices.map((service) {
                    final isSelected = _selectedService == service;
                    Color activeColor;
                    switch (service) {
                      case 'Medical':
                        activeColor = Colors.pink;
                        break;
                      case 'Psychology':
                        activeColor = Colors.purple;
                        break;
                      case 'Social':
                        activeColor = Colors.indigo;
                        break;
                      case 'Homelife':
                        activeColor = Colors.teal;
                        break;
                      default:
                        activeColor = Colors.blueGrey;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(service),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedService = service;
                              // Default to first sub-category
                              _selectedCategory =
                                  _serviceCategories[service]!.first;
                            });
                          }
                        },
                        selectedColor: activeColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: Colors.grey.shade100,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],

            // 2. Data Type Selector
            Text(
              '$_selectedService Category',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: (_serviceCategories[_selectedService] ?? [])
                    .map((category) {
                  final isSelected = _selectedCategory == category;
                  final color = _getCategoryColor(category);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(
                        _getCategoryLabel(category),
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? color : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                            // If new category supports form, default to it
                            _useStructuredForm =
                                StructuredDataForms.hasForm(category);
                            // Clear structured data if category changes to avoid schema mismatch
                            if (widget.existingNote == null ||
                                widget.existingNote?.category != category) {
                              _structuredData = {};
                            }
                          });
                        }
                      },
                      backgroundColor: Colors.white,
                      selectedColor: color.withOpacity(0.1),
                      side: BorderSide(
                        color: isSelected ? color : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            // Read-Only Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: _getCategoryColor(_selectedCategory).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getCategoryColor(_selectedCategory).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 20, color: _getCategoryColor(_selectedCategory)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedService.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(_selectedCategory),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getCategoryLabel(_selectedCategory),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Switch to toggle form view should only show if editable or if there is actually data
          if (_canEdit && StructuredDataForms.hasForm(_selectedCategory))
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  'Use ${_getCategoryLabel(_selectedCategory)} Form',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                value: _useStructuredForm,
                onChanged: _canEdit
                    ? (val) => setState(() => _useStructuredForm = val)
                    : null,
              ),
            ),

          // Content Area (Form or Text)
          if (_useStructuredForm &&
              StructuredDataForms.hasForm(_selectedCategory))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: AbsorbPointer(
                absorbing: !_canEdit,
                child: StructuredDataForms.buildForm(
                  category: _selectedCategory,
                  data: _structuredData,
                  onChanged: (key, value) {
                    setState(() {
                      _structuredData[key] = value;
                    });
                  },
                ),
              ),
            )
          else
            TextField(
              controller: _contentController,
              enabled: _canEdit,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note Content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

          // Confidential Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title:
                const Text('Confidential Note', style: TextStyle(fontSize: 14)),
            subtitle: const Text(
              'Only visible to you and admins',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            value: _isConfidential,
            activeThumbColor: Colors.red,
            onChanged: _canEdit
                ? (val) => setState(() => _isConfidential = val)
                : null,
          ),

          const SizedBox(height: 16),

          // Save Button
          if (_canEdit)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveNote,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.existingNote != null
                        ? 'Update Note'
                        : 'Save Note'),
              ),
            ),
        ],
      ),
    );
  }
}
