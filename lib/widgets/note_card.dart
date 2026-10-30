import 'package:flutter/material.dart';

import '../models/note.dart';
import '../util/text.dart';
import 'note_bits.dart';

export 'note_bits.dart' show CategoryLabel;

/// A note in the list: category icon, title and category, a preview, then the reminder (if any)
/// or when it was last changed. Notes with a reminder get a round "done" check.
class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, required this.onTap, required this.onLongPress, this.onToggleDone});

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onToggleDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final preview = note.preview;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryBadge(note.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            note.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: note.done ? TextDecoration.lineThrough : null,
                              color: note.done ? muted : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(padding: const EdgeInsets.only(top: 2, right: 8), child: CategoryLabel(note.category)),
                      ],
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.35),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (note.hasDue)
                      DueLabel(note: note)
                    else
                      Text(formatRelative(note.updatedAt), style: theme.textTheme.labelSmall?.copyWith(color: muted)),
                  ],
                ),
              ),
              if (note.hasDue && onToggleDone != null) DoneToggle(note: note, onToggle: onToggleDone!),
            ],
          ),
        ),
      ),
    );
  }
}
