import 'package:flutter/material.dart';

import '../models/category_style.dart';
import '../models/note.dart';
import '../notes_controller.dart';
import '../util/text.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_actions.dart';
import '../widgets/note_bits.dart';

/// Every note with a reminder, grouped: overdue, today, tomorrow, this week, later, done.
class UpcomingTab extends StatelessWidget {
  const UpcomingTab({super.key, required this.controller});

  final NotesController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final now = DateTime.now();
        final overdue = controller.overdue(now: now);
        final upcoming = controller.upcoming(now: now);
        final done = controller.completed().take(10).toList();

        final groups = <(String, List<Note>)>[
          ('Gecikenler', overdue),
          ('Bugün', upcoming.where((n) => daysUntil(n.dueAt!, now) == 0).toList()),
          ('Yarın', upcoming.where((n) => daysUntil(n.dueAt!, now) == 1).toList()),
          ('Bu hafta', upcoming.where((n) => daysUntil(n.dueAt!, now) > 1 && daysUntil(n.dueAt!, now) < 7).toList()),
          ('Daha sonra', upcoming.where((n) => daysUntil(n.dueAt!, now) >= 7).toList()),
          ('Tamamlananlar', done),
        ].where((group) => group.$2.isNotEmpty).toList();

        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yaklaşanlar', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        upcoming.isEmpty && overdue.isEmpty
                            ? 'Bekleyen hatırlatma yok'
                            : '${upcoming.length + overdue.length} bekleyen hatırlatma'
                                  '${overdue.isEmpty ? '' : ', ${overdue.length} gecikmiş'}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              if (groups.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.alarm_off_outlined,
                    title: 'Yaklaşan hatırlatma yok',
                    message: 'Bir nota tarih ve saat eklediğinde burada geri sayımıyla görünür.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  sliver: SliverList.list(
                    children: [
                      for (final (title, notes) in groups) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                          child: Text(
                            title,
                            key: Key('group-$title'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: title == 'Gecikenler' ? theme.colorScheme.error : null,
                            ),
                          ),
                        ),
                        for (final note in notes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _UpcomingTile(controller: controller, note: note, now: now),
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.controller, required this.note, required this.now});

  final NotesController controller;
  final Note note;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final overdue = note.isOverdue(now);
    final countdown = note.done ? 'Tamamlandı' : formatCountdown(note.dueAt!, now: now);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openNoteDetail(context, controller, note),
        onLongPress: () => showNoteMenu(context, controller, note),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              DateTile(date: note.dueAt!, color: categoryStyle(note.category).color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: note.done ? TextDecoration.lineThrough : null,
                        color: note.done ? muted : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${note.category} · ${formatTime(note.dueAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      countdown,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: overdue
                            ? theme.colorScheme.error
                            : note.done
                            ? muted
                            : theme.colorScheme.primary,
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
