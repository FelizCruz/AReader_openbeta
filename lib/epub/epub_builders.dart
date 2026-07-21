import 'epub_metadata.dart';
import 'xhtml_sanitizer.dart';

/// Builder class for generating EPUB XML package files.
class EpubBuilders {
  static String buildContainerXml() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  }

  static String buildStyleCss() {
    return '''
body {
  font-family: serif;
  margin: 1em;
  line-height: 1.6;
  color: #111111;
  background-color: #ffffff;
}
h1, h2, h3 {
  font-family: sans-serif;
  text-align: center;
  margin-top: 1.5em;
  margin-bottom: 0.5em;
}
p {
  text-indent: 1.5em;
  margin-top: 0;
  margin-bottom: 0.5em;
}
img {
  max-width: 100%;
  height: auto;
  display: block;
  margin: 1em auto;
}
''';
  }

  static String buildChapterXhtml(String title, String sanitizedBody) {
    final escapedTitle = XhtmlSanitizer.escapeXml(title);
    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="en">
<head>
  <meta charset="UTF-8"/>
  <title>$escapedTitle</title>
  <link rel="stylesheet" type="text/css" href="../Styles/style.css"/>
</head>
<body>
  <h1>$escapedTitle</h1>
  $sanitizedBody
</body>
</html>''';
  }

  static String buildContentOpf(EpubMetadata metadata) {
    final title = XhtmlSanitizer.escapeXml(metadata.title);
    final author = XhtmlSanitizer.escapeXml(metadata.author);
    final identifier = XhtmlSanitizer.escapeXml(metadata.identifier);
    final language = XhtmlSanitizer.escapeXml(metadata.language);
    final publisher = XhtmlSanitizer.escapeXml(metadata.publisher ?? 'ArcReader');

    final manifestBuffer = StringBuffer();
    final spineBuffer = StringBuffer();

    manifestBuffer.writeln('    <item id="style" href="Styles/style.css" media-type="text/css"/>');
    manifestBuffer.writeln('    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>');
    manifestBuffer.writeln('    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');

    if (metadata.coverImageBytes != null) {
      manifestBuffer.writeln('    <item id="cover-image" href="Images/cover.jpg" media-type="${metadata.coverImageMimeType}" properties="cover-image"/>');
    }

    for (int i = 0; i < metadata.chapters.length; i++) {
      final id = 'chap_$i';
      manifestBuffer.writeln('    <item id="$id" href="Text/chap_$i.xhtml" media-type="application/xhtml+xml"/>');
      spineBuffer.writeln('    <itemref idref="$id"/>');
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="pub-id">$identifier</dc:identifier>
    <dc:title>$title</dc:title>
    <dc:creator>$author</dc:creator>
    <dc:language>$language</dc:language>
    <dc:publisher>$publisher</dc:publisher>
    <meta property="dcterms:modified">${DateTime.now().toUtc().toIso8601String().split('.')[0]}Z</meta>
  </metadata>
  <manifest>
$manifestBuffer  </manifest>
  <spine toc="ncx">
$spineBuffer  </spine>
</package>''';
  }

  static String buildNavXhtml(EpubMetadata metadata) {
    final title = XhtmlSanitizer.escapeXml(metadata.title);
    final navItems = StringBuffer();

    for (int i = 0; i < metadata.chapters.length; i++) {
      final chapTitle = XhtmlSanitizer.escapeXml(metadata.chapters[i].title);
      navItems.writeln('      <li><a href="Text/chap_$i.xhtml">$chapTitle</a></li>');
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="en">
<head>
  <meta charset="UTF-8"/>
  <title>$title - Table of Contents</title>
  <link rel="stylesheet" type="text/css" href="Styles/style.css"/>
</head>
<body>
  <nav epub:type="toc" id="toc">
    <h1>Table of Contents</h1>
    <ol>
$navItems    </ol>
  </nav>
</body>
</html>''';
  }

  static String buildTocNcx(EpubMetadata metadata) {
    final title = XhtmlSanitizer.escapeXml(metadata.title);
    final identifier = XhtmlSanitizer.escapeXml(metadata.identifier);
    final navPoints = StringBuffer();

    for (int i = 0; i < metadata.chapters.length; i++) {
      final chapTitle = XhtmlSanitizer.escapeXml(metadata.chapters[i].title);
      navPoints.writeln('''    <navPoint id="navPoint-${i + 1}" playOrder="${i + 1}">
      <navLabel><text>$chapTitle</text></navLabel>
      <content src="Text/chap_$i.xhtml"/>
    </navPoint>''');
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="$identifier"/>
    <meta name="dtb:depth" content="1"/>
    <meta name="dtb:totalPageCount" content="0"/>
    <meta name="dtb:maxPageNumber" content="0"/>
  </head>
  <docTitle><text>$title</text></docTitle>
  <navMap>
$navPoints  </navMap>
</ncx>''';
  }
}
