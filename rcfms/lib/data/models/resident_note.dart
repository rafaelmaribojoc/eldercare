import 'package:equatable/equatable.dart';

class ResidentNote extends Equatable {
  final String id;
  final String residentId;
  final String? authorId;
  final String content;
  final String category;
  final List<String> mediaUrls;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // New field
  final String? title;
  final bool isConfidential;
  final bool isFavorite;
  final Map<String, dynamic>? structuredData;

  // Optional: details about the author if we join tables later
  final String? authorName;

  const ResidentNote({
    required this.id,
    required this.residentId,
    this.authorId,
    required this.content,
    required this.category,
    this.mediaUrls = const [],
    this.isArchived = false,
    this.isConfidential = false,
    this.isFavorite = false,
    this.structuredData,
    required this.createdAt,
    this.updatedAt,
    this.title,
    this.authorName,
  });

  factory ResidentNote.fromJson(Map<String, dynamic> json) {
    String? extractAuthorName() {
      if (json['profiles'] != null) {
        if (json['profiles'] is Map) {
          return json['profiles']['full_name'] as String?;
        }
      }
      return null;
    }

    return ResidentNote(
      id: json['id'] as String,
      residentId: json['resident_id'] as String,
      authorId: json['author_id'] as String?,
      content: json['content'] as String,
      category: json['category'] as String,
      mediaUrls: (json['media_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isArchived: json['is_archived'] as bool? ?? false,
      isConfidential: json['is_confidential'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      structuredData: json['structured_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      title: json['title'] as String?,
      authorName: extractAuthorName(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resident_id': residentId,
      'author_id': authorId,
      'content': content,
      'category': category,
      'media_urls': mediaUrls,
      'is_archived': isArchived,
      'is_confidential': isConfidential,
      'is_favorite': isFavorite,
      'structured_data': structuredData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'title': title,
    };
  }

  ResidentNote copyWith({
    String? id,
    String? residentId,
    String? authorId,
    String? content,
    String? category,
    List<String>? mediaUrls,
    bool? isArchived,
    bool? isConfidential,
    bool? isFavorite,
    Map<String, dynamic>? structuredData,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    String? authorName,
  }) {
    return ResidentNote(
      id: id ?? this.id,
      residentId: residentId ?? this.residentId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      category: category ?? this.category,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      isArchived: isArchived ?? this.isArchived,
      isConfidential: isConfidential ?? this.isConfidential,
      isFavorite: isFavorite ?? this.isFavorite,
      structuredData: structuredData ?? this.structuredData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      authorName: authorName ?? this.authorName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        residentId,
        authorId,
        content,
        category,
        mediaUrls,
        isArchived,
        isConfidential,
        isFavorite,
        structuredData,
        createdAt,
        updatedAt,
        title,
        authorName,
      ];
}
