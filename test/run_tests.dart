import 'package:arcreader_custom/download/download_queue_manager.dart';
import 'package:arcreader_custom/download/download_status.dart';
import 'package:arcreader_custom/download/download_task.dart';
import 'package:arcreader_custom/epub/epub_builders.dart';
import 'package:arcreader_custom/epub/epub_metadata.dart';
import 'package:arcreader_custom/epub/epub_packager.dart';
import 'package:arcreader_custom/epub/xhtml_sanitizer.dart';
import 'package:arcreader_custom/shelf/shelf_import_export_service.dart';
import 'package:arcreader_custom/shelf/shelf_model.dart';
import 'package:arcreader_custom/shelf/shelf_serializer.dart';
import 'package:arcreader_custom/theme/eink_palette.dart';
import 'package:arcreader_custom/theme/eink_theme_controller.dart';

void main() async {
  print('=== RUNNING DEVELOPER FEATURE SUITE TESTS ===\n');

  // Test 1: Download Queue Manager
  print('[1/4] Testing Download Queue System...');
  int completedCount = 0;
  final queueManager = DownloadQueueManager(
    maxConcurrent: 2,
    fetcher: (task) async {
      await Future.delayed(const Duration(milliseconds: 50));
      return 'Chapter content for ${task.chapterTitle}';
    },
    onTaskCompleted: (task, content) async {
      completedCount++;
    },
  );

  final tasks = List.generate(
    5,
    (i) => DownloadTask(
      taskId: 'task_$i',
      novelId: 'novel_1',
      chapterId: 'chap_$i',
      chapterTitle: 'Chapter $i',
      downloadUrl: 'https://example.com/chap_$i',
    ),
  );

  queueManager.enqueueBatch(tasks);

  // Wait for queue processing
  await Future.delayed(const Duration(milliseconds: 500));
  assert(completedCount == 5, 'Expected 5 completed downloads, got $completedCount');
  print('  ✓ Download Queue Manager: 5/5 tasks completed successfully with throttling.');

  // Test 2: EPUB Exporter Engine
  print('\n[2/4] Testing Lossless EPUB 3.0 Exporter Engine...');
  final sanitized = XhtmlSanitizer.sanitizeChapterBody('Line 1 & Line 2\n<br>\nUnclosed image: <img src="test.jpg">');
  assert(sanitized.contains('&amp;'), 'Ampersand escaping failed');
  assert(sanitized.contains('<br/>'), 'Self-closing br tag failed');
  assert(sanitized.contains('<img src="test.jpg"/>'), 'Self-closing img tag failed');

  final metadata = EpubMetadata(
    title: 'Test Novel & Story',
    author: 'Test Author',
    identifier: 'urn:uuid:12345678-1234-1234-1234-123456789abc',
    chapters: [
      EpubChapterInput(id: 'c1', title: 'Chapter 1', rawBody: 'Once upon a time & far away...'),
    ],
  );

  final entries = EpubPackager.createEpubEntries(metadata);
  assert(entries.first.path == 'mimetype' && entries.first.storeOnly == true, 'Mimetype must be uncompressed & first');
  assert(entries.any((e) => e.path == 'OEBPS/content.opf'), 'Manifest missing content.opf');
  assert(entries.any((e) => e.path == 'OEBPS/nav.xhtml'), 'Manifest missing nav.xhtml');
  assert(entries.any((e) => e.path == 'OEBPS/toc.ncx'), 'Manifest missing toc.ncx');
  print('  ✓ EPUB 3.0 Exporter Engine: Packaging and XHTML sanitization verified.');

  // Test 3: Inverted E-Ink Theme Engine
  print('\n[3/4] Testing Inverted E-Ink Theme Engine...');
  final themeController = EInkThemeController();
  themeController.setMode(EInkMode.invertedNight);
  assert(themeController.backgroundColor == EInkPalette.invertedBackground, 'Inverted background should be pure black');
  assert(themeController.textColor == EInkPalette.invertedForeground, 'Inverted text should be pure white');
  assert(themeController.suppressAnimations == true, 'Animations should be suppressed on E-Ink mode');
  assert(themeController.animationDuration == Duration.zero, 'Animation duration should be zero');
  print('  ✓ Inverted E-Ink Theme Engine: Zero-ghosting palette & animation suppression verified.');

  // Test 4: Shelf Sharing System
  print('\n[4/4] Testing Shelf Sharing System (.arcshelf)...');
  final shelfService = ShelfImportExportService();
  shelfService.addLocalNovel(BookmarkedNovel(
    novelId: 'n1',
    title: 'Immortal Journey',
    author: 'Xianxia Master',
    sourceId: 'source_a',
    sourceUrl: 'https://example.com/n1',
    tags: ['Xianxia', 'Cultivation'],
    bookmarkedChapter: 10,
  ));

  final exportedJson = shelfService.exportShelf('Main Favorites');
  assert(exportedJson.contains('"shelfName": "Main Favorites"'), 'Exported JSON missing shelfName');
  assert(exportedJson.contains('"title": "Immortal Journey"'), 'Exported JSON missing novel title');

  // Import into secondary service
  final shelfService2 = ShelfImportExportService();
  shelfService2.addLocalNovel(BookmarkedNovel(
    novelId: 'n1',
    title: 'Immortal Journey',
    author: 'Xianxia Master',
    sourceId: 'source_a',
    sourceUrl: 'https://example.com/n1',
    tags: ['Xianxia'],
    bookmarkedChapter: 25, // Higher chapter locally
  ));

  final importedCount = shelfService2.importShelf(exportedJson, strategy: MergeStrategy.mergeBookmarks);
  assert(importedCount == 1, 'Expected 1 updated entry');
  final mergedNovel = shelfService2.currentShelf.firstWhere((n) => n.novelId == 'n1');
  assert(mergedNovel.bookmarkedChapter == 25, 'Merge strategy failed to retain higher chapter');
  assert(mergedNovel.tags.contains('Cultivation'), 'Merge strategy failed to merge tags');
  print('  ✓ Shelf Sharing System: Serialization, deserialization, & bookmark merging verified.');

  print('\n=== ALL DEVELOPER FEATURE TESTS PASSED SUCCESSFULLY! ===');
}
