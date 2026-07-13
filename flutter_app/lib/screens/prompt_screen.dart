import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadPrompts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt 管理'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPromptEditDialog(context, null),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                _resetPrompt(context);
              } else if (value == 'export') {
                _exportPrompt(context);
              } else if (value == 'import') {
                _importPrompt(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'reset', child: ListTile(
                leading: Icon(Icons.restore),
                title: Text('恢复默认'),
              )),
              const PopupMenuItem(value: 'export', child: ListTile(
                leading: Icon(Icons.file_upload_outlined),
                title: Text('导出'),
              )),
              const PopupMenuItem(value: 'import', child: ListTile(
                leading: Icon(Icons.file_download_outlined),
                title: Text('导入'),
              )),
            ],
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, _) {
          if (provider.prompts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology_outlined, size: 64, color: colorScheme.primary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('暂无 Prompt 模板', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('点击右上角 + 添加', style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  )),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.prompts.length,
            itemBuilder: (_, index) {
              final prompt = provider.prompts[index];
              final isActive = prompt['is_active'] == true;
              final isDefault = prompt['is_default'] == true;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isActive
                      ? BorderSide(color: colorScheme.primary, width: 2)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              prompt['name'] ?? '',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '使用中',
                                style: TextStyle(fontSize: 11, color: colorScheme.onPrimary),
                              ),
                            ),
                          if (isDefault && !isActive)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text('默认', style: TextStyle(
                                fontSize: 11, color: colorScheme.onSurfaceVariant,
                              )),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        prompt['content'] ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isActive)
                            TextButton.icon(
                              onPressed: () {
                                provider.activatePrompt(prompt['id']);
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('激活'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _showPromptEditDialog(context, prompt),
                            tooltip: '编辑',
                          ),
                          if (!isDefault)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _deletePrompt(context, prompt['id']),
                              tooltip: '删除',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPromptEditDialog(BuildContext context, Map<String, dynamic>? prompt) {
    final nameController = TextEditingController(text: prompt?['name'] ?? '');
    final contentController = TextEditingController(text: prompt?['content'] ?? '');
    final isEdit = prompt != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '编辑 Prompt' : '新建 Prompt'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: 'Prompt 名称',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: '内容',
                  hintText: '输入 System Prompt...',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                minLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (isEdit) {
                context.read<SettingsProvider>().updatePrompt(
                  prompt!['id'],
                  {
                    'name': nameController.text.trim(),
                    'content': contentController.text.trim(),
                  },
                );
              } else {
                context.read<SettingsProvider>().createPrompt(
                  nameController.text.trim(),
                  contentController.text.trim(),
                );
              }
              Navigator.pop(ctx);
            },
            child: Text(isEdit ? '保存' : '创建'),
          ),
        ],
      ),
    );
  }

  void _deletePrompt(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个 Prompt 模板吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              context.read<SettingsProvider>().deletePrompt(id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _resetPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复默认'),
        content: const Text('将重置为默认 System Prompt，确定继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              context.read<SettingsProvider>().resetDefaultPrompt();
              Navigator.pop(ctx);
            },
            child: const Text('恢复'),
          ),
        ],
      ),
    );
  }

  void _exportPrompt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prompt 已复制到剪贴板'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _importPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入 Prompt'),
        content: const Text('从剪贴板导入 Prompt 内容'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }
}
