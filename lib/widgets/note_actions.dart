import 'package:flutter/material.dart';

import '../models/note.dart';
import '../notes_controller.dart';
import '../screens/note_detail_screen.dart';
import '../screens/note_edit_screen.dart';

/// Opens the editor for [note], or for a new note — optionally with a reminder already set
/// to [initialDue] (used by "Bu güne not ekle" in the calendar).
Future<void> openNoteEditor(BuildContext context, NotesController controller, {Note? note, DateTime? initialDue}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NoteEditScreen(controller: controller, note: note, initialDue: initialDue),
    ),
  );
}

Future<void> openNoteDetail(BuildContext context, NotesController controller, Note note) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => NoteDetailScreen(controller: controller, noteId: note.id)));
}

/// Deletes the note at once and offers "Geri al" (undo) — quicker than asking first,
/// and nothing is lost by a mistaken tap.
Future<void> deleteWithUndo(ScaffoldMessengerState messenger, NotesController controller, Note note) async {
  await controller.delete(note);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('"${note.displayTitle}" silindi'),
        action: SnackBarAction(label: 'Geri al', onPressed: () => controller.restore(note)),
      ),
    );
}

/// The long-press menu from the prototype: Düzenle / Sil.
Future<void> showNoteMenu(BuildContext context, NotesController controller, Note note) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    builder:
        (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  note.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheetContext).textTheme.titleSmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Düzenle'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  openNoteEditor(context, controller, note: note);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(sheetContext).colorScheme.error),
                title: Text('Sil', style: TextStyle(color: Theme.of(sheetContext).colorScheme.error)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  deleteWithUndo(messenger, controller, note);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
  );
}
