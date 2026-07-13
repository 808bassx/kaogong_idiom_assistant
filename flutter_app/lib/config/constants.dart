class AppConstants {
  static const String appName = '考公成语随身助教';
  static const String version = '1.0.0';

  // API 配置
  static const String defaultApiHost = '127.0.0.1';
  static const int defaultApiPort = 8000;
  static const String basePath = '/api';

  // 学习配置
  static const int wordsPerPage = 20;
  static const int maxHistoryMessages = 100;

  // 标签
  static const List<String> defaultTags = [
    '全部', '高频', '低频', '申论', '行测', '易错',
  ];

  // 抽查数量
  static const List<int> quizCounts = [5, 10, 20];

  // 导出格式
  static const List<String> exportFormats = [
    'CSV', 'Excel', 'Markdown', 'JSON', 'PDF',
  ];

  // 字体大小选项
  static const List<int> fontSizeOptions = [14, 16, 18, 20, 22, 24];

  // 主题选项
  static const String themeLight = 'light';
  static const String themeDark = 'dark';
  static const String themeSystem = 'system';

  // 语言选项
  static const String langChinese = 'zh';
  static const String langEnglish = 'en';

  // 存储键
  static const String keyTheme = 'theme';
  static const String keyLanguage = 'language';
  static const String keyFontSize = 'font_size';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyApiHost = 'api_host';
  static const String keyApiPort = 'api_port';
}
