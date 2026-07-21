import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'download/download_queue_manager.dart';
import 'download/download_task.dart';
import 'epub/epub_metadata.dart';
import 'epub/epub_packager.dart';
import 'shelf/shelf_import_export_service.dart';
import 'shelf/shelf_model.dart';
import 'theme/eink_palette.dart';
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
  String _selectedFontFamily = 'Newsreader';
  double _fontSize = 18.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArcReader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: _themeController.isInvertedNight ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: _themeController.backgroundColor,
        fontFamily: _selectedFontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: _themeController.backgroundColor,
          foregroundColor: _themeController.textColor,
          elevation: 0,
        ),
      ),
      home: ArcReaderHomeScreen(
        themeController: _themeController,
        selectedFontFamily: _selectedFontFamily,
        fontSize: _fontSize,
        onFontChanged: (font) => setState(() => _selectedFontFamily = font),
        onFontSizeChanged: (size) => setState(() => _fontSize = size),
        onToggleTheme: () => setState(() {}),
      ),
    );
  }
}

class ArcReaderHomeScreen extends StatefulWidget {
  final EInkThemeController themeController;
  final String selectedFontFamily;
  final double fontSize;
  final ValueChanged<String> onFontChanged;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback onToggleTheme;

  const ArcReaderHomeScreen({
    super.key,
    required this.themeController,
    required this.selectedFontFamily,
    required this.fontSize,
    required this.onFontChanged,
    required this.onFontSizeChanged,
    required this.onToggleTheme,
  });

  @override
  State<ArcReaderHomeScreen> createState() => _ArcReaderHomeScreenState();
}

class _ArcReaderHomeScreenState extends State<ArcReaderHomeScreen> {
  final ShelfImportExportService _shelfService = ShelfImportExportService();
  late DownloadQueueManager _downloadManager;
  
  Map<String, dynamic>? _welcomeNovelManifest;
  List<String> _chapterContents = [];
  int _currentChapterIdx = 0;
  bool _showToolbar = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _downloadManager = DownloadQueueManager(
      maxConcurrent: 3,
      fetcher: (task) async {
        await Future.delayed(const Duration(milliseconds: 300));
        return 'Downloaded content for ${task.chapterTitle}';
      },
      onTaskCompleted: (task, content) async {},
    );

    _loadWelcomeNovel();
  }

  Future<void> _loadWelcomeNovel() async {
    try {
      final manifestString = await rootBundle.loadString('assets/welcome_novel/manifest.json');
      final manifest = jsonDecode(manifestString) as Map<String, dynamic>;
      
      final chapters = manifest['chapters'] as List<dynamic>;
      List<String> contents = [];
      for (final ch in chapters) {
        final fileName = ch['file'] as String;
        final text = await rootBundle.loadString('assets/welcome_novel/$fileName');
        contents.add(text);
      }

      // Add to shelf service
      _shelfService.addLocalNovel(BookmarkedNovel(
        novelId: 'welcome_novel_1',
        title: manifest['title'] as String? ?? 'Welcome to ArcReader',
        author: manifest['author'] as String? ?? 'ArcReader Team',
        sourceId: 'local_bundle',
        sourceUrl: 'assets/welcome_novel/manifest.json',
        tags: ['guide'],
        bookmarkedChapter: 1,
      ));

      setState(() {
        _welcomeNovelManifest = manifest;
        _chapterContents = contents;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading welcome novel: $e');
      setState(() => _isLoading = false);
    }
  }

  void _exportCurrentNovelEpub() {
    if (_welcomeNovelManifest == null || _chapterContents.isEmpty) return;

    final chapters = _welcomeNovelManifest!['chapters'] as List<dynamic>;
    List<EpubChapterInput> epubChapters = [];
    for (int i = 0; i < chapters.length; i++) {
      epubChapters.add(EpubChapterInput(
        id: 'chap_${i + 1}',
        title: chapters[i]['title'] as String,
        rawBody: _chapterContents[i],
      ));
    }

    final metadata = EpubMetadata(
      title: _welcomeNovelManifest!['title'] as String? ?? 'Welcome to ArcReader',
      author: _welcomeNovelManifest!['author'] as String? ?? 'ArcReader Team',
      identifier: 'urn:uuid:arcreader-welcome-guide',
      chapters: epubChapters,
    );

    final entries = EpubPackager.createEpubEntries(metadata);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated EPUB 3.0 Package (${entries.length} assets embedded).'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportShelfPackage() {
    final jsonStr = _shelfService.exportShelf('ArcReader Library');
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported .arcshelf library manifest (${jsonStr.length} bytes) copied to clipboard.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDisplaySettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.themeController.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final fg = widget.themeController.textColor;
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Display Settings', style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Font Family', style: TextStyle(color: fg)),
                  DropdownButton<String>(
                    value: widget.selectedFontFamily,
                    dropdownColor: widget.themeController.backgroundColor,
                    style: TextStyle(color: fg),
                    items: const [
                      DropdownMenuItem(value: 'Newsreader', child: Text('Newsreader (Serif)')),
                      DropdownMenuItem(value: 'Inter', child: Text('Inter (Sans-Serif)')),
                      DropdownMenuItem(value: 'JetBrainsMono', child: Text('JetBrains Mono (Code)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        widget.onFontChanged(val);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Font Size', style: TextStyle(color: fg)),
                  Expanded(
                    child: Slider(
                      value: widget.fontSize,
                      min: 14.0,
                      max: 28.0,
                      divisions: 14,
                      onChanged: (val) => widget.onFontSizeChanged(val),
                    ),
                  ),
                  Text('${widget.fontSize.toInt()}pt', style: TextStyle(color: fg)),
                ],
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Inverted E-Ink Night Mode', style: TextStyle(color: fg)),
                subtitle: Text('Pure black/white high contrast for e-ink & night reading', style: TextStyle(color: fg.withAlpha(150), fontSize: 12)),
                trailing: Switch(
                  value: widget.themeController.isInvertedNight,
                  onChanged: (val) {
                    widget.themeController.toggleInvertedNight();
                    widget.onToggleTheme();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.themeController.backgroundColor;
    final fg = widget.themeController.textColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chapters = (_welcomeNovelManifest?['chapters'] as List<dynamic>?) ?? [];
    final currentTitle = chapters.isNotEmpty ? chapters[_currentChapterIdx]['title'] as String : '';
    final currentText = _chapterContents.isNotEmpty ? _chapterContents[_currentChapterIdx] : '';

    return Scaffold(
      backgroundColor: bg,
      appBar: _showToolbar
          ? AppBar(
              leading: Image.asset('assets/branding/app_icon.png', width: 28, height: 28),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_welcomeNovelManifest?['title'] ?? 'ArcReader', style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(currentTitle, style: TextStyle(color: fg.withAlpha(180), fontSize: 12)),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.share, color: fg),
                  tooltip: 'Export .arcshelf',
                  onPressed: _exportShelfPackage,
                ),
                IconButton(
                  icon: Icon(Icons.picture_as_pdf_outlined, color: fg),
                  tooltip: 'Export EPUB 3.0',
                  onPressed: _exportCurrentNovelEpub,
                ),
              ],
            )
          : null,
      bottomNavigationBar: _showToolbar
          ? Container(
              color: bg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.text_fields, color: fg),
                    tooltip: 'Display Settings',
                    onPressed: _showDisplaySettingsSheet,
                  ),
                  IconButton(
                    icon: Icon(Icons.file_download_outlined, color: fg),
                    tooltip: 'Download Offline Queue',
                    onPressed: () {
                      final task = DownloadTask(
                        taskId: 'dl_${DateTime.now().millisecondsSinceEpoch}',
                        novelId: 'welcome_novel_1',
                        chapterId: 'chap_${_currentChapterIdx + 1}',
                        chapterTitle: currentTitle,
                        downloadUrl: 'local',
                      );
                      _downloadManager.enqueue(task);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Enqueued "$currentTitle" for offline sync.')),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.list, color: fg),
                    tooltip: 'Chapters TOC',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: bg,
                        builder: (context) {
                          return ListView.builder(
                            itemCount: chapters.length,
                            itemBuilder: (context, idx) {
                              final item = chapters[idx];
                              return ListTile(
                                title: Text(item['title'] as String, style: TextStyle(color: fg)),
                                selected: idx == _currentChapterIdx,
                                onTap: () {
                                  setState(() => _currentChapterIdx = idx);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _showToolbar = !_showToolbar),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: widget.themeController.suppressAnimations
                ? const ClampingScrollPhysics()
                : const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTitle,
                  style: TextStyle(
                    fontFamily: widget.selectedFontFamily,
                    fontSize: widget.fontSize + 6,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  currentText,
                  style: TextStyle(
                    fontFamily: widget.selectedFontFamily,
                    fontSize: widget.fontSize,
                    height: 1.6,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
