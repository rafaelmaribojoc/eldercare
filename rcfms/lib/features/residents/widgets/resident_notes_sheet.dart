import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/resident_note.dart';
import '../../../data/repositories/resident_note_repository.dart';
import 'quick_note_bottom_sheet.dart'; // Import for functionality inside screen

class ResidentNotesSheet extends StatefulWidget {
  final String residentId;
  final String residentName;

  const ResidentNotesSheet({
    super.key,
    required this.residentId,
    required this.residentName,
  });

  @override
  State<ResidentNotesSheet> createState() => _ResidentNotesSheetState();
}

class _ResidentNotesSheetState extends State<ResidentNotesSheet> {
  late Future<List<ResidentNote>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  void _refreshNotes() {
    setState(() {
      _notesFuture =
          ResidentNoteRepository().getNotesByResident(widget.residentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(LucideIcons.notebookText, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Notes History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.circlePlus,
                      color: AppColors.primary, size: 28),
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => QuickNoteBottomSheet(
                        residentId: widget.residentId,
                        residentName: widget.residentName,
                      ),
                    );
                    _refreshNotes();
                  },
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // List
          Expanded(
            child: FutureBuilder<List<ResidentNote>>(
              future: _notesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final notes = snapshot.data ?? [];

                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.notebookText,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No notes recorded yet',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _buildNoteCard(note);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(ResidentNote note) {
    // Helper to get category properties
    (String label, Color color, IconData icon) getCategoryProps(String cat) {
      switch (cat) {
        // --- MEDICAL (Pink/Red) ---
        case 'vitals':
          return ('Vitals', Colors.pink, LucideIcons.heartPulse);
        case 'medication':
          return ('Meds', Colors.pink, LucideIcons.pill);
        case 'physical':
          return ('Physical', Colors.pink, LucideIcons.accessibility);
        case 'body_map':
          return ('Body Map', Colors.pink, LucideIcons.userRoundX);
        case 'complaint':
        case 'medical_complaint':
          return ('Complaint', Colors.pink, LucideIcons.thermometer);
        case 'treatment':
          return ('Treatment', Colors.pink, LucideIcons.heartPulse);
        case 'dietary':
          return ('Dietary', Colors.pink, LucideIcons.utensils);

        // --- SOCIAL (Indigo/Blue) ---
        case 'behavior':
          return ('Behavior', Colors.indigo, LucideIcons.brain);
        case 'interaction':
          return ('Interaction', Colors.indigo, LucideIcons.users);
        case 'counseling':
          return ('Counseling', Colors.indigo, LucideIcons.mic);
        case 'case_note':
          return ('Case Note', Colors.indigo, LucideIcons.folderOpen);
        case 'goal':
          return ('Goal/Plan', Colors.indigo, LucideIcons.flag);

        // --- HOMELIFE (Teal/Green) ---
        case 'activity':
          return ('Activity', Colors.teal, LucideIcons.ticket);
        case 'hygiene':
          return ('Hygiene', Colors.teal, LucideIcons.hand);
        case 'inventory':
          return ('Inventory', Colors.teal, LucideIcons.packageOpen);
        case 'incident':
          return ('Incident', Colors.teal, LucideIcons.triangleAlert);
        case 'movement':
          return ('Movement', Colors.teal, LucideIcons.footprints);

        // --- LEGACY / OTHER ---
        case 'general':
        case 'other':
          return ('General', Colors.blueGrey, LucideIcons.notebook);

        case 'medical':
          return ('Medical', Colors.pink, LucideIcons.stethoscope);
        case 'social':
          return ('Social', Colors.indigo, LucideIcons.users);
        case 'homelife':
          return ('Homelife', Colors.teal, LucideIcons.house);
        case 'behavioral':
          return ('Behavioral', Colors.indigo, LucideIcons.brain);

        default:
          return (cat.toUpperCase(), Colors.grey, LucideIcons.circle);
      }
    }

    final props = getCategoryProps(note.category);
    final label = props.$1;
    final color = props.$2;
    final icon = props.$3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          // Open edit sheet
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
          _refreshNotes();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (note.isConfidential) ...[
                    const Icon(LucideIcons.lockKeyhole,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (note.authorName != null)
                        Text(
                          note.authorName!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      Text(
                        DateFormat('MMM dd, yyyy h:mm a')
                            .format(note.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(LucideIcons.ellipsisVertical, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Note'),
                            content: const Text(
                                'Are you sure you want to delete this note?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            // Use archive as "soft delete" or delete based on preference.
                            // The repository has both. Using archive for safety unless specified.
                            // User asked for "crud", usually implies delete. I'll use archiveNote
                            // as it sets is_archived=true which hides it from the default list.
                            await ResidentNoteRepository().archiveNote(note.id);
                            _refreshNotes();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      } else if (value == 'edit') {
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
                        _refreshNotes();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(LucideIcons.pencil, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(LucideIcons.trash2,
                                size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (note.title != null && note.title!.isNotEmpty) ...[
                Text(
                  note.title!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                note.content,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
