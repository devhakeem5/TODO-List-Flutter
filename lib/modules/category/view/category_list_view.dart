import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/category_controller.dart';
import 'add_edit_category_view.dart';

class CategoryListView extends GetView<CategoryController> {
  const CategoryListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Get.theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Get.theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
        title: Text('categories'.tr, style: Get.theme.appBarTheme.titleTextStyle),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Get.theme.primaryColor),
            onPressed: () {
              Get.to(() => AddEditCategoryView());
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 64, color: Get.theme.disabledColor),
                const SizedBox(height: 16),
                Text(
                  'no_categories_yet'.tr,
                  style: TextStyle(color: Get.theme.disabledColor, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => Get.to(() => AddEditCategoryView()),
                  child: Text('add_first_category'.tr),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final category = controller.categories[index];
            return Container(
              decoration: BoxDecoration(
                color: Get.theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Get.theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Get.theme.shadowColor.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () {
                  Get.to(() => AddEditCategoryView(category: category));
                },
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(category.color).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(category.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: category.isActive
                        ? Get.theme.textTheme.bodyLarge?.color
                        : Get.theme.disabledColor,
                    decoration: !category.isActive ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: Switch(
                  value: category.isActive,
                  activeThumbColor: Get.theme.primaryColor,
                  onChanged: (value) {
                    controller.toggleCategoryStatus(category);
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
