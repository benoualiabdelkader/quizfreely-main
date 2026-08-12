import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quizfreely_flutter/models/studyset.dart';
import 'package:quizfreely_flutter/services/database_service.dart';
import 'package:quizfreely_flutter/services/sync_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseService();
  final _sync = SyncService();
  List<Studyset> _studysets = [];
  Map<int, int> _termCounts = {};
  bool _loading = true;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final signedIn = await _sync.isSignedIn();
    if (mounted) setState(() => _signedIn = signedIn);
  }

  Future<void> _loadData() async {
    final sets = await _db.getAllStudysets();
    final counts = <int, int>{};
    for (final s in sets) {
      if (s.id != null) {
        counts[s.id!] = await _db.countTerms(s.id!);
      }
    }
    if (mounted) {
      setState(() {
        _studysets = sets;
        _termCounts = counts;
        _loading = false;
      });
    }
  }

  Future<void> _deleteStudyset(Studyset s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete study set?'),
        content: Text('This will permanently delete "${s.title}" and all its terms.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && s.id != null) {
      await _db.deleteStudyset(s.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.secondary ?? cs.primary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('QuizFreely'),
          ],
        ),
        actions: [
          // Sync status chip
          if (_signedIn)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: () async {
                  await context.push('/account');
                  _loadData();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_done_rounded,
                          size: 14, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Synced',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _studysets.isEmpty
              ? _buildEmptyState(cs)
              : _buildStudysetList(cs),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/edit');
          _loadData();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Study Set'),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school_rounded, size: 56, color: cs.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'No study sets yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first study set to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () async {
              await context.push('/edit');
              _loadData();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Study Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudysetList(ColorScheme cs) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _studysets.length,
        itemBuilder: (context, index) {
          final s = _studysets[index];
          final count = _termCounts[s.id] ?? 0;
          return _StudysetCard(
            studyset: s,
            termCount: count,
            onTap: () async {
              await context.push('/studyset/${s.id}');
              _loadData();
            },
            onEdit: () async {
              await context.push('/edit/${s.id}');
              _loadData();
            },
            onDelete: () => _deleteStudyset(s),
          );
        },
      ),
    );
  }
}

class _StudysetCard extends StatelessWidget {
  final Studyset studyset;
  final int termCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudysetCard({
    required this.studyset,
    required this.termCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final updatedStr = DateFormat('MMM d, yyyy').format(studyset.updatedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        studyset.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded,
                          color: cs.onSurface.withOpacity(0.5)),
                      onSelected: (val) {
                        if (val == 'edit') onEdit();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_rounded),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_rounded, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
                if (studyset.description != null &&
                    studyset.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    studyset.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$termCount term${termCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time_rounded,
                        size: 13, color: cs.onSurface.withOpacity(0.4)),
                    const SizedBox(width: 4),
                    Text(
                      updatedStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
