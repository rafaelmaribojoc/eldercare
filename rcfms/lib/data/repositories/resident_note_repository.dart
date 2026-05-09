import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resident_note.dart';

class ResidentNoteRepository {
  final SupabaseClient _supabase;

  ResidentNoteRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  Future<List<ResidentNote>> getNotesByResident(
    String residentId, {
    bool includeArchived = false,
  }) async {
    try {
      // 1. Fetch Notes
      if (residentId.isEmpty) return [];

      var query = _supabase
          .from('resident_notes')
          .select()
          .eq('resident_id', residentId);

      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }

      final response = await query.order('created_at', ascending: false);

      final notes = (response as List<dynamic>)
          .map((e) => ResidentNote.fromJson(e))
          .toList();

      // 2. Fetch Personal Favorites for current user
      final userId = _supabase.auth.currentUser?.id;
      Set<String> favoritedIds = {};

      if (userId != null) {
        try {
          final favoritesResponse = await _supabase
              .from('user_favorite_notes') // This might fail if table missing
              .select('note_id')
              .eq('user_id', userId);

          favoritedIds = (favoritesResponse as List)
              .map((e) => e['note_id'] as String)
              .toSet();
        } catch (e) {
          // Table likely doesn't exist yet or other error.
          // Fail gracefully so we still show the notes.
          print('Warning: Could not fetch favorites (Table missing?): $e');
        }
      }

      // 3. Extract unique Author IDs
      final authorIds = notes
          .map((n) => n.authorId)
          .where((id) => id != null)
          .toSet()
          .toList();

      Map<String, String> profilesMap = {};
      if (authorIds.isNotEmpty) {
        final profilesResponse = await _supabase
            .from('profiles')
            .select('id, full_name')
            .filter('id', 'in', authorIds);

        profilesMap = {
          for (var p in (profilesResponse as List<dynamic>))
            p['id'] as String: p['full_name'] as String,
        };
      }

      // 4. Attach Author Name & Favorite Status
      return notes.map((note) {
        // Determine personalized favorite status
        final isMeFavorite = favoritedIds.contains(note.id);

        // We use copyWith to populate these transient fields
        // Note: isFavorite in database is now ignored/deprecated.
        // We overwrite it with the personalized value.
        return note.copyWith(
          authorName: note.authorId != null ? profilesMap[note.authorId] : null,
          isFavorite: isMeFavorite,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch notes: $e');
    }
  }

  Future<void> createNote({
    required String residentId,
    required String content,
    required String category,
    String? title,
    bool isConfidential = false,
    bool isFavorite = false,
    Map<String, dynamic>? structuredData,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _supabase.from('resident_notes').insert({
        'resident_id': residentId,
        'author_id': user.id,
        'content': content,
        'category': category,
        'title': title,
        'is_confidential': isConfidential,
        // 'is_favorite': isFavorite, // Temporarily disabled to fix PGRST204 error
        'structured_data': structuredData,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create note: $e');
    }
  }

  Future<void> archiveNote(String noteId) async {
    try {
      await _supabase.from('resident_notes').update({
        'is_archived': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', noteId);
    } catch (e) {
      throw Exception('Failed to archive note: $e');
    }
  }

  Future<void> restoreNote(String noteId) async {
    try {
      await _supabase.from('resident_notes').update({
        'is_archived': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', noteId);
    } catch (e) {
      throw Exception('Failed to restore note: $e');
    }
  }

  Future<void> toggleFavorite(String noteId, bool isFavorite) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to favorite');

    try {
      if (isFavorite) {
        // Add to favorites
        await _supabase.from('user_favorite_notes').upsert({
          'user_id': user.id,
          'note_id': noteId,
        });
      } else {
        // Remove from favorites
        await _supabase.from('user_favorite_notes').delete().match({
          'user_id': user.id,
          'note_id': noteId,
        });
      }
    } catch (e) {
      throw Exception('Failed to update favorite: $e');
    }
  }

  Future<void> updateNote({
    required String noteId,
    String? title,
    String? content,
    String? category,
    bool? isConfidential,
    bool? isFavorite,
    Map<String, dynamic>? structuredData,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (title != null) updates['title'] = title;
      if (content != null) updates['content'] = content;
      if (category != null) updates['category'] = category;
      if (isConfidential != null) updates['is_confidential'] = isConfidential;
      if (isFavorite != null) updates['is_favorite'] = isFavorite;
      if (structuredData != null) updates['structured_data'] = structuredData;

      await _supabase.from('resident_notes').update(updates).eq('id', noteId);
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _supabase.from('resident_notes').delete().eq('id', noteId);
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }
}
