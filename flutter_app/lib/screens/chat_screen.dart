import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  // 快速操作成语示例
  static const List<_QuickAction> _quickActions = [
    _QuickAction('解释成语', Icons.auto_stories),
    _QuickAction('近义词', Icons.compare_arrows),
    _QuickAction('反义词', Icons.swap_horiz),
    _QuickAction('造句', Icons.edit_note),
    _QuickAction('典故', Icons.menu_book),
  ];

  @override
  void initState() {
    super.initState();
    // 加载历史消息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      if (chat.messages.isEmpty && !chat.isLoading) {
        chat.loadHistory();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    _focusNode.unfocus();

    setState(() => _isSending = true);

    try {
      final chat = context.read<ChatProvider>();
      final bool wasCurrentlyStreaming = chat.isStreaming;
      if (wasCurrentlyStreaming) {
        chat.stopStreaming();
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await chat.sendMessage(text);
    } finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  Future<void> _quickAction(String label) async {
    if (_isSending) return;
    _focusNode.unfocus();

    setState(() => _isSending = true);

    try {
      final chat = context.read<ChatProvider>();
      await chat.explainIdiom(label);
    } finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有对话记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ChatProvider>().clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI成语对话'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清除历史',
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chat, _) {
                if (chat.messages.isEmpty && !chat.isLoading) {
                  return _buildEmptyState(colorScheme);
                }

                return RefreshIndicator(
                  onRefresh: () => chat.loadHistory(),
                  child: GestureDetector(
                    onTap: () => _focusNode.unfocus(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 8,
                      ),
                      itemCount: chat.messages.length + (chat.isStreaming ? 1 : 0),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemBuilder: (context, index) {
                        // 流式加载中的提示
                        if (index == chat.messages.length && chat.isStreaming) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: _ThinkingIndicator(),
                          );
                        }

                        final message = chat.messages[index];
                        return _MessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          colorScheme: colorScheme,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // 快速操作栏
          _buildQuickActionBar(colorScheme),

          // 输入区域
          _buildInputArea(colorScheme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: () => context.read<ChatProvider>().loadHistory(),
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 成语书图标占位
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      Icons.auto_stories,
                      size: 56,
                      color: colorScheme.primary.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '开始你的成语学习之旅',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击下方成语标签快速学习，\n或输入你想了解的成语',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBar(ColorScheme colorScheme) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickActions.map((action) {
                final isDisabled = chat.isStreaming || chat.isLoading;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(
                      action.icon,
                      size: 16,
                    ),
                    label: Text(
                      action.label,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: isDisabled
                        ? null
                        : () => _quickAction(action.label),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        final bool canSend = !chat.isStreaming && !chat.isLoading;

        return Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  enabled: canSend,
                  textInputAction: TextInputAction.send,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    hintText: chat.isStreaming ? 'AI正在回复...' : '输入你想了解的成语...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  ),
                  onSubmitted: (_) {
                    if (canSend) _sendMessage();
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: chat.isStreaming
                    ? _buildStopButton(colorScheme)
                    : _buildSendButton(colorScheme, canSend),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSendButton(ColorScheme colorScheme, bool canSend) {
    return SizedBox(
      key: const ValueKey('send'),
      width: 44,
      height: 44,
      child: FilledButton(
        onPressed: (_textController.text.trim().isNotEmpty && canSend)
            ? _sendMessage
            : null,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          minimumSize: const Size(44, 44),
        ),
        child: const Icon(Icons.send_rounded, size: 20),
      ),
    );
  }

  Widget _buildStopButton(ColorScheme colorScheme) {
    return SizedBox(
      key: const ValueKey('stop'),
      width: 44,
      height: 44,
      child: FilledButton(
        onPressed: () => context.read<ChatProvider>().stopStreaming(),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          minimumSize: const Size(44, 44),
        ),
        child: const Icon(Icons.stop_rounded, size: 20),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 消息气泡组件
// ---------------------------------------------------------------------------
class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final ColorScheme colorScheme;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 角色标识
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 4,
              right: isUser ? 4 : 0,
              bottom: 4,
            ),
            child: Text(
              isUser ? '你' : 'AI助教',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ),

          // 气泡主体
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isUser ? 16 : 4),
                topRight: Radius.circular(isUser ? 4 : 16),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _buildContent(isUser),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isUser) {
    // 用户消息或已经完整的 AI 消息
    if (message.content.isNotEmpty) {
      return Text(
        message.content,
        key: ValueKey('content-${message.content.length}'),
        style: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: isUser
              ? colorScheme.onPrimary
              : colorScheme.onSurface,
        ),
      );
    }

    // AI 消息内容为空且正在等待时，显示闪烁光标
    return const _ThinkingDots();
  }
}

// ---------------------------------------------------------------------------
// "正在思考" 指示器 — 用于流式加载中
// ---------------------------------------------------------------------------
class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator();

  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
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
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AI正在思考...',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
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
// 三点闪烁动画（用于空内容的 AI 气泡）
// ---------------------------------------------------------------------------
class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = value < 0.5
                ? 0.3 + value * 1.4
                : 1.0 - (value - 0.5) * 1.4;

            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 快速操作数据模型
// ---------------------------------------------------------------------------
class _QuickAction {
  final String label;
  final IconData icon;

  const _QuickAction(this.label, this.icon);
}
