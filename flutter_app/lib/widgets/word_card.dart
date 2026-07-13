import 'package:flutter/material.dart';
import '../models/word.dart';

class WordCard extends StatelessWidget {
  final WordModel word;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onMaster;

  const WordCard({
    super.key,
    required this.word,
    this.onTap,
    this.onFavorite,
    this.onMaster,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 词语名
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          word.word,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (word.isMastered)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(Icons.check_circle, size: 18, color: Colors.green),
                          ),
                        if (word.isFavorite)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.favorite, size: 18, color: Colors.red.shade300),
                          ),
                      ],
                    ),
                  ),
                  // 操作按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: word.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: word.isFavorite ? Colors.red : null,
                        onPressed: onFavorite,
                      ),
                      const SizedBox(width: 4),
                      _buildActionButton(
                        icon: word.isMastered ? Icons.check_circle : Icons.check_circle_outline,
                        color: word.isMastered ? Colors.green : null,
                        onPressed: onMaster,
                      ),
                    ],
                  ),
                ],
              ),
              // 拼音
              if (word.pinyin.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  word.pinyin,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              // 释义
              if (word.meaning.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  word.meaning,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
              // 标签和统计
              const SizedBox(height: 8),
              Row(
                children: [
                  // 标签
                  if (word.tags.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: word.tags.take(3).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTagColor(tag).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              color: _getTagColor(tag),
                            ),
                          ),
                        )).toList()
                          ..addAll(
                            word.tags.length > 3
                                ? [Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '+${word.tags.length - 3}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  )]
                                : [],
                          ),
                      ),
                    ),
                  // 统计
                  Row(
                    children: [
                      if (word.reviewCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.replay, size: 14, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 2),
                              Text('${word.reviewCount}', style: TextStyle(
                                fontSize: 12, color: colorScheme.onSurfaceVariant,
                              )),
                            ],
                          ),
                        ),
                      if (word.errorCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 14, color: Colors.orange.shade300),
                            const SizedBox(width: 2),
                            Text('${word.errorCount}', style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade300,
                            )),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    Color? color,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: color,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case '高频':
        return Colors.red;
      case '低频':
        return Colors.blue;
      case '申论':
        return Colors.green;
      case '行测':
        return Colors.orange;
      case '易错':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
