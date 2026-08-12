import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:quizfreely_flutter/services/sync_service.dart';
import 'package:quizfreely_flutter/screens/signin_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _sync = SyncService();
  bool _signedIn = false;
  String? _username;
  DateTime? _lastSync;
  bool _syncing = false;
  String? _syncMessage;
  bool _syncSuccess = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final signedIn = await _sync.isSignedIn();
    final username = await _sync.getUsername();
    final lastSync = await _sync.getLastSync();
    if (mounted) {
      setState(() {
        _signedIn = signedIn;
        _username = username;
        _lastSync = lastSync;
        _loading = false;
      });
    }
  }

  Future<void> _doSync() async {
    setState(() {
      _syncing = true;
      _syncMessage = null;
    });

    final result = await _sync.sync();

    if (!mounted) return;
    setState(() {
      _syncing = false;
      _syncSuccess = result.success;
      _lastSync = result.success ? DateTime.now() : _lastSync;
      if (result.success) {
        _syncMessage =
            '✅ Synced! ${result.pulled} downloaded, ${result.pushed} uploaded';
      } else {
        _syncMessage = '❌ ${result.error ?? 'Sync failed'}';
      }
    });
  }

  Future<void> _openSignIn({bool signUp = false}) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => SignInScreen(startOnSignUp: signUp)),
    );
    if (success == true) {
      _loadState();
      await _doSync();
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'Your locally saved study sets will remain on this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) {
      await _sync.signOut();
      _loadState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sync & Account')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _signedIn
              ? _buildSignedIn(cs)
              : _buildSignedOut(cs),
    );
  }

  Widget _buildSignedOut(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sync_rounded, size: 48, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Sync Your Study Sets',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Sign in to your quizfreely.org account to sync study sets across all your devices — phone, tablet, and browser.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: cs.onSurface.withOpacity(0.6), height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _openSignIn(signUp: false),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Sign In',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _openSignIn(signUp: true),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Create Account',
                    style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildFeatureRow(
                cs, Icons.devices_rounded, 'Access on any device'),
            _buildFeatureRow(
                cs, Icons.cloud_done_rounded, 'Automatic cloud backup'),
            _buildFeatureRow(
                cs, Icons.wifi_off_rounded, 'Works offline too'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(ColorScheme cs, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: cs.primary, size: 18),
          const SizedBox(width: 10),
          Text(text,
              style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildSignedIn(ColorScheme cs) {
    final lastSyncStr = _lastSync == null
        ? 'Never synced'
        : 'Last synced: ${DateFormat('MMM d, h:mm a').format(_lastSync!)}';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Account card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primary.withOpacity(0.6)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    (_username?.isNotEmpty == true
                            ? _username![0].toUpperCase()
                            : '?'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username ?? 'Unknown',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'quizfreely.org account',
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.5),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _signOut,
                  child: Text('Sign out',
                      style: TextStyle(color: cs.error)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Sync card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sync_rounded, color: cs.primary),
                    const SizedBox(width: 10),
                    const Text('Sync',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  lastSyncStr,
                  style: TextStyle(
                      color: cs.onSurface.withOpacity(0.5), fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Sync message
                if (_syncMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _syncSuccess
                          ? Colors.green.withOpacity(0.1)
                          : cs.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _syncMessage!,
                      style: TextStyle(
                          color: _syncSuccess
                              ? Colors.green.shade700
                              : cs.onErrorContainer,
                          fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _syncing ? null : _doSync,
                    icon: _syncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync_rounded),
                    label:
                        Text(_syncing ? 'Syncing...' : 'Sync Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // How sync works
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How sync works',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildSyncStep(cs, Icons.cloud_download_rounded,
                    'Download', 'New sets from quizfreely.org are saved to your device'),
                _buildSyncStep(cs, Icons.cloud_upload_rounded, 'Upload',
                    'Sets you created offline are pushed to quizfreely.org'),
                _buildSyncStep(cs, Icons.update_rounded, 'Update',
                    'Changed sets are updated using the most recent version'),
                _buildSyncStep(cs, Icons.wifi_off_rounded, 'Offline',
                    'All sets stay accessible even without internet'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStep(
      ColorScheme cs, IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                Text(desc,
                    style: TextStyle(
                        color: cs.onSurface.withOpacity(0.6),
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
