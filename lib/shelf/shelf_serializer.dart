import 'dart:convert';

import 'shelf_model.dart';

/// Handles serialization, deserialization, and validation of `.arcshelf` payloads.
class ShelfSerializer {
  /// Encodes a [ShelfManifest] into a formatted JSON string.
  static String serialize(ShelfManifest manifest) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(manifest.toJson());
  }

  /// Parses and validates a JSON string into a [ShelfManifest].
  static ShelfManifest deserialize(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate required fields
      if (!decoded.containsKey('novels') || decoded['novels'] is! List) {
        throw const FormatException('Invalid .arcshelf format: missing "novels" array');
      }

      return ShelfManifest.fromJson(decoded);
    } catch (e) {
      throw FormatException('Failed to parse .arcshelf payload: $e');
    }
  }
}
