import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'core/database/db_helper.dart';
import 'core/i18n/app_translations.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/utils/theme.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/subtask_repository.dart';
import 'data/repositories/task_repository.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services
  await DatabaseHelper.instance.database;
  await Get.putAsync(() => StorageService().init());

  // Initialize NotificationService
  final notificationService = Get.put(NotificationService());
  await notificationService.init();

  // Determine Initial Locale
  final storage = Get.find<StorageService>();
  final String? savedLang = storage.read<String>(StorageKeys.languageCode);
  final Locale initialLocale = savedLang != null
      ? Locale(savedLang.split('_')[0], savedLang.split('_')[1])
      : const Locale('ar', 'SA'); // Default to Arabic

  // Determine Initial Route
  final bool isFirstLaunch = storage.read<bool>(StorageKeys.isFirstLaunch) ?? true;
  final String initialRoute = isFirstLaunch ? Routes.onboarding : Routes.home;

  runApp(MyApp(initialRoute: initialRoute, initialLocale: initialLocale));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final Locale initialLocale;

  const MyApp({super.key, required this.initialRoute, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'أنجز',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: initialRoute,
      getPages: AppPages.pages,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CategoryRepository());
    Get.put(TaskRepository());
    Get.put(SubTaskRepository());
  }
}
