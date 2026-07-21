/// Sanitizes raw HTML or plain text into strict, valid XHTML 1.1 compliant markup.
class XhtmlSanitizer {
  /// Converts plain text or messy HTML into well-formed XHTML paragraph elements.
  static String sanitizeChapterBody(String rawContent) {
    if (rawContent.trim().isEmpty) {
      return '<p></p>';
    }

    String content = rawContent;

    // Check if the content is plain text (no HTML tags)
    if (!content.contains('<p>') && !content.contains('<div>')) {
      final lines = content.split(RegExp(r'\r?\n'));
      final buffer = StringBuffer();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          buffer.write('<p>${escapeXml(trimmed)}</p>\n');
        }
      }
      return buffer.toString();
    }

    // Escape raw unescaped ampersands that are not part of valid entities
    content = content.replaceAllMapped(
      RegExp(r'&(?!(amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)'),
      (match) => '&amp;',
    );

    // Fix unclosed void HTML tags to self-closing XHTML tags
    content = content.replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '<br/>');
    content = content.replaceAll(RegExp(r'<hr\s*\/?>', caseSensitive: false), '<hr/>');
    content = content.replaceAllMapped(
      RegExp(r'<img\s+([^>]*?)(?<!\/)>', caseSensitive: false),
      (match) => '<img ${match.group(1)}/>',
    );

    return content;
  }

  /// Escapes special XML characters.
  static String escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
