import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import 'prompt_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: Consumer2<SettingsProvider, ThemeProvider>(
        builder: (context, settingsProvider, themeProvider, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // AI 配置
              _buildSectionHeader(context, 'AI 配置'),
              _buildSettingsCard(context, [
                _buildListTile(
                  context,
                  icon: Icons.memory_outlined,
                  title: 'AI 引擎',
                  subtitle: settingsProvider.aiConfig['engine'] ?? 'ollama',
                  onTap: () => _showAIEngineDialog(context, settingsProvider),
                ),
                _buildListTile(
                  context,
                  icon: Icons.link_outlined,
                  title: '服务地址',
                  subtitle: settingsProvider.aiConfig['base_url'] ?? 'http://localhost:11434',
                  onTap: () => _showTextEditDialog(
                    context,
                    '服务地址',
                    settingsProvider.aiConfig['base_url'] ?? '',
                    (value) {
                      settingsProvider.updateAIConfig({'base_url': value});
                    },
                  ),
                ),
                _buildListTile(
                  context,
                  icon: Icons.model_training_outlined,
                  title: '当前模型',
                  subtitle: settingsProvider.aiConfig['model'] ?? 'qwen2.5:7b',
                  onTap: () => _showModelDialog(context, settingsProvider),
                ),
                _buildListTile(
                  context,
                  icon: Icons.favorite_outline,
                  title: 'AI 健康检查',
                  subtitle: settingsProvider.aiHealth['ollama']?['available'] == true
                      ? 'Ollama 连接正常'
                      : '未检测到 AI 服务',
                  trailing: Icon(
                    settingsProvider.aiHealth['ollama']?['available'] == true
                        ? Icons.check_circle
                        : Icons.error_outline,
                    color: settingsProvider.aiHealth['ollama']?['available'] == true
                        ? Colors.green
                        : Colors.orange,
                  ),
                  onTap: () => settingsProvider.checkAIHealth(),
                ),
              ]),

              const SizedBox(height: 8),

              // 外观设置
              _buildSectionHeader(context, '外观'),
              _buildSettingsCard(context, [
                _buildListTile(
                  context,
                  icon: Icons.brightness_6_outlined,
                  title: '主题模式',
                  subtitle: _getThemeName(themeProvider.themeMode),
                  onTap: () => _showThemeDialog(context, themeProvider),
                ),
                _buildListTile(
                  context,
                  icon: Icons.text_fields_outlined,
                  title: '字体大小',
                  subtitle: '${themeProvider.fontSize.toInt()}px',
                  onTap: () => _showFontSizeDialog(context, themeProvider),
                ),
                _buildListTile(
                  context,
                  icon: Icons.language_outlined,
                  title: '语言',
                  subtitle: themeProvider.language == 'en' ? 'English' : '中文',
                  onTap: () => _showLanguageDialog(context, themeProvider),
                ),
              ]),

              const SizedBox(height: 8),

              // System Prompt
              _buildSectionHeader(context, 'System Prompt'),
              _buildSettingsCard(context, [
                _buildListTile(
                  context,
                  icon: Icons.psychology_outlined,
                  title: 'Prompt 管理',
                  subtitle: settingsProvider.activePrompt['name'] ?? '默认系统提示词',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PromptScreen()),
                    );
                  },
                ),
              ]),

              const SizedBox(height: 8),

              // 数据管理
              _buildSectionHeader(context, '数据管理'),
              _buildSettingsCard(context, [
                _buildListTile(
                  context,
                  icon: Icons.backup_outlined,
                  title: '备份数据库',
                  subtitle: '创建当前数据备份',
                  onTap: () => _backupDatabase(context, settingsProvider),
                ),
                _buildListTile(
                  context,
                  icon: Icons.restore_outlined,
                  title: '恢复数据库',
                  subtitle: '从备份恢复数据',
                  onTap: () => _showRestoreDialog(context, settingsProvider),
                ),
                _buildListTile(
                  context,
                  icon: Icons.file_download_outlined,
                  title: '导出数据',
                  subtitle: 'CSV / Excel / Markdown / JSON',
                  onTap: () => _showExportDialog(context),
                ),
              ]),

              const SizedBox(height: 8),

              // 关于
              _buildSectionHeader(context, '关于'),
              _buildSettingsCard(context, [
                _buildListTile(
                  context,
                  icon: Icons.info_outline,
                  title: '关于应用',
                  subtitle: '考公成语随身助教 v${AppConstants.version}',
                ),
              ]),

              const SizedBox(height: 32),

              // 版本信息
              Center(
                child: Text(
                  '考公成语随身助教 v${AppConstants.version}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: trailing ?? (onTap != null
          ? const Icon(Icons.chevron_right, size: 20)
          : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  // ===== Dialogs =====

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('浅色模式'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (v) {
                themeProvider.setThemeMode(v!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色模式'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (v) {
                themeProvider.setThemeMode(v!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (v) {
                themeProvider.setThemeMode(v!);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('字体大小'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.fontSizeOptions.map((size) {
            return RadioListTile<int>(
              title: Text('${size}px'),
              value: size,
              groupValue: themeProvider.fontSize.toInt(),
              onChanged: (v) {
                themeProvider.setFontSize(v!.toDouble());
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择语言'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('中文'),
              value: AppConstants.langChinese,
              groupValue: themeProvider.language,
              onChanged: (v) {
                themeProvider.setLanguage(v!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: AppConstants.langEnglish,
              groupValue: themeProvider.language,
              onChanged: (v) {
                themeProvider.setLanguage(v!);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAIEngineDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择 AI 引擎'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Ollama'),
              subtitle: const Text('本地 Ollama 服务'),
              value: 'ollama',
              groupValue: provider.aiConfig['engine'] ?? 'ollama',
              onChanged: (v) {
                provider.updateAIConfig({'engine': v!});
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<String>(
              title: const Text('llama.cpp'),
              subtitle: const Text('llama.cpp HTTP Server'),
              value: 'llamacpp',
              groupValue: provider.aiConfig['engine'] ?? 'ollama',
              onChanged: (v) {
                provider.updateAIConfig({'engine': v!});
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showModelDialog(BuildContext context, SettingsProvider provider) async {
    await provider.loadModels(provider.aiConfig['engine'] ?? 'ollama');

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择模型'),
        content: SizedBox(
          width: double.maxFinite,
          child: provider.availableModels.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('无法获取模型列表，请手动输入模型名称'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.availableModels.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text(provider.availableModels[i]),
                    selected: provider.availableModels[i] == provider.aiConfig['model'],
                    onTap: () {
                      provider.updateAIConfig({'model': provider.availableModels[i]});
                      Navigator.pop(ctx);
                    },
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => _showTextEditDialog(
              context,
              '模型名称',
              provider.aiConfig['model'] ?? '',
              (value) {
                provider.updateAIConfig({'model': value});
              },
            ),
            child: const Text('手动输入'),
          ),
        ],
      ),
    );
  }

  void _showTextEditDialog(
    BuildContext context,
    String title,
    String initialValue,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('修改$title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '请输入$title',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _backupDatabase(BuildContext context, SettingsProvider provider) async {
    final result = await provider.backupDatabase();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result ?? '备份失败'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, SettingsProvider provider) async {
    await provider.loadBackups();
    if (!context.mounted) return;

    if (provider.backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有找到备份文件'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择备份'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.backups.length,
            itemBuilder: (_, i) {
              final backup = provider.backups[i];
              return ListTile(
                title: Text(backup['filename'] ?? ''),
                subtitle: Text('${backup['created_at']}  (${_formatSize(backup['size'] ?? 0)})'),
                onTap: () {
                  // TODO: call restore API
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('恢复功能需要在设置页面手动操作'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('导出格式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            const Divider(height: 1),
            ...AppConstants.exportFormats.map((format) => ListTile(
              leading: Icon(_getExportIcon(format)),
              title: Text(format),
              trailing: const Icon(Icons.download_outlined),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('导出 $format 文件'),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: '打开',
                      onPressed: () {},
                    ),
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  IconData _getExportIcon(String format) {
    switch (format) {
      case 'CSV': return Icons.table_chart_outlined;
      case 'Excel': return Icons.grid_on_outlined;
      case 'Markdown': return Icons.description_outlined;
      case 'JSON': return Icons.data_object_outlined;
      case 'PDF': return Icons.picture_as_pdf_outlined;
      default: return Icons.file_download_outlined;
    }
  }

  String _formatSize(dynamic size) {
    if (size is int) {
      if (size < 1024) return '$size B';
      if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '';
  }
}
