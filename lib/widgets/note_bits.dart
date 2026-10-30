import 'package:flutter/material.dart';

import '../models/category_style.dart';
import '../models/note.dart';
import '../util/text.dart';

/// The round, coloured category icon used in lists and on the timeline.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge(this.category, {super.key, this.size = 40, this.solid = false});

  final String category;
  final double size;

  /// Filled with the category colour (timeline) instead of a light tint (lists).
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: solid ? style.color : style.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(style.icon, size: size * 0.5, color: solid ? Colors.white : style.color),
    );
  }
}

/// The category name in its colour.
class CategoryLabel extends StatelessWidget {
  const CategoryLabel(this.category, {super.key});

  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      category,
      style: theme.textTheme.labelMedium?.copyWith(color: _readable(categoryStyle(category).color, theme)),
    );
  }
}

/// Category colours are bright; on a light background darken them a little so text stays readable.
Color _readable(Color color, ThemeData theme) {
  if (theme.brightness == Brightness.dark) return color;
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
}

/// The round "done" check from the timeline design. Tapping it ticks the note off (or back on).
class DoneToggle extends StatelessWidget {
  const DoneToggle({super.key, required this.note, required this.onToggle});

  final Note note;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = categoryStyle(note.category).color;
    return IconButton(
      tooltip: note.done ? 'Tamamlanmadı olarak işaretle' : 'Tamamlandı olarak işaretle',
      onPressed: onToggle,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: note.done ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
        ),
        child: note.done ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
      ),
    );
  }
}

/// "Yarın 14:00 · Yarın" style reminder line, red when overdue.
class DueLabel extends StatelessWidget {
  const DueLabel({super.key, required this.note, this.now});

  final Note note;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = now ?? DateTime.now();
    final due = note.dueAt!;
    final overdue = note.isOverdue(t);
    final today = !note.done && isSameDay(due, t);
    final color = overdue
        ? theme.colorScheme.error
        : today
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final countdown = note.done ? 'Tamamlandı' : formatCountdown(due, now: t);
    final when = formatDue(due, now: t);
    final text = countdown == 'Bugün' || countdown == 'Yarın' ? when : '$when · $countdown';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(note.done ? Icons.check_circle_outline : Icons.alarm, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: overdue ? FontWeight.w700 : null),
          ),
        ),
      ],
    );
  }
}

/// A calendar-page tile: short month on top, day number below ("KAS / 2").
class DateTile extends StatelessWidget {
  const DateTile({super.key, required this.date, required this.color, this.size = 48});

  final DateTime date;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size + 4,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            shortMonthUpper(date),
            style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          Text('${date.day}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
        ],
      ),
    );
  }
}
