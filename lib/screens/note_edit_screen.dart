import 'package:flutter/material.dart';

import '../models/note.dart';
import '../notes_controller.dart';

/// Add a new note (when [note] is null) or edit an existing one.
class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, required this.controller, this.note});

  final NotesController controller;
  final Note? note;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final String _initialCategory;
  late String _category;
  String? _error;
  bool _closing = false;

  NotesController get _controller => widget.controller;
  bool get _isNew => widget.note == null;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title ?? '');
    _content = TextEditingController(text: widget.note?.content ?? '');
    // A new note starts in the category that is being filtered, if any.
    _initialCategory = widget.note?.category ?? _controller.filter ?? _controller.categories.first;
    _category = _initialCategory;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _title.text.trim() != (widget.note?.title ?? '') ||
      _content.text.trim() != (widget.note?.content ?? '') ||
      _category != _initialCategory;

  Future<void> _save() async {
    if (_title.text.trim().isEmpty && _content.text.trim().isEmpty) {
      setState(() => _error = 'Boş not kaydedilemez. Bir başlık ya da içerik yaz.');
      return;
    }
    final note = widget.note;
    if (note == null) {
      await _controller.create(title: _title.text, content: _content.text, category: _category);
    } else {
      await _controller.update(note, title: _title.text, content: _content.text, category: _category);
    }
    _close();
  }

  void _close() {
    if (!mounted) return;
    setState(() => _closing = true);
    Navigator.of(context).pop();
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Değişiklikler kaydedilmedi'),
            content: const Text('Kaydetmeden çıkarsan yaptığın değişiklikler kaybolur.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Düzenlemeye dön')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Kaydetmeden çık')),
            ],
          ),
    );
    if (discard == true) _close();
  }

  Future<void> _addCategory() async {
    final name = await showDialog<String>(context: context, builder: (_) => const _NewCategoryDialog());
    if (name == null || name.trim().isEmpty) return;
    final added = await _controller.addCategory(name);
    if (mounted) setState(() => _category = added);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: theme.textTheme.titleSmall),
    );

    return PopScope<Object?>(
      canPop: _closing || !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isNew ? 'Yeni not' : 'Notu düzenle')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              label('Başlık'),
              TextField(
                key: const Key('title-field'),
                controller: _title,
                autofocus: _isNew,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Başlık'),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 20),
              label('Not'),
              TextField(
                key: const Key('content-field'),
                controller: _content,
                minLines: 6,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Notunu yaz…'),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 20),
              label('Kategori'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in _controller.categories)
                    ChoiceChip(
                      key: Key('category-$category'),
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ActionChip(
                    key: const Key('new-category'),
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Yeni kategori'),
                    onPressed: _addCategory,
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton(key: const Key('save-note'), onPressed: _save, child: const Text('Kaydet')),
          ),
        ),
      ),
    );
  }
}

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog();

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(_name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni kategori'),
      content: TextField(
        key: const Key('category-name-field'),
        controller: _name,
        autofocus: true,
        maxLength: 24,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Örn. Okul'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgeç')),
        TextButton(key: const Key('category-add'), onPressed: _submit, child: const Text('Ekle')),
      ],
    );
  }
}
