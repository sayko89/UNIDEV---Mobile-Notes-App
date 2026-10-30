import 'package:flutter/material.dart';

import '../models/category_style.dart';
import '../models/note.dart';
import '../notes_controller.dart';
import '../util/text.dart';
import '../widgets/note_actions.dart';
import '../widgets/note_bits.dart';

/// Month calendar with a coloured dot for every reminder, and the selected day's notes on a
/// timeline below.
class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key, required this.controller});

  final NotesController controller;

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late DateTime _month; // first day of the month on screen
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _selected = today;
    _month = DateTime(today.year, today.month);
  }

  void _changeMonth(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  void _goToToday() {
    final today = dateOnly(DateTime.now());
    setState(() {
      _selected = today;
      _month = DateTime(today.year, today.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final dayNotes = widget.controller.notesOn(_selected);
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            children: [
              _monthHeader(context),
              const SizedBox(height: 8),
              Card(
                child: Padding(padding: const EdgeInsets.fromLTRB(8, 12, 8, 8), child: _monthGrid(context)),
              ),
              const SizedBox(height: 20),
              _dayHeader(context, dayNotes.length),
              const SizedBox(height: 8),
              if (dayNotes.isEmpty) _emptyDay(context) else _Timeline(controller: widget.controller, notes: dayNotes),
            ],
          ),
        );
      },
    );
  }

  Widget _monthHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatMonthTitle(_month),
              key: const Key('month-title'),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(onPressed: _goToToday, child: const Text('Bugün')),
          IconButton(tooltip: 'Önceki ay', onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
          IconButton(tooltip: 'Sonraki ay', onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }

  Widget _monthGrid(BuildContext context) {
    final theme = Theme.of(context);
    final today = dateOnly(DateTime.now());
    final offset = _month.weekday - 1; // Monday first
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((offset + daysInMonth) / 7).ceil();

    return Column(
      children: [
        Row(
          children: [
            for (final label in shortWeekdays)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _dayCell(context, DateTime(_month.year, _month.month, 1 + row * 7 + col - offset), today),
                ),
            ],
          ),
      ],
    );
  }

  Widget _dayCell(BuildContext context, DateTime day, DateTime today) {
    final theme = Theme.of(context);
    final inMonth = day.month == _month.month;
    final selected = isSameDay(day, _selected);
    final isToday = isSameDay(day, today);
    final notes = widget.controller.notesOn(day);
    final key = 'day-${day.year}-${day.month}-${day.day}';

    return InkWell(
      key: Key(key),
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() {
        _selected = day;
        if (!inMonth) _month = DateTime(day.year, day.month);
      }),
      child: SizedBox(
        height: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? theme.colorScheme.primary : null,
                border: isToday && !selected ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null,
              ),
              child: Text(
                '${day.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isToday || selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : inMonth
                      ? null
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final note in notes.take(3))
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: categoryStyle(note.category).color.withValues(alpha: note.done ? 0.35 : 1),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayHeader(BuildContext context, int count) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatDayTitle(_selected),
              key: const Key('selected-day'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (count > 0)
            Text(
              '$count not',
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _emptyDay(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [
            Icon(Icons.event_available_outlined, size: 40, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 8),
            Text('Bu gün için hatırlatma yok', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              key: const Key('add-note-on-day'),
              onPressed: () => openNoteEditor(
                context,
                widget.controller,
                initialDue: DateTime(_selected.year, _selected.month, _selected.day, 9),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Bu güne not ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The selected day's notes on a vertical timeline: time, coloured icon on a line, card, check.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.controller, required this.notes});

  final NotesController controller;
  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = theme.colorScheme.outlineVariant;
    return Column(
      children: [
        for (var i = 0; i < notes.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 52,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      formatTime(notes[i].dueAt!),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Column(
                    children: [
                      Container(width: 2, height: 6, color: i == 0 ? Colors.transparent : line),
                      CategoryBadge(notes[i].category, size: 40, solid: true),
                      Expanded(child: Container(width: 2, color: i == notes.length - 1 ? Colors.transparent : line)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TimelineCard(controller: controller, note: notes[i]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.controller, required this.note});

  final NotesController controller;
  final Note note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final overdue = note.isOverdue(DateTime.now());
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openNoteDetail(context, controller, note),
        onLongPress: () => showNoteMenu(context, controller, note),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overdue ? 'Gecikti · ${note.category}' : note.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: overdue ? theme.colorScheme.error : muted,
                        fontWeight: overdue ? FontWeight.w700 : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: note.done ? TextDecoration.lineThrough : null,
                        color: note.done ? muted : null,
                      ),
                    ),
                  ],
                ),
              ),
              DoneToggle(note: note, onToggle: () => controller.toggleDone(note)),
            ],
          ),
        ),
      ),
    );
  }
}
