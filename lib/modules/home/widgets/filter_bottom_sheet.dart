import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/enums.dart';
import '../home_controller.dart';

class FilterBottomSheet extends GetView<HomeController> {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'filters'.tr,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  controller.clearFilters();
                  Get.back();
                },
                child: Text('reset'.tr),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Filter
          _buildSectionTitle(context, 'status'.tr),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              children: TaskStatus.values.map((status) {
                final isSelected = controller.filterStatus.value == status;
                return ChoiceChip(
                  label: Text(status.name.tr),
                  selected: isSelected,
                  onSelected: (selected) {
                    controller.setFilterStatus(selected ? status : null);
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Priority Filter
          _buildSectionTitle(context, 'priority'.tr),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              children: TaskPriority.values.map((priority) {
                final isSelected = controller.filterPriority.value == priority;
                return ChoiceChip(
                  label: Text('priority_${priority.name}'.tr),
                  selected: isSelected,
                  onSelected: (selected) {
                    controller.setFilterPriority(selected ? priority : null);
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Category Filter
          _buildSectionTitle(context, 'categories'.tr),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.availableCategories.isEmpty) {
              return Text(
                'no_categories_available'.tr,
                style: TextStyle(color: Theme.of(context).disabledColor),
              );
            }
            return Wrap(
              spacing: 8,
              children: controller.availableCategories.map((category) {
                final isSelected = controller.filterCategoryIds.contains(category.id);
                return FilterChip(
                  label: Text(category.name),
                  selected: isSelected,
                  onSelected: (_) {
                    controller.toggleFilterCategory(category.id);
                  },
                  selectedColor: Color(category.color),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Theme.of(context).cardTheme.color,
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('apply_filters'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
