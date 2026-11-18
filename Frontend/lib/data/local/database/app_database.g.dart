// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedNotesTable extends CachedNotes
    with TableInfo<$CachedNotesTable, CachedNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPendingMeta = const VerificationMeta(
    'isPending',
  );
  @override
  late final GeneratedColumn<bool> isPending = GeneratedColumn<bool>(
    'is_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    serverId,
    title,
    content,
    category,
    createdAt,
    updatedAt,
    tags,
    pinned,
    isPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('is_pending')) {
      context.handle(
        _isPendingMeta,
        isPending.isAcceptableOrUnknown(data['is_pending']!, _isPendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, serverId},
  ];
  @override
  CachedNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      isPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending'],
      )!,
    );
  }

  @override
  $CachedNotesTable createAlias(String alias) {
    return $CachedNotesTable(attachedDatabase, alias);
  }
}

class CachedNote extends DataClass implements Insertable<CachedNote> {
  final int id;
  final int userId;
  final int? serverId;
  final String title;
  final String content;
  final String? category;
  final String? createdAt;
  final String? updatedAt;
  final String? tags;
  final bool pinned;
  final bool isPending;
  const CachedNote({
    required this.id,
    required this.userId,
    this.serverId,
    required this.title,
    required this.content,
    this.category,
    this.createdAt,
    this.updatedAt,
    this.tags,
    required this.pinned,
    required this.isPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['pinned'] = Variable<bool>(pinned);
    map['is_pending'] = Variable<bool>(isPending);
    return map;
  }

  CachedNotesCompanion toCompanion(bool nullToAbsent) {
    return CachedNotesCompanion(
      id: Value(id),
      userId: Value(userId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      title: Value(title),
      content: Value(content),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      pinned: Value(pinned),
      isPending: Value(isPending),
    );
  }

  factory CachedNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedNote(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      category: serializer.fromJson<String?>(json['category']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
      tags: serializer.fromJson<String?>(json['tags']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      isPending: serializer.fromJson<bool>(json['isPending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'serverId': serializer.toJson<int?>(serverId),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'category': serializer.toJson<String?>(category),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
      'tags': serializer.toJson<String?>(tags),
      'pinned': serializer.toJson<bool>(pinned),
      'isPending': serializer.toJson<bool>(isPending),
    };
  }

  CachedNote copyWith({
    int? id,
    int? userId,
    Value<int?> serverId = const Value.absent(),
    String? title,
    String? content,
    Value<String?> category = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    bool? pinned,
    bool? isPending,
  }) => CachedNote(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    serverId: serverId.present ? serverId.value : this.serverId,
    title: title ?? this.title,
    content: content ?? this.content,
    category: category.present ? category.value : this.category,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    tags: tags.present ? tags.value : this.tags,
    pinned: pinned ?? this.pinned,
    isPending: isPending ?? this.isPending,
  );
  CachedNote copyWithCompanion(CachedNotesCompanion data) {
    return CachedNote(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      tags: data.tags.present ? data.tags.value : this.tags,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      isPending: data.isPending.present ? data.isPending.value : this.isPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedNote(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tags: $tags, ')
          ..write('pinned: $pinned, ')
          ..write('isPending: $isPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    serverId,
    title,
    content,
    category,
    createdAt,
    updatedAt,
    tags,
    pinned,
    isPending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedNote &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.serverId == this.serverId &&
          other.title == this.title &&
          other.content == this.content &&
          other.category == this.category &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.tags == this.tags &&
          other.pinned == this.pinned &&
          other.isPending == this.isPending);
}

class CachedNotesCompanion extends UpdateCompanion<CachedNote> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int?> serverId;
  final Value<String> title;
  final Value<String> content;
  final Value<String?> category;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<String?> tags;
  final Value<bool> pinned;
  final Value<bool> isPending;
  const CachedNotesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.tags = const Value.absent(),
    this.pinned = const Value.absent(),
    this.isPending = const Value.absent(),
  });
  CachedNotesCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    this.serverId = const Value.absent(),
    required String title,
    required String content,
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.tags = const Value.absent(),
    this.pinned = const Value.absent(),
    this.isPending = const Value.absent(),
  }) : userId = Value(userId),
       title = Value(title),
       content = Value(content);
  static Insertable<CachedNote> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? serverId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? category,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? tags,
    Expression<bool>? pinned,
    Expression<bool>? isPending,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (serverId != null) 'server_id': serverId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (tags != null) 'tags': tags,
      if (pinned != null) 'pinned': pinned,
      if (isPending != null) 'is_pending': isPending,
    });
  }

  CachedNotesCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int?>? serverId,
    Value<String>? title,
    Value<String>? content,
    Value<String?>? category,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<String?>? tags,
    Value<bool>? pinned,
    Value<bool>? isPending,
  }) {
    return CachedNotesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      pinned: pinned ?? this.pinned,
      isPending: isPending ?? this.isPending,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (isPending.present) {
      map['is_pending'] = Variable<bool>(isPending.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedNotesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tags: $tags, ')
          ..write('pinned: $pinned, ')
          ..write('isPending: $isPending')
          ..write(')'))
        .toString();
  }
}

class $PendingNotesTable extends PendingNotes
    with TableInfo<$PendingNotesTable, PendingNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localNoteIdMeta = const VerificationMeta(
    'localNoteId',
  );
  @override
  late final GeneratedColumn<int> localNoteId = GeneratedColumn<int>(
    'local_note_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    localNoteId,
    payload,
    queuedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('local_note_id')) {
      context.handle(
        _localNoteIdMeta,
        localNoteId.isAcceptableOrUnknown(
          data['local_note_id']!,
          _localNoteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localNoteIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {localNoteId},
  ];
  @override
  PendingNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      localNoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_note_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
    );
  }

  @override
  $PendingNotesTable createAlias(String alias) {
    return $PendingNotesTable(attachedDatabase, alias);
  }
}

class PendingNote extends DataClass implements Insertable<PendingNote> {
  final int id;
  final int userId;
  final int localNoteId;
  final String payload;
  final DateTime queuedAt;
  const PendingNote({
    required this.id,
    required this.userId,
    required this.localNoteId,
    required this.payload,
    required this.queuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['local_note_id'] = Variable<int>(localNoteId);
    map['payload'] = Variable<String>(payload);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    return map;
  }

  PendingNotesCompanion toCompanion(bool nullToAbsent) {
    return PendingNotesCompanion(
      id: Value(id),
      userId: Value(userId),
      localNoteId: Value(localNoteId),
      payload: Value(payload),
      queuedAt: Value(queuedAt),
    );
  }

  factory PendingNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingNote(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      localNoteId: serializer.fromJson<int>(json['localNoteId']),
      payload: serializer.fromJson<String>(json['payload']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'localNoteId': serializer.toJson<int>(localNoteId),
      'payload': serializer.toJson<String>(payload),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
    };
  }

  PendingNote copyWith({
    int? id,
    int? userId,
    int? localNoteId,
    String? payload,
    DateTime? queuedAt,
  }) => PendingNote(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    localNoteId: localNoteId ?? this.localNoteId,
    payload: payload ?? this.payload,
    queuedAt: queuedAt ?? this.queuedAt,
  );
  PendingNote copyWithCompanion(PendingNotesCompanion data) {
    return PendingNote(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      localNoteId: data.localNoteId.present
          ? data.localNoteId.value
          : this.localNoteId,
      payload: data.payload.present ? data.payload.value : this.payload,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingNote(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('localNoteId: $localNoteId, ')
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, localNoteId, payload, queuedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingNote &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.localNoteId == this.localNoteId &&
          other.payload == this.payload &&
          other.queuedAt == this.queuedAt);
}

class PendingNotesCompanion extends UpdateCompanion<PendingNote> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int> localNoteId;
  final Value<String> payload;
  final Value<DateTime> queuedAt;
  const PendingNotesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.localNoteId = const Value.absent(),
    this.payload = const Value.absent(),
    this.queuedAt = const Value.absent(),
  });
  PendingNotesCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required int localNoteId,
    required String payload,
    this.queuedAt = const Value.absent(),
  }) : userId = Value(userId),
       localNoteId = Value(localNoteId),
       payload = Value(payload);
  static Insertable<PendingNote> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? localNoteId,
    Expression<String>? payload,
    Expression<DateTime>? queuedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (localNoteId != null) 'local_note_id': localNoteId,
      if (payload != null) 'payload': payload,
      if (queuedAt != null) 'queued_at': queuedAt,
    });
  }

  PendingNotesCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int>? localNoteId,
    Value<String>? payload,
    Value<DateTime>? queuedAt,
  }) {
    return PendingNotesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      localNoteId: localNoteId ?? this.localNoteId,
      payload: payload ?? this.payload,
      queuedAt: queuedAt ?? this.queuedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (localNoteId.present) {
      map['local_note_id'] = Variable<int>(localNoteId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingNotesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('localNoteId: $localNoteId, ')
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedProfilesTable extends CachedProfiles
    with TableInfo<$CachedProfilesTable, CachedProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
    'mobile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    profileId,
    name,
    email,
    mobile,
    gender,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('mobile')) {
      context.handle(
        _mobileMeta,
        mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  CachedProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProfile(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      mobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mobile'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
    );
  }

  @override
  $CachedProfilesTable createAlias(String alias) {
    return $CachedProfilesTable(attachedDatabase, alias);
  }
}

class CachedProfile extends DataClass implements Insertable<CachedProfile> {
  final int userId;
  final int? profileId;
  final String? name;
  final String? email;
  final String? mobile;
  final String? gender;
  const CachedProfile({
    required this.userId,
    this.profileId,
    this.name,
    this.email,
    this.mobile,
    this.gender,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<int>(profileId);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || mobile != null) {
      map['mobile'] = Variable<String>(mobile);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    return map;
  }

  CachedProfilesCompanion toCompanion(bool nullToAbsent) {
    return CachedProfilesCompanion(
      userId: Value(userId),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      mobile: mobile == null && nullToAbsent
          ? const Value.absent()
          : Value(mobile),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
    );
  }

  factory CachedProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProfile(
      userId: serializer.fromJson<int>(json['userId']),
      profileId: serializer.fromJson<int?>(json['profileId']),
      name: serializer.fromJson<String?>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      mobile: serializer.fromJson<String?>(json['mobile']),
      gender: serializer.fromJson<String?>(json['gender']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'profileId': serializer.toJson<int?>(profileId),
      'name': serializer.toJson<String?>(name),
      'email': serializer.toJson<String?>(email),
      'mobile': serializer.toJson<String?>(mobile),
      'gender': serializer.toJson<String?>(gender),
    };
  }

  CachedProfile copyWith({
    int? userId,
    Value<int?> profileId = const Value.absent(),
    Value<String?> name = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> mobile = const Value.absent(),
    Value<String?> gender = const Value.absent(),
  }) => CachedProfile(
    userId: userId ?? this.userId,
    profileId: profileId.present ? profileId.value : this.profileId,
    name: name.present ? name.value : this.name,
    email: email.present ? email.value : this.email,
    mobile: mobile.present ? mobile.value : this.mobile,
    gender: gender.present ? gender.value : this.gender,
  );
  CachedProfile copyWithCompanion(CachedProfilesCompanion data) {
    return CachedProfile(
      userId: data.userId.present ? data.userId.value : this.userId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      gender: data.gender.present ? data.gender.value : this.gender,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfile(')
          ..write('userId: $userId, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('mobile: $mobile, ')
          ..write('gender: $gender')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, profileId, name, email, mobile, gender);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProfile &&
          other.userId == this.userId &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.email == this.email &&
          other.mobile == this.mobile &&
          other.gender == this.gender);
}

class CachedProfilesCompanion extends UpdateCompanion<CachedProfile> {
  final Value<int> userId;
  final Value<int?> profileId;
  final Value<String?> name;
  final Value<String?> email;
  final Value<String?> mobile;
  final Value<String?> gender;
  const CachedProfilesCompanion({
    this.userId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.mobile = const Value.absent(),
    this.gender = const Value.absent(),
  });
  CachedProfilesCompanion.insert({
    this.userId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.mobile = const Value.absent(),
    this.gender = const Value.absent(),
  });
  static Insertable<CachedProfile> custom({
    Expression<int>? userId,
    Expression<int>? profileId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? mobile,
    Expression<String>? gender,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (mobile != null) 'mobile': mobile,
      if (gender != null) 'gender': gender,
    });
  }

  CachedProfilesCompanion copyWith({
    Value<int>? userId,
    Value<int?>? profileId,
    Value<String?>? name,
    Value<String?>? email,
    Value<String?>? mobile,
    Value<String?>? gender,
  }) {
    return CachedProfilesCompanion(
      userId: userId ?? this.userId,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      gender: gender ?? this.gender,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfilesCompanion(')
          ..write('userId: $userId, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('mobile: $mobile, ')
          ..write('gender: $gender')
          ..write(')'))
        .toString();
  }
}

class $CachedTasksTable extends CachedTasks
    with TableInfo<$CachedTasksTable, CachedTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueTimeMeta = const VerificationMeta(
    'dueTime',
  );
  @override
  late final GeneratedColumn<String> dueTime = GeneratedColumn<String>(
    'due_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('MEDIUM'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingMeta = const VerificationMeta(
    'isPending',
  );
  @override
  late final GeneratedColumn<bool> isPending = GeneratedColumn<bool>(
    'is_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    serverId,
    title,
    description,
    dueDate,
    dueTime,
    category,
    priority,
    status,
    isCompleted,
    createdAt,
    updatedAt,
    isPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('due_time')) {
      context.handle(
        _dueTimeMeta,
        dueTime.isAcceptableOrUnknown(data['due_time']!, _dueTimeMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_pending')) {
      context.handle(
        _isPendingMeta,
        isPending.isAcceptableOrUnknown(data['is_pending']!, _isPendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, serverId},
  ];
  @override
  CachedTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      dueTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_time'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      isPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending'],
      )!,
    );
  }

  @override
  $CachedTasksTable createAlias(String alias) {
    return $CachedTasksTable(attachedDatabase, alias);
  }
}

class CachedTask extends DataClass implements Insertable<CachedTask> {
  final int id;
  final int userId;
  final int? serverId;
  final String title;
  final String? description;
  final String? dueDate;
  final String? dueTime;
  final String? category;
  final String priority;
  final String status;
  final bool isCompleted;
  final String? createdAt;
  final String? updatedAt;
  final bool isPending;
  const CachedTask({
    required this.id,
    required this.userId,
    this.serverId,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    this.category,
    required this.priority,
    required this.status,
    required this.isCompleted,
    this.createdAt,
    this.updatedAt,
    required this.isPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || dueTime != null) {
      map['due_time'] = Variable<String>(dueTime);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['priority'] = Variable<String>(priority);
    map['status'] = Variable<String>(status);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['is_pending'] = Variable<bool>(isPending);
    return map;
  }

  CachedTasksCompanion toCompanion(bool nullToAbsent) {
    return CachedTasksCompanion(
      id: Value(id),
      userId: Value(userId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      dueTime: dueTime == null && nullToAbsent
          ? const Value.absent()
          : Value(dueTime),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      priority: Value(priority),
      status: Value(status),
      isCompleted: Value(isCompleted),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isPending: Value(isPending),
    );
  }

  factory CachedTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedTask(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      dueTime: serializer.fromJson<String?>(json['dueTime']),
      category: serializer.fromJson<String?>(json['category']),
      priority: serializer.fromJson<String>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
      isPending: serializer.fromJson<bool>(json['isPending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'serverId': serializer.toJson<int?>(serverId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'dueDate': serializer.toJson<String?>(dueDate),
      'dueTime': serializer.toJson<String?>(dueTime),
      'category': serializer.toJson<String?>(category),
      'priority': serializer.toJson<String>(priority),
      'status': serializer.toJson<String>(status),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
      'isPending': serializer.toJson<bool>(isPending),
    };
  }

  CachedTask copyWith({
    int? id,
    int? userId,
    Value<int?> serverId = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> dueDate = const Value.absent(),
    Value<String?> dueTime = const Value.absent(),
    Value<String?> category = const Value.absent(),
    String? priority,
    String? status,
    bool? isCompleted,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    bool? isPending,
  }) => CachedTask(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    serverId: serverId.present ? serverId.value : this.serverId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    dueTime: dueTime.present ? dueTime.value : this.dueTime,
    category: category.present ? category.value : this.category,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isPending: isPending ?? this.isPending,
  );
  CachedTask copyWithCompanion(CachedTasksCompanion data) {
    return CachedTask(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      dueTime: data.dueTime.present ? data.dueTime.value : this.dueTime,
      category: data.category.present ? data.category.value : this.category,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isPending: data.isPending.present ? data.isPending.value : this.isPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedTask(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTime: $dueTime, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPending: $isPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    serverId,
    title,
    description,
    dueDate,
    dueTime,
    category,
    priority,
    status,
    isCompleted,
    createdAt,
    updatedAt,
    isPending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTask &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.serverId == this.serverId &&
          other.title == this.title &&
          other.description == this.description &&
          other.dueDate == this.dueDate &&
          other.dueTime == this.dueTime &&
          other.category == this.category &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isPending == this.isPending);
}

class CachedTasksCompanion extends UpdateCompanion<CachedTask> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int?> serverId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> dueDate;
  final Value<String?> dueTime;
  final Value<String?> category;
  final Value<String> priority;
  final Value<String> status;
  final Value<bool> isCompleted;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<bool> isPending;
  const CachedTasksCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.category = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isPending = const Value.absent(),
  });
  CachedTasksCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    this.serverId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.category = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isPending = const Value.absent(),
  }) : userId = Value(userId),
       title = Value(title);
  static Insertable<CachedTask> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? serverId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? dueDate,
    Expression<String>? dueTime,
    Expression<String>? category,
    Expression<String>? priority,
    Expression<String>? status,
    Expression<bool>? isCompleted,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<bool>? isPending,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (serverId != null) 'server_id': serverId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'due_date': dueDate,
      if (dueTime != null) 'due_time': dueTime,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isPending != null) 'is_pending': isPending,
    });
  }

  CachedTasksCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int?>? serverId,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? dueDate,
    Value<String?>? dueTime,
    Value<String?>? category,
    Value<String>? priority,
    Value<String>? status,
    Value<bool>? isCompleted,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<bool>? isPending,
  }) {
    return CachedTasksCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPending: isPending ?? this.isPending,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (dueTime.present) {
      map['due_time'] = Variable<String>(dueTime.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (isPending.present) {
      map['is_pending'] = Variable<bool>(isPending.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedTasksCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTime: $dueTime, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPending: $isPending')
          ..write(')'))
        .toString();
  }
}

class $PendingTasksTable extends PendingTasks
    with TableInfo<$PendingTasksTable, PendingTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localTaskIdMeta = const VerificationMeta(
    'localTaskId',
  );
  @override
  late final GeneratedColumn<int> localTaskId = GeneratedColumn<int>(
    'local_task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    localTaskId,
    payload,
    queuedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('local_task_id')) {
      context.handle(
        _localTaskIdMeta,
        localTaskId.isAcceptableOrUnknown(
          data['local_task_id']!,
          _localTaskIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localTaskIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {localTaskId},
  ];
  @override
  PendingTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      localTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_task_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
    );
  }

  @override
  $PendingTasksTable createAlias(String alias) {
    return $PendingTasksTable(attachedDatabase, alias);
  }
}

class PendingTask extends DataClass implements Insertable<PendingTask> {
  final int id;
  final int userId;
  final int localTaskId;
  final String payload;
  final DateTime queuedAt;
  const PendingTask({
    required this.id,
    required this.userId,
    required this.localTaskId,
    required this.payload,
    required this.queuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['local_task_id'] = Variable<int>(localTaskId);
    map['payload'] = Variable<String>(payload);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    return map;
  }

  PendingTasksCompanion toCompanion(bool nullToAbsent) {
    return PendingTasksCompanion(
      id: Value(id),
      userId: Value(userId),
      localTaskId: Value(localTaskId),
      payload: Value(payload),
      queuedAt: Value(queuedAt),
    );
  }

  factory PendingTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingTask(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      localTaskId: serializer.fromJson<int>(json['localTaskId']),
      payload: serializer.fromJson<String>(json['payload']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'localTaskId': serializer.toJson<int>(localTaskId),
      'payload': serializer.toJson<String>(payload),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
    };
  }

  PendingTask copyWith({
    int? id,
    int? userId,
    int? localTaskId,
    String? payload,
    DateTime? queuedAt,
  }) => PendingTask(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    localTaskId: localTaskId ?? this.localTaskId,
    payload: payload ?? this.payload,
    queuedAt: queuedAt ?? this.queuedAt,
  );
  PendingTask copyWithCompanion(PendingTasksCompanion data) {
    return PendingTask(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      localTaskId: data.localTaskId.present
          ? data.localTaskId.value
          : this.localTaskId,
      payload: data.payload.present ? data.payload.value : this.payload,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingTask(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('localTaskId: $localTaskId, ')
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, localTaskId, payload, queuedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingTask &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.localTaskId == this.localTaskId &&
          other.payload == this.payload &&
          other.queuedAt == this.queuedAt);
}

class PendingTasksCompanion extends UpdateCompanion<PendingTask> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int> localTaskId;
  final Value<String> payload;
  final Value<DateTime> queuedAt;
  const PendingTasksCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.localTaskId = const Value.absent(),
    this.payload = const Value.absent(),
    this.queuedAt = const Value.absent(),
  });
  PendingTasksCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required int localTaskId,
    required String payload,
    this.queuedAt = const Value.absent(),
  }) : userId = Value(userId),
       localTaskId = Value(localTaskId),
       payload = Value(payload);
  static Insertable<PendingTask> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? localTaskId,
    Expression<String>? payload,
    Expression<DateTime>? queuedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (localTaskId != null) 'local_task_id': localTaskId,
      if (payload != null) 'payload': payload,
      if (queuedAt != null) 'queued_at': queuedAt,
    });
  }

  PendingTasksCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int>? localTaskId,
    Value<String>? payload,
    Value<DateTime>? queuedAt,
  }) {
    return PendingTasksCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      localTaskId: localTaskId ?? this.localTaskId,
      payload: payload ?? this.payload,
      queuedAt: queuedAt ?? this.queuedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (localTaskId.present) {
      map['local_task_id'] = Variable<int>(localTaskId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingTasksCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('localTaskId: $localTaskId, ')
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedRemindersTable extends CachedReminders
    with TableInfo<$CachedRemindersTable, CachedReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remindAtMeta = const VerificationMeta(
    'remindAt',
  );
  @override
  late final GeneratedColumn<String> remindAt = GeneratedColumn<String>(
    'remind_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueTimeMeta = const VerificationMeta(
    'dueTime',
  );
  @override
  late final GeneratedColumn<String> dueTime = GeneratedColumn<String>(
    'due_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _repeatIntervalMeta = const VerificationMeta(
    'repeatInterval',
  );
  @override
  late final GeneratedColumn<String> repeatInterval = GeneratedColumn<String>(
    'repeat_interval',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('NONE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingMeta = const VerificationMeta(
    'isPending',
  );
  @override
  late final GeneratedColumn<bool> isPending = GeneratedColumn<bool>(
    'is_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    serverId,
    title,
    remindAt,
    dueDate,
    dueTime,
    category,
    status,
    repeatInterval,
    createdAt,
    updatedAt,
    isPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedReminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('remind_at')) {
      context.handle(
        _remindAtMeta,
        remindAt.isAcceptableOrUnknown(data['remind_at']!, _remindAtMeta),
      );
    } else if (isInserting) {
      context.missing(_remindAtMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('due_time')) {
      context.handle(
        _dueTimeMeta,
        dueTime.isAcceptableOrUnknown(data['due_time']!, _dueTimeMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('repeat_interval')) {
      context.handle(
        _repeatIntervalMeta,
        repeatInterval.isAcceptableOrUnknown(
          data['repeat_interval']!,
          _repeatIntervalMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_pending')) {
      context.handle(
        _isPendingMeta,
        isPending.isAcceptableOrUnknown(data['is_pending']!, _isPendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, serverId},
  ];
  @override
  CachedReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedReminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      remindAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remind_at'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      dueTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_time'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      repeatInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_interval'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      isPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending'],
      )!,
    );
  }

  @override
  $CachedRemindersTable createAlias(String alias) {
    return $CachedRemindersTable(attachedDatabase, alias);
  }
}

class CachedReminder extends DataClass implements Insertable<CachedReminder> {
  final int id;
  final int userId;
  final int? serverId;
  final String title;
  final String remindAt;
  final String? dueDate;
  final String? dueTime;
  final String? category;
  final String status;
  final String repeatInterval;
  final String? createdAt;
  final String? updatedAt;
  final bool isPending;
  const CachedReminder({
    required this.id,
    required this.userId,
    this.serverId,
    required this.title,
    required this.remindAt,
    this.dueDate,
    this.dueTime,
    this.category,
    required this.status,
    required this.repeatInterval,
    this.createdAt,
    this.updatedAt,
    required this.isPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['title'] = Variable<String>(title);
    map['remind_at'] = Variable<String>(remindAt);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || dueTime != null) {
      map['due_time'] = Variable<String>(dueTime);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['status'] = Variable<String>(status);
    map['repeat_interval'] = Variable<String>(repeatInterval);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['is_pending'] = Variable<bool>(isPending);
    return map;
  }

  CachedRemindersCompanion toCompanion(bool nullToAbsent) {
    return CachedRemindersCompanion(
      id: Value(id),
      userId: Value(userId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      title: Value(title),
      remindAt: Value(remindAt),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      dueTime: dueTime == null && nullToAbsent
          ? const Value.absent()
          : Value(dueTime),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      status: Value(status),
      repeatInterval: Value(repeatInterval),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isPending: Value(isPending),
    );
  }

  factory CachedReminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedReminder(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      title: serializer.fromJson<String>(json['title']),
      remindAt: serializer.fromJson<String>(json['remindAt']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      dueTime: serializer.fromJson<String?>(json['dueTime']),
      category: serializer.fromJson<String?>(json['category']),
      status: serializer.fromJson<String>(json['status']),
      repeatInterval: serializer.fromJson<String>(json['repeatInterval']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
      isPending: serializer.fromJson<bool>(json['isPending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'serverId': serializer.toJson<int?>(serverId),
      'title': serializer.toJson<String>(title),
      'remindAt': serializer.toJson<String>(remindAt),
      'dueDate': serializer.toJson<String?>(dueDate),
      'dueTime': serializer.toJson<String?>(dueTime),
      'category': serializer.toJson<String?>(category),
      'status': serializer.toJson<String>(status),
      'repeatInterval': serializer.toJson<String>(repeatInterval),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
      'isPending': serializer.toJson<bool>(isPending),
    };
  }

  CachedReminder copyWith({
    int? id,
    int? userId,
    Value<int?> serverId = const Value.absent(),
    String? title,
    String? remindAt,
    Value<String?> dueDate = const Value.absent(),
    Value<String?> dueTime = const Value.absent(),
    Value<String?> category = const Value.absent(),
    String? status,
    String? repeatInterval,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    bool? isPending,
  }) => CachedReminder(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    serverId: serverId.present ? serverId.value : this.serverId,
    title: title ?? this.title,
    remindAt: remindAt ?? this.remindAt,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    dueTime: dueTime.present ? dueTime.value : this.dueTime,
    category: category.present ? category.value : this.category,
    status: status ?? this.status,
    repeatInterval: repeatInterval ?? this.repeatInterval,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isPending: isPending ?? this.isPending,
  );
  CachedReminder copyWithCompanion(CachedRemindersCompanion data) {
    return CachedReminder(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      title: data.title.present ? data.title.value : this.title,
      remindAt: data.remindAt.present ? data.remindAt.value : this.remindAt,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      dueTime: data.dueTime.present ? data.dueTime.value : this.dueTime,
      category: data.category.present ? data.category.value : this.category,
      status: data.status.present ? data.status.value : this.status,
      repeatInterval: data.repeatInterval.present
          ? data.repeatInterval.value
          : this.repeatInterval,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isPending: data.isPending.present ? data.isPending.value : this.isPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedReminder(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('remindAt: $remindAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTime: $dueTime, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('repeatInterval: $repeatInterval, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPending: $isPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    serverId,
    title,
    remindAt,
    dueDate,
    dueTime,
    category,
    status,
    repeatInterval,
    createdAt,
    updatedAt,
    isPending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedReminder &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.serverId == this.serverId &&
          other.title == this.title &&
          other.remindAt == this.remindAt &&
          other.dueDate == this.dueDate &&
          other.dueTime == this.dueTime &&
          other.category == this.category &&
          other.status == this.status &&
          other.repeatInterval == this.repeatInterval &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isPending == this.isPending);
}

class CachedRemindersCompanion extends UpdateCompanion<CachedReminder> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int?> serverId;
  final Value<String> title;
  final Value<String> remindAt;
  final Value<String?> dueDate;
  final Value<String?> dueTime;
  final Value<String?> category;
  final Value<String> status;
  final Value<String> repeatInterval;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<bool> isPending;
  const CachedRemindersCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.title = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
    this.repeatInterval = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isPending = const Value.absent(),
  });
  CachedRemindersCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    this.serverId = const Value.absent(),
    required String title,
    required String remindAt,
    this.dueDate = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
    this.repeatInterval = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isPending = const Value.absent(),
  }) : userId = Value(userId),
       title = Value(title),
       remindAt = Value(remindAt);
  static Insertable<CachedReminder> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? serverId,
    Expression<String>? title,
    Expression<String>? remindAt,
    Expression<String>? dueDate,
    Expression<String>? dueTime,
    Expression<String>? category,
    Expression<String>? status,
    Expression<String>? repeatInterval,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<bool>? isPending,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (serverId != null) 'server_id': serverId,
      if (title != null) 'title': title,
      if (remindAt != null) 'remind_at': remindAt,
      if (dueDate != null) 'due_date': dueDate,
      if (dueTime != null) 'due_time': dueTime,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (repeatInterval != null) 'repeat_interval': repeatInterval,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isPending != null) 'is_pending': isPending,
    });
  }

  CachedRemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int?>? serverId,
    Value<String>? title,
    Value<String>? remindAt,
    Value<String?>? dueDate,
    Value<String?>? dueTime,
    Value<String?>? category,
    Value<String>? status,
    Value<String>? repeatInterval,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<bool>? isPending,
  }) {
    return CachedRemindersCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      remindAt: remindAt ?? this.remindAt,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      category: category ?? this.category,
      status: status ?? this.status,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPending: isPending ?? this.isPending,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<String>(remindAt.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (dueTime.present) {
      map['due_time'] = Variable<String>(dueTime.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (repeatInterval.present) {
      map['repeat_interval'] = Variable<String>(repeatInterval.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (isPending.present) {
      map['is_pending'] = Variable<bool>(isPending.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedRemindersCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('remindAt: $remindAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTime: $dueTime, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('repeatInterval: $repeatInterval, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPending: $isPending')
          ..write(')'))
        .toString();
  }
}

class $PendingRemindersTable extends PendingReminders
    with TableInfo<$PendingRemindersTable, PendingReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localReminderIdMeta = const VerificationMeta(
    'localReminderId',
  );
  @override
  late final GeneratedColumn<int> localReminderId = GeneratedColumn<int>(
    'local_reminder_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    localReminderId,
    payload,
    queuedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingReminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('local_reminder_id')) {
      context.handle(
        _localReminderIdMeta,
        localReminderId.isAcceptableOrUnknown(
          data['local_reminder_id']!,
          _localReminderIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localReminderIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {localReminderId},
  ];
  @override
  PendingReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingReminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      localReminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_reminder_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
    );
  }

  @override
  $PendingRemindersTable createAlias(String alias) {
    return $PendingRemindersTable(attachedDatabase, alias);
  }
}

class PendingReminder extends DataClass implements Insertable<PendingReminder> {
  final int id;
  final int userId;
  final int localReminderId;
  final String payload;
  final DateTime queuedAt;
  const PendingReminder({
    required this.id,
    required this.userId,
    required this.localReminderId,
    required this.payload,
    required this.queuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['local_reminder_id'] = Variable<int>(localReminderId);
    map['payload'] = Variable<String>(payload);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    return map;
  }

  PendingRemindersCompanion toCompanion(bool nullToAbsent) {
    return PendingRemindersCompanion(
      id: Value(id),
      userId: Value(userId),
      localReminderId: Value(localReminderId),
      payload: Value(payload),
      queuedAt: Value(queuedAt),
    );
  }

  factory PendingReminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingReminder(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      localReminderId: serializer.fromJson<int>(json['localReminderId']),
      payload: serializer.fromJson<String>(json['payload']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'localReminderId': serializer.toJson<int>(localReminderId),
      'payload': serializer.toJson<String>(payload),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
    };
  }

  PendingReminder copyWith({
    int? id,
    int? userId,
    int? localReminderId,
    String? payload,
    DateTime? queuedAt,
  }) => PendingReminder(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    localReminderId: localReminderId ?? this.localReminderId,
    payload: payload ?? this.payload,
    queuedAt: queuedAt ?? this.queuedAt,
  );
  PendingReminder copyWithCompanion(PendingRemindersCompanion data) {
    return PendingReminder(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      localReminderId: data.localReminderId.present
          ? data.localReminderId.value
          : this.localReminderId,
      payload: data.payload.present ? data.payload.value : this.payload,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingReminder(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('localReminderId: $localReminderId, ')
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, localReminderId, payload, queuedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingReminder &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.localReminderId == this.localReminderId &&
          other.payload == this.payload &&
          other.queuedAt == this.queuedAt);
}

class PendingRemindersCompanion extends UpdateCompanion<PendingReminder> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int> localReminderId;
  final Value<String> payload;
  final Value<DateTime> queuedAt;
  const PendingRemindersCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.localReminderId = const Value.absent(),
    this.payload = const Value.absent(),
    this.queuedAt = const Value.absent(),
  });
  PendingRemindersCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required int localReminderId,
    required String payload,
    this.queuedAt = const Value.absent(),
  }) : userId = Value(userId),
       localReminderId = Value(localReminderId),
       payload = Value(payload);
  static Insertable<PendingReminder> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? localReminderId,
    Expression<String>? payload,
    Expression<DateTime>? queuedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (localReminderId != null) 'local_reminder_id': localReminderId,
      if (payload != null) 'payload': payload,
      if (queuedAt != null) 'queued_at': queuedAt,
    });
  }

  PendingRemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int>? localReminderId,
    Value<String>? payload,
    Value<DateTime>? queuedAt,
  }) {
    return PendingRemindersCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      localReminderId: localReminderId ?? this.localReminderId,
      payload: payload ?? this.payload,
      queuedAt: queuedAt ?? this.queuedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (localReminderId.present) {
      map['local_reminder_id'] = Variable<int>(localReminderId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingRemindersCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('localReminderId: $localReminderId, ')
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedNotesTable cachedNotes = $CachedNotesTable(this);
  late final $PendingNotesTable pendingNotes = $PendingNotesTable(this);
  late final $CachedProfilesTable cachedProfiles = $CachedProfilesTable(this);
  late final $CachedTasksTable cachedTasks = $CachedTasksTable(this);
  late final $PendingTasksTable pendingTasks = $PendingTasksTable(this);
  late final $CachedRemindersTable cachedReminders = $CachedRemindersTable(
    this,
  );
  late final $PendingRemindersTable pendingReminders = $PendingRemindersTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedNotes,
    pendingNotes,
    cachedProfiles,
    cachedTasks,
    pendingTasks,
    cachedReminders,
    pendingReminders,
  ];
}

typedef $$CachedNotesTableCreateCompanionBuilder =
    CachedNotesCompanion Function({
      Value<int> id,
      required int userId,
      Value<int?> serverId,
      required String title,
      required String content,
      Value<String?> category,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<String?> tags,
      Value<bool> pinned,
      Value<bool> isPending,
    });
typedef $$CachedNotesTableUpdateCompanionBuilder =
    CachedNotesCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int?> serverId,
      Value<String> title,
      Value<String> content,
      Value<String?> category,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<String?> tags,
      Value<bool> pinned,
      Value<bool> isPending,
    });

class $$CachedNotesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedNotesTable> {
  $$CachedNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPending => $composableBuilder(
    column: $table.isPending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedNotesTable> {
  $$CachedNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPending => $composableBuilder(
    column: $table.isPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedNotesTable> {
  $$CachedNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<bool> get isPending =>
      $composableBuilder(column: $table.isPending, builder: (column) => column);
}

class $$CachedNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedNotesTable,
          CachedNote,
          $$CachedNotesTableFilterComposer,
          $$CachedNotesTableOrderingComposer,
          $$CachedNotesTableAnnotationComposer,
          $$CachedNotesTableCreateCompanionBuilder,
          $$CachedNotesTableUpdateCompanionBuilder,
          (
            CachedNote,
            BaseReferences<_$AppDatabase, $CachedNotesTable, CachedNote>,
          ),
          CachedNote,
          PrefetchHooks Function()
        > {
  $$CachedNotesTableTableManager(_$AppDatabase db, $CachedNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<bool> isPending = const Value.absent(),
              }) => CachedNotesCompanion(
                id: id,
                userId: userId,
                serverId: serverId,
                title: title,
                content: content,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                tags: tags,
                pinned: pinned,
                isPending: isPending,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                Value<int?> serverId = const Value.absent(),
                required String title,
                required String content,
                Value<String?> category = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<bool> isPending = const Value.absent(),
              }) => CachedNotesCompanion.insert(
                id: id,
                userId: userId,
                serverId: serverId,
                title: title,
                content: content,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                tags: tags,
                pinned: pinned,
                isPending: isPending,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedNotesTable, CachedNote>(table),
                  BaseReferences<_$AppDatabase, $CachedNotesTable, CachedNote>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedNotesTable,
      CachedNote,
      $$CachedNotesTableFilterComposer,
      $$CachedNotesTableOrderingComposer,
      $$CachedNotesTableAnnotationComposer,
      $$CachedNotesTableCreateCompanionBuilder,
      $$CachedNotesTableUpdateCompanionBuilder,
      (
        CachedNote,
        BaseReferences<_$AppDatabase, $CachedNotesTable, CachedNote>,
      ),
      CachedNote,
      PrefetchHooks Function()
    >;
typedef $$PendingNotesTableCreateCompanionBuilder =
    PendingNotesCompanion Function({
      Value<int> id,
      required int userId,
      required int localNoteId,
      required String payload,
      Value<DateTime> queuedAt,
    });
typedef $$PendingNotesTableUpdateCompanionBuilder =
    PendingNotesCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int> localNoteId,
      Value<String> payload,
      Value<DateTime> queuedAt,
    });

class $$PendingNotesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingNotesTable> {
  $$PendingNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localNoteId => $composableBuilder(
    column: $table.localNoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingNotesTable> {
  $$PendingNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localNoteId => $composableBuilder(
    column: $table.localNoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingNotesTable> {
  $$PendingNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get localNoteId => $composableBuilder(
    column: $table.localNoteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);
}

class $$PendingNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingNotesTable,
          PendingNote,
          $$PendingNotesTableFilterComposer,
          $$PendingNotesTableOrderingComposer,
          $$PendingNotesTableAnnotationComposer,
          $$PendingNotesTableCreateCompanionBuilder,
          $$PendingNotesTableUpdateCompanionBuilder,
          (
            PendingNote,
            BaseReferences<_$AppDatabase, $PendingNotesTable, PendingNote>,
          ),
          PendingNote,
          PrefetchHooks Function()
        > {
  $$PendingNotesTableTableManager(_$AppDatabase db, $PendingNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int> localNoteId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
              }) => PendingNotesCompanion(
                id: id,
                userId: userId,
                localNoteId: localNoteId,
                payload: payload,
                queuedAt: queuedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required int localNoteId,
                required String payload,
                Value<DateTime> queuedAt = const Value.absent(),
              }) => PendingNotesCompanion.insert(
                id: id,
                userId: userId,
                localNoteId: localNoteId,
                payload: payload,
                queuedAt: queuedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingNotesTable, PendingNote>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingNotesTable,
                    PendingNote
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingNotesTable,
      PendingNote,
      $$PendingNotesTableFilterComposer,
      $$PendingNotesTableOrderingComposer,
      $$PendingNotesTableAnnotationComposer,
      $$PendingNotesTableCreateCompanionBuilder,
      $$PendingNotesTableUpdateCompanionBuilder,
      (
        PendingNote,
        BaseReferences<_$AppDatabase, $PendingNotesTable, PendingNote>,
      ),
      PendingNote,
      PrefetchHooks Function()
    >;
typedef $$CachedProfilesTableCreateCompanionBuilder =
    CachedProfilesCompanion Function({
      Value<int> userId,
      Value<int?> profileId,
      Value<String?> name,
      Value<String?> email,
      Value<String?> mobile,
      Value<String?> gender,
    });
typedef $$CachedProfilesTableUpdateCompanionBuilder =
    CachedProfilesCompanion Function({
      Value<int> userId,
      Value<int?> profileId,
      Value<String?> name,
      Value<String?> email,
      Value<String?> mobile,
      Value<String?> gender,
    });

class $$CachedProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);
}

class $$CachedProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedProfilesTable,
          CachedProfile,
          $$CachedProfilesTableFilterComposer,
          $$CachedProfilesTableOrderingComposer,
          $$CachedProfilesTableAnnotationComposer,
          $$CachedProfilesTableCreateCompanionBuilder,
          $$CachedProfilesTableUpdateCompanionBuilder,
          (
            CachedProfile,
            BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
          ),
          CachedProfile,
          PrefetchHooks Function()
        > {
  $$CachedProfilesTableTableManager(
    _$AppDatabase db,
    $CachedProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<int?> profileId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<String?> gender = const Value.absent(),
              }) => CachedProfilesCompanion(
                userId: userId,
                profileId: profileId,
                name: name,
                email: email,
                mobile: mobile,
                gender: gender,
              ),
          createCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<int?> profileId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<String?> gender = const Value.absent(),
              }) => CachedProfilesCompanion.insert(
                userId: userId,
                profileId: profileId,
                name: name,
                email: email,
                mobile: mobile,
                gender: gender,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedProfilesTable, CachedProfile>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedProfilesTable,
                    CachedProfile
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedProfilesTable,
      CachedProfile,
      $$CachedProfilesTableFilterComposer,
      $$CachedProfilesTableOrderingComposer,
      $$CachedProfilesTableAnnotationComposer,
      $$CachedProfilesTableCreateCompanionBuilder,
      $$CachedProfilesTableUpdateCompanionBuilder,
      (
        CachedProfile,
        BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
      ),
      CachedProfile,
      PrefetchHooks Function()
    >;
typedef $$CachedTasksTableCreateCompanionBuilder =
    CachedTasksCompanion Function({
      Value<int> id,
      required int userId,
      Value<int?> serverId,
      required String title,
      Value<String?> description,
      Value<String?> dueDate,
      Value<String?> dueTime,
      Value<String?> category,
      Value<String> priority,
      Value<String> status,
      Value<bool> isCompleted,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<bool> isPending,
    });
typedef $$CachedTasksTableUpdateCompanionBuilder =
    CachedTasksCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int?> serverId,
      Value<String> title,
      Value<String?> description,
      Value<String?> dueDate,
      Value<String?> dueTime,
      Value<String?> category,
      Value<String> priority,
      Value<String> status,
      Value<bool> isCompleted,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<bool> isPending,
    });

class $$CachedTasksTableFilterComposer
    extends Composer<_$AppDatabase, $CachedTasksTable> {
  $$CachedTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPending => $composableBuilder(
    column: $table.isPending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedTasksTable> {
  $$CachedTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPending => $composableBuilder(
    column: $table.isPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedTasksTable> {
  $$CachedTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get dueTime =>
      $composableBuilder(column: $table.dueTime, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isPending =>
      $composableBuilder(column: $table.isPending, builder: (column) => column);
}

class $$CachedTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedTasksTable,
          CachedTask,
          $$CachedTasksTableFilterComposer,
          $$CachedTasksTableOrderingComposer,
          $$CachedTasksTableAnnotationComposer,
          $$CachedTasksTableCreateCompanionBuilder,
          $$CachedTasksTableUpdateCompanionBuilder,
          (
            CachedTask,
            BaseReferences<_$AppDatabase, $CachedTasksTable, CachedTask>,
          ),
          CachedTask,
          PrefetchHooks Function()
        > {
  $$CachedTasksTableTableManager(_$AppDatabase db, $CachedTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<String?> dueTime = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<bool> isPending = const Value.absent(),
              }) => CachedTasksCompanion(
                id: id,
                userId: userId,
                serverId: serverId,
                title: title,
                description: description,
                dueDate: dueDate,
                dueTime: dueTime,
                category: category,
                priority: priority,
                status: status,
                isCompleted: isCompleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isPending: isPending,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                Value<int?> serverId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<String?> dueTime = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<bool> isPending = const Value.absent(),
              }) => CachedTasksCompanion.insert(
                id: id,
                userId: userId,
                serverId: serverId,
                title: title,
                description: description,
                dueDate: dueDate,
                dueTime: dueTime,
                category: category,
                priority: priority,
                status: status,
                isCompleted: isCompleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isPending: isPending,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedTasksTable, CachedTask>(table),
                  BaseReferences<_$AppDatabase, $CachedTasksTable, CachedTask>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedTasksTable,
      CachedTask,
      $$CachedTasksTableFilterComposer,
      $$CachedTasksTableOrderingComposer,
      $$CachedTasksTableAnnotationComposer,
      $$CachedTasksTableCreateCompanionBuilder,
      $$CachedTasksTableUpdateCompanionBuilder,
      (
        CachedTask,
        BaseReferences<_$AppDatabase, $CachedTasksTable, CachedTask>,
      ),
      CachedTask,
      PrefetchHooks Function()
    >;
typedef $$PendingTasksTableCreateCompanionBuilder =
    PendingTasksCompanion Function({
      Value<int> id,
      required int userId,
      required int localTaskId,
      required String payload,
      Value<DateTime> queuedAt,
    });
typedef $$PendingTasksTableUpdateCompanionBuilder =
    PendingTasksCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int> localTaskId,
      Value<String> payload,
      Value<DateTime> queuedAt,
    });

class $$PendingTasksTableFilterComposer
    extends Composer<_$AppDatabase, $PendingTasksTable> {
  $$PendingTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localTaskId => $composableBuilder(
    column: $table.localTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingTasksTable> {
  $$PendingTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localTaskId => $composableBuilder(
    column: $table.localTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingTasksTable> {
  $$PendingTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get localTaskId => $composableBuilder(
    column: $table.localTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);
}

class $$PendingTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingTasksTable,
          PendingTask,
          $$PendingTasksTableFilterComposer,
          $$PendingTasksTableOrderingComposer,
          $$PendingTasksTableAnnotationComposer,
          $$PendingTasksTableCreateCompanionBuilder,
          $$PendingTasksTableUpdateCompanionBuilder,
          (
            PendingTask,
            BaseReferences<_$AppDatabase, $PendingTasksTable, PendingTask>,
          ),
          PendingTask,
          PrefetchHooks Function()
        > {
  $$PendingTasksTableTableManager(_$AppDatabase db, $PendingTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int> localTaskId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
              }) => PendingTasksCompanion(
                id: id,
                userId: userId,
                localTaskId: localTaskId,
                payload: payload,
                queuedAt: queuedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required int localTaskId,
                required String payload,
                Value<DateTime> queuedAt = const Value.absent(),
              }) => PendingTasksCompanion.insert(
                id: id,
                userId: userId,
                localTaskId: localTaskId,
                payload: payload,
                queuedAt: queuedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingTasksTable, PendingTask>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingTasksTable,
                    PendingTask
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingTasksTable,
      PendingTask,
      $$PendingTasksTableFilterComposer,
      $$PendingTasksTableOrderingComposer,
      $$PendingTasksTableAnnotationComposer,
      $$PendingTasksTableCreateCompanionBuilder,
      $$PendingTasksTableUpdateCompanionBuilder,
      (
        PendingTask,
        BaseReferences<_$AppDatabase, $PendingTasksTable, PendingTask>,
      ),
      PendingTask,
      PrefetchHooks Function()
    >;
typedef $$CachedRemindersTableCreateCompanionBuilder =
    CachedRemindersCompanion Function({
      Value<int> id,
      required int userId,
      Value<int?> serverId,
      required String title,
      required String remindAt,
      Value<String?> dueDate,
      Value<String?> dueTime,
      Value<String?> category,
      Value<String> status,
      Value<String> repeatInterval,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<bool> isPending,
    });
typedef $$CachedRemindersTableUpdateCompanionBuilder =
    CachedRemindersCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int?> serverId,
      Value<String> title,
      Value<String> remindAt,
      Value<String?> dueDate,
      Value<String?> dueTime,
      Value<String?> category,
      Value<String> status,
      Value<String> repeatInterval,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<bool> isPending,
    });

class $$CachedRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $CachedRemindersTable> {
  $$CachedRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatInterval => $composableBuilder(
    column: $table.repeatInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPending => $composableBuilder(
    column: $table.isPending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedRemindersTable> {
  $$CachedRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatInterval => $composableBuilder(
    column: $table.repeatInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPending => $composableBuilder(
    column: $table.isPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedRemindersTable> {
  $$CachedRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get remindAt =>
      $composableBuilder(column: $table.remindAt, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get dueTime =>
      $composableBuilder(column: $table.dueTime, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get repeatInterval => $composableBuilder(
    column: $table.repeatInterval,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isPending =>
      $composableBuilder(column: $table.isPending, builder: (column) => column);
}

class $$CachedRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedRemindersTable,
          CachedReminder,
          $$CachedRemindersTableFilterComposer,
          $$CachedRemindersTableOrderingComposer,
          $$CachedRemindersTableAnnotationComposer,
          $$CachedRemindersTableCreateCompanionBuilder,
          $$CachedRemindersTableUpdateCompanionBuilder,
          (
            CachedReminder,
            BaseReferences<
              _$AppDatabase,
              $CachedRemindersTable,
              CachedReminder
            >,
          ),
          CachedReminder,
          PrefetchHooks Function()
        > {
  $$CachedRemindersTableTableManager(
    _$AppDatabase db,
    $CachedRemindersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> remindAt = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<String?> dueTime = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> repeatInterval = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<bool> isPending = const Value.absent(),
              }) => CachedRemindersCompanion(
                id: id,
                userId: userId,
                serverId: serverId,
                title: title,
                remindAt: remindAt,
                dueDate: dueDate,
                dueTime: dueTime,
                category: category,
                status: status,
                repeatInterval: repeatInterval,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isPending: isPending,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                Value<int?> serverId = const Value.absent(),
                required String title,
                required String remindAt,
                Value<String?> dueDate = const Value.absent(),
                Value<String?> dueTime = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> repeatInterval = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<bool> isPending = const Value.absent(),
              }) => CachedRemindersCompanion.insert(
                id: id,
                userId: userId,
                serverId: serverId,
                title: title,
                remindAt: remindAt,
                dueDate: dueDate,
                dueTime: dueTime,
                category: category,
                status: status,
                repeatInterval: repeatInterval,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isPending: isPending,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedRemindersTable, CachedReminder>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedRemindersTable,
                    CachedReminder
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedRemindersTable,
      CachedReminder,
      $$CachedRemindersTableFilterComposer,
      $$CachedRemindersTableOrderingComposer,
      $$CachedRemindersTableAnnotationComposer,
      $$CachedRemindersTableCreateCompanionBuilder,
      $$CachedRemindersTableUpdateCompanionBuilder,
      (
        CachedReminder,
        BaseReferences<_$AppDatabase, $CachedRemindersTable, CachedReminder>,
      ),
      CachedReminder,
      PrefetchHooks Function()
    >;
typedef $$PendingRemindersTableCreateCompanionBuilder =
    PendingRemindersCompanion Function({
      Value<int> id,
      required int userId,
      required int localReminderId,
      required String payload,
      Value<DateTime> queuedAt,
    });
typedef $$PendingRemindersTableUpdateCompanionBuilder =
    PendingRemindersCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int> localReminderId,
      Value<String> payload,
      Value<DateTime> queuedAt,
    });

class $$PendingRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $PendingRemindersTable> {
  $$PendingRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localReminderId => $composableBuilder(
    column: $table.localReminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingRemindersTable> {
  $$PendingRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localReminderId => $composableBuilder(
    column: $table.localReminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingRemindersTable> {
  $$PendingRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get localReminderId => $composableBuilder(
    column: $table.localReminderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);
}

class $$PendingRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingRemindersTable,
          PendingReminder,
          $$PendingRemindersTableFilterComposer,
          $$PendingRemindersTableOrderingComposer,
          $$PendingRemindersTableAnnotationComposer,
          $$PendingRemindersTableCreateCompanionBuilder,
          $$PendingRemindersTableUpdateCompanionBuilder,
          (
            PendingReminder,
            BaseReferences<
              _$AppDatabase,
              $PendingRemindersTable,
              PendingReminder
            >,
          ),
          PendingReminder,
          PrefetchHooks Function()
        > {
  $$PendingRemindersTableTableManager(
    _$AppDatabase db,
    $PendingRemindersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int> localReminderId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
              }) => PendingRemindersCompanion(
                id: id,
                userId: userId,
                localReminderId: localReminderId,
                payload: payload,
                queuedAt: queuedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required int localReminderId,
                required String payload,
                Value<DateTime> queuedAt = const Value.absent(),
              }) => PendingRemindersCompanion.insert(
                id: id,
                userId: userId,
                localReminderId: localReminderId,
                payload: payload,
                queuedAt: queuedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingRemindersTable, PendingReminder>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingRemindersTable,
                    PendingReminder
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingRemindersTable,
      PendingReminder,
      $$PendingRemindersTableFilterComposer,
      $$PendingRemindersTableOrderingComposer,
      $$PendingRemindersTableAnnotationComposer,
      $$PendingRemindersTableCreateCompanionBuilder,
      $$PendingRemindersTableUpdateCompanionBuilder,
      (
        PendingReminder,
        BaseReferences<_$AppDatabase, $PendingRemindersTable, PendingReminder>,
      ),
      PendingReminder,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedNotesTableTableManager get cachedNotes =>
      $$CachedNotesTableTableManager(_db, _db.cachedNotes);
  $$PendingNotesTableTableManager get pendingNotes =>
      $$PendingNotesTableTableManager(_db, _db.pendingNotes);
  $$CachedProfilesTableTableManager get cachedProfiles =>
      $$CachedProfilesTableTableManager(_db, _db.cachedProfiles);
  $$CachedTasksTableTableManager get cachedTasks =>
      $$CachedTasksTableTableManager(_db, _db.cachedTasks);
  $$PendingTasksTableTableManager get pendingTasks =>
      $$PendingTasksTableTableManager(_db, _db.pendingTasks);
  $$CachedRemindersTableTableManager get cachedReminders =>
      $$CachedRemindersTableTableManager(_db, _db.cachedReminders);
  $$PendingRemindersTableTableManager get pendingReminders =>
      $$PendingRemindersTableTableManager(_db, _db.pendingReminders);
}
