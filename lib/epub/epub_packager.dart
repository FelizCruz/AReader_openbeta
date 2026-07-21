import 'dart:convert';

import 'epub_builders.dart';
import 'epub_metadata.dart';
import 'xhtml_sanitizer.dart';

/// Structured archive entry representation.
class ArchiveEntry {
  final String path;
  final List<int> data;
  final bool storeOnly; // True for mimetype (uncompressed)

  ArchiveEntry(this.path, this.data, {this.storeOnly = false});
}

/// Package builder for assembling valid EPUB 3 files.
class EpubPackager {
  /// Generates a list of file entries suitable for zipping into an EPUB container.
  static List<ArchiveEntry> createEpubEntries(EpubMetadata metadata) {
    final List<ArchiveEntry> entries = [];

    // 1. mimetype (MUST be uncompressed and first in the archive)
    entries.add(ArchiveEntry('mimetype', utf8.encode('application/epub+zip'), storeOnly: true));

    // 2. META-INF/container.xml
    entries.add(ArchiveEntry('META-INF/container.xml', utf8.encode(EpubBuilders.buildContainerXml())));

    // 3. OEBPS/content.opf
    entries.add(ArchiveEntry('OEBPS/content.opf', utf8.encode(EpubBuilders.buildContentOpf(metadata))));

    // 4. OEBPS/nav.xhtml
    entries.add(ArchiveEntry('OEBPS/nav.xhtml', utf8.encode(EpubBuilders.buildNavXhtml(metadata))));

    // 5. OEBPS/toc.ncx
    entries.add(ArchiveEntry('OEBPS/toc.ncx', utf8.encode(EpubBuilders.buildTocNcx(metadata))));

    // 6. OEBPS/Styles/style.css
    entries.add(ArchiveEntry('OEBPS/Styles/style.css', utf8.encode(EpubBuilders.buildStyleCss())));

    // 7. Cover image if present
    if (metadata.coverImageBytes != null) {
      entries.add(ArchiveEntry('OEBPS/Images/cover.jpg', metadata.coverImageBytes!));
    }

    // 8. OEBPS/Text/chap_X.xhtml
    for (int i = 0; i < metadata.chapters.length; i++) {
      final chap = metadata.chapters[i];
      final sanitizedBody = XhtmlSanitizer.sanitizeChapterBody(chap.rawBody);
      final xhtml = EpubBuilders.buildChapterXhtml(chap.title, sanitizedBody);
      entries.add(ArchiveEntry('OEBPS/Text/chap_$i.xhtml', utf8.encode(xhtml)));
    }

    return entries;
  }
}
