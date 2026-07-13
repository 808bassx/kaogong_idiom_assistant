import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../providers/chat_provider.dart';
import '../models/word.dart';
import '../config/theme.dart';
import 'chat_screen.dart';

class WordDetailScreen extends StatefulWidget {
  final WordModel word;

  const WordDetailScreen({super.key, required this.word});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  late WordModel _word;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _word = widget.word;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_word.word),
        actions: [
          IconButton(
            icon: Icon(
              _word.isFavorite ? Icons.favorite : Icons.favorite_outline,
              color: _word.isFavorite ? Colors.red : null,
            ),
            onPressed: () async {
              final provider = context.read<WordProvider>();
              final result = await provider.toggleFavorite(_word.id);
              setState(() {
                _word = WordModel(
                  id: _word.id,
                  word: _word.word,
                  pinyin: _word.pinyin,
                  meaning: _word.meaning,
                  source: _word.source,
                  usage: _word.usage,
                  example: _word.example,
                  synonym: _word.synonym,
                  antonym: _word.antonym,
                  confusable: _word.confusable,
                  memoryTip: _word.memoryTip,
                  tags: _word.tags,
                  isMastered: _word.isMastered,
                  reviewCount: _word.reviewCount,
                  errorCount: _word.errorCount,
                  isFavorite: result,
                  notes: _word.notes,
                  createdAt: _word.createdAt,
                  updatedAt: _word.updatedAt,
                );
              });
            },
          ),
          IconButton(
            icon: Icon(
              _word.isMastered ? Icons.check_circle : Icons.check_circle_outline,
              color: _word.isMastered ? Colors.green : null,
            ),
            onPressed: () async {
              final provider = context.read<WordProvider>();
              final result = await provider.toggleMaster(_word.id);
              setState(() => _word = WordModel(
                id: _word.id,
                word: _word.word,
                isMastered: result,
                tags: _word.tags,
                isFavorite: _word.isFavorite,
                reviewCount: _word.reviewCount,
                errorCount: _word.errorCount,
                notes: _word.notes,
              ));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拼音和标签
            if (_word.pinyin.isNotEmpty) ...[
              Text(
                _word.pinyin,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // 标签
            if (_word.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _word.tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            const SizedBox(height: 16),

            // 释义
            _buildSection(
              context,
              '📖 释义',
              _word.meaning,
            ),

            // 出处
            if (_word.source.isNotEmpty)
              _buildSection(context, '📚 出处', _word.source),

            // 用法
            if (_word.usage.isNotEmpty)
              _buildSection(context, '✍️ 用法', _word.usage),

            // 例句
            if (_word.example.isNotEmpty)
              _buildSection(context, '💬 例句', _word.example),

            // 近义词
            if (_word.synonym.isNotEmpty)
              _buildSection(context, '➡️ 近义词', _word.synonym),

            // 反义词
            if (_word.antonym.isNotEmpty)
              _buildSection(context, '⬅️ 反义词', _word.antonym),

            // 易混词
            if (_word.confusable.isNotEmpty)
              _buildSection(context, '⚠️ 易混词', _word.confusable),

            // 记忆技巧
            if (_word.memoryTip.isNotEmpty)
              _buildSection(context, '🧠 记忆技巧', _word.memoryTip),

            const SizedBox(height: 16),

            // 学习统计
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '学习统计',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(),
                    _buildStatRow('复习次数', '${_word.reviewCount} 次'),
                    _buildStatRow('错误次数', '${_word.errorCount} 次'),
                    _buildStatRow('掌握状态', _word.isMastered ? '已掌握' : '学习中'),
                    if (_word.lastReviewedAt != null)
                      _buildStatRow('最后复习', _word.lastReviewedAt!.substring(0, 10)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      context.read<ChatProvider>().explainIdiom(_word.word);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('AI 深度解析'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
