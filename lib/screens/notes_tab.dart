import 'package:flutter/material.dart';

import '../models/category_style.dart';
import '../models/note.dart';
import '../notes_controller.dart';
import '../util/text.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_actions.dart';
import '../widgets/note_bits.dart';
import '../widgets/note_card.dart';

/// The first tab: greeting, upcoming reminders, search, category filter and the note list.
class NotesTab extends StatefulWidget {
  const NotesTab({super.key, required this.controller, this.onShowUpcoming});

  final NotesController controller;

  /// Switches to the "Yaklaşanlar" tab.
  final VoidCallback? onShowUpcoming;

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  final _search = TextEditingController();

  NotesController get _controller => widget.controller;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    _controller.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final notes = _controller.visibleNotes;
        final now = DateTime.now();
        final soon = [..._controller.overdue(now: now), ..._controller.upcoming(now: now)].take(8).toList();
        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(context, now)),
              if (soon.isNotEmpty && !_controller.isFiltering) SliverToBoxAdapter(child: _upcomingStrip(context, soon)),
              SliverToBoxAdapter(child: _searchField()),
              SliverToBoxAdapter(child: _categoryFilter()),
              if (notes.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _emptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: notes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return NoteCard(
                        key: ValueKey('note-${note.id}'),
                        note: note,
                        onTap: () => openNoteDetail(context, _controller, note),
                        onLongPress: () => showNoteMenu(context, _controller, note),
                        onToggleDone: () => _controller.toggleDone(note),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, DateTime now) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${greeting(now)} · ${formatDayTitle(now)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text('Notlarım', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton.filled(
            key: const Key('add-note'),
            tooltip: 'Yeni not',
            iconSize: 28,
            onPressed: () => openNoteEditor(context, _controller),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  /// Horizontal cards for overdue and upcoming reminders, like the countdown cards in the
  /// design references.
  Widget _upcomingStrip(BuildContext context, List<Note> soon) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('Yaklaşanlar', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (widget.onShowUpcoming != null)
                TextButton(onPressed: widget.onShowUpcoming, child: const Text('Tümünü gör')),
            ],
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            key: const Key('upcoming-strip'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            itemCount: soon.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final note = soon[index];
              final overdue = note.isOverdue(now);
              return SizedBox(
                width: 216,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => openNoteDetail(context, _controller, note),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          DateTile(date: note.dueAt!, color: categoryStyle(note.category).color, size: 44),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.displayTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatCountdown(note.dueAt!, now: now),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: overdue ? theme.colorScheme.error : theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        key: const Key('search-field'),
        controller: _search,
        onChanged: _controller.setQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Notlarda ara',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _search.text.isEmpty
                  ? null
                  : IconButton(
                    tooltip: 'Aramayı temizle',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _search.clear();
                      _controller.setQuery('');
                    },
                  ),
        ),
      ),
    );
  }

  Widget _categoryFilter() {
    final selected = _controller.filter;
    Widget chip(String? category, String label) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          key: Key('filter-${category ?? 'all'}'),
          avatar:
              category == null
                  ? null
                  : Icon(categoryStyle(category).icon, size: 16, color: categoryStyle(category).color),
          label: Text('$label  ${_controller.count(category)}'),
          selected: selected == category,
          onSelected: (_) => _controller.setFilter(category),
        ),
      );
    }

    return SizedBox(
      height: 60,
      // A Row in a scroll view (rather than a lazy ListView) builds every chip, so they are all
      // reachable by screen readers and keyboard focus. There are only a handful.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
        child: Row(
          children: [chip(null, 'Tümü'), for (final category in _controller.categories) chip(category, category)],
        ),
      ),
    );
  }

  Widget _emptyState() {
    if (_controller.count() == 0) {
      return const EmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: 'Henüz not yok',
        message: 'Sağ üstteki + ile ilk notunu ekle.',
      );
    }
    return EmptyState(
      icon: Icons.search_off,
      title: 'Eşleşen not yok',
      message: 'Aramayı ya da kategori filtresini değiştir.',
      actionLabel: 'Filtreleri temizle',
      onAction: _clearFilters,
    );
  }
}
