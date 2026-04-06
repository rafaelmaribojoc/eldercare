import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum NoteFilterType { all, locked, favorites, trash, folder }

class NoteFilter {
  final NoteFilterType type;
  final String? folderName;

  const NoteFilter({required this.type, this.folderName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteFilter &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          folderName == other.folderName;

  @override
  int get hashCode => type.hashCode ^ folderName.hashCode;
}

class ModernNotesSidebar extends StatelessWidget {
  final NoteFilter currentFilter;
  final Function(NoteFilter) onFilterChanged;

  const ModernNotesSidebar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.notes, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Resident Notes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit', // Uses brand font
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildNavItem(
                  icon: Icons.note_alt_outlined,
                  label: 'All notes',
                  filter: const NoteFilter(type: NoteFilterType.all),
                  count: null, // TODO: Add counts
                ),
                _buildNavItem(
                  icon: Icons.star_outline,
                  label: 'Favorites',
                  filter: const NoteFilter(type: NoteFilterType.favorites),
                ),
                _buildNavItem(
                  icon: Icons.lock_outline,
                  label: 'Locked notes',
                  filter: const NoteFilter(type: NoteFilterType.locked),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'FOLDERS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _buildFolderItem('Medical', Colors.pink),
                _buildFolderItem('Social', Colors.blue),
                _buildFolderItem('Psychology', Colors.indigo),
                _buildFolderItem('Homelife', Colors.teal),
                _buildFolderItem('Other', Colors.grey),
                const SizedBox(height: 20),
                const Divider(),
                _buildNavItem(
                  icon: Icons.delete_outline,
                  label: 'Recycle bin',
                  filter: const NoteFilter(type: NoteFilterType.trash),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required NoteFilter filter,
    int? count,
  }) {
    final bool isSelected = currentFilter == filter;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : Colors.grey.shade700,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : Colors.black87,
        ),
      ),
      trailing: count != null
          ? Text(
              count.toString(),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            )
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: () => onFilterChanged(filter),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
    );
  }

  Widget _buildFolderItem(String folderName, Color color) {
    final filter =
        NoteFilter(type: NoteFilterType.folder, folderName: folderName);
    final bool isSelected = currentFilter == filter;

    return ListTile(
      leading: Icon(
        Icons.folder,
        color: isSelected ? color : color.withOpacity(0.7),
      ),
      title: Text(
        folderName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.black : Colors.black87,
        ),
      ),
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selected: isSelected,
      selectedTileColor: color.withOpacity(0.1),
      onTap: () => onFilterChanged(filter),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
