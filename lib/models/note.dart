import 'package:flutter/foundation.dart';

/// A single note. Immutable: edits produce a new instance with [copyWith].
@immutable
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.dueAt,
    this.done = false,
  });

  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optional reminder date and time. Notes with a date appear in the calendar and in
  /// "Yaklaşanlar", and — on Android and iOS — trigger a notification.
  final DateTime? dueAt;

  /// Ticked off. Only meaningful for notes with a [dueAt].
  final bool done;

  bool get hasDue => dueAt != null;

  /// Has a date in the past and isn't done yet.
  bool isOverdue(DateTime now) => dueAt != null && !done && dueAt!.isBefore(now);

  /// The title, or — for notes saved without one — the first line of the content.
  String get displayTitle {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isNotEmpty) return trimmedTitle;
    final firstLine = content.trim().split('\n').first.trim();
    return firstLine.isEmpty ? 'Başlıksız not' : firstLine;
  }

  /// Text shown under the title in the list, on a single line.
  String get preview {
    final lines = content.trim().split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty);
    // When the first line is already used as the title, don't repeat it.
    final rest = title.trim().isEmpty ? lines.skip(1) : lines;
    return rest.join(' · ');
  }

  /// True when the note was changed after it was created.
  bool get wasEdited => updatedAt.difference(createdAt).inSeconds >= 1;

  /// [dueAt] is changed only when [setDue] is true, so that it can also be cleared (set to null).
  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    DateTime? updatedAt,
    bool setDue = false,
    DateTime? dueAt,
    bool? done,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueAt: setDue ? dueAt : this.dueAt,
      done: done ?? this.done,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.id == id &&
      other.title == title &&
      other.content == content &&
      other.category == category &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.dueAt == dueAt &&
      other.done == done;

  @override
  int get hashCode => Object.hash(id, title, content, category, createdAt, updatedAt, dueAt, done);

  @override
  String toString() => 'Note($id, "$displayTitle", $category${dueAt == null ? '' : ', due $dueAt'})';
}
