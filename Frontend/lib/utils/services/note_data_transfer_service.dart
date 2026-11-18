import 'dart:convert';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';

enum NoteExportFormat {
  csv,
  txt,
  json,
}

class NoteExportItem {
  final int? noteId;
  final String title;
  final String content;
  final String? category;
  final bool pinned;
  final String? tags;
  final String? createdAt;
  final String? updatedAt;

  const NoteExportItem({
    this.noteId,
    required this.title,
    required this.content,
    this.category,
    this.pinned = false,
    this.tags,
    this.createdAt,
    this.updatedAt,
  });

  factory NoteExportItem.fromCachedNote(CachedNote note) {
    return NoteExportItem(
      noteId: note.serverId,
      title: note.title,
      content: note.content,
      category: note.category,
      pinned: note.pinned,
      tags: note.tags,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );
  }

  factory NoteExportItem.fromNoteItem(NoteItem item) {
    return NoteExportItem(
      noteId: item.noteId != null && item.noteId! > 0 ? item.noteId : null,
      title: item.title ?? '',
      content: item.content ?? '',
      category: item.category,
      pinned: item.pinned ?? false,
      tags: item.tags,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  factory NoteExportItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['noteId'] ?? json['id'] ?? json['serverId'];
    int? parsedId;
    if (rawId is int) {
      parsedId = rawId > 0 ? rawId : null;
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId);
      if (parsedId != null && parsedId <= 0) parsedId = null;
    }

    final rawPinned = json['pinned'] ?? json['isPinned'];
    bool parsedPinned = false;
    if (rawPinned is bool) {
      parsedPinned = rawPinned;
    } else if (rawPinned is String) {
      parsedPinned = rawPinned.toLowerCase() == 'true' || rawPinned == '1';
    }

    return NoteExportItem(
      noteId: parsedId,
      title: (json['title'] ?? json['name'] ?? '').toString(),
      content: (json['content'] ?? json['body'] ?? json['description'] ?? '').toString(),
      category: json['category']?.toString(),
      pinned: parsedPinned,
      tags: json['tags']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (noteId != null) 'noteId': noteId,
      'title': title,
      'content': content,
      if (category != null) 'category': category,
      'pinned': pinned,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  NoteExportItem copyWith({
    int? noteId,
    String? title,
    String? content,
    String? category,
    bool? pinned,
    String? tags,
    String? createdAt,
    String? updatedAt,
  }) {
    return NoteExportItem(
      noteId: noteId ?? this.noteId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      pinned: pinned ?? this.pinned,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteExportItem &&
          runtimeType == other.runtimeType &&
          noteId == other.noteId &&
          title == other.title &&
          content == other.content &&
          category == other.category &&
          pinned == other.pinned &&
          tags == other.tags;

  @override
  int get hashCode =>
      noteId.hashCode ^
      title.hashCode ^
      content.hashCode ^
      category.hashCode ^
      pinned.hashCode ^
      tags.hashCode;
}

class NoteDataTransferService {
  static const String csvHeader =
      'Title,Content,Category,Pinned,Tags,Created At,Updated At';

  /// Formats a list of notes into the requested format (CSV, TXT, JSON).
  static String exportNotes(
    List<NoteExportItem> notes,
    NoteExportFormat format, {
    int? userId,
  }) {
    switch (format) {
      case NoteExportFormat.csv:
        return _exportToCsv(notes);
      case NoteExportFormat.txt:
        return _exportToTxt(notes);
      case NoteExportFormat.json:
        return _exportToJson(notes, userId: userId);
    }
  }

  /// Exports a single note as a formatted string in the selected format.
  static String exportSingleNote(
    NoteExportItem note,
    NoteExportFormat format,
  ) {
    switch (format) {
      case NoteExportFormat.csv:
        final buffer = StringBuffer();
        buffer.writeln(csvHeader);
        buffer.write(_formatCsvRow(note));
        return buffer.toString();
      case NoteExportFormat.txt:
        return _formatTxtBlock(note);
      case NoteExportFormat.json:
        return const JsonEncoder.withIndent('  ').convert(note.toJson());
    }
  }

  /// Parses raw text data into a list of NoteExportItem objects.
  /// If [preferredFormat] is omitted, the format is automatically detected.
  static List<NoteExportItem> parseNotes(
    String rawData, [
    NoteExportFormat? preferredFormat,
  ]) {
    final trimmed = rawData.trim();
    if (trimmed.isEmpty) return [];

    final format = preferredFormat ?? detectFormat(trimmed);
    switch (format) {
      case NoteExportFormat.json:
        return _parseJson(trimmed);
      case NoteExportFormat.csv:
        return _parseCsv(trimmed);
      case NoteExportFormat.txt:
        return _parseTxt(trimmed);
    }
  }

  /// Automatically identifies the format of the provided text data.
  static NoteExportFormat detectFormat(String rawData) {
    final trimmed = rawData.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return NoteExportFormat.json;
    }

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('title,') ||
        lower.startsWith('"title",') ||
        lower.contains(',content,') ||
        lower.contains(',"content",')) {
      return NoteExportFormat.csv;
    }

    if (trimmed.contains('===') ||
        trimmed.contains('---') ||
        trimmed.startsWith('Title:') ||
        trimmed.startsWith('# ')) {
      return NoteExportFormat.txt;
    }

    // Fallback: check if first line has commas
    final firstLine = trimmed.split('\n').first;
    if (firstLine.contains(',')) {
      return NoteExportFormat.csv;
    }

    return NoteExportFormat.txt;
  }

  // ---------------------------------------------------------------------------
  // CSV Export & Parse (RFC 4180 Compliant)
  // ---------------------------------------------------------------------------

  static String _exportToCsv(List<NoteExportItem> notes) {
    final buffer = StringBuffer();
    buffer.writeln(csvHeader);
    for (final note in notes) {
      buffer.writeln(_formatCsvRow(note));
    }
    return buffer.toString().trimRight();
  }

  static String _formatCsvRow(NoteExportItem note) {
    return [
      escapeCsvField(note.title),
      escapeCsvField(note.content),
      escapeCsvField(note.category ?? 'General'),
      escapeCsvField(note.pinned ? 'true' : 'false'),
      escapeCsvField(note.tags ?? ''),
      escapeCsvField(note.createdAt ?? ''),
      escapeCsvField(note.updatedAt ?? ''),
    ].join(',');
  }

  static String escapeCsvField(String? value) {
    if (value == null) return '';
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }

  static List<NoteExportItem> _parseCsv(String csvData) {
    final rows = _tokenizeCsv(csvData);
    if (rows.isEmpty) return [];

    // Header mapping
    final firstRow = rows.first;
    final headerMap = <String, int>{};
    bool hasHeader = false;

    for (int i = 0; i < firstRow.length; i++) {
      final colName = firstRow[i].trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
      headerMap[colName] = i;
      if (colName == 'title' || colName == 'content' || colName == 'body') {
        hasHeader = true;
      }
    }

    final dataRows = hasHeader ? rows.sublist(1) : rows;
    final results = <NoteExportItem>[];

    for (final row in dataRows) {
      if (row.isEmpty || (row.length == 1 && row[0].trim().isEmpty)) continue;

      String title = '';
      String content = '';
      String? category;
      bool pinned = false;
      String? tags;
      String? createdAt;
      String? updatedAt;

      if (hasHeader) {
        title = _getCsvValue(row, headerMap, ['title', 'name']) ?? '';
        content = _getCsvValue(row, headerMap, ['content', 'body', 'description']) ?? '';
        category = _getCsvValue(row, headerMap, ['category', 'type']);
        final pinnedVal = _getCsvValue(row, headerMap, ['pinned', 'ispinned']);
        pinned = pinnedVal?.toLowerCase() == 'true' || pinnedVal == '1';
        tags = _getCsvValue(row, headerMap, ['tags', 'tag']);
        createdAt = _getCsvValue(row, headerMap, ['createdat', 'created']);
        updatedAt = _getCsvValue(row, headerMap, ['updatedat', 'updated']);
      } else {
        // Positional fallback: title, content, category, pinned, tags, createdAt, updatedAt
        if (row.isNotEmpty) title = row[0].trim();
        if (row.length > 1) content = row[1].trim();
        if (row.length > 2) category = row[2].trim();
        if (row.length > 3) pinned = row[3].trim().toLowerCase() == 'true';
        if (row.length > 4) tags = row[4].trim();
        if (row.length > 5) createdAt = row[5].trim();
        if (row.length > 6) updatedAt = row[6].trim();
      }

      if (title.isEmpty && content.isEmpty) continue;
      if (title.isEmpty) title = 'Untitled Note';

      results.add(
        NoteExportItem(
          title: title,
          content: content,
          category: (category != null && category.isNotEmpty) ? category : 'General',
          pinned: pinned,
          tags: (tags != null && tags.isNotEmpty) ? tags : null,
          createdAt: (createdAt != null && createdAt.isNotEmpty) ? createdAt : null,
          updatedAt: (updatedAt != null && updatedAt.isNotEmpty) ? updatedAt : null,
        ),
      );
    }

    return results;
  }

  static String? _getCsvValue(
    List<String> row,
    Map<String, int> headerMap,
    List<String> possibleKeys,
  ) {
    for (final key in possibleKeys) {
      final index = headerMap[key];
      if (index != null && index < row.length) {
        final val = row[index].trim();
        return val.isEmpty ? null : val;
      }
    }
    return null;
  }

  /// RFC 4180 compliant CSV tokenizer.
  /// Handles multiline content inside quotes, escaped quotes (""), and commas.
  static List<List<String>> _tokenizeCsv(String input) {
    final results = <List<String>>[];
    final currentRow = <String>[];
    final currentField = StringBuffer();
    bool insideQuote = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (insideQuote) {
        if (char == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            currentField.write('"');
            i++; // skip next quote
          } else {
            insideQuote = false;
          }
        } else {
          currentField.write(char);
        }
      } else {
        if (char == '"') {
          insideQuote = true;
        } else if (char == ',') {
          currentRow.add(currentField.toString());
          currentField.clear();
        } else if (char == '\n') {
          currentRow.add(currentField.toString());
          currentField.clear();
          results.add(List<String>.from(currentRow));
          currentRow.clear();
        } else if (char == '\r') {
          if (i + 1 < input.length && input[i + 1] == '\n') {
            i++;
          }
          currentRow.add(currentField.toString());
          currentField.clear();
          results.add(List<String>.from(currentRow));
          currentRow.clear();
        } else {
          currentField.write(char);
        }
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString());
      results.add(currentRow);
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // Plain Text (TXT) Export & Parse
  // ---------------------------------------------------------------------------

  static const String txtNoteDivider =
      '==================================================';
  static const String txtContentDivider =
      '--------------------------------------------------';

  static String _exportToTxt(List<NoteExportItem> notes) {
    final buffer = StringBuffer();
    for (int i = 0; i < notes.length; i++) {
      buffer.write(_formatTxtBlock(notes[i]));
      if (i < notes.length - 1) {
        buffer.writeln();
      }
    }
    return buffer.toString().trimRight();
  }

  static String _formatTxtBlock(NoteExportItem note) {
    final buffer = StringBuffer();
    buffer.writeln(txtNoteDivider);
    buffer.writeln('Title: ${note.title}');
    buffer.writeln('Category: ${note.category ?? "General"}');
    buffer.writeln('Pinned: ${note.pinned}');
    if (note.tags != null && note.tags!.isNotEmpty) {
      buffer.writeln('Tags: ${note.tags}');
    }
    if (note.createdAt != null && note.createdAt!.isNotEmpty) {
      buffer.writeln('Created: ${note.createdAt}');
    }
    if (note.updatedAt != null && note.updatedAt!.isNotEmpty) {
      buffer.writeln('Updated: ${note.updatedAt}');
    }
    buffer.writeln(txtContentDivider);
    buffer.writeln(note.content);
    buffer.writeln(txtNoteDivider);
    return buffer.toString();
  }

  static List<NoteExportItem> _parseTxt(String txtData) {
    final notes = <NoteExportItem>[];

    // Check if the data uses '=' dividers between notes
    final hasEqualsDividers = RegExp(r'(?:^|\r?\n)={3,}').hasMatch(txtData);
    final dividerRegex = hasEqualsDividers
        ? RegExp(r'(?:^|\r?\n)={3,}\s*(?:\r?\n|$)')
        : RegExp(r'(?:^|\r?\n)-{3,}\s*(?:\r?\n|$)');

    final rawBlocks = txtData.split(dividerRegex);

    for (final rawBlock in rawBlocks) {
      final block = rawBlock.trim();
      if (block.isEmpty) continue;

      final parsed = _parseSingleTxtBlock(block);
      if (parsed != null) {
        notes.add(parsed);
      }
    }

    // Fallback: If no blocks were parsed by dividers, treat the entire string as one note
    if (notes.isEmpty && txtData.trim().isNotEmpty) {
      final fallback = _parseSingleTxtBlock(txtData.trim());
      if (fallback != null) {
        notes.add(fallback);
      }
    }

    return notes;
  }

  static NoteExportItem? _parseSingleTxtBlock(String block) {
    final rawLines = block.split('\n').map((l) => l.trimRight()).toList();

    // Remove leading and trailing empty lines or divider lines (=== or ---)
    while (rawLines.isNotEmpty &&
        (rawLines.first.trim().isEmpty ||
            RegExp(r'^[=\-]{3,}$').hasMatch(rawLines.first.trim()))) {
      rawLines.removeAt(0);
    }
    while (rawLines.isNotEmpty &&
        (rawLines.last.trim().isEmpty ||
            RegExp(r'^[=\-]{3,}$').hasMatch(rawLines.last.trim()))) {
      rawLines.removeLast();
    }

    if (rawLines.isEmpty) return null;

    final lines = rawLines;
    String title = '';
    String? category;
    bool pinned = false;
    String? tags;
    String? createdAt;
    String? updatedAt;
    int contentStartIndex = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (RegExp(r'^-{3,}$').hasMatch(line)) {
        contentStartIndex = i + 1;
        break;
      }

      if (line.toLowerCase().startsWith('title:')) {
        title = line.substring(6).trim();
      } else if (line.toLowerCase().startsWith('# ')) {
        title = line.substring(2).trim();
      } else if (line.toLowerCase().startsWith('category:')) {
        category = line.substring(9).trim();
      } else if (line.toLowerCase().startsWith('pinned:')) {
        final val = line.substring(7).trim().toLowerCase();
        pinned = val == 'true' || val == '1';
      } else if (line.toLowerCase().startsWith('tags:')) {
        tags = line.substring(5).trim();
      } else if (line.toLowerCase().startsWith('created:') ||
          line.toLowerCase().startsWith('created at:')) {
        final idx = line.indexOf(':');
        createdAt = line.substring(idx + 1).trim();
      } else if (line.toLowerCase().startsWith('updated:') ||
          line.toLowerCase().startsWith('updated at:')) {
        final idx = line.indexOf(':');
        updatedAt = line.substring(idx + 1).trim();
      } else if (title.isEmpty && contentStartIndex == -1 && line.isNotEmpty) {
        // If no keyword, first non-empty line can be title
        title = line;
      }
    }

    String content = '';
    if (contentStartIndex != -1 && contentStartIndex < lines.length) {
      content = lines.sublist(contentStartIndex).join('\n').trim();
    } else if (title.isNotEmpty && lines.length > 1) {
      // Content is everything after the title line
      content = lines.sublist(1).join('\n').trim();
    }

    if (title.isEmpty && content.isEmpty) return null;
    if (title.isEmpty) title = 'Untitled Note';

    return NoteExportItem(
      title: title,
      content: content,
      category: (category != null && category.isNotEmpty) ? category : 'General',
      pinned: pinned,
      tags: (tags != null && tags.isNotEmpty) ? tags : null,
      createdAt: (createdAt != null && createdAt.isNotEmpty) ? createdAt : null,
      updatedAt: (updatedAt != null && updatedAt.isNotEmpty) ? updatedAt : null,
    );
  }

  // ---------------------------------------------------------------------------
  // JSON Export & Parse
  // ---------------------------------------------------------------------------

  static String _exportToJson(
    List<NoteExportItem> notes, {
    int? userId,
  }) {
    final payload = {
      'exportVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      if (userId != null && userId > 0) 'userId': userId,
      'totalNotes': notes.length,
      'notes': notes.map((n) => n.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static List<NoteExportItem> _parseJson(String jsonData) {
    try {
      final decoded = jsonDecode(jsonData);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => NoteExportItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        if (map.containsKey('notes') && map['notes'] is List) {
          final list = map['notes'] as List;
          return list
              .whereType<Map>()
              .map((e) => NoteExportItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else if (map.containsKey('data') && map['data'] is List) {
          final list = map['data'] as List;
          return list
              .whereType<Map>()
              .map((e) => NoteExportItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else if (map.containsKey('title') || map.containsKey('content')) {
          // Single note json
          return [NoteExportItem.fromJson(map)];
        }
      }
    } catch (_) {
      // If direct jsonDecode fails, try to fallback to CSV or TXT
      return _parseCsv(jsonData);
    }
    return [];
  }
}
