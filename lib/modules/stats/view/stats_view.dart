import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/stats_controller.dart';

class StatsView extends GetView<StatsController> {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.scaffoldBackgroundColor, // Or adapt to theme
      appBar: AppBar(
        backgroundColor: Get.theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Get.theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
        title: Text('stats'.tr, style: Get.theme.appBarTheme.titleTextStyle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'your_progress'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                // 1. Today
                _buildStatCard(
                  title: 'today'.tr,
                  valueObx: controller.completedToday,
                  icon: Icons.today,
                  color: Colors.blueAccent,
                ),
                // 2. This Week
                _buildStatCard(
                  title: 'last_7_days'.tr,
                  valueObx: controller.completedThisWeek,
                  icon: Icons.date_range,
                  color: Colors.orangeAccent,
                ),
                // 3. Overdue
                _buildStatCard(
                  title: 'overdue'.tr,
                  valueObx: controller.overdueCount,
                  icon: Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                ),
                // 4. Top Category
                _buildCategoryCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required RxInt valueObx,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Get.theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Get.theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          Obx(
            () => Text(
              '${valueObx.value}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Get.theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Get.theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Get.theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(Icons.category, color: Get.theme.colorScheme.onPrimary, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => Text(
                  controller.topCategoryName.value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Get.theme.colorScheme.onPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Obx(
                () => Text(
                  'n_tasks'.trParams({'count': controller.topCategoryCount.value.toString()}),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Get.theme.colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          Text(
            'top_category'.tr,
            style: TextStyle(
              fontSize: 12,
              color: Get.theme.colorScheme.onPrimary.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
