import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/theme.dart';
import 'config/constants.dart';
import 'services/api_service.dart';
import 'providers/theme_provider.dart';
import 'providers/word_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KaogongIdiomApp());
}

class KaogongIdiomApp extends StatelessWidget {
  const KaogongIdiomApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => WordProvider(apiService)),
        ChangeNotifierProvider(create: (_) => ChatProvider(apiService)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(apiService)),
        Provider.value(value: apiService),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // 主题
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // 本地化
            locale: themeProvider.language == 'en'
                ? const Locale('en', 'US')
                : const Locale('zh', 'CN'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'CN'),
              Locale('en', 'US'),
            ],

            home: const MainApp(),
          );
        },
      ),
    );
  }
}
