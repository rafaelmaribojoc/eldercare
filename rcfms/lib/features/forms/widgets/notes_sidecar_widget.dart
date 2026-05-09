import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/resident_note.dart';
import '../../../data/repositories/resident_note_repository.dart';

class NotesSidecarWidget extends StatefulWidget {
  final String residentId;

  const NotesSidecarWidget({super.key, required this.residentId});

  @override
  State<NotesSidecarWidget> createState() => _NotesSidecarWidgetState();
}

class _NotesSidecarWidgetState extends State<NotesSidecarWidget> {
  late Future<List<ResidentNote>> _notesFuture;
  String _filter = 'all'; // all, medical, behavior, etc

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  void _refreshNotes() {
    setState(() {
      final id = widget.residentId.trim();
      // Basic UUID check (length 36, or at least not empty)
      if (id.isEmpty || id.length < 10) {
        _notesFuture = Future.value([]);
      } else {
        _notesFuture = ResidentNoteRepository().getNotesByResident(id);
      }
    });
  }

  final Map<String, List<String>> _serviceCategories = {
    'Medical': [
      'vitals',
      'medication',
      'physical',
      'body_map',
      'complaint',
      'medical_complaint',
      'treatment',
      'dietary',
      'medical', // Legacy
    ],
    'Social': [
      'behavior',
      'interaction',
      'counseling',
      'case_note',
      'goal',
      'social', // Legacy
      'behavioral', // Legacy
    ],
    'Homelife': [
      'activity',
      'hygiene',
      'inventory',
      'incident',
      'movement',
      'homelife', // Legacy
    ],
    'Other': ['general', 'other'],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(-2, 0),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.bookOpen,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Reference Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      onPressed: _refreshNotes,
                      tooltip: 'Refresh',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Copy findings from daily rounds.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Chips Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['all', 'Medical', 'Social', 'Homelife', 'Other'].map((
                cat,
              ) {
                final isSelected = _filter == cat;
                Color chipColor = AppColors.primary;
                if (cat == 'Medical') chipColor = Colors.pink;
                if (cat == 'Social') chipColor = Colors.indigo;
                if (cat == 'Homelife') chipColor = Colors.teal;
                if (cat == 'Other') chipColor = Colors.blueGrey;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      cat.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white : chipColor,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _filter = cat);
                    },
                    selectedColor: chipColor,
                    backgroundColor: chipColor.withOpacity(0.05),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : chipColor.withOpacity(0.2),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: FutureBuilder<List<ResidentNote>>(
              future: _notesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  );
                }

                final allNotes = snapshot.data ?? [];

                final notes = _filter == 'all'
                    ? allNotes
                    : allNotes.where((n) {
                        return _serviceCategories[_filter]?.contains(
                              n.category,
                            ) ??
                            false;
                      }).toList();

                if (notes.isEmpty) {
                  return Center(
                    child: Text(
                      'No notes found.',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _buildNoteItem(note);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(ResidentNote note) {
    // Mini helper for desktop sidecar
    (String, Color) getProps(String cat) {
      switch (cat) {
        // --- MEDICAL (Pink/Red) ---
        case 'vitals':
          return ('VITALS', Colors.pink);
        case 'medication':
          return ('MEDS', Colors.pink);
        case 'physical':
          return ('PHYSICAL', Colors.pink);
        case 'body_map':
          return ('BODY MAP', Colors.pink);
        case 'complaint':
        case 'medical_complaint':
          return ('COMPLAINT', Colors.pink);
        case 'treatment':
          return ('TREATMENT', Colors.pink);
        case 'dietary':
          return ('DIETARY', Colors.pink);

        // --- SOCIAL (Indigo/Blue) ---
        case 'behavior':
          return ('BEHAVIOR', Colors.indigo);
        case 'interaction':
          return ('INTERACTION', Colors.indigo);
        case 'counseling':
          return ('COUNSELING', Colors.indigo);
        case 'case_note':
          return ('CASE NOTE', Colors.indigo);
        case 'goal':
          return ('GOAL', Colors.indigo);

        // --- HOMELIFE (Teal/Green) ---
        case 'activity':
          return ('ACTIVITY', Colors.teal);
        case 'hygiene':
          return ('HYGIENE', Colors.teal);
        case 'inventory':
          return ('INVENTORY', Colors.teal);
        case 'incident':
          return ('INCIDENT', Colors.teal);
        case 'movement':
          return ('MOVEMENT', Colors.teal);

        // --- LEGACY ---
        case 'medical':
          return ('MEDICAL', Colors.pink);
        case 'social':
          return ('SOCIAL', Colors.indigo);
        case 'homelife':
          return ('HOMELIFE', Colors.teal);
        case 'behavioral':
          return ('BEHAVIORAL', Colors.indigo);

        default:
          return (cat.toUpperCase(), Colors.blueGrey);
      }
    }

    final props = getProps(note.category);
    final label = props.$1;
    final color = props.$2;
    // Icon unused in sidecar minimal view, or can enable it.
    // I'll keep text label for density, maybe add icon?
    // The previous code used text label in colored box.

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MM/dd h:mm a').format(note.createdAt),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (note.title != null && note.title!.isNotEmpty) ...[
            Text(
              note.title!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            note.content,
            style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: note.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              },
              icon: const Icon(LucideIcons.copy, size: 14),
              label: const Text('Copy'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 11),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
