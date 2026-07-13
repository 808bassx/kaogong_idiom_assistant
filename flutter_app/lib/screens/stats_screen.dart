import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Map<String, dynamic> _stats = {
    'total_words': 128,
    'today_learned': 5,
    'week_learned': 23,
    'month_learned': 45,
    'mastered': 67,
    'favorite_count': 12,
    'accuracy': 78.5,
    'total_reviews': 356,
    'error_rate': 12.3,
  };

  final List<Map<String, dynamic>> _dailyData = [
    {'day': '周一', 'count': 8},
    {'day': '周二', 'count': 12},
    {'day': '周三', 'count': 5},
    {'day': '周四', 'count': 15},
    {'day': '周五', 'count': 10},
    {'day': '周六', 'count': 3},
    {'day': '周日', 'count': 7},
  ];

  final int _currentYear = 2026;
  final int _currentMonth = 7;

  // Sample study days for the calendar (day-of-month)
  final Set<int> _studyDays = {1, 2, 3, 5, 7, 10, 12, 15, 18, 20, 22, 25, 27};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习统计'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildOverviewSection(),
            const SizedBox(height: 16),
            _buildMasterySection(),
            const SizedBox(height: 16),
            _buildWeeklyChartSection(),
            const SizedBox(height: 16),
            _buildStatsInfoSection(),
            const SizedBox(height: 16),
            _buildCalendarSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // 1. Overview cards (2×2 grid)
  // -------------------------------------------------------
  Widget _buildOverviewSection() {
    final cards = [
      {'label': '累计学习', 'value': '${_stats['total_words']}', 'icon': Icons.menu_book_rounded, 'color': const Color(0xFF1565C0)},
      {'label': '今日学习', 'value': '${_stats['today_learned']}', 'icon': Icons.today_rounded, 'color': const Color(0xFF2E7D32)},
      {'label': '本周学习', 'value': '${_stats['week_learned']}', 'icon': Icons.date_range_rounded, 'color': const Color(0xFFE65100)},
      {'label': '本月学习', 'value': '${_stats['month_learned']}', 'icon': Icons.calendar_month_rounded, 'color': const Color(0xFF6A1B9A)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '学习概览',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final progress = (Interval(
                  0.2 + 0.1 * index,
                  0.6 + 0.1 * index,
                  curve: Curves.easeOutCubic,
                ).transform(_animationController.value));
                return Opacity(
                  opacity: progress,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - progress)),
                    child: child,
                  ),
                );
              },
              child: _buildOverviewCard(
                label: card['label'] as String,
                value: card['value'] as String,
                icon: card['icon'] as IconData,
                color: card['color'] as Color,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // 2. Mastery circular progress
  // -------------------------------------------------------
  Widget _buildMasterySection() {
    final mastered = _stats['mastered'] as int;
    final total = _stats['total_words'] as int;
    final accuracy = _stats['accuracy'] as double;
    final masteryRate = total > 0 ? mastered / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '掌握情况',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _CircularProgressPainter(
                          progress: masteryRate * _animationController.value,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          progressColor: Theme.of(context).colorScheme.primary,
                          trackWidth: 12,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${accuracy.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '掌握率',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '已掌握 $mastered/$total 词',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '正确率 ${accuracy.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: masteryRate,
                    minHeight: 8,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------
  // 3. Weekly bar chart
  // -------------------------------------------------------
  Widget _buildWeeklyChartSection() {
    final maxCount = _dailyData
        .fold<int>(0, (max, d) => (d['count'] as int) > max ? d['count'] : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '本周学习趋势',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_dailyData.length, (index) {
                  final item = _dailyData[index];
                  final count = item['count'] as int;
                  final day = item['day'] as String;
                  final barHeight = maxCount > 0
                      ? (count / maxCount) * 140.0
                      : 0.0;
                  final isToday = index == _dailyData.length - 1;

                  return Expanded(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final delay = 0.3 + 0.07 * index;
                        final animValue = CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            delay,
                            delay + 0.4,
                            curve: Curves.easeOutCubic,
                          ),
                        ).value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isToday
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                height: barHeight * animValue,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: isToday
                                        ? [
                                            Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.7),
                                          ]
                                        : [
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.5),
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.25),
                                          ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                day,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------
  // 4. Stats info row
  // -------------------------------------------------------
  Widget _buildStatsInfoSection() {
    final items = [
      {
        'icon': Icons.refresh_rounded,
        'label': '总复习次数',
        'value': '${_stats['total_reviews']}',
      },
      {
        'icon': Icons.cancel_outlined,
        'label': '错误率',
        'value': '${_stats['error_rate']}%',
      },
      {
        'icon': Icons.favorite_rounded,
        'label': '收藏数',
        'value': '${_stats['favorite_count']}',
      },
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Expanded(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final delay = 0.6 + 0.1 * index;
                  final opacity = Interval(
                    delay,
                    delay + 0.25,
                    curve: Curves.easeOut,
                  ).transform(_animationController.value);
                  return Opacity(
                    opacity: opacity,
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['value'] as String,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // 5. Learning calendar
  // -------------------------------------------------------
  Widget _buildCalendarSection() {
    // Days of week header
    const weekDays = ['一', '二', '三', '四', '五', '六', '日'];

    // July 2026 starts on a Wednesday.
    // 2026-07-01 is a Wednesday. In DateTime, Monday=1, Sunday=7.
    // Wednesday = 3, so weekday index (Mon=0..Sun=6) = 2 (Wednesday).
    // But we want Mon=0. The DateTime weekday for Monday is 1, so offset = weekday - 1.
    final firstDayOfMonth = DateTime(_currentYear, _currentMonth, 1);
    final startOffset = firstDayOfMonth.weekday - 1; // 0=Monday
    final daysInMonth = DateTime(_currentYear, _currentMonth + 1, 0).day;

    // Build a list of day widgets: null for empty slots, int for day numbers.
    final List<Object?> calendarDays = [];
    for (int i = 0; i < startOffset; i++) {
      calendarDays.add(null);
    }
    for (int day = 1; day <= daysInMonth; day++) {
      calendarDays.add(day);
    }

    const int crossAxisCount = 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '学习日历',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Month header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    Text(
                      '${_currentYear}年${_currentMonth}月',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Weekday headers
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: calendarDays.length + 7, // +7 for weekday header
                  itemBuilder: (context, index) {
                    if (index < 7) {
                      // Weekday header
                      final isWeekend = index >= 5;
                      return Center(
                        child: Text(
                          weekDays[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isWeekend
                                ? Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withOpacity(0.7)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    final dayIndex = index - 7;
                    if (dayIndex >= calendarDays.length) {
                      return const SizedBox.shrink();
                    }

                    final day = calendarDays[dayIndex];
                    if (day == null) {
                      return const SizedBox.shrink();
                    }

                    final dayNumber = day as int;
                    final hasStudied = _studyDays.contains(dayNumber);
                    final isToday = dayNumber == 13 &&
                        _currentYear == 2026 &&
                        _currentMonth == 7;

                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final slotIndex = dayIndex;
                        final delay = 0.7 + 0.008 * slotIndex;
                        final opacity = Interval(
                          delay,
                          delay + 0.3,
                          curve: Curves.easeOut,
                        ).transform(_animationController.value);
                        return Opacity(
                          opacity: opacity,
                          child: Container(
                            decoration: BoxDecoration(
                              color: hasStudied
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.12)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              border: isToday
                                  ? Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$dayNumber',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isToday
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isToday
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : hasStudied
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                    ),
                                  ),
                                  if (hasStudied)
                                    Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.only(top: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------
// Custom circular progress painter
// ---------------------------------------------------------------
class _CircularProgressPainter extends CustomPainter {
  static const double _pi = 3.1415926535897932;

  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double trackWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.trackWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - trackWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -_pi / 2, // Start from top
      2 * _pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackWidth != trackWidth;
  }
}
