import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/resident_note.dart';

class NoteCard extends StatelessWidget {
  final ResidentNote note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle; // New callback
  final bool isSelected;
  final bool selectionMode;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
    this.onFavoriteToggle, // Accept callback
    this.isSelected = false,
    this.selectionMode = false,
  });

  // Helper to get category colors
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
      case 'vitals':
      case 'medication':
      case 'physical':
      case 'treatment':
        return Colors.pink.shade50;
      case 'psychology':
      case 'behavior':
      case 'counseling':
        return Colors.indigo.shade50;
      case 'social':
      case 'interaction':
      case 'case_note':
        return Colors.blue.shade50;
      case 'homelife':
      case 'activity':
      case 'hygiene':
        return Colors.teal.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getCategoryAccent(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
      case 'vitals':
        return Colors.pink;
      case 'psychology':
      case 'behavior':
        return Colors.indigo;
      case 'social':
        return Colors.blue;
      case 'homelife':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Keep valid vars)
    final bgColor = _getCategoryColor(note
        .category); // Helper needs to be in class or mixin, assuming it's there
    final accentColor = _getCategoryAccent(note.category);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: note.isConfidential ? Colors.grey.shade200 : bgColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          // ... shadow
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Title & Icons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align top
              children: [
                Expanded(
                  child: Text(
                    note.title ?? 'No Title',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: note.isConfidential ? Colors.grey : Colors.black87,
                      decoration:
                          note.isArchived ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Interactive Favorite Star
                if (!note.isArchived) // Don't allow favoriting trash
                  GestureDetector(
                    onTap: onFavoriteToggle, // Toggle action
                    behavior: HitTestBehavior.opaque, // Ensure easy tap
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Icon(
                        note.isFavorite ? LucideIcons.star : LucideIcons.star,
                        size: 20,
                        color: note.isFavorite
                            ? Colors.amber
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                if (note.isConfidential)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(LucideIcons.lockKeyhole,
                        size: 16, color: Colors.grey),
                  ),
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      isSelected ? LucideIcons.circleCheck : LucideIcons.circle,
                      color: isSelected ? AppColors.primary : Colors.grey,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Content Preview (or Locked User feedback)
            if (note.isConfidential)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: const Column(
                  children: [
                    Icon(LucideIcons.lockKeyhole, size: 32, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Confidential',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else
              Text(
                note.content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black54,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 16),

            // Footer: Date & Category Tag
            // Footer: Date & Category Tag
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                Text(
                  dateFormat.format(note.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    note.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
