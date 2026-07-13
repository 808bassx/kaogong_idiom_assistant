import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  int _questionCount = 5;
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  final TextEditingController _answerController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isStarted = false;
  bool _isFinished = false;
  bool _isLoading = false;
  bool _showAnswer = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _answerController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startQuiz() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final questions = await api.generateQuiz(count: _questionCount);
      setState(() {
        _questions = questions;
        _isStarted = true;
        _isLoading = false;
        _currentIndex = 0;
        _results = [];
        _isFinished = false;
        _showAnswer = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成题目失败：$e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _submitAnswer() {
    final answer = _answerController.text.trim();
    final question = _questions[_currentIndex];

    setState(() => _showAnswer = true);

    _results.add({
      'question_id': question['id'],
      'word': question['word'],
      'user_answer': answer,
      'correct_answer': question['meaning'] as String? ?? '',
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
        _answerController.clear();
      });
      _animController.forward(from: 0);
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final result = await api.submitQuiz(_results);
      setState(() {
        _isFinished = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败：$e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  int get _correctCount => _results.where((r) {
    final q = _questions.firstWhere(
      (q) => q['id'] == r['question_id'],
      orElse: () => {'meaning': ''},
    );
    final correct = q['meaning'] as String? ?? '';
    final user = r['user_answer'] as String? ?? '';
    return user.isNotEmpty && correct.contains(user.substring(0, user.length > 5 ? 5 : user.length));
  }).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('抽查模式'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isFinished
              ? _buildResultPage(theme, colorScheme)
              : _isStarted
                  ? _buildQuizPage(theme, colorScheme)
                  : _buildStartPage(theme, colorScheme),
    );
  }

  Widget _buildStartPage(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '成语抽查',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '选择题目数量开始测试',
              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            // 题目数量选择
            Wrap(
              spacing: 12,
              children: [5, 10, 20].map((count) {
                final isSelected = _questionCount == count;
                return ChoiceChip(
                  label: Text('$count 题'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _questionCount = count),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _startQuiz,
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始测试'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizPage(ThemeData theme, ColorScheme colorScheme) {
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
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
              '${_currentIndex + 1} / ${_questions.length}',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // 词语显示
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(
                      question['word'] ?? '',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (question['pinyin'] != null && (question['pinyin'] as String).isNotEmpty)
                      Text(
                        question['pinyin'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 题目
            Text(
              '请写出该成语的释义：',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),

            // 输入
            TextField(
              controller: _answerController,
              decoration: InputDecoration(
                hintText: '输入释义...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
              enabled: !_showAnswer,
            ),
            const SizedBox(height: 16),

            // 答案展示
            if (_showAnswer) ...[
              Card(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('正确答案：', style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                      )),
                      const SizedBox(height: 8),
                      Text(
                        question['meaning'] ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                      if (question['example'] != null && (question['example'] as String).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('例句：${question['example']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Spacer(),

            // 按钮
            SizedBox(
              width: double.infinity,
              child: _showAnswer
                  ? FilledButton.icon(
                      onPressed: _nextQuestion,
                      icon: Icon(_currentIndex < _questions.length - 1
                          ? Icons.arrow_forward
                          : Icons.check),
                      label: Text(_currentIndex < _questions.length - 1 ? '下一题' : '完成'),
                    )
                  : FilledButton.icon(
                      onPressed: _submitAnswer,
                      icon: const Icon(Icons.check),
                      label: const Text('提交答案'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPage(ThemeData theme, ColorScheme colorScheme) {
    final total = _questions.length;
    final correct = _correctCount;
    final accuracy = total > 0 ? (correct / total * 100).toStringAsFixed(1) : '0';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: double.parse(accuracy) >= 60
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$accuracy%',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: double.parse(accuracy) >= 60 ? Colors.green : Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              double.parse(accuracy) >= 80 ? '优秀！' :
              double.parse(accuracy) >= 60 ? '不错！' : '继续努力！',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildResultChip('$correct', '正确', Colors.green),
                const SizedBox(width: 24),
                _buildResultChip('${total - correct}', '错误', Colors.red),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isStarted = false;
                    _isFinished = false;
                    _questions = [];
                    _results = [];
                  });
                },
                icon: const Icon(Icons.replay),
                label: const Text('再来一轮'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text('返回首页'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultChip(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
