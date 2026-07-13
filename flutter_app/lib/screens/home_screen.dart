import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../config/constants.dart';
import 'word_list_screen.dart';
import 'quiz_screen.dart';
import 'review_screen.dart';
import 'search_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final List<Animation<double>> _itemAnimations;

  final List<_ActivityItem> _recentActivity = const [
    _ActivityItem('胸有成竹', '学习了', '10分钟前', _ActivityIcon.study),
    _ActivityItem('对牛弹琴', '复习了', '30分钟前', _ActivityIcon.review),
    _ActivityItem('画蛇添足', '学习了', '1小时前', _ActivityIcon.study),
    _ActivityItem('守株待兔', '抽查了', '2小时前', _ActivityIcon.quiz),
    _ActivityItem('叶公好龙', '学习了', '3小时前', _ActivityIcon.study),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _itemAnimations = List<Animation<double>>.generate(8, (int i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            i * 0.08,
            0.5 + i * 0.06,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordProvider>().loadWords();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(),
              _buildStatsSection(),
              _buildActionButtons(),
              _buildRecentActivity(),
              _buildQuickActions(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return _fadeSlide(
      index: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF0D47A1),
              Color(0xFF1565C0),
              Color(0xFF1E88E5),
              Color(0xFF42A5F5),
            ],
            stops: <double>[0.0, 0.3, 0.7, 1.0],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF0D47A1).withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Title row
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '每日积累，轻松上岸',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.75),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Quick stats bar
            Consumer<WordProvider>(
              builder: (BuildContext context, WordProvider provider, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _headerStatItem(
                      Icons.library_books_rounded,
                      '${provider.total}',
                      '总词库',
                    ),
                    _headerStatItem(
                      Icons.today_rounded,
                      '${provider.words.length}',
                      '已掌握',
                    ),
                    _headerStatItem(
                      Icons.local_fire_department_rounded,
                      '${(provider.total / 5).ceil()}',
                      '连续打卡',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: Colors.white.withOpacity(0.85), size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stats grid (2x2)
  // ---------------------------------------------------------------------------

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Consumer<WordProvider>(
        builder: (BuildContext context, WordProvider provider, _) {
          final List<_StatCardData> stats = <_StatCardData>[
            _StatCardData(
              icon: Icons.today_rounded,
              label: '今日学习',
              // TODO: replace with provider.todayStudy when available
              value: '${provider.words.length > 0 ? (provider.words.length % 8 + 1) : 0}',
              color: const Color(0xFF43A047),
              bgColor: const Color(0xFFE8F5E9),
            ),
            _StatCardData(
              icon: Icons.auto_stories_rounded,
              label: '今日新增',
              // TODO: replace with provider.todayNew when available
              value: '${provider.words.length > 3 ? (provider.words.length % 5 + 1) : 0}',
              color: const Color(0xFF1E88E5),
              bgColor: const Color(0xFFE3F2FD),
            ),
            _StatCardData(
              icon: Icons.library_books_rounded,
              label: '累计词数',
              value: '${provider.total}',
              color: const Color(0xFFFB8C00),
              bgColor: const Color(0xFFFFF8E1),
            ),
            _StatCardData(
              icon: Icons.replay_rounded,
              label: '待复习',
              // TODO: replace with provider.reviewCount when available
              value: '${provider.words.length > 5 ? (provider.words.length ~/ 4) : 0}',
              color: const Color(0xFF8E24AA),
              bgColor: const Color(0xFFF3E5F5),
            ),
          ];

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: stats.length,
            itemBuilder: (BuildContext context, int index) {
              return _fadeSlide(
                index: index + 1,
                child: _StatCard(data: stats[index]),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action buttons : 继续学习 / 随机抽查
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: _fadeSlide(
        index: 5,
        child: Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _onContinueLearning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFF1565C0).withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.play_arrow_rounded, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '继续学习',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: _onRandomQuiz,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1565C0),
                    side: const BorderSide(
                      color: Color(0xFF1565C0),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.shuffle_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        '随机抽查',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recent activity list
  // ---------------------------------------------------------------------------

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _fadeSlide(
        index: 6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  '最近学习',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<WordListScreen>(
                        builder: (BuildContext context) =>
                            const WordListScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('查看全部'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: _recentActivity
                    .map((_ActivityItem item) => _buildActivityTile(item))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(_ActivityItem item) {
    IconData leadingIcon;
    switch (item.iconType) {
      case _ActivityIcon.review:
        leadingIcon = Icons.replay_rounded;
        break;
      case _ActivityIcon.quiz:
        leadingIcon = Icons.quiz_rounded;
        break;
      case _ActivityIcon.study:
      default:
        leadingIcon = Icons.menu_book_rounded;
        break;
    }

    final Color tileColor;
    switch (item.iconType) {
      case _ActivityIcon.review:
        tileColor = const Color(0xFF1E88E5);
        break;
      case _ActivityIcon.quiz:
        tileColor = const Color(0xFFFB8C00);
        break;
      case _ActivityIcon.study:
      default:
        tileColor = const Color(0xFF43A047);
        break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: tileColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(leadingIcon, color: tileColor, size: 20),
      ),
      title: Text(
        item.word,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        item.action,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: Text(
        item.time,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
      ),
      shape: Border(
        bottom: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Quick action chips
  // ---------------------------------------------------------------------------

  Widget _buildQuickActions() {
    final List<_QuickActionData> actions = <_QuickActionData>[
      _QuickActionData(
        icon: Icons.search_rounded,
        label: '搜索',
        color: const Color(0xFF1E88E5),
        onTap: _onSearch,
      ),
      _QuickActionData(
        icon: Icons.shuffle_rounded,
        label: '抽查',
        color: const Color(0xFFFB8C00),
        onTap: _onRandomQuiz,
      ),
      _QuickActionData(
        icon: Icons.replay_rounded,
        label: '复习',
        color: const Color(0xFF8E24AA),
        onTap: _onReview,
      ),
      _QuickActionData(
        icon: Icons.chat_rounded,
        label: 'AI对话',
        color: const Color(0xFF43A047),
        onTap: _onChat,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: _fadeSlide(
        index: 7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '快捷操作',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: actions
                  .map(
                    (_QuickActionData a) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: _QuickActionChip(data: a),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _onContinueLearning() {
    // Pass route argument to indicate navigation source
    Navigator.push(
      context,
      MaterialPageRoute<WordListScreen>(
        settings: const RouteSettings(
          arguments: <String, String>{'source': 'home_continue'},
        ),
        builder: (BuildContext context) => const WordListScreen(),
      ),
    );
  }

  void _onRandomQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute<QuizScreen>(
        settings: const RouteSettings(
          arguments: <String, dynamic>{'random': true, 'count': 10},
        ),
        builder: (BuildContext context) => const QuizScreen(),
      ),
    );
  }

  void _onSearch() {
    Navigator.push(
      context,
      MaterialPageRoute<SearchScreen>(
        builder: (BuildContext context) => const SearchScreen(),
      ),
    );
  }

  void _onReview() {
    Navigator.push(
      context,
      MaterialPageRoute<ReviewScreen>(
        builder: (BuildContext context) => const ReviewScreen(),
      ),
    );
  }

  void _onChat() {
    Navigator.push(
      context,
      MaterialPageRoute<ChatScreen>(
        builder: (BuildContext context) => const ChatScreen(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Animation helper
  // ---------------------------------------------------------------------------

  Widget _fadeSlide({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _itemAnimations[index],
      builder: (BuildContext context, Widget? animatedChild) {
        final double animValue = _itemAnimations[index].value;
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 28.0 * (1.0 - animValue)),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

/// Stat card shown in the 2x2 grid.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: data.bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: data.color.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const Spacer(),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: data.color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick-action chip button.
class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: data.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: data.color.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(data.icon, color: data.color, size: 26),
              const SizedBox(height: 8),
              Text(
                data.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: data.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class _StatCardData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

enum _ActivityIcon { study, review, quiz }

class _ActivityItem {
  final String word;
  final String action;
  final String time;
  final _ActivityIcon iconType;

  const _ActivityItem(this.word, this.action, this.time, this.iconType);
}
