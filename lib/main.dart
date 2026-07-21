import 'package:flutter/material.dart';

import 'download/download_queue_manager.dart';
import 'download/download_status.dart';
import 'download/download_task.dart';
import 'epub/epub_metadata.dart';
import 'epub/epub_packager.dart';
import 'shelf/shelf_import_export_service.dart';
import 'shelf/shelf_model.dart';
import 'theme/eink_theme_controller.dart';

void main() {
  runApp(const ArcReaderApp());
}

class ArcReaderApp extends StatefulWidget {
  const ArcReaderApp({super.key});

  @override
  State<ArcReaderApp> createState() => _ArcReaderAppState();
}

class _ArcReaderAppState extends State<ArcReaderApp> {
  final EInkThemeController _themeController = EInkThemeController();

  void _toggleEInkMode() {
    setState(() {
      _themeController.toggleInvertedNight();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArcReader Custom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _themeController.isInvertedNight ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: _themeController.backgroundColor,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: _themeController.textColor),
          bodyMedium: TextStyle(color: _themeController.textColor),
        ),
      ),
      home: HomeScreen(
        themeController: _themeController,
        onToggleEInk: _toggleEInkMode,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final EInkThemeController themeController;
  final VoidCallback onToggleEInk;

  const HomeScreen({
    super.key,
    required this.themeController,
    required this.onToggleEInk,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShelfImportExportService _shelfService = ShelfImportExportService();
  late DownloadQueueManager _downloadManager;

  @override
  void initState() {
    super.initState();
    _downloadManager = DownloadQueueManager(
      maxConcurrent: 3,
      fetcher: (task) async {
        await Future.delayed(const Duration(milliseconds: 300));
        return 'Sample content for ${task.chapterTitle}';
      },
      onTaskCompleted: (task, content) async {},
    );

    // Initial dummy data
    _shelfService.addLocalNovel(BookmarkedNovel(
      novelId: 'novel_1',
      title: 'The Great Web Novel',
      author: 'Master Author',
      sourceId: 'custom_source',
      sourceUrl: 'https://example.com/novel/1',
      tags: ['Fantasy', 'Adventure'],
      bookmarkedChapter: 12,
    ));
  }

  void _exportEpub() {
    final metadata = EpubMetadata(
      title: 'The Great Web Novel',
      author: 'Master Author',
      identifier: 'urn:uuid:arcreader-demo',
      chapters: [
        EpubChapterInput(
          id: 'chap_1',
          title: 'Chapter 1: The Beginning',
          rawBody: '<p>Welcome to the world of web novels.</p>',
        ),
      ],
    );

    final entries = EpubPackager.createEpubEntries(metadata);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generated EPUB with ${entries.length} package items.')),
    );
  }

  void _exportShelf() {
    final jsonString = _shelfService.exportShelf('My Favorites');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported .arcshelf (${jsonString.length} bytes)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.themeController.backgroundColor;
    final fg = widget.themeController.textColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('ArcReader Developer Dashboard', style: TextStyle(color: fg)),
        backgroundColor: bg,
        actions: [
          IconButton(
            icon: Icon(
              widget.themeController.isInvertedNight ? Icons.wb_sunny : Icons.nightlight_round,
              color: fg,
            ),
            tooltip: 'Toggle Inverted E-Ink Night Mode',
            onPressed: widget.onToggleEInk,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: bg == Colors.black ? const Color(0xFF111111) : Colors.white,
            child: ListTile(
              title: Text('The Great Web Novel', style: TextStyle(color: fg, fontWeight: FontWeight.bold)),
              subtitle: Text('Author: Master Author • Chapter 12', style: TextStyle(color: fg.withOpacity(0.7))),
              trailing: PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'epub') _exportEpub();
                  if (val == 'shelf') _exportShelf();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'epub', child: Text('Export EPUB 3.0')),
                  const PopupMenuItem(value: 'shelf', child: Text('Export .arcshelf')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Start Offline Download Test'),
            onPressed: () {
              final task = DownloadTask(
                taskId: 't_${DateTime.now().millisecondsSinceEpoch}',
                novelId: 'novel_1',
                chapterId: 'chap_13',
                chapterTitle: 'Chapter 13',
                downloadUrl: 'https://example.com/chap_13',
              );
              _downloadManager.enqueue(task);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enqueued Chapter 13 download task')),
              );
            },
          ),
        ],
      ),
    );
  }
}
