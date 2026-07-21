import 'shelf_model.dart';
import 'shelf_serializer.dart';

enum MergeStrategy {
  skipDuplicates,
  overwrite,
  mergeBookmarks,
}

/// Service handling bookshelf import, export, and merge conflict resolution.
class ShelfImportExportService {
  final Map<String, BookmarkedNovel> _localBookshelf = {};

  List<BookmarkedNovel> get currentShelf => _localBookshelf.values.toList();

  void addLocalNovel(BookmarkedNovel novel) {
    _localBookshelf[novel.novelId] = novel;
  }

  /// Exports current local library to an `.arcshelf` JSON string.
  String exportShelf(String shelfName, {String? description}) {
    final manifest = ShelfManifest(
      shelfName: shelfName,
      description: description,
      novels: _localBookshelf.values.toList(),
    );
    return ShelfSerializer.serialize(manifest);
  }

  /// Imports an `.arcshelf` JSON string using the specified [MergeStrategy].
  /// Returns the count of newly added or updated novels.
  int importShelf(String jsonString, {MergeStrategy strategy = MergeStrategy.mergeBookmarks}) {
    final manifest = ShelfSerializer.deserialize(jsonString);
    int modifiedCount = 0;

    for (final importedNovel in manifest.novels) {
      final existing = _localBookshelf[importedNovel.novelId];

      if (existing == null) {
        _localBookshelf[importedNovel.novelId] = importedNovel;
        modifiedCount++;
      } else {
        switch (strategy) {
          case MergeStrategy.skipDuplicates:
            // Keep existing entry unchanged
            break;
          case MergeStrategy.overwrite:
            _localBookshelf[importedNovel.novelId] = importedNovel;
            modifiedCount++;
            break;
          case MergeStrategy.mergeBookmarks:
            // Keep higher chapter progress and merge unique tags
            final mergedChapter = importedNovel.bookmarkedChapter > existing.bookmarkedChapter
                ? importedNovel.bookmarkedChapter
                : existing.bookmarkedChapter;

            final mergedTags = {...existing.tags, ...importedNovel.tags}.toList();

            _localBookshelf[importedNovel.novelId] = BookmarkedNovel(
              novelId: existing.novelId,
              title: existing.title,
              author: existing.author,
              coverUrl: existing.coverUrl ?? importedNovel.coverUrl,
              sourceId: existing.sourceId,
              sourceUrl: existing.sourceUrl,
              tags: mergedTags,
              bookmarkedChapter: mergedChapter,
              lastReadChapterTitle: importedNovel.bookmarkedChapter > existing.bookmarkedChapter
                  ? importedNovel.lastReadChapterTitle
                  : existing.lastReadChapterTitle,
            );
            modifiedCount++;
            break;
        }
      }
    }

    return modifiedCount;
  }
}
