import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quizfreely_flutter/models/studyset.dart';
import 'package:quizfreely_flutter/models/term.dart';
import 'package:quizfreely_flutter/services/database_service.dart';

class StudysetScreen extends StatefulWidget {
  final int studysetId;
  const StudysetScreen({super.key, required this.studysetId});

  @override
  State<StudysetScreen> createState() => _StudysetScreenState();
}

class _StudysetScreenState extends State<StudysetScreen> {
  final _db = DatabaseService();
  Studyset? _studyset;
  List<Term> _terms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final s = await _db.getStudyset(widget.studysetId);
    final terms = await _db.getTermsForStudyset(widget.studysetId);
    if (mounted) {
      setState(() {
        _studyset = s;
        _terms = terms;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_studyset == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(child: Text('Study set not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_studyset!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
            onPressed: () async {
              await context.push('/edit/${widget.studysetId}');
              _loadData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStudyModes(cs),
          Expanded(
            child: _terms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.playlist_add_rounded,
                            size: 56, color: cs.primary.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text('No terms yet'),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () async {
                            await context.push('/edit/${widget.studysetId}');
                            _loadData();
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Terms'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _terms.length,
                    itemBuilder: (ctx, i) => _TermTile(term: _terms[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyModes(ColorScheme cs) {
    if (_terms.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest ?? cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant ?? cs.outline.withOpacity(0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_terms.length} term${_terms.length == 1 ? '' : 's'}',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ModeChip(
                icon: Icons.style_rounded,
                label: 'Flashcards',
                color: const Color(0xFF6C63FF),
                onTap: () => context.push('/flashcards/${widget.studysetId}'),
              ),
              const SizedBox(width: 8),
              _ModeChip(
                icon: Icons.quiz_rounded,
                label: 'Practice',
                color: const Color(0xFF00BFA5),
                onTap: () => context.push('/practice/${widget.studysetId}'),
              ),
              const SizedBox(width: 8),
              _ModeChip(
                icon: Icons.games_rounded,
                label: 'Match',
                color: const Color(0xFFFF6B6B),
                onTap: () => context.push('/match/${widget.studysetId}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermTile extends StatefulWidget {
  final Term term;
  const _TermTile({required this.term});

  @override
  State<_TermTile> createState() => _TermTileState();
}

class _TermTileState extends State<_TermTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Card(
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.term.term,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: cs.onSurface.withOpacity(0.4),
                      size: 20,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  Divider(color: cs.outlineVariant ?? cs.outline.withOpacity(0.3)),
                  const SizedBox(height: 4),
                  Text(
                    widget.term.definition,
                    style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
