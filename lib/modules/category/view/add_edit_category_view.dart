import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/category_model.dart';
import '../controller/category_controller.dart';

class AddEditCategoryView extends GetView<CategoryController> {
  final Category? category; // If null, we are adding new

  AddEditCategoryView({super.key, this.category});

  final TextEditingController nameController = TextEditingController();
  final RxInt selectedColor = Colors.blue.value.obs;

  // Predefined colors
  final List<Color> colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.deepPurple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    // Initialize if editing
    if (category != null) {
      nameController.text = category!.name;
      selectedColor.value = category!.color;
    }

    return Scaffold(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Get.theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Get.theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
        title: Text(
          category == null ? 'add_category'.tr : 'edit_category'.tr,
          style: Get.theme.appBarTheme.titleTextStyle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Field
            Text('category_name'.tr, style: Get.theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'category_name_hint'.tr,
                filled: true,
                fillColor: Get.theme.inputDecorationTheme.fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Color Picker
            Text('category_color'.tr, style: Get.theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Obx(
              () => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: colors.map((color) {
                  final isSelected = selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () {
                      selectedColor.value = color.value;
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Get.theme.colorScheme.onSurface, width: 3)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
            ),

            const Spacer(),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (category == null) {
                    final success = await controller.addCategory(
                      nameController.text,
                      selectedColor.value,
                    );
                    if (success) Get.back();
                  } else {
                    final success = await controller.editCategory(
                      category!.id,
                      nameController.text,
                      selectedColor.value,
                    );
                    if (success) Get.back();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Get.theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: Text(
                  category == null ? 'create_category'.tr : 'save_changes'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Get.theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
