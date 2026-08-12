import 'package:flutter/material.dart';
import 'package:quizfreely_flutter/models/term.dart';
import 'package:quizfreely_flutter/services/database_service.dart';
import 'dart:math';

enum _AnswerState { unanswered, correct, incorrect }

class PracticeScreen extends StatefulWidget {
  final int studysetId;
  const PracticeScreen({super.key, required this.studysetId});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _db = DatabaseService();
  List<Term> _terms = [];
  List<Term> _queue = [];
  int _currentIndex = 0;
  List<Term> _choices = [];
  _AnswerState _answerState = _AnswerState.unanswered;
  int? _selectedChoiceIndex;
  bool _loading = true;
  int _score = 0;
  int _total = 0;
  bool _finished = false;

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
        _queue = List.from(terms)..shuffle(Random());
        _loading = false;
        if (_queue.isNotEmpty) _buildChoices();
      });
    }
  }

  void _buildChoices() {
    if (_currentIndex >= _queue.length) {
      setState(() => _finished = true);
      return;
    }
    final correct = _queue[_currentIndex];
    final others = _terms.where((t) => t.id != correct.id).toList()
      ..shuffle(Random());
    final distractors = others.take(min(3, others.length)).toList();
    final all = [correct, ...distractors]..shuffle(Random());
    setState(() {
      _choices = all;
      _answerState = _AnswerState.unanswered;
      _selectedChoiceIndex = null;
    });
  }

  void _answer(int choiceIndex) {
    if (_answerState != _AnswerState.unanswered) return;
    final correct = _queue[_currentIndex];
    final chosen = _choices[choiceIndex];
    final isCorrect = chosen.id == correct.id;

    setState(() {
      _selectedChoiceIndex = choiceIndex;
      _answerState =
          isCorrect ? _AnswerState.correct : _AnswerState.incorrect;
      _total++;
      if (isCorrect) _score++;
    });

    if (correct.id != null) {
      if (isCorrect) {
        _db.recordCorrect(correct.id!, isDefinition: true);
      } else {
        _db.recordIncorrect(correct.id!, isDefinition: true);
      }
    }
  }

  void _next() {
    setState(() => _currentIndex++);
    _buildChoices();
  }

  void _restart() {
    setState(() {
      _queue = List.from(_terms)..shuffle(Random());
      _currentIndex = 0;
      _score = 0;
      _total = 0;
      _finished = false;
    });
    _buildChoices();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
        actions: [
          if (!_loading && !_finished)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$_score / $_total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _terms.length < 2
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 56, color: cs.error),
                        const SizedBox(height: 16),
                        const Text(
                          'You need at least 2 terms to use Practice mode.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : _finished
                  ? _buildFinished(cs)
                  : _buildQuestion(cs),
    );
  }

  Widget _buildQuestion(ColorScheme cs) {
    if (_currentIndex >= _queue.length) return _buildFinished(cs);
    final current = _queue[_currentIndex];
    final progress = (_currentIndex + 1) / _queue.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentIndex + 1} of ${_queue.length}',
                    style: TextStyle(
                        color: cs.onSurface.withOpacity(0.6), fontSize: 13),
                  ),
                  Text(
                    'Score: $_score / $_total',
                    style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
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
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withOpacity(0.15),
                        cs.primary.withOpacity(0.05)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'What is the definition of:',
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.5),
                            fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        current.term,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose the correct definition:',
                  style: TextStyle(
                      color: cs.onSurface.withOpacity(0.5), fontSize: 13),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _choices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) =>
                        _buildChoiceButton(cs, i, current),
                  ),
                ),
                if (_answerState != _AnswerState.unanswered)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _next,
                        child: Text(
                          _currentIndex < _queue.length - 1
                              ? 'Next Question'
                              : 'See Results',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButton(ColorScheme cs, int i, Term correct) {
    final choice = _choices[i];
    final isSelected = _selectedChoiceIndex == i;
    final isCorrectAnswer = choice.id == correct.id;

    Color bgColor = cs.surface;
    Color borderColor = cs.outline.withOpacity(0.3);
    Color textColor = cs.onSurface;
    IconData? icon;

    if (_answerState != _AnswerState.unanswered) {
      if (isCorrectAnswer) {
        bgColor = Colors.green.withOpacity(0.15);
        borderColor = Colors.green;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_rounded;
      } else if (isSelected) {
        bgColor = cs.error.withOpacity(0.15);
        borderColor = cs.error;
        textColor = cs.error;
        icon = Icons.cancel_rounded;
      }
    } else if (isSelected) {
      bgColor = cs.primary.withOpacity(0.15);
      borderColor = cs.primary;
    }

    return GestureDetector(
      onTap: () => _answer(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                choice.definition,
                style: TextStyle(
                    color: textColor, fontWeight: FontWeight.w500),
              ),
            ),
            if (icon != null)
              Icon(icon,
                  color: isCorrectAnswer ? Colors.green : cs.error),
          ],
        ),
      ),
    );
  }

  Widget _buildFinished(ColorScheme cs) {
    final pct = _total == 0 ? 0 : (_score / _total * 100).round();
    final color = pct >= 80
        ? Colors.green
        : pct >= 50
            ? Colors.orange
            : cs.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3), width: 2),
              ),
              child: Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              pct >= 80
                  ? '🎉 Excellent!'
                  : pct >= 50
                      ? '👍 Good effort!'
                      : '📚 Keep studying!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You got $_score out of $_total correct',
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Try Again'),
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
