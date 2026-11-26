import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/note_database_mapper.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/note/update_note_request_dto.dart';
import 'package:notes_app/data/network/dto/response/note/delete_note_response_dto.dart';
import 'package:notes_app/data/network/dto/response/note/note_details_response_dto.dart';
import 'package:notes_app/data/network/dto/response/note/update_note_response_dto.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/note_data_transfer_service.dart';
import 'package:uuid/uuid.dart';

class ImportResult {
  final int totalProcessed;
  final int importedCount;
  final int updatedCount;
  final int duplicateCount;
  final bool syncedToServer;
  final List<String> errors;

  const ImportResult({
    required this.totalProcessed,
    required this.importedCount,
    required this.updatedCount,
    required this.duplicateCount,
    required this.syncedToServer,
    this.errors = const [],
  });

  String get summary {
    final parts = <String>[];
    if (importedCount > 0) {
      parts.add(
        '$importedCount new imported'
        '${syncedToServer ? ' and synced to server' : ' (saved locally, pending sync)'}',
      );
    }
    if (updatedCount > 0) {
      parts.add('$updatedCount updated');
    }
    if (duplicateCount > 0) {
      parts.add(
        '$duplicateCount duplicate${duplicateCount > 1 ? 's' : ''} skipped',
      );
    }
    if (parts.isEmpty) {
      return 'No notes were imported.';
    }
    return parts.join(', ');
  }
}

class NoteRepo {
  final ApiClient client;
  final AppDatabase database;
  final OfflineSyncService syncService;

  NoteRepo({
    required this.client,
    required this.database,
    required this.syncService,
  });

  /// Saves the note locally, queues its upload and asks for a sync.
  Future<int> enqueueNote(CreateNoteRequestDto requestDto) async {
    final localId = await _queueNote(requestDto);
    unawaited(syncService.requestSync());
    return localId;
  }

  /// Stores the note and its queued create, tagged with a new client id so a
  /// retried upload can't create it twice on the server.
  Future<int> _queueNote(
    CreateNoteRequestDto requestDto, {
    String? createdAt,
    String? updatedAt,
  }) {
    final userId = requestDto.userId;
    final title = requestDto.title;
    final content = requestDto.content;
    if (userId == null || title == null || content == null) {
      throw ArgumentError('A note needs a user ID, title, and content.');
    }

    final clientId = const Uuid().v4();
    return database.enqueueNote(
      userId: userId,
      title: title,
      content: content,
      category: requestDto.category ?? 'General',
      pinned: requestDto.pinned ?? false,
      tags: requestDto.tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
      clientId: clientId,
      payload: jsonEncode({...requestDto.toJson(), 'clientId': clientId}),
    );
  }

  Future<UpdateNoteResponseDto> updateNote(
    int userId,
    UpdateNoteRequestDto requestDto,
  ) async {
    final response = await client.updateNote(requestDto);
    if (response.statusCode != 200) {
      throw HttpException((response.statusCode ?? 500).toString());
    }

    final result = UpdateNoteResponseDto.fromJson(response.data);
    final note = result.data;
    if (result.success == true && note != null && requestDto.noteId != null) {
      await database.saveServerNote(
        NoteDatabaseMapper.fromDetails(
          userId,
          NoteDetailsData(
            noteId: note.noteId ?? requestDto.noteId,
            title: note.title ?? requestDto.title,
            content: note.content ?? requestDto.content,
            category: note.category ?? requestDto.category,
            createdAt: note.createdAt,
            updatedAt: note.updateAt,
            pinned: note.pinned ?? requestDto.pinned,
            tags: note.tags ?? requestDto.tags,
          ),
        ),
      );
    }
    return result;
  }

  Future<void> togglePin(int userId, int noteId) async {
    final response = await client.togglePin(noteId);
    if (response.statusCode != 200) {
      throw HttpException((response.statusCode ?? 500).toString());
    }
    final existing = await database.getNote(userId, noteId);
    if (existing != null) {
      final updated = existing.copyWith(
        pinned: !existing.pinned,
        updatedAt: Value(DateTime.now().toIso8601String()),
      );
      await database.saveServerNote(
        NoteDatabaseMapper.fromDetails(userId, NoteDatabaseMapper.toDetails(updated)),
      );
    }
  }

  Future<NoteDetailsResponseDto> getNoteDetails(int userId, int id) async {
    final cachedNote = await database.getNote(userId, id);
    if (cachedNote != null) {
      return NoteDetailsResponseDto(
        success: true,
        data: NoteDatabaseMapper.toDetails(cachedNote),
      );
    }

    if (id < 0) {
      throw StateError('The local note $id was not found.');
    }

    final response = await client.getNoteDetails(id);
    if (response.statusCode != 200) {
      throw HttpException((response.statusCode ?? 500).toString());
    }

    final result = NoteDetailsResponseDto.fromJson(response.data);
    if (result.success == true && result.data != null) {
      await database.saveServerNote(
        NoteDatabaseMapper.fromDetails(userId, result.data!),
      );
    }
    return result;
  }

  Future<DeleteNoteResponseDto> deleteNote(int id) async {
    final Response response;
    try {
      response = await client.deleteNote(id);
    } on DioException catch (e) {
      // 404: the server no longer has the note, so drop the stale local copy
      // too, then let the caller show "Note not found".
      if (e.response?.statusCode == 404) {
        await _deleteCachedNote(id);
      }
      rethrow;
    }
    if (response.statusCode != 200) {
      throw HttpException((response.statusCode ?? 500).toString());
    }
    await _deleteCachedNote(id);
    return DeleteNoteResponseDto.fromJson(response.data);
  }

  Future<void> _deleteCachedNote(int serverId) async {
    await (database.delete(database.cachedNotes)
          ..where((n) => n.serverId.equals(serverId)))
        .go();
  }

  Future<Map<String, dynamic>> exportNotes(int userId) async {
    final response = await client.exportNotes(userId);
    if (response.statusCode != 200) {
      throw HttpException((response.statusCode ?? 500).toString());
    }
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<NoteExportItem>> getAllLocalNotes(int userId) async {
    final cached = await database.getNotesForUser(userId);
    return cached.map(NoteExportItem.fromCachedNote).toList();
  }

  Future<ImportResult> importNotes({
    required int userId,
    required List<NoteExportItem> notes,
  }) async {
    int importedCount = 0;
    int updatedCount = 0;
    int duplicateCount = 0;
    final errors = <String>[];

    for (final item in notes) {
      final title = item.title.trim();
      final content = item.content.trim();

      if (title.isEmpty && content.isEmpty) {
        continue;
      }

      final normalizedTitle = title.isEmpty ? 'Untitled Note' : title;

      try {
        // 1. Check if note with same serverId already exists in DB
        if (item.noteId != null && item.noteId! > 0) {
          final existing =
              await database.getNoteByServerId(userId, item.noteId!);
          if (existing != null) {
            final isIdentical = existing.title == normalizedTitle &&
                existing.content == content &&
                (existing.category ?? 'General') ==
                    (item.category ?? 'General') &&
                existing.pinned == item.pinned &&
                (existing.tags ?? '') == (item.tags ?? '');

            if (isIdentical) {
              duplicateCount++;
            } else {
              await database.saveServerNote(
                CachedNotesCompanion(
                  id: Value(existing.id),
                  userId: Value(userId),
                  serverId: Value(item.noteId),
                  title: Value(normalizedTitle),
                  content: Value(content),
                  category: Value(item.category ?? existing.category),
                  pinned: Value(item.pinned),
                  tags: Value(item.tags ?? existing.tags),
                  updatedAt: Value(DateTime.now().toIso8601String()),
                ),
              );

              try {
                await client.updateNote(
                  UpdateNoteRequestDto(
                    noteId: item.noteId,
                    title: normalizedTitle,
                    content: content,
                    category: item.category ?? existing.category,
                    pinned: item.pinned,
                    tags: item.tags ?? existing.tags,
                  ),
                );
              } catch (_) {
                // Keep local cache updated if offline or network error
              }
              updatedCount++;
            }
            continue;
          }
        }

        // 2. Check if a note with identical title and content already exists in DB
        final duplicate = await database.findDuplicateNote(
          userId: userId,
          title: normalizedTitle,
          content: content,
        );

        if (duplicate != null) {
          final metaDiffers = (duplicate.category ?? 'General') !=
                  (item.category ?? 'General') ||
              duplicate.pinned != item.pinned ||
              (duplicate.tags ?? '') != (item.tags ?? '');

          if (metaDiffers) {
            await database.updateCachedNote(
              CachedNotesCompanion(
                id: Value(duplicate.id),
                userId: Value(userId),
                serverId: Value(duplicate.serverId),
                title: Value(duplicate.title),
                content: Value(duplicate.content),
                category: Value(item.category ?? duplicate.category),
                pinned: Value(item.pinned),
                tags: Value(item.tags ?? duplicate.tags),
                updatedAt: Value(DateTime.now().toIso8601String()),
              ),
            );
            updatedCount++;
          } else {
            duplicateCount++;
          }
          continue;
        }

        // 3. New Note -> Enqueue in local DB with isPending: true
        await _queueNote(
          CreateNoteRequestDto(
            userId: userId,
            title: normalizedTitle,
            content: content,
            category: item.category ?? 'General',
            pinned: item.pinned,
            tags: item.tags,
          ),
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
        );
        importedCount++;
      } catch (e) {
        errors.add('Failed to import "$normalizedTitle": $e');
      }
    }

    // 4. Upload the new notes through the sync service. Anything it could not
    // send stays safely queued in the local database.
    bool syncedToServer = false;
    if (importedCount > 0) {
      await syncService.requestSync();
      syncedToServer = (await database.getPendingNotes(userId)).isEmpty;
    }

    return ImportResult(
      totalProcessed: notes.length,
      importedCount: importedCount,
      updatedCount: updatedCount,
      duplicateCount: duplicateCount,
      syncedToServer: syncedToServer,
      errors: errors,
    );
  }
}
