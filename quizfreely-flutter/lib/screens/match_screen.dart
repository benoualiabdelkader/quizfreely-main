import 'package:flutter/material.dart';
import 'package:quizfreely_flutter/models/term.dart';
import 'package:quizfreely_flutter/services/database_service.dart';
import 'dart:math';

class MatchScreen extends StatefulWidget {
  final int studysetId;
  const MatchScreen({super.key, required this.studysetId});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchItem {
  final String text;
  final int termId;
  final bool isTerm; // true = term side, false = definition side
  bool matched = false;
  bool selected = false;
  bool wrong = false;

  _MatchItem({
    required this.text,
    required this.termId,
    required this.isTerm,
  });
}

class _MatchScreenState extends State<MatchScreen> {
  final _db = DatabaseService();
  List<_MatchItem> _leftColumn = [];
  List<_MatchItem> _rightColumn = [];
  _MatchItem? _selected;
  bool _loading = true;
  int _matched = 0;
  int _total = 0;
  bool _finished = false;
  Stopwatch _stopwatch = Stopwatch();
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    final terms = await _db.getTermsForStudyset(widget.studysetId);
    if (!mounted) return;

    // Use up to 8 terms for the match game
    final subset = List<Term>.from(terms)..shuffle(Random());
    final gameTerms = subset.take(min(8, subset.length)).toList();

    final left = gameTerms
        .map((t) => _MatchItem(text: t.term, termId: t.id!, isTerm: true))
        .toList()
      ..shuffle(Random());
    final right = gameTerms
        .map((t) =>
            _MatchItem(text: t.definition, termId: t.id!, isTerm: false))
        .toList()
      ..shuffle(Random());

    setState(() {
      _leftColumn = left;
      _rightColumn = right;
      _total = gameTerms.length;
      _loading = false;
    });
    _stopwatch.start();
  }

  void _onTap(_MatchItem item) {
    if (item.matched) return;

    setState(() {
      // Clear wrong states
      for (final i in [..._leftColumn, ..._rightColumn]) {
        i.wrong = false;
      }

      if (_selected == null) {
        // First selection
        _selected?.selected = false;
        item.selected = true;
        _selected = item;
      } else if (_selected == item) {
        // Deselect
        item.selected = false;
        _selected = null;
      } else if (_selected!.isTerm == item.isTerm) {
        // Same column — switch selection
        _selected!.selected = false;
        item.selected = true;
        _selected = item;
      } else {
        // Different column — check match
        final a = _selected!;
        final b = item;
        if (a.termId == b.termId) {
          // Correct match!
          a.matched = true;
          b.matched = true;
          a.selected = false;
          b.selected = false;
          _selected = null;
          _matched++;
          if (_matched == _total) {
            _stopwatch.stop();
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) setState(() => _finished = true);
            });
          }
        } else {
          // Wrong match
          a.wrong = true;
          b.wrong = true;
          _mistakes++;
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() {
                a.wrong = false;
                b.wrong = false;
              });
            }
          });
          a.selected = false;
          b.selected = false;
          _selected = null;
        }
      }
    });
  }

  void _restart() {
    setState(() {
      _matched = 0;
      _mistakes = 0;
      _finished = false;
      _selected = null;
      _stopwatch.reset();
    });
    _loadTerms();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match'),
        actions: [
          if (!_loading && !_finished)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$_matched / $_total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _finished
              ? _buildFinished(cs)
              : _buildGame(cs),
    );
  }

  Widget _buildGame(ColorScheme cs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Match terms to their definitions',
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.5), fontSize: 13),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_mistakes mistakes',
                  style: TextStyle(
                      color: cs.onErrorContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildColumn(_leftColumn, cs)),
                const SizedBox(width: 12),
                Expanded(child: _buildColumn(_rightColumn, cs)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(List<_MatchItem> items, ColorScheme cs) {
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildMatchTile(item, cs),
              ))
          .toList(),
    );
  }

  Widget _buildMatchTile(_MatchItem item, ColorScheme cs) {
    Color bgColor;
    Color borderColor;
    Color textColor = cs.onSurface;

    if (item.matched) {
      bgColor = Colors.green.withOpacity(0.12);
      borderColor = Colors.green;
      textColor = Colors.green.shade700;
    } else if (item.wrong) {
      bgColor = cs.error.withOpacity(0.12);
      borderColor = cs.error;
      textColor = cs.error;
    } else if (item.selected) {
      bgColor = cs.primary.withOpacity(0.15);
      borderColor = cs.primary;
      textColor = cs.primary;
    } else {
      bgColor = cs.surfaceContainerHighest ?? cs.surface;
      borderColor = cs.outline.withOpacity(0.3);
    }

    return GestureDetector(
      onTap: () => _onTap(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Text(
          item.text,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: item.selected || item.matched
                ? FontWeight.w600
                : FontWeight.normal,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildFinished(ColorScheme cs) {
    final elapsed = _stopwatch.elapsed;
    final mins = elapsed.inMinutes;
    final secs = elapsed.inSeconds % 60;
    final timeStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.green.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 56, color: Colors.green),
            ),
            const SizedBox(height: 24),
            Text(
              '🎯 Perfect Match!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(
                  icon: Icons.timer_rounded,
                  label: 'Time',
                  value: timeStr,
                  color: cs.primary,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.close_rounded,
                  label: 'Mistakes',
                  value: '$_mistakes',
                  color: _mistakes == 0 ? Colors.green : cs.error,
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Play Again'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Study Set'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 18),
          ),
          Text(
            label,
            style: TextStyle(
                color: color.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
