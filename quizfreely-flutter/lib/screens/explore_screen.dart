import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quizfreely_flutter/services/api_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _api = QuizFreelyApiService();
  final _searchCtrl = TextEditingController();

  List<ApiStudyset> _results = [];
  bool _loading = false;
  bool _searched = false;
  bool? _isOnline;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final online = await _api.isOnline();
    if (mounted) setState(() => _isOnline = online);
    if (online) _explore();
  }

  Future<void> _explore() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    final results = await _api.exploreStudysets();
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
        _searched = true;
        if (results.isEmpty) {
          _errorMessage =
              'No public study sets found. Try searching for something specific.';
        }
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _explore();
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    final results = await _api.searchStudysets(query.trim());
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
        _searched = true;
        if (results.isEmpty) {
          _errorMessage = 'No results found for "${query.trim()}"';
        }
      });
    }
  }

  Future<void> _download(ApiStudyset set) async {
    final cs = Theme.of(context).colorScheme;
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Downloading...', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    set.title,
                    style: TextStyle(
                        color: cs.onSurface.withOpacity(0.6), fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Fetch full set with terms
    final full = await _api.fetchStudyset(set.id);
    if (!mounted) return;
    Navigator.pop(context); // close dialog

    if (full == null || full.terms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to download — try again'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final localId = await _api.downloadToLocal(full);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"${full.title}" saved offline (${full.terms.length} terms)',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () => context.push('/studyset/$localId'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore & Download'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Search public study sets...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _explore();
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: () => _search(_searchCtrl.text),
                      ),
                filled: true,
                fillColor: cs.surfaceContainerHighest ?? cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Connectivity banner
          if (_isOnline == false) _buildOfflineBanner(cs),
          Expanded(child: _buildBody(cs)),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: cs.error.withOpacity(0.12),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: cs.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You\'re offline. Browse or create study sets locally.',
              style: TextStyle(color: cs.error, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _checkConnectivity,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_isOnline == false) {
      return _buildOfflineContent(cs);
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_searched) {
      return _buildWelcome(cs);
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(_errorMessage,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: cs.onSurface.withOpacity(0.5))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _search(_searchCtrl.text),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _results.length,
        itemBuilder: (ctx, i) => _buildResultCard(_results[i], cs),
      ),
    );
  }

  Widget _buildWelcome(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_download_rounded,
                size: 48, color: cs.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Find & Download Study Sets',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Search millions of public study sets from quizfreely.org and save them offline',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineContent(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 48, color: cs.error),
            ),
            const SizedBox(height: 20),
            Text(
              'No Internet Connection',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You need internet to download study sets from quizfreely.org. '
              'You can still create new study sets and study your saved ones.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _checkConnectivity,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Check Connection'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go to My Sets'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ApiStudyset set, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.school_rounded,
                    color: cs.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (set.description != null &&
                        set.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        set.description!,
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.6),
                            fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.public_rounded,
                            size: 13,
                            color: cs.onSurface.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(
                          'quizfreely.org',
                          style: TextStyle(
                              color: cs.onSurface.withOpacity(0.4),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => _download(set),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
