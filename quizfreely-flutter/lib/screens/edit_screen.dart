import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quizfreely_flutter/models/studyset.dart';
import 'package:quizfreely_flutter/models/term.dart';
import 'package:quizfreely_flutter/services/database_service.dart';

class EditScreen extends StatefulWidget {
  final int? studysetId;
  const EditScreen({super.key, this.studysetId});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _db = DatabaseService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<_TermEntry> _termEntries = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.studysetId != null) {
      final s = await _db.getStudyset(widget.studysetId!);
      final terms = await _db.getTermsForStudyset(widget.studysetId!);
      if (mounted) {
        setState(() {
          if (s != null) {
            _titleCtrl.text = s.title;
            _descCtrl.text = s.description ?? '';
          }
          _termEntries.clear();
          for (final t in terms) {
            _termEntries.add(_TermEntry(
              termCtrl: TextEditingController(text: t.term),
              defCtrl: TextEditingController(text: t.definition),
              existingTerm: t,
            ));
          }
          if (_termEntries.isEmpty) _addBlankTerm();
          _loading = false;
        });
      }
    } else {
      setState(() {
        _addBlankTerm();
        _addBlankTerm();
        _loading = false;
      });
    }
  }

  void _addBlankTerm() {
    _termEntries.add(_TermEntry(
      termCtrl: TextEditingController(),
      defCtrl: TextEditingController(),
    ));
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title')),
      );
      return;
    }

    final validTerms = _termEntries
        .where((e) =>
            e.termCtrl.text.trim().isNotEmpty ||
            e.defCtrl.text.trim().isNotEmpty)
        .toList();

    if (validTerms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one term')),
      );
      return;
    }

    setState(() => _saving = true);

    int studysetId;
    if (widget.studysetId == null) {
      final newSet = Studyset(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      );
      studysetId = await _db.insertStudyset(newSet);
    } else {
      studysetId = widget.studysetId!;
      final existing = await _db.getStudyset(studysetId);
      if (existing != null) {
        await _db.updateStudyset(existing.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
        ));
      }
    }

    final termsToSave = validTerms.asMap().entries.map((e) {
      return Term(
        id: e.value.existingTerm?.id,
        studysetId: studysetId,
        term: e.value.termCtrl.text.trim(),
        definition: e.value.defCtrl.text.trim(),
        sortOrder: e.key,
      );
    }).toList();

    await _db.replaceTermsForStudyset(studysetId, termsToSave);

    if (mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final e in _termEntries) {
      e.termCtrl.dispose();
      e.defCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studysetId == null ? 'Create Study Set' : 'Edit Study Set'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : FilledButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoCard(cs),
                const SizedBox(height: 20),
                Text(
                  'Terms',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ..._termEntries.asMap().entries.map((entry) =>
                    _buildTermCard(context, cs, entry.key, entry.value)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _addBlankTerm());
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Term'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _buildInfoCard(ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Biology Chapter 3',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.title_rounded),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.description_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermCard(
      BuildContext context, ColorScheme cs, int index, _TermEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_termEntries.length > 1)
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: cs.error, size: 20),
                      onPressed: () =>
                          setState(() => _termEntries.removeAt(index)),
                      tooltip: 'Remove',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: entry.termCtrl,
                decoration: InputDecoration(
                  labelText: 'Term',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: entry.defCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Definition',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermEntry {
  final TextEditingController termCtrl;
  final TextEditingController defCtrl;
  final Term? existingTerm;

  _TermEntry({
    required this.termCtrl,
    required this.defCtrl,
    this.existingTerm,
  });
}
