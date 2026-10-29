import 'package:flutter/material.dart';

import '../models/note.dart';
import '../util/text.dart';

/// A note in the list: title and category on top, a preview, then when it was last changed.
class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, required this.onTap, required this.onLongPress});

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

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
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
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
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CategoryLabel(note.category),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.35),
                ),
              ],
              const SizedBox(height: 10),
              Text(formatRelative(note.updatedAt), style: theme.textTheme.labelSmall?.copyWith(color: muted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The category name in the accent colour, as in the prototype.
class CategoryLabel extends StatelessWidget {
  const CategoryLabel(this.category, {super.key});

  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      category,
      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
    );
  }
}
