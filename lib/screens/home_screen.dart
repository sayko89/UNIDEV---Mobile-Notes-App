import 'package:flutter/material.dart';

import '../notes_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_actions.dart';
import '../widgets/note_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final NotesController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header(context)),
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
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Notlarım',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
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
          label: Text('$label  ${_controller.count(category)}'),
          selected: selected == category,
          onSelected: (_) => _controller.setFilter(category),
        ),
      );
    }

    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
        children: [chip(null, 'Tümü'), for (final category in _controller.categories) chip(category, category)],
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
