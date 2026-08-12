import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:quizfreely_flutter/models/studyset.dart';
import 'package:quizfreely_flutter/models/term.dart';

/// Universal database service.
/// On web → SharedPreferences (localStorage JSON).
/// On Android/iOS → SQLite via sqflite.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // ─── SQLite (Android) ─────────────────────────────────────────────
  static Database? _db;

  Future<Database> get _database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quizfreely.db');
    return await openDatabase(path, version: 2,
        onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE studysets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        remoteId TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE terms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studysetId INTEGER NOT NULL,
        term TEXT NOT NULL,
        definition TEXT NOT NULL,
        sortOrder INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE term_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        termId INTEGER NOT NULL,
        termCorrectCount INTEGER DEFAULT 0,
        termIncorrectCount INTEGER DEFAULT 0,
        defCorrectCount INTEGER DEFAULT 0,
        defIncorrectCount INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE studysets ADD COLUMN remoteId TEXT');
    }
  }

  // ─── SharedPreferences (Web) ───────────────────────────────────────
  static const _setsKey = 'qf_studysets';
  static const _termsKey = 'qf_terms';
  static const _progressKey = 'qf_progress';
  static const _counterKey = 'qf_id_counter';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<int> _nextId() async {
    final p = await _prefs;
    final current = p.getInt(_counterKey) ?? 0;
    await p.setInt(_counterKey, current + 1);
    return current + 1;
  }

  Future<List<Map<String, dynamic>>> _webGetAll(String key) async {
    final p = await _prefs;
    final raw = p.getString(key);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  Future<void> _webSaveAll(String key, List<Map<String, dynamic>> data) async {
    final p = await _prefs;
    await p.setString(key, jsonEncode(data));
  }

  // ═══════════════════════════════════════════════════════════════════
  // STUDYSETS
  // ═══════════════════════════════════════════════════════════════════

  Future<List<Studyset>> getAllStudysets() async {
    if (kIsWeb) {
      final all = await _webGetAll(_setsKey);
      final sets = all.map((m) => Studyset.fromMap(m)).toList();
      sets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sets;
    }
    final db = await _database;
    final maps = await db.query('studysets', orderBy: 'updatedAt DESC');
    return maps.map((m) => Studyset.fromMap(m)).toList();
  }

  Future<Studyset?> getStudysetByRemoteId(String remoteId) async {
    if (kIsWeb) {
      final all = await _webGetAll(_setsKey);
      final map = all.cast<Map<String, dynamic>?>().firstWhere(
            (m) => m!['remoteId'] == remoteId,
            orElse: () => null,
          );
      return map == null ? null : Studyset.fromMap(map);
    }
    final db = await _database;
    final maps = await db.query('studysets',
        where: 'remoteId = ?', whereArgs: [remoteId], limit: 1);
    if (maps.isEmpty) return null;
    return Studyset.fromMap(maps.first);
  }

  Future<Studyset?> getStudyset(int id) async {
    if (kIsWeb) {
      final all = await _webGetAll(_setsKey);
      final map = all.cast<Map<String, dynamic>?>().firstWhere(
            (m) => m!['id'] == id,
            orElse: () => null,
          );
      return map == null ? null : Studyset.fromMap(map);
    }
    final db = await _database;
    final maps = await db.query('studysets',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Studyset.fromMap(maps.first);
  }

  Future<int> insertStudyset(Studyset studyset) async {
    if (kIsWeb) {
      final id = await _nextId();
      final all = await _webGetAll(_setsKey);
      all.add({...studyset.toMap(), 'id': id});
      await _webSaveAll(_setsKey, all);
      return id;
    }
    final db = await _database;
    return await db.insert('studysets', studyset.toMap());
  }

  Future<void> updateStudyset(Studyset studyset) async {
    if (kIsWeb) {
      final all = await _webGetAll(_setsKey);
      final idx = all.indexWhere((m) => m['id'] == studyset.id);
      if (idx >= 0) {
        all[idx] = studyset.copyWith(updatedAt: DateTime.now()).toMap()
          ..['id'] = studyset.id;
      }
      await _webSaveAll(_setsKey, all);
      return;
    }
    final db = await _database;
    await db.update('studysets', studyset.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?', whereArgs: [studyset.id]);
  }

  Future<void> deleteStudyset(int id) async {
    if (kIsWeb) {
      final sets = await _webGetAll(_setsKey);
      sets.removeWhere((m) => m['id'] == id);
      await _webSaveAll(_setsKey, sets);
      // also remove terms
      final terms = await _webGetAll(_termsKey);
      terms.removeWhere((m) => m['studysetId'] == id);
      await _webSaveAll(_termsKey, terms);
      return;
    }
    final db = await _database;
    await db.delete('studysets', where: 'id = ?', whereArgs: [id]);
    await db.delete('terms', where: 'studysetId = ?', whereArgs: [id]);
  }

  Future<int> countTerms(int studysetId) async {
    if (kIsWeb) {
      final terms = await _webGetAll(_termsKey);
      return terms.where((m) => m['studysetId'] == studysetId).length;
    }
    final db = await _database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM terms WHERE studysetId = ?',
        [studysetId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════════
  // TERMS
  // ═══════════════════════════════════════════════════════════════════

  Future<List<Term>> getTermsForStudyset(int studysetId) async {
    if (kIsWeb) {
      final all = await _webGetAll(_termsKey);
      final filtered = all
          .where((m) => m['studysetId'] == studysetId)
          .map((m) => Term.fromMap(m))
          .toList();
      filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return filtered;
    }
    final db = await _database;
    final maps = await db.query('terms',
        where: 'studysetId = ?',
        whereArgs: [studysetId],
        orderBy: 'sortOrder ASC');
    return maps.map((m) => Term.fromMap(m)).toList();
  }

  Future<int> insertTerm(Term term) async {
    if (kIsWeb) {
      final id = await _nextId();
      final all = await _webGetAll(_termsKey);
      all.add({...term.toMap(), 'id': id});
      await _webSaveAll(_termsKey, all);
      return id;
    }
    final db = await _database;
    return await db.insert('terms', term.toMap());
  }

  Future<void> updateTerm(Term term) async {
    if (kIsWeb) {
      final all = await _webGetAll(_termsKey);
      final idx = all.indexWhere((m) => m['id'] == term.id);
      if (idx >= 0) all[idx] = {...term.toMap(), 'id': term.id};
      await _webSaveAll(_termsKey, all);
      return;
    }
    final db = await _database;
    await db.update('terms', term.toMap(),
        where: 'id = ?', whereArgs: [term.id]);
  }

  Future<void> deleteTerm(int id) async {
    if (kIsWeb) {
      final all = await _webGetAll(_termsKey);
      all.removeWhere((m) => m['id'] == id);
      await _webSaveAll(_termsKey, all);
      return;
    }
    final db = await _database;
    await db.delete('terms', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceTermsForStudyset(int studysetId, List<Term> terms) async {
    if (kIsWeb) {
      final all = await _webGetAll(_termsKey);
      all.removeWhere((m) => m['studysetId'] == studysetId);
      for (int i = 0; i < terms.length; i++) {
        final id = await _nextId();
        final t = terms[i].copyWith(studysetId: studysetId, sortOrder: i);
        all.add({...t.toMap(), 'id': id});
      }
      await _webSaveAll(_termsKey, all);
      return;
    }
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('terms', where: 'studysetId = ?', whereArgs: [studysetId]);
      for (int i = 0; i < terms.length; i++) {
        final t = terms[i].copyWith(studysetId: studysetId, sortOrder: i);
        await txn.insert('terms', t.toMap());
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // PROGRESS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> recordCorrect(int termId, {bool isDefinition = false}) async {
    if (kIsWeb) {
      final all = await _webGetAll(_progressKey);
      final idx = all.indexWhere((m) => m['termId'] == termId);
      if (idx < 0) {
        all.add({
          'termId': termId,
          'termCorrectCount': isDefinition ? 0 : 1,
          'termIncorrectCount': 0,
          'defCorrectCount': isDefinition ? 1 : 0,
          'defIncorrectCount': 0,
        });
      } else {
        final field = isDefinition ? 'defCorrectCount' : 'termCorrectCount';
        all[idx][field] = (all[idx][field] as int) + 1;
      }
      await _webSaveAll(_progressKey, all);
      return;
    }
    final db = await _database;
    final existing = await db.query('term_progress',
        where: 'termId = ?', whereArgs: [termId], limit: 1);
    if (existing.isEmpty) {
      await db.insert('term_progress', {
        'termId': termId,
        'termCorrectCount': isDefinition ? 0 : 1,
        'termIncorrectCount': 0,
        'defCorrectCount': isDefinition ? 1 : 0,
        'defIncorrectCount': 0,
      });
    } else {
      final field = isDefinition ? 'defCorrectCount' : 'termCorrectCount';
      await db.rawUpdate(
          'UPDATE term_progress SET $field = $field + 1 WHERE termId = ?',
          [termId]);
    }
  }

  Future<void> recordIncorrect(int termId, {bool isDefinition = false}) async {
    if (kIsWeb) {
      final all = await _webGetAll(_progressKey);
      final idx = all.indexWhere((m) => m['termId'] == termId);
      if (idx < 0) {
        all.add({
          'termId': termId,
          'termCorrectCount': 0,
          'termIncorrectCount': isDefinition ? 0 : 1,
          'defCorrectCount': 0,
          'defIncorrectCount': isDefinition ? 1 : 0,
        });
      } else {
        final field = isDefinition ? 'defIncorrectCount' : 'termIncorrectCount';
        all[idx][field] = (all[idx][field] as int) + 1;
      }
      await _webSaveAll(_progressKey, all);
      return;
    }
    final db = await _database;
    final existing = await db.query('term_progress',
        where: 'termId = ?', whereArgs: [termId], limit: 1);
    if (existing.isEmpty) {
      await db.insert('term_progress', {
        'termId': termId,
        'termCorrectCount': 0,
        'termIncorrectCount': isDefinition ? 0 : 1,
        'defCorrectCount': 0,
        'defIncorrectCount': isDefinition ? 1 : 0,
      });
    } else {
      final field = isDefinition ? 'defIncorrectCount' : 'termIncorrectCount';
      await db.rawUpdate(
          'UPDATE term_progress SET $field = $field + 1 WHERE termId = ?',
          [termId]);
    }
  }
}
