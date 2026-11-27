import 'dart:io';
import 'dart:ui' show Rect;

import 'package:notes_app/utils/services/note_data_transfer_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// FE-06: a notes export written to a file and handed to the share sheet,
/// where the user can save it (Files / Drive / Downloads) or send it. Large
/// exports don't fit the Android clipboard; a file has no such limit.
class NoteExportFile {
  NoteExportFile._();

  static String extension(NoteExportFormat format) => switch (format) {
        NoteExportFormat.csv => 'csv',
        NoteExportFormat.txt => 'txt',
        NoteExportFormat.json => 'json',
      };

  static String mimeType(NoteExportFormat format) => switch (format) {
        NoteExportFormat.csv => 'text/csv',
        NoteExportFormat.txt => 'text/plain',
        NoteExportFormat.json => 'application/json',
      };

  /// `daymark-notes-20261127-0930.csv`, in local time.
  static String fileName(NoteExportFormat format, DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}';
    return 'daymark-notes-$stamp.${extension(format)}';
  }

  /// Writes [content] to [directory] (the app's temporary directory by
  /// default) and returns the file. UTF-8, so non-ASCII notes survive.
  static Future<File> write(
    String content,
    NoteExportFormat format, {
    Directory? directory,
    DateTime? now,
  }) async {
    final dir = directory ?? await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}${fileName(format, now ?? DateTime.now())}');
    return file.writeAsString(content, flush: true);
  }

  /// Writes the export and opens the share sheet for it. [origin] is where
  /// the sheet anchors on iPad (the tapped button). Returns the share result.
  static Future<ShareResult> share(
    String content,
    NoteExportFormat format, {
    Rect? origin,
  }) async {
    final file = await write(content, format);
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType(format))],
        subject: 'Daymark notes export',
        sharePositionOrigin: origin,
      ),
    );
  }
}
