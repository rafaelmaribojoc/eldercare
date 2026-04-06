import 'package:flutter_test/flutter_test.dart';

void main() {
  // Logic extracted from QuickNoteBottomSheet
  final Map<String, List<String>> serviceCategories = {
    'Medical': [
      'vitals',
      'medication',
      'physical',
      'body_map',
      'complaint',
      'treatment',
      'dietary'
    ],
    'Social': ['behavior', 'interaction', 'counseling', 'case_note', 'goal'],
    'Homelife': ['activity', 'hygiene', 'inventory', 'incident', 'movement'],
    'Other': ['general'],
  };

  String getServiceFromCategory(String category) {
    for (var entry in serviceCategories.entries) {
      if (entry.value.contains(category)) {
        return entry.key;
      }
    }
    return 'Other';
  }

  test('Medical categories map correctly', () {
    expect(getServiceFromCategory('vitals'), 'Medical');
    expect(getServiceFromCategory('medication'), 'Medical');
    expect(getServiceFromCategory('body_map'), 'Medical');
  });

  test('Social categories map correctly', () {
    expect(getServiceFromCategory('behavior'), 'Social');
    expect(getServiceFromCategory('counseling'), 'Social');
  });

  test('Homelife categories map correctly', () {
    expect(getServiceFromCategory('activity'), 'Homelife');
    expect(getServiceFromCategory('inventory'), 'Homelife');
  });

  test('Unknown categories map to Other', () {
    expect(getServiceFromCategory('unknown_xyz'), 'Other');
    expect(getServiceFromCategory('general'), 'Other');
  });
}
