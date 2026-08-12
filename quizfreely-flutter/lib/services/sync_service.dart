import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizfreely_flutter/models/studyset.dart';
import 'package:quizfreely_flutter/models/term.dart';
import 'package:quizfreely_flutter/services/database_service.dart';
import 'package:quizfreely_flutter/services/app_settings.dart';

class SyncResult {
  final bool success;
  final String? error;
  final int pushed;
  final int pulled;

  SyncResult({
    required this.success,
    this.error,
    this.pushed = 0,
    this.pulled = 0,
  });
}

class AuthResult {
  final bool success;
  final String? error;
  final String? username;

  AuthResult({required this.success, this.error, this.username});
}

class SyncService {
  // URLs are loaded dynamically from AppSettings
  String get _baseUrl => AppSettings().apiUrl;
  String get _apiUrl => '${AppSettings().apiUrl}/api';

  static const String _sessionKey = 'qf_session_cookie';
  static const String _usernameKey = 'qf_username';
  static const String _lastSyncKey = 'qf_last_sync';

  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // ── Auth state ─────────────────────────────────────────────────────

  Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final session = prefs.getString(_sessionKey);
    return session != null && session.isNotEmpty;
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<String?> _getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  Future<void> _saveSession(String cookie, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, cookie);
    await prefs.setString(_usernameKey, username);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_lastSyncKey);
  }

  Future<bool> testConnection(String url) async {
    try {
      final clean = url.trim().replaceAll(RegExp(r'/$'), '');
      final response = await http
          .get(Uri.parse('$clean/api/v0/app-info'))
          .timeout(const Duration(seconds: 8));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastSyncKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // ── Sign In ─────────────────────────────────────────────────────────

  Future<AuthResult> signIn(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v0/auth/sign-in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);

      if (body['error'] != null) {
        final err = body['error'];
        final msg = err['message'] ?? err['code'] ?? 'Sign in failed';
        return AuthResult(success: false, error: msg);
      }

      final rawCookie = response.headers['set-cookie'] ?? '';
      final sessionCookie = _extractSessionCookie(rawCookie);

      if (sessionCookie.isEmpty) {
        return AuthResult(success: false, error: 'No session received');
      }

      await _saveSession(sessionCookie, username);
      return AuthResult(success: true, username: username);
    } catch (e) {
      return AuthResult(
          success: false, error: 'Connection failed. Check your internet.');
    }
  }

  Future<AuthResult> signUp(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v0/auth/sign-up'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);

      if (body['error'] != null) {
        final err = body['error'];
        String msg;
        if (err['code'] == 'USERNAME_INVALID') {
          msg = 'Invalid username. Use only letters, numbers, underscores, dots or dashes (no uppercase). Max 100 characters.';
        } else {
          msg = err['message'] ?? err['code'] ?? 'Sign up failed';
        }
        return AuthResult(success: false, error: msg);
      }

      // Sign-up auto signs in — extract session cookie
      final rawCookie = response.headers['set-cookie'] ?? '';
      final sessionCookie = _extractSessionCookie(rawCookie);

      if (sessionCookie.isNotEmpty) {
        await _saveSession(sessionCookie, username);
      }

      return AuthResult(success: true, username: username);
    } catch (e) {
      return AuthResult(
          success: false, error: 'Connection failed. Check your internet.');
    }
  }

  String _extractSessionCookie(String rawCookie) {
    // Parse "name=value; Path=...; HttpOnly" format
    if (rawCookie.isEmpty) return '';
    final parts = rawCookie.split(';');
    if (parts.isEmpty) return '';
    return parts.first.trim(); // e.g. "session=abc123"
  }

  // ── GraphQL helper ─────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _gql(String query,
      [Map<String, dynamic>? variables]) async {
    final session = await _getSession();
    if (session == null) return null;

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': session,
        },
        body: jsonEncode({
          'query': query,
          if (variables != null) 'variables': variables,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        debugPrint('GraphQL errors: ${data['errors']}');
        return null;
      }
      return data['data'];
    } catch (e) {
      debugPrint('GQL error: $e');
      return null;
    }
  }

  // ── Fetch remote studysets ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>?> _fetchRemoteStudysets() async {
    const query = r'''
      query MyStudysets {
        myStudysets {
          id
          title
          description
          updatedAt
          terms {
            id
            term
            def
            sortOrder
          }
        }
      }
    ''';
    final data = await _gql(query);
    if (data == null) return null;
    final sets = data['myStudysets'];
    if (sets is! List) return null;
    return List<Map<String, dynamic>>.from(sets);
  }

  // ── Push a local studyset to server ───────────────────────────────

  Future<String?> _createRemoteStudyset(
      Studyset studyset, List<Term> terms) async {
    const mutation = r'''
      mutation CreateStudyset($title: String!, $description: String, $terms: [TermInput!]) {
        createStudyset(title: $title, description: $description, terms: $terms) {
          id
        }
      }
    ''';

    final termInputs = terms
        .map((t) => {
              'term': t.term,
              'def': t.definition,
              'sortOrder': t.sortOrder,
            })
        .toList();

    final data = await _gql(mutation, {
      'title': studyset.title,
      'description': studyset.description ?? '',
      'terms': termInputs,
    });

    return data?['createStudyset']?['id']?.toString();
  }

  Future<bool> _updateRemoteStudyset(
      String remoteId, Studyset studyset, List<Term> terms) async {
    const mutation = r'''
      mutation UpdateStudyset($id: ID!, $title: String, $description: String, $terms: [TermInput!]) {
        updateStudyset(id: $id, title: $title, description: $description, terms: $terms) {
          id
        }
      }
    ''';

    final termInputs = terms
        .map((t) => {
              'term': t.term,
              'def': t.definition,
              'sortOrder': t.sortOrder,
            })
        .toList();

    final data = await _gql(mutation, {
      'id': remoteId,
      'title': studyset.title,
      'description': studyset.description ?? '',
      'terms': termInputs,
    });

    return data?['updateStudyset'] != null;
  }

  // ── Main Sync ──────────────────────────────────────────────────────

  /// Bidirectional sync:
  /// 1. Pull all remote studysets → save locally if new/updated
  /// 2. Push all local studysets without remoteId → create on server
  Future<SyncResult> sync() async {
    final signedIn = await isSignedIn();
    if (!signedIn) {
      return SyncResult(success: false, error: 'Not signed in');
    }

    try {
      final db = DatabaseService();
      int pulled = 0;
      int pushed = 0;

      // ── PULL: server → local ──────────────────────────────────────
      final remoteStudysets = await _fetchRemoteStudysets();
      if (remoteStudysets == null) {
        return SyncResult(
            success: false, error: 'Could not fetch from server');
      }

      final localSets = await db.getAllStudysets();

      for (final remote in remoteStudysets) {
        final remoteId = remote['id'].toString();
        final remoteTitle = remote['title'] ?? 'Untitled';
        final remoteDesc = remote['description'] ?? '';
        final remoteUpdatedRaw = remote['updatedAt'];

        DateTime remoteUpdated;
        try {
          remoteUpdated = DateTime.parse(remoteUpdatedRaw.toString());
        } catch (_) {
          remoteUpdated = DateTime.now();
        }

        // Check if we already have this remote studyset locally
        final existing = await db.getStudysetByRemoteId(remoteId);

        if (existing == null) {
          // New from server — save locally
          final newSet = Studyset(
            title: remoteTitle,
            description: remoteDesc,
            remoteId: remoteId,
            updatedAt: remoteUpdated,
          );
          final localId = await db.insertStudyset(newSet);

          // Save its terms
          final rawTerms = remote['terms'] as List? ?? [];
          final terms = rawTerms.asMap().entries.map((e) {
            final t = e.value as Map;
            return Term(
              studysetId: localId,
              term: t['term']?.toString() ?? '',
              definition: t['def']?.toString() ?? '',
              sortOrder: (t['sortOrder'] as num?)?.toInt() ?? e.key,
            );
          }).toList();
          await db.replaceTermsForStudyset(localId, terms);
          pulled++;
        } else {
          // Already exists locally — update if server is newer
          if (remoteUpdated.isAfter(existing.updatedAt)) {
            await db.updateStudyset(existing.copyWith(
              title: remoteTitle,
              description: remoteDesc,
              updatedAt: remoteUpdated,
            ));

            final rawTerms = remote['terms'] as List? ?? [];
            final terms = rawTerms.asMap().entries.map((e) {
              final t = e.value as Map;
              return Term(
                studysetId: existing.id!,
                term: t['term']?.toString() ?? '',
                definition: t['def']?.toString() ?? '',
                sortOrder: (t['sortOrder'] as num?)?.toInt() ?? e.key,
              );
            }).toList();
            await db.replaceTermsForStudyset(existing.id!, terms);
            pulled++;
          }
        }
      }

      // ── PUSH: local → server ──────────────────────────────────────
      final allLocal = await db.getAllStudysets();
      for (final local in allLocal) {
        if (local.remoteId == null) {
          // Never synced — create on server
          final terms = await db.getTermsForStudyset(local.id!);
          final remoteId = await _createRemoteStudyset(local, terms);
          if (remoteId != null) {
            // Save the remoteId back locally
            await db.updateStudyset(local.copyWith(remoteId: remoteId));
            pushed++;
          }
        } else {
          // Already synced — check if local is newer than last sync
          final lastSync = await getLastSync();
          if (lastSync == null || local.updatedAt.isAfter(lastSync)) {
            final terms = await db.getTermsForStudyset(local.id!);
            await _updateRemoteStudyset(local.remoteId!, local, terms);
            pushed++;
          }
        }
      }

      // Save last sync timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      return SyncResult(success: true, pulled: pulled, pushed: pushed);
    } catch (e) {
      debugPrint('Sync error: $e');
      return SyncResult(success: false, error: 'Sync failed: $e');
    }
  }
}
