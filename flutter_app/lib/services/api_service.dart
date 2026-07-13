import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/word.dart';
import '../models/chat_message.dart';

class ApiService {
  String _host;
  int _port;

  ApiService({String host = '127.0.0.1', int port = 8000})
      : _host = host,
        _port = port;

  String get baseUrl => 'http://$_host:$_port/api';

  void updateConfig({String? host, int? port}) {
    if (host != null) _host = host;
    if (port != null) _port = port;
  }

  // ===== 词语管理 =====

  Future<WordListResponse> getWords({
    int page = 1,
    int pageSize = 20,
    String? tag,
    bool? favoriteOnly,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (tag != null && tag != '全部') params['tag'] = tag;
    if (favoriteOnly == true) params['favorite_only'] = 'true';

    final uri = Uri.parse('$baseUrl/words').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return WordListResponse.fromJson(jsonDecode(response.body));
    }
    throw ApiException('获取词语列表失败', response.statusCode);
  }

  Future<WordModel> getWord(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/words/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return WordModel.fromJson(jsonDecode(response.body));
    }
    throw ApiException('获取词语详情失败', response.statusCode);
  }

  Future<WordModel> createWord(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/words'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return WordModel.fromJson(jsonDecode(response.body));
    }
    throw ApiException('创建词语失败', response.statusCode);
  }

  Future<WordModel> updateWord(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/words/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return WordModel.fromJson(jsonDecode(response.body));
    }
    throw ApiException('更新词语失败', response.statusCode);
  }

  Future<void> deleteWord(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/words/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw ApiException('删除词语失败', response.statusCode);
    }
  }

  Future<bool> toggleMaster(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/words/$id/master'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['is_mastered'] ?? false;
    }
    throw ApiException('切换掌握状态失败', response.statusCode);
  }

  Future<bool> toggleFavorite(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/words/$id/favorite'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['is_favorite'] ?? false;
    }
    throw ApiException('切换收藏状态失败', response.statusCode);
  }

  Future<WordListResponse> searchWords({
    required String keyword,
    String searchType = 'keyword',
    String? tag,
    bool favoriteOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, String>{
      'keyword': keyword,
      'search_type': searchType,
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (tag != null && tag != '全部') params['tag'] = tag;
    if (favoriteOnly) params['favorite_only'] = 'true';

    final uri = Uri.parse('$baseUrl/words/search').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return WordListResponse.fromJson(jsonDecode(response.body));
    }
    throw ApiException('搜索失败', response.statusCode);
  }

  // ===== 标签 =====

  Future<List<Map<String, dynamic>>> getTags() async {
    final response = await http.get(
      Uri.parse('$baseUrl/words/tags/list'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  // ===== 学习统计 =====

  Future<Map<String, dynamic>> getTodayStudy() async {
    final response = await http.get(
      Uri.parse('$baseUrl/study/today'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> getRecentStudy({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/study/recent?limit=$limit'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['records'] ?? []);
    }
    return [];
  }

  // ===== AI 对话 =====

  Future<Stream<String>> chat(String message, {int? wordId}) async {
    final uri = Uri.parse('$baseUrl/chat');
    final request = http.Request('POST', uri);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    });
    request.body = jsonEncode({
      'message': message,
      'stream': true,
      'word_id': wordId,
    });

    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw ApiException('对话请求失败', response.statusCode);
    }

    return response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.startsWith('data: ') && !line.contains('[DONE]'))
        .map((line) {
          try {
            final data = jsonDecode(line.substring(6));
            return data['content'] as String? ?? '';
          } catch (_) {
            return '';
          }
        });
  }

  Future<Stream<String>> explainIdiom(String word) async {
    final uri = Uri.parse('$baseUrl/chat/explain');
    final request = http.Request('POST', uri);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    });
    request.body = jsonEncode({
      'message': word,
      'stream': true,
    });

    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw ApiException('解释成语失败', response.statusCode);
    }

    return response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.startsWith('data: ') && !line.contains('[DONE]'))
        .map((line) {
          try {
            final data = jsonDecode(line.substring(6));
            return data['content'] as String? ?? '';
          } catch (_) {
            return '';
          }
        });
  }

  Future<List<ChatMessageModel>> getChatHistory({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/history?page=$page&page_size=$pageSize'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['messages'] as List? ?? [])
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> clearChatHistory() async {
    await http.delete(
      Uri.parse('$baseUrl/chat/history'),
      headers: _headers,
    );
  }

  // ===== 抽查 =====

  Future<List<Map<String, dynamic>>> generateQuiz({
    int count = 5,
    String? tag,
  }) async {
    final uri = Uri.parse('$baseUrl/quiz/generate?count=$count${tag != null && tag != '全部' ? '&tag=$tag' : ''}');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'count': count}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['questions'] ?? []);
    }
    throw ApiException('生成题目失败', response.statusCode);
  }

  Future<Map<String, dynamic>> submitQuiz(List<Map<String, dynamic>> answers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quiz/submit'),
      headers: _headers,
      body: jsonEncode(answers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException('提交答案失败', response.statusCode);
  }

  Future<Map<String, dynamic>?> getRandomWord() async {
    final response = await http.get(
      Uri.parse('$baseUrl/quiz/random'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // ===== 复习 =====

  Future<List<Map<String, dynamic>>> getTodayReview() async {
    final response = await http.get(
      Uri.parse('$baseUrl/review/today'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['items'] ?? []);
    }
    return [];
  }

  Future<Map<String, dynamic>> submitReview(int wordId, bool isCorrect) async {
    final response = await http.post(
      Uri.parse('$baseUrl/review/submit'),
      headers: _headers,
      body: jsonEncode({'word_id': wordId, 'is_correct': isCorrect}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException('提交复习失败', response.statusCode);
  }

  Future<Map<String, dynamic>> getReviewStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/review/stats'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  // ===== 统计 =====

  Future<Map<String, dynamic>> getStatsOverview() async {
    final response = await http.get(
      Uri.parse('$baseUrl/stats/overview'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> getDailyStats({int days = 30}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/stats/daily?days=$days'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  // ===== 设置 =====

  Future<Map<String, dynamic>> getAllSettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<void> updateSetting(String key, String value) async {
    await http.put(
      Uri.parse('$baseUrl/settings/$key?value=$value'),
      headers: _headers,
    );
  }

  Future<void> updateSettings(Map<String, String> settings) async {
    await http.put(
      Uri.parse('$baseUrl/settings'),
      headers: _headers,
      body: jsonEncode(settings),
    );
  }

  Future<Map<String, dynamic>> getAIConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings/ai/config'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<void> updateAIConfig(Map<String, String> config) async {
    await http.put(
      Uri.parse('$baseUrl/settings/ai/config'),
      headers: _headers,
      body: jsonEncode(config),
    );
  }

  Future<Map<String, dynamic>> getAIHealth() async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings/ai/health'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<List<String>> getAIModels(String engine) async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings/ai/models?engine=$engine'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['models'] ?? []);
    }
    return [];
  }

  // ===== Prompt =====

  Future<List<Map<String, dynamic>>> getPrompts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/prompts'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<Map<String, dynamic>> getActivePrompt() async {
    final response = await http.get(
      Uri.parse('$baseUrl/prompts/active'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<void> createPrompt(String name, String content) async {
    await http.post(
      Uri.parse('$baseUrl/prompts'),
      headers: _headers,
      body: jsonEncode({'name': name, 'content': content}),
    );
  }

  Future<void> updatePrompt(int id, Map<String, dynamic> data) async {
    await http.put(
      Uri.parse('$baseUrl/prompts/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
  }

  Future<void> deletePrompt(int id) async {
    await http.delete(
      Uri.parse('$baseUrl/prompts/$id'),
      headers: _headers,
    );
  }

  Future<void> activatePrompt(int id) async {
    await http.post(
      Uri.parse('$baseUrl/prompts/$id/activate'),
      headers: _headers,
    );
  }

  Future<void> resetDefaultPrompt() async {
    await http.post(
      Uri.parse('$baseUrl/prompts/reset-default'),
      headers: _headers,
    );
  }

  // ===== 导出 =====

  String getExportUrl(String format, {List<int>? wordIds}) {
    final params = <String, String>{};
    if (wordIds != null && wordIds.isNotEmpty) {
      params['word_ids'] = wordIds.join(',');
    }
    final uri = Uri.parse('$baseUrl/export/$format').replace(queryParameters: params);
    return uri.toString();
  }

  // ===== 备份 =====

  Future<Map<String, dynamic>> backupDatabase() async {
    final response = await http.post(
      Uri.parse('$baseUrl/settings/backup'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException('备份失败', response.statusCode);
  }

  Future<List<Map<String, dynamic>>> listBackups() async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings/backups'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['backups'] ?? []);
    }
    return [];
  }

  // ===== 收藏 =====

  Future<WordListResponse> getFavorites({int page = 1, int pageSize = 20}) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    final response = await http.get(
      Uri.parse('$baseUrl/favorites').replace(queryParameters: params),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return WordListResponse(
        total: data['total'] ?? 0,
        page: data['page'] ?? 1,
        pageSize: data['page_size'] ?? 20,
        words: (data['words'] as List? ?? [])
            .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    throw ApiException('获取收藏列表失败', response.statusCode);
  }

  // ===== 统计扩展接口 =====

  Future<Map<String, dynamic>> getStatsOverviewExt() async {
    // 整合多个统计接口
    try {
      final study = await getTodayStudy();
      final reviewStats = await getReviewStats();

      return {
        'total_words': study['total_words'] ?? 0,
        'today_learned': study['today_learned'] ?? 0,
        'today_new': study['today_new'] ?? 0,
        'today_review': reviewStats['today_review'] ?? 0,
      };
    } catch (e) {
      return {};
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
