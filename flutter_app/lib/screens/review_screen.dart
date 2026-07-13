import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/word.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<Map<String, dynamic>> _reviewItems = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isStarted = false;
  bool _isFinished = false;
  bool _showAnswer = false;
  int _correctCount = 0;
  int _wrongCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final items = await api.getTodayReview();
      setState(() {
        _reviewItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startReview() async {
    setState(() {
      _isStarted = true;
      _currentIndex = 0;
      _correctCount = 0;
      _wrongCount = 0;
      _showAnswer = false;
      _isFinished = false;
    });
  }

  Future<void> _answer(bool isCorrect) async {
    setState(() => _showAnswer = true);
    if (isCorrect) {
      _correctCount++;
    } else {
      _wrongCount++;
    }
  }

  Future<void> _next() async {
    final item = _reviewItems[_currentIndex];
    final isCorrect = _correctCount + _wrongCount > 0 &&
        _correctCount > (_currentIndex == 0 ? 0 : _correctCount);

    try {
      final api = context.read<ApiService>();
      await api.submitReview(item['word_id'], _correctCount > _wrongCount);
    } catch (_) {}

    if (_currentIndex < _reviewItems.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    } else {
      setState(() => _isFinished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日复习'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isFinished
              ? _buildFinishedPage(theme, colorScheme)
              : _isStarted
                  ? _buildReviewPage(theme, colorScheme)
                  : _buildStartPage(theme, colorScheme),
    );
  }

  Widget _buildStartPage(ThemeData theme, ColorScheme colorScheme) {
    final totalToday = _reviewItems.length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.replay_circle_filled_outlined, size: 64, color: colorScheme.tertiary),
            ),
            const SizedBox(height: 24),
            Text(
              '每日复习',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              totalToday > 0
                  ? '今天有 $totalToday 个词语需要复习'
                  : '今天没有需要复习的词语 🎉',
              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            if (totalToday > 0) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _startReview,
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始复习'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewPage(ThemeData theme, ColorScheme colorScheme) {
    final item = _reviewItems[_currentIndex];
    final progress = (_currentIndex + 1) / _reviewItems.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 进度
          LinearProgressIndicator(
            value: progress,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentIndex + 1} / ${_reviewItems.length}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          // 词语卡片
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(
                    item['word'] ?? '',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item['pinyin'] != null && (item['pinyin'] as String).isNotEmpty)
                    Text(
                      item['pinyin'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 答案区
          if (_showAnswer) ...[
            Card(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('释义', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(item['meaning'] ?? '', style: const TextStyle(height: 1.5)),
                    if (item['example'] != null && (item['example'] as String).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('例句', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(item['example'], style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      )),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Spacer(),

          // 按钮
          if (!_showAnswer)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _answer(false),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('不认识', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _answer(true),
                    icon: const Icon(Icons.check),
                    label: const Text('认识'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _next,
                icon: Icon(_currentIndex < _reviewItems.length - 1
                    ? Icons.arrow_forward
                    : Icons.check),
                label: Text(_currentIndex < _reviewItems.length - 1 ? '下一个' : '完成复习'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinishedPage(ThemeData theme, ColorScheme colorScheme) {
    final total = _correctCount + _wrongCount;
    final accuracy = total > 0 ? (_correctCount / total * 100).toStringAsFixed(0) : '0';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.celebration_outlined, size: 64, color: Colors.green),
            ),
            const SizedBox(height: 24),
            Text(
              '复习完成！',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip('$_correctCount', '正确', Colors.green),
                const SizedBox(width: 24),
                _buildStatChip('$_wrongCount', '错误', Colors.red),
                const SizedBox(width: 24),
                _buildStatChip('$accuracy%', '正确率', colorScheme.primary),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _isStarted = false;
                    _isFinished = false;
                  });
                  _loadReviews();
                },
                icon: const Icon(Icons.home),
                label: const Text('返回'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String count, String label, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
