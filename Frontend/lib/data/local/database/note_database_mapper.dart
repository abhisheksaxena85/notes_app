import 'package:drift/drift.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/data/network/dto/response/note/note_details_response_dto.dart';

class NoteDatabaseMapper {
  static NoteItem toNoteItem(CachedNote note) {
    return NoteItem(
      noteId: note.serverId ?? -note.id,
      title: note.title,
      content: note.content,
      category: note.category,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      pinned: note.pinned,
      tags: note.tags,
    );
  }

  static NoteDetailsData toDetails(CachedNote note) {
    return NoteDetailsData(
      noteId: note.serverId ?? -note.id,
      title: note.title,
      content: note.content,
      category: note.category,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      pinned: note.pinned,
      tags: note.tags,
    );
  }

  static CachedNotesCompanion fromNoteItem(int userId, NoteItem note) {
    final serverId = note.noteId;
    if (serverId == null) {
      throw StateError('A server note must have an ID.');
    }

    return CachedNotesCompanion.insert(
      userId: userId,
      serverId: Value(serverId),
      title: note.title ?? '',
      content: note.content ?? '',
      category: Value(note.category),
      createdAt: Value(note.createdAt),
      updatedAt: Value(note.updatedAt),
      pinned: Value(note.pinned ?? false),
      tags: Value(note.tags),
      clientId: Value(note.clientId),
    );
  }

  static CachedNotesCompanion fromDetails(int userId, NoteDetailsData note) {
    final serverId = note.noteId;
    if (serverId == null) {
      throw StateError('A server note must have an ID.');
    }

    return CachedNotesCompanion.insert(
      userId: userId,
      serverId: Value(serverId),
      title: note.title ?? '',
      content: note.content ?? '',
      category: Value(note.category),
      createdAt: Value(note.createdAt),
      updatedAt: Value(note.updatedAt),
      pinned: Value(note.pinned ?? false),
      tags: Value(note.tags),
    );
  }
}
