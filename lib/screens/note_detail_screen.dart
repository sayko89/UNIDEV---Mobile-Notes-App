import 'package:flutter/material.dart';

import '../models/note.dart';
import '../notes_controller.dart';
import '../util/text.dart';
import '../widgets/note_actions.dart';
import '../widgets/note_bits.dart';

/// Shows a whole note. Follows edits made from the editor, because it listens to the controller.
class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, required this.controller, required this.noteId});

  final NotesController controller;
  final String noteId;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Note? _last; // keeps the page drawn while it closes after a delete

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final note = widget.controller.noteById(widget.noteId) ?? _last;
        if (note == null) return const Scaffold();
        _last = note;
        final theme = Theme.of(context);
        final muted = theme.colorScheme.onSurfaceVariant;

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: 'Düzenle',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => openNoteEditor(context, widget.controller, note: note),
              ),
              IconButton(
                tooltip: 'Sil',
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.of(context).pop();
                  deleteWithUndo(messenger, widget.controller, note);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Row(
                  children: [
                    CategoryBadge(note.category, size: 32),
                    const SizedBox(width: 10),
                    CategoryLabel(note.category),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  note.displayTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  note.wasEdited
                      ? 'Oluşturuldu ${formatFull(note.createdAt)}\nDüzenlendi ${formatFull(note.updatedAt)}'
                      : 'Oluşturuldu ${formatFull(note.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.5),
                ),
                if (note.hasDue) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      child: Row(
                        children: [
                          Expanded(child: DueLabel(note: note)),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            key: const Key('detail-toggle-done'),
                            onPressed: () => widget.controller.toggleDone(note),
                            icon: Icon(note.done ? Icons.undo : Icons.check),
                            label: Text(note.done ? 'Yeniden aç' : 'Tamamlandı'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Divider(height: 32),
                if (note.content.isEmpty)
                  Text('Bu notun içeriği yok.', style: theme.textTheme.bodyLarge?.copyWith(color: muted))
                else
                  SelectableText(note.content, style: theme.textTheme.bodyLarge?.copyWith(height: 1.55)),
              ],
            ),
          ),
        );
      },
    );
  }
}
