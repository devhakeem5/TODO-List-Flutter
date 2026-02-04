import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                children: const [
                  _LanguageScreen(),
                  _NameScreen(),
                  _CategorySelectionScreen(),
                  _SummaryScreen(),
                ],
              ),
            ),
            // Progress Indicator (Optional, but nice for UX)
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => Container(
                    margin: const EdgeInsets.all(4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.currentPage.value == index
                          ? Get.theme.primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _LanguageScreen extends GetView<OnboardingController> {
  const _LanguageScreen();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.language, size: 80, color: Colors.blue),
          const SizedBox(height: 32),
          Text(
            'select_language'.tr,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'choose_language'.tr,
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildLanguageOption('ar_SA', 'العربية', '🇸🇦'),
          const SizedBox(height: 16),
          _buildLanguageOption('en_US', 'English', '🇺🇸'),
          const Spacer(),
          ElevatedButton(
            onPressed: controller.nextPage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('next'.tr),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String code, String label, String flag) {
    return Obx(() {
      final isSelected = controller.selectedLanguage.value == code;
      return InkWell(
        onTap: () => controller.changeLanguage(code),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Get.theme.primaryColor.withOpacity(0.1) : Get.theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Get.theme.primaryColor : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Get.theme.primaryColor : Get.theme.textTheme.bodyLarge?.color,
                ),
              ),
              const Spacer(),
              if (isSelected) Icon(Icons.check_circle, color: Get.theme.primaryColor),
            ],
          ),
        ),
      );
    });
  }
}

class _NameScreen extends GetView<OnboardingController> {
  const _NameScreen();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'welcome'.tr,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'what_should_we_call_you'.tr,
            style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          TextField(
            controller: controller.nameController,
            onChanged: controller.updateName,
            decoration: InputDecoration(
              labelText: 'your_name_optional'.tr,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              TextButton(onPressed: controller.previousPage, child: Text('back'.tr)),
              const Spacer(),
              ElevatedButton(
                onPressed: controller.nextPage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('next'.tr),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(onPressed: controller.skipName, child: Text('skip'.tr)),
          ),
        ],
      ),
    );
  }
}

class _CategorySelectionScreen extends GetView<OnboardingController> {
  const _CategorySelectionScreen();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(
            'what_do_you_want_to_achieve'.tr,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'select_categories_to_start_with'.tr,
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Obx(
              () => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: controller.defaultCategories.map((category) {
                  final isSelected = controller.isCategorySelected(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => controller.toggleCategory(category),
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Row(
            children: [
              TextButton(onPressed: controller.previousPage, child: Text('back'.tr)),
              const Spacer(),
              ElevatedButton(
                onPressed: controller.nextPage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text('next'.tr),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SummaryScreen extends GetView<OnboardingController> {
  const _SummaryScreen();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.check_circle_outline, size: 80, color: Theme.of(context).primaryColor),
          const SizedBox(height: 24),
          Obx(
            () => Text(
              'you_are_all_set'.trParams({
                'name': controller.userName.value.isEmpty ? 'friend'.tr : controller.userName.value,
              }),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'workspace_setup_msg'.tr,
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Obx(
            () => Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: controller.selectedCategories
                  .map(
                    (c) => Chip(
                      label: Text(c),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'change_later_settings'.tr,
            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Row(
            children: [
              TextButton(onPressed: controller.previousPage, child: Text('back'.tr)),
              const Spacer(),
              ElevatedButton(
                onPressed: controller.completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: Text('get_started'.tr),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
