/// Chapter entry for EPUB export.
class EpubChapterInput {
  final String id;
  final String title;
  final String rawBody;

  EpubChapterInput({
    required this.id,
    required this.title,
    required this.rawBody,
  });
}

/// Metadata container for an EPUB novel export.
class EpubMetadata {
  final String title;
  final String author;
  final String language;
  final String identifier;
  final String? publisher;
  final String? description;
  final List<int>? coverImageBytes;
  final String coverImageMimeType;
  final List<EpubChapterInput> chapters;

  EpubMetadata({
    required this.title,
    required this.author,
    this.language = 'en',
    required this.identifier,
    this.publisher = 'ArcReader',
    this.description,
    this.coverImageBytes,
    this.coverImageMimeType = 'image/jpeg',
    required this.chapters,
  });
}
