import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _api;

  ChatProvider(this._api);

  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isStreaming = false;
  String? _error;
  String _currentResponse = '';

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
  String? get error => _error;
  String get currentResponse => _currentResponse;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _messages = await _api.getChatHistory(pageSize: 100);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // 添加用户消息
    final userMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      role: 'user',
      content: message,
    );
    _messages.add(userMsg);
    _isStreaming = true;
    _currentResponse = '';
    notifyListeners();

    try {
      // 添加占位的 AI 消息
      final aiMsg = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        role: 'assistant',
        content: '',
      );
      _messages.add(aiMsg);
      notifyListeners();

      // 流式接收
      final stream = await _api.chat(message);
      await for (final chunk in stream) {
        _currentResponse += chunk;
        // 更新最后一条消息
        _messages.last = ChatMessageModel(
          id: _messages.last.id,
          role: 'assistant',
          content: _currentResponse,
        );
        notifyListeners();
      }

      _isStreaming = false;
      notifyListeners();

      // 加载完整历史（确保消息保存）
      await loadHistory();
    } catch (e) {
      _isStreaming = false;
      _error = e.toString();
      _messages.add(ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch + 2,
        role: 'assistant',
        content: '抱歉，AI 回复出错：$e',
      ));
      notifyListeners();
    }
  }

  Future<void> explainIdiom(String word) async {
    if (word.trim().isEmpty) return;

    final userMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      role: 'user',
      content: '请解释成语：$word',
    );
    _messages.add(userMsg);
    _isStreaming = true;
    _currentResponse = '';
    notifyListeners();

    try {
      final aiMsg = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        role: 'assistant',
        content: '',
      );
      _messages.add(aiMsg);
      notifyListeners();

      final stream = await _api.explainIdiom(word);
      await for (final chunk in stream) {
        _currentResponse += chunk;
        _messages.last = ChatMessageModel(
          id: _messages.last.id,
          role: 'assistant',
          content: _currentResponse,
        );
        notifyListeners();
      }

      _isStreaming = false;
      notifyListeners();
    } catch (e) {
      _isStreaming = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  void stopStreaming() {
    _isStreaming = false;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    try {
      await _api.clearChatHistory();
      _messages.clear();
      _currentResponse = '';
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void regenerate() {
    if (_messages.length >= 2) {
      // 删除最后一条 AI 回复
      if (!_messages.last.isUser) {
        _messages.removeLast();
      }
      // 重新发送最后一条用户消息
      if (_messages.isNotEmpty) {
        final lastUserMsg = _messages.lastWhere(
          (m) => m.isUser,
          orElse: () => _messages.last,
        );
        if (lastUserMsg.isUser) {
          sendMessage(lastUserMsg.content);
        }
      }
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
