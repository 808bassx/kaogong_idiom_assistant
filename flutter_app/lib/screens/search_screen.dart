import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../models/word.dart';
import 'word_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'keyword';
  bool _showResults = false;

  final List<Map<String, String>> _searchTypes = [
    {'value': 'keyword', 'label': '关键词'},
    {'value': 'pinyin', 'label': '拼音'},
    {'value': 'fuzzy', 'label': '模糊'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索成语'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                // 搜索框
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '输入成语、拼音或关键词...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _showResults = false);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 8),
                // 搜索类型切换
                Row(
                  children: _searchTypes.map((type) {
                    final isSelected = _searchType == type['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type['label']!),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _searchType = type['value']!);
                          if (_searchController.text.isNotEmpty) {
                            _search();
                          }
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _showResults
          ? Consumer<WordProvider>(
              builder: (context, provider, _) {
                if (provider.isSearching) {
                  return const Center(child: CircularProgressIndicator());
                }

                final results = provider.searchResults;

                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          '未找到相关成语',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '试试其他关键词或搜索方式',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: results.length,
                  itemBuilder: (_, index) {
                    final word = results[index];
                    return _buildWordCard(context, word);
                  },
                );
              },
            )
          : _buildInitialState(context),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.manage_search, size: 80, color: colorScheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            '搜索成语词库',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '支持关键词、拼音和模糊搜索',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(BuildContext context, WordModel word) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WordDetailScreen(word: word),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          word.word,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (word.isMastered)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(Icons.check_circle,
                                size: 16, color: Colors.green),
                          ),
                        if (word.isFavorite)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.favorite,
                                size: 16, color: Colors.red.shade300),
                          ),
                      ],
                    ),
                    if (word.pinyin.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        word.pinyin,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (word.meaning.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        word.meaning,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (word.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: word.tags.map((tag) => Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 10)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _search() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    setState(() => _showResults = true);

    context.read<WordProvider>().search(keyword, type: _searchType);
  }
}
