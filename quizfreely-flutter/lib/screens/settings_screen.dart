import 'package:flutter/material.dart';
import 'package:quizfreely_flutter/services/app_settings.dart';
import 'package:quizfreely_flutter/services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = AppSettings();
  final _sync = SyncService();
  final _serverCtrl = TextEditingController();
  bool _loading = true;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _settings.load();
    if (mounted) {
      setState(() {
        _serverCtrl.text = _settings.apiUrl;
        _loading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    final url = _serverCtrl.text.trim().replaceAll(RegExp(r'/$'), '');
    if (url.isEmpty) {
      setState(() {
        _testResult = 'Please enter a server URL';
        _testOk = false;
      });
      return;
    }
    setState(() { _testing = true; _testResult = null; });

    final online = await _sync.testConnection(url);
    if (mounted) {
      setState(() {
        _testing = false;
        _testOk = online;
        _testResult = online
            ? '✅ Connected successfully to $url'
            : '❌ Could not connect. Check the URL and make sure the server is running.';
      });
    }
  }

  Future<void> _save() async {
    final url = _serverCtrl.text.trim().replaceAll(RegExp(r'/$'), '');
    if (url.isEmpty) return;

    // Sign out when changing server — session is server-specific
    final wasSignedIn = await _sync.isSignedIn();
    if (wasSignedIn) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Change server?'),
          content: const Text(
              'Changing the server URL will sign you out of your current account. '
              'You will need to sign in again on the new server.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Change')),
          ],
        ),
      );
      if (confirm != true) return;
      await _sync.signOut();
    }

    await _settings.setApiUrl(url);
    if (mounted) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Server URL saved'),
          ]),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 2),
          () { if (mounted) setState(() => _saved = false); });
    }
  }

  Future<void> _reset() async {
    await _settings.resetToDefaults();
    await _sync.signOut();
    if (mounted) {
      setState(() {
        _serverCtrl.text = AppSettings.defaultApiUrl;
        _testResult = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset to quizfreely.org')),
      );
    }
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Server Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.dns_rounded, color: cs.primary),
                          const SizedBox(width: 10),
                          const Text('Server URL',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          'Enter the URL of your QuizFreely server. '
                          'This is the URL you deployed to Render (or any other host). '
                          'Leave as default to use quizfreely.org.',
                          style: TextStyle(
                              color: cs.onSurface.withOpacity(0.6),
                              fontSize: 13,
                              height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _serverCtrl,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          onChanged: (_) =>
                              setState(() { _testResult = null; _saved = false; }),
                          decoration: InputDecoration(
                            labelText: 'Server URL',
                            hintText: 'https://my-quizfreely.onrender.com',
                            prefixIcon: const Icon(Icons.link_rounded),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            suffixIcon: _serverCtrl.text !=
                                    AppSettings.defaultApiUrl
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _serverCtrl.text =
                                          AppSettings.defaultApiUrl;
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Test result banner
                        if (_testResult != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: _testOk
                                  ? Colors.green.withOpacity(0.1)
                                  : cs.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _testResult!,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _testOk
                                      ? Colors.green.shade700
                                      : cs.onErrorContainer),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _testing ? null : _testConnection,
                                icon: _testing
                                    ? const SizedBox(
                                        width: 16, height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.wifi_tethering_rounded),
                                label: Text(_testing ? 'Testing...' : 'Test'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _save,
                                icon: Icon(_saved
                                    ? Icons.check_rounded
                                    : Icons.save_rounded),
                                label: Text(_saved ? 'Saved!' : 'Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Render guide
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF46E3B7).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('⬛',
                                style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 10),
                          const Text('Deploy to Render',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                        const SizedBox(height: 12),
                        ..._renderSteps(cs),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Reset button
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: Icon(Icons.restore_rounded, color: cs.error),
                  label: Text('Reset to quizfreely.org',
                      style: TextStyle(color: cs.error)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(color: cs.error.withOpacity(0.4)),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _renderSteps(ColorScheme cs) {
    final steps = [
      ('1', 'Push your project to GitHub or Codeberg'),
      ('2', 'Go to render.com and create a free account'),
      ('3', 'Click "New +" → "Web Service"'),
      ('4', 'Connect your GitHub repo (quizfreely-main)'),
      ('5', 'Render auto-detects render.yaml — click Deploy'),
      ('6', 'Copy your Render URL (e.g. https://quizfreely-web.onrender.com)'),
      ('7', 'Paste it above and tap Save'),
    ];
    return steps.map((s) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(s.$1,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(s.$2,
                    style: TextStyle(
                        color: cs.onSurface.withOpacity(0.7),
                        height: 1.4)),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
