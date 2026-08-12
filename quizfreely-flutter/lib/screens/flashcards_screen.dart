import 'package:flutter/material.dart';
import 'package:quizfreely_flutter/models/term.dart';
import 'package:quizfreely_flutter/services/database_service.dart';
import 'dart:math';

class FlashcardsScreen extends StatefulWidget {
  final int studysetId;
  const FlashcardsScreen({super.key, required this.studysetId});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final _db = DatabaseService();
  List<Term> _terms = [];
  int _current = 0;
  bool _showDefinition = false;
  bool _loading = true;
  bool _shuffled = false;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    final terms = await _db.getTermsForStudyset(widget.studysetId);
    if (mounted) {
      setState(() {
        _terms = terms;
        _loading = false;
      });
    }
  }

  void _shuffle() {
    setState(() {
      _terms.shuffle(Random());
      _shuffled = true;
      _current = 0;
      _showDefinition = false;
    });
  }

  void _reset() {
    setState(() {
      _terms.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _shuffled = false;
      _current = 0;
      _showDefinition = false;
    });
  }

  void _next() {
    if (_current < _terms.length - 1) {
      setState(() {
        _current++;
        _showDefinition = false;
      });
    }
  }

  void _prev() {
    if (_current > 0) {
      setState(() {
        _current--;
        _showDefinition = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            icon: Icon(_shuffled ? Icons.sort_rounded : Icons.shuffle_rounded),
            tooltip: _shuffled ? 'Reset order' : 'Shuffle',
            onPressed: _shuffled ? _reset : _shuffle,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _terms.isEmpty
              ? const Center(child: Text('No terms in this set.'))
              : Column(
                  children: [
                    _buildProgressBar(cs),
                    Expanded(child: _buildCard(cs)),
                    _buildNavButtons(cs),
                  ],
                ),
    );
  }

  Widget _buildProgressBar(ColorScheme cs) {
    final progress = _terms.isEmpty ? 0.0 : (_current + 1) / _terms.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_current + 1} / ${_terms.length}',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(_showDefinition ? 'Definition' : 'Term')}',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: cs.surfaceVariant ?? cs.surface,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ColorScheme cs) {
    final term = _terms[_current];
    return GestureDetector(
      onTap: () => setState(() => _showDefinition = !_showDefinition),
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < -300) _next();
        if (details.primaryVelocity! > 300) _prev();
      },
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: Container(
            key: ValueKey('${_current}_$_showDefinition'),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _showDefinition
                    ? [
                        const Color(0xFF00BFA5).withOpacity(0.15),
                        const Color(0xFF00BFA5).withOpacity(0.05),
                      ]
                    : [
                        cs.primary.withOpacity(0.15),
                        cs.primary.withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _showDefinition
                    ? const Color(0xFF00BFA5).withOpacity(0.3)
                    : cs.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _showDefinition
                          ? const Color(0xFF00BFA5).withOpacity(0.2)
                          : cs.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _showDefinition ? 'DEFINITION' : 'TERM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: _showDefinition
                            ? const Color(0xFF00BFA5)
                            : cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _showDefinition ? term.definition : term.term,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 16,
                        color: cs.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to flip',
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.3),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButtons(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _current > 0 ? _prev : null,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _current < _terms.length - 1 ? _next : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(_current < _terms.length - 1 ? 'Next' : 'Done'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
