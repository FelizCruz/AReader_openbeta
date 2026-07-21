/// Represents a bookmarked novel item within a shared shelf package.
class BookmarkedNovel {
  final String novelId;
  final String title;
  final String author;
  final String? coverUrl;
  final String sourceId;
  final String sourceUrl;
  final List<String> tags;
  final int bookmarkedChapter;
  final String? lastReadChapterTitle;
  final Map<String, dynamic>? customMetadata;

  BookmarkedNovel({
    required this.novelId,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.sourceId,
    required this.sourceUrl,
    this.tags = const [],
    this.bookmarkedChapter = 1,
    this.lastReadChapterTitle,
    this.customMetadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'novelId': novelId,
      'title': title,
      'author': author,
      if (coverUrl != null) 'coverUrl': coverUrl,
      'sourceId': sourceId,
      'sourceUrl': sourceUrl,
      'tags': tags,
      'bookmarkedChapter': bookmarkedChapter,
      if (lastReadChapterTitle != null) 'lastReadChapterTitle': lastReadChapterTitle,
      if (customMetadata != null) 'customMetadata': customMetadata,
    };
  }

  factory BookmarkedNovel.fromJson(Map<String, dynamic> json) {
    return BookmarkedNovel(
      novelId: json['novelId'] as String? ?? json['title'].toString().hashCode.toString(),
      title: json['title'] as String,
      author: json['author'] as String? ?? 'Unknown',
      coverUrl: json['coverUrl'] as String?,
      sourceId: json['sourceId'] as String? ?? 'custom_source',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      bookmarkedChapter: json['bookmarkedChapter'] as int? ?? 1,
      lastReadChapterTitle: json['lastReadChapterTitle'] as String?,
      customMetadata: json['customMetadata'] as Map<String, dynamic>?,
    );
  }
}

/// Represents the top-level `.arcshelf` manifest wrapper.
class ShelfManifest {
  final String version;
  final String shelfName;
  final String? description;
  final DateTime exportedAt;
  final List<BookmarkedNovel> novels;

  ShelfManifest({
    this.version = '1.0',
    required this.shelfName,
    this.description,
    DateTime? exportedAt,
    required this.novels,
  }) : exportedAt = exportedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'shelfName': shelfName,
      if (description != null) 'description': description,
      'exportedAt': exportedAt.toIso8601String(),
      'novels': novels.map((n) => n.toJson()).toList(),
    };
  }

  factory ShelfManifest.fromJson(Map<String, dynamic> json) {
    return ShelfManifest(
      version: json['version'] as String? ?? '1.0',
      shelfName: json['shelfName'] as String? ?? 'Imported Shelf',
      description: json['description'] as String?,
      exportedAt: json['exportedAt'] != null
          ? DateTime.parse(json['exportedAt'] as String)
          : DateTime.now(),
      novels: (json['novels'] as List<dynamic>?)
              ?.map((e) => BookmarkedNovel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
