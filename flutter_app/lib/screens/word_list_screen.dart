import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../models/word.dart';
import 'search_screen.dart';
import 'word_detail_screen.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final ScrollController _scrollController = ScrollController();

  static const List<_TagChipData> _tags = [
    _TagChipData('全部', ''),
    _TagChipData('高频', '高频'),
    _TagChipData('低频', '低频'),
    _TagChipData('申论', '申论'),
    _TagChipData('行测', '行测'),
    _TagChipData('易错', '易错'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordProvider>().loadWords();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<WordProvider>().loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<WordProvider>().loadWords(refresh: true);
  }

  void _onTagSelected(String tag) {
    context.read<WordProvider>().setTag(tag);
  }

  void _onFavoriteOnlyChanged(bool value) {
    context.read<WordProvider>().setFavoriteOnly(value);
  }

  void _onWordTap(WordModel word) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordDetailScreen(word: word),
      ),
    );
  }

  Future<void> _onLearnNewWord() async {
    final TextEditingController controller = TextEditingController();
    final String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('学习新词'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '请输入成语',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => Navigator.pop(context, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );

    if (input != null && input.isNotEmpty && mounted) {
      // Navigate to the explain flow / detail screen with the input word
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WordDetailScreen(
            word: WordModel(
              id: -1,
              word: input,
              pinyin: '',
              meaning: '',
              tags: const [],
              isMastered: false,
              isFavorite: false,
              reviewCount: 0,
              errorCount: 0,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('词库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tag filter chips
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Consumer<WordProvider>(
                builder: (context, provider, _) {
                  return Row(
                    children: _tags.map((tag) {
                      final bool isSelected =
                          provider.currentTag == tag.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tag.label),
                          selected: isSelected,
                          onSelected: (_) => _onTagSelected(tag.value),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),

          // Favorite-only toggle
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Consumer<WordProvider>(
              builder: (context, provider, _) {
                return Row(
                  children: [
                    Text(
                      '仅看收藏',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 32,
                      child: Switch.adaptive(
                        value: provider.favoriteOnly,
                        onChanged: _onFavoriteOnlyChanged,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '共 ${provider.total} 个成语',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Word list
          Expanded(
            child: Consumer<WordProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.words.isEmpty) {
                  return _buildShimmerLoading();
                }

                if (!provider.isLoading &&
                    provider.words.isEmpty) {
                  return _buildEmptyState(colorScheme);
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: provider.words.length +
                        (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.words.length) {
                        return _buildLoadingIndicator(colorScheme);
                      }
                      return _buildWordCard(provider.words[index], colorScheme);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onLearnNewWord,
        icon: const Icon(Icons.auto_stories),
        label: const Text('学习新词'),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _ShimmerCard();
      },
    );
  }

  Widget _buildLoadingIndicator(ColorScheme colorScheme) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              '还没有学习任何成语，开始学习吧！',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCard(WordModel word, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onWordTap(word),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: word + status icons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word.word,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                        ),
                        if (word.pinyin.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            word.pinyin,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (word.isMastered)
                    Tooltip(
                      message: '已掌握',
                      child: Icon(
                        Icons.check_circle,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                  if (word.isFavorite)
                    Tooltip(
                      message: '已收藏',
                      child: Icon(
                        Icons.favorite,
                        size: 20,
                        color: colorScheme.error,
                      ),
                    ),
                ],
              ),

              // Meaning preview
              if (word.meaning.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  word.meaning,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],

              // Tags + stats row
              if (word.tags.isNotEmpty ||
                  word.reviewCount > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Tag chips
                    ...word.tags.take(3).map(
                          (tag) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _tagColor(tag, colorScheme)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: _tagColor(tag, colorScheme),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ),
                        ),
                    if (word.tags.length > 3)
                      Text(
                        '+${word.tags.length - 3}',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                      ),
                    const Spacer(),
                    Icon(
                      Icons.replay,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${word.reviewCount}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (word.errorCount > 0) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.error_outline,
                        size: 14,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${word.errorCount}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.error,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _tagColor(String tag, ColorScheme colorScheme) {
    switch (tag) {
      case '高频':
        return Colors.deepOrange;
      case '低频':
        return Colors.teal;
      case '申论':
        return Colors.blue;
      case '行测':
        return Colors.purple;
      case '易错':
        return Colors.red;
      default:
        return colorScheme.secondary;
    }
  }
}

/// Data class for a tag filter chip.
class _TagChipData {
  final String label;
  final String value;

  const _TagChipData(this.label, this.value);
}

/// A shimmer placeholder card shown while the word list is loading.
class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title shimmer
                Container(
                  width: 160,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(
                      alpha: _animation.value,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle shimmer
                Container(
                  width: 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(
                      alpha: _animation.value * 0.6,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                // Body shimmer lines
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(
                      alpha: _animation.value * 0.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 180,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(
                      alpha: _animation.value * 0.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                // Tag shimmer row
                Row(
                  children: List.generate(3, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 40 + i * 8.0,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(
                            alpha: _animation.value * 0.4,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
