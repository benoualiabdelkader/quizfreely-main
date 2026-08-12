import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quizfreely_flutter/models/studyset.dart';
import 'package:quizfreely_flutter/models/term.dart';
import 'package:quizfreely_flutter/services/database_service.dart';
import 'package:quizfreely_flutter/services/app_settings.dart';

class ApiStudyset {
  final String id;
  final String title;
  final String? description;
  final List<ApiTerm> terms;

  ApiStudyset({
    required this.id,
    required this.title,
    this.description,
    required this.terms,
  });
}

class ApiTerm {
  final String term;
  final String definition;

  ApiTerm({required this.term, required this.definition});
}

class QuizFreelyApiService {
  String get _baseUrl => '${AppSettings().apiUrl}/api';

  // Search public study sets on quizfreely.org
  Future<List<ApiStudyset>> searchStudysets(String query) async {
    try {
      const gqlQuery = r'''
        query SearchStudysets($query: String!) {
          searchStudysets(query: $query, limit: 20) {
            id
            title
            description
          }
        }
      ''';

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': gqlQuery,
              'variables': {'query': query},
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      final sets = data['data']?['searchStudysets'];
      if (sets == null || sets is! List) return [];

      return sets
          .map<ApiStudyset>((s) => ApiStudyset(
                id: s['id'].toString(),
                title: s['title'] ?? 'Untitled',
                description: s['description'],
                terms: [],
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Fetch full study set with terms
  Future<ApiStudyset?> fetchStudyset(String id) async {
    try {
      const gqlQuery = r'''
        query GetStudyset($id: ID!) {
          studyset(id: $id) {
            id
            title
            description
            terms {
              term
              definition
            }
          }
        }
      ''';

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': gqlQuery,
              'variables': {'id': id},
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      final s = data['data']?['studyset'];
      if (s == null) return null;

      final rawTerms = s['terms'] as List? ?? [];
      final terms = rawTerms
          .map<ApiTerm>((t) => ApiTerm(
                term: t['term']?.toString() ?? '',
                definition: t['definition']?.toString() ?? '',
              ))
          .toList();

      return ApiStudyset(
        id: s['id'].toString(),
        title: s['title'] ?? 'Untitled',
        description: s['description'],
        terms: terms,
      );
    } catch (_) {
      return null;
    }
  }

  // Save a downloaded studyset to local SQLite
  Future<int> downloadToLocal(ApiStudyset apiSet) async {
    final db = DatabaseService();
    final studyset = Studyset(
      title: apiSet.title,
      description: apiSet.description,
    );
    final id = await db.insertStudyset(studyset);

    final terms = apiSet.terms.asMap().entries.map((e) {
      return Term(
        studysetId: id,
        term: e.value.term,
        definition: e.value.definition,
        sortOrder: e.key,
      );
    }).toList();

    await db.replaceTermsForStudyset(id, terms);
    return id;
  }

  // Explore popular/recent studysets (no auth required)
  Future<List<ApiStudyset>> exploreStudysets() async {
    try {
      const gqlQuery = r'''
        query ExploreStudysets {
          exploreStudysets(limit: 20) {
            id
            title
            description
          }
        }
      ''';

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'query': gqlQuery}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      final sets = data['data']?['exploreStudysets'];
      if (sets == null || sets is! List) return [];

      return sets
          .map<ApiStudyset>((s) => ApiStudyset(
                id: s['id'].toString(),
                title: s['title'] ?? 'Untitled',
                description: s['description'],
                terms: [],
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isOnline() async {
    try {
      final response = await http
          .get(Uri.parse('https://quizfreely.org'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
