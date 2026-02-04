import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/storage_service.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import '../../routes/app_routes.dart';

class OnboardingController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final CategoryRepository _categoryRepo = Get.find<CategoryRepository>();

  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  // Screen 0: Language
  final RxString selectedLanguage = ''.obs;

  // Screen 1: Name
  final TextEditingController nameController = TextEditingController();
  final RxString userName = ''.obs;

  // Screen 2: Categories
  final List<String> defaultCategories = ['Personal', 'Work', 'Study', 'Health', 'General'];
  final RxList<String> selectedCategories = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize selected language from current locale
    selectedLanguage.value = Get.locale?.toString() ?? 'ar_SA';
    // Default selection for categories
    selectedCategories.add('General');
  }

  void changeLanguage(String langCode) {
    selectedLanguage.value = langCode;
    final locale = Locale(langCode.split('_')[0], langCode.split('_')[1]);
    Get.updateLocale(locale);
    _storage.write(StorageKeys.languageCode, langCode);
  }

  void nextPage() {
    if (currentPage.value < 3) {
      pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void previousPage() {
    if (currentPage.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  // Logic 1: Update Name
  void updateName(String name) {
    userName.value = name.trim();
  }

  void skipName() {
    userName.value = '';
    nextPage();
  }

  // Logic 2: Toggle Category
  void toggleCategory(String category) {
    if (selectedCategories.contains(category)) {
      if (selectedCategories.length > 1) {
        selectedCategories.remove(category);
      } else {
        Get.snackbar('Alert', 'Please select at least one category.');
      }
    } else {
      selectedCategories.add(category);
    }
  }

  bool isCategorySelected(String category) => selectedCategories.contains(category);

  // Logic 3: Finalize
  Future<void> completeOnboarding() async {
    try {
      // 1. Save Name
      if (userName.isNotEmpty) {
        await _storage.write(StorageKeys.userName, userName.value);
      } else {
        await _storage.write(StorageKeys.userName, 'User');
      }

      // 2. Save Categories to DB
      const uuid = Uuid();
      int colorIndex = 0;
      final List<int> colors = [
        0xFF4CAF50, // Green
        0xFF2196F3, // Blue
        0xFFFFC107, // Amber
        0xFFF44336, // Red
        0xFF9C27B0, // Purple
      ];

      for (String catName in selectedCategories) {
        final category = Category(
          id: uuid.v4(),
          name: catName,
          color: colors[colorIndex % colors.length],
          createdAt: DateTime.now(),
          isActive: true,
        );
        await _categoryRepo.create(category);
        colorIndex++;
      }

      // 3. Set Flag
      await _storage.write(StorageKeys.isFirstLaunch, false);

      // 4. Navigate to Home
      Get.offAllNamed(Routes.home);
    } catch (e) {
      Get.snackbar('Error', 'Failed to complete setup: $e');
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    nameController.dispose();
    super.onClose();
  }
}
