import 'package:flutter/material.dart';
import 'package:quizfreely_flutter/services/sync_service.dart';

class SignInScreen extends StatefulWidget {
  final bool startOnSignUp;
  const SignInScreen({super.key, this.startOnSignUp = false});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _sync = SyncService();
  late TabController _tabController;

  // Sign In fields
  final _siUsernameCtrl = TextEditingController();
  final _siPasswordCtrl = TextEditingController();
  bool _siLoading = false;
  bool _siObscure = true;
  String? _siError;

  // Sign Up fields
  final _suUsernameCtrl = TextEditingController();
  final _suPasswordCtrl = TextEditingController();
  final _suConfirmCtrl = TextEditingController();
  bool _suLoading = false;
  bool _suObscure = true;
  bool _suObscureConfirm = true;
  String? _suError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.startOnSignUp ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _siUsernameCtrl.dispose();
    _siPasswordCtrl.dispose();
    _suUsernameCtrl.dispose();
    _suPasswordCtrl.dispose();
    _suConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_siUsernameCtrl.text.trim().isEmpty || _siPasswordCtrl.text.isEmpty) {
      setState(() => _siError = 'Please enter your username and password');
      return;
    }
    setState(() { _siLoading = true; _siError = null; });

    final result = await _sync.signIn(
      _siUsernameCtrl.text.trim(),
      _siPasswordCtrl.text,
    );

    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, true);
    } else {
      setState(() { _siLoading = false; _siError = result.error; });
    }
  }

  Future<void> _signUp() async {
    final username = _suUsernameCtrl.text.trim();
    final password = _suPasswordCtrl.text;
    final confirm = _suConfirmCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _suError = 'Please fill in all fields');
      return;
    }
    if (password != confirm) {
      setState(() => _suError = "Passwords don't match");
      return;
    }
    if (password.length < 8) {
      setState(() => _suError = 'Password must be at least 8 characters');
      return;
    }

    setState(() { _suLoading = true; _suError = null; });

    final result = await _sync.signUp(username, password);

    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, true);
    } else {
      setState(() { _suLoading = false; _suError = result.error; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sign In'),
            Tab(text: 'Create Account'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSignInTab(cs),
          _buildSignUpTab(cs),
        ],
      ),
    );
  }

  // ── Sign In Tab ──────────────────────────────────────────────────────

  Widget _buildSignInTab(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _buildHero(cs, Icons.login_rounded, 'Welcome back',
              'Sign in to sync your study sets across all your devices'),
          const SizedBox(height: 28),
          _buildErrorBanner(_siError, cs),
          // Username
          TextField(
            controller: _siUsernameCtrl,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: const Icon(Icons.person_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          // Password
          TextField(
            controller: _siPasswordCtrl,
            obscureText: _siObscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _signIn(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(_siObscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded),
                onPressed: () => setState(() => _siObscure = !_siObscure),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _siLoading ? null : _signIn,
              child: _siLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Sign In', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                  children: [
                    const TextSpan(text: "Don't have an account? "),
                    TextSpan(
                      text: 'Create one',
                      style: TextStyle(
                          color: cs.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoBox(cs,
              'Use your quizfreely.org account. The app works fully offline without signing in.'),
        ],
      ),
    );
  }

  // ── Sign Up Tab ──────────────────────────────────────────────────────

  Widget _buildSignUpTab(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _buildHero(cs, Icons.person_add_rounded, 'Create account',
              'Free forever. No credit card needed.'),
          const SizedBox(height: 28),
          _buildErrorBanner(_suError, cs),

          // Username
          TextField(
            controller: _suUsernameCtrl,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'letters, numbers, _ . - (no uppercase)',
              prefixIcon: const Icon(Icons.person_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Letters, numbers, underscores, dots, dashes only. No uppercase.',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(height: 14),

          // Password
          TextField(
            controller: _suPasswordCtrl,
            obscureText: _suObscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'At least 8 characters',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(_suObscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded),
                onPressed: () => setState(() => _suObscure = !_suObscure),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),

          // Confirm Password
          TextField(
            controller: _suConfirmCtrl,
            obscureText: _suObscureConfirm,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _signUp(),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_suObscureConfirm
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded),
                onPressed: () =>
                    setState(() => _suObscureConfirm = !_suObscureConfirm),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 24),

          // Password strength indicator
          _buildPasswordStrength(cs),
          const SizedBox(height: 16),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _suLoading ? null : _signUp,
              child: _suLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Account', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () => _tabController.animateTo(0),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Sign in',
                      style: TextStyle(
                          color: cs.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'By creating an account, you accept\nQuizFreely\'s Privacy Policy & Terms of Service',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withOpacity(0.4)),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoBox(cs, 'Your account is free and works across all devices.'),
        ],
      ),
    );
  }

  // ── Shared Widgets ──────────────────────────────────────────────────

  Widget _buildHero(ColorScheme cs, IconData icon, String title, String sub) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(sub,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
      ],
    );
  }

  Widget _buildErrorBanner(String? error, ColorScheme cs) {
    if (error == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded,
                color: cs.onErrorContainer, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(error,
                  style: TextStyle(color: cs.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrength(ColorScheme cs) {
    final pw = _suPasswordCtrl.text;
    int strength = 0;
    if (pw.length >= 8) strength++;
    if (pw.length >= 12) strength++;
    if (pw.contains(RegExp(r'[A-Z]'))) strength++;
    if (pw.contains(RegExp(r'[0-9]'))) strength++;
    if (pw.contains(RegExp(r'[!@#\$%^&*]'))) strength++;

    Color barColor;
    String label;
    if (pw.isEmpty) return const SizedBox();
    if (strength <= 1) { barColor = Colors.red; label = 'Weak'; }
    else if (strength <= 2) { barColor = Colors.orange; label = 'Fair'; }
    else if (strength <= 3) { barColor = Colors.yellow.shade700; label = 'Good'; }
    else { barColor = Colors.green; label = 'Strong'; }

    return ListenableBuilder(
      listenable: _suPasswordCtrl,
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Password strength',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: barColor)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength / 5,
              minHeight: 5,
              backgroundColor: cs.outline.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(ColorScheme cs, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: cs.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.7))),
          ),
        ],
      ),
    );
  }
}
