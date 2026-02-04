import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../home_controller.dart';

class DailyOverviewWidget extends StatefulWidget {
  const DailyOverviewWidget({super.key});

  @override
  State<DailyOverviewWidget> createState() => _DailyOverviewWidgetState();
}

class _DailyOverviewWidgetState extends State<DailyOverviewWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();

    return Obx(() {
      final List<Widget> cards = [
        // Card 1: Today's Tasks or Available Tasks
        _buildTodayCard(context, homeController),

        // Card 2: In Progress
        _buildOverviewCard(
          context,
          title: 'in_progress'.tr,
          count: homeController.inProgressCount.value,
          subtitle: 'in_progress_desc'.tr,
          icon: Icons.pending_actions_rounded,
          color: Colors.orange.shade700,
          onTap: () => Get.toNamed(Routes.inProgressTasks)?.then((_) => homeController.loadTasks()),
        ),

        // Card 3: Completed This Month
        _buildOverviewCard(
          context,
          title: 'completed_month'.tr,
          count: homeController.completedThisMonthCount.value,
          subtitle: '', // Custom handling below
          icon: Icons.task_alt_rounded,
          color: Colors.green.shade700,
          onTap: () => Get.toNamed(Routes.completedTasks)?.then((_) => homeController.loadTasks()),
          customSubtitle: Text(
            'with_n_subtasks'.trParams({
              'count': homeController.completedSubtasksThisMonth.value.toString(),
            }),
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
        ),
      ];

      // Conditional Card 4: Recurring Tasks
      if (homeController.showRecurringCard.value) {
        cards.add(_buildRecurringCard(context, homeController));
      }

      return Column(
        children: [
          SizedBox(
            height: 180,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: cards,
            ),
          ),
          const SizedBox(height: 12),
          // Simple Dot Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(cards.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).primaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      );
    });
  }

  Widget _buildTodayCard(BuildContext context, HomeController homeController) {
    final todayCount = homeController.todayTasksCount.value;
    final availableCount = homeController.availableTasksCount.value;

    String title;
    int displayCount;
    String subtitle = '';
    Widget? customSubtitle;

    if (todayCount == 0) {
      if (availableCount > 0) {
        title = 'available_tasks'.tr;
        displayCount = availableCount;
        subtitle = 'available_tasks_desc'.tr;
      } else {
        title = 'todays_tasks'.tr;
        displayCount = 0;
        subtitle = 'no_tasks_lately'.tr;
      }
    } else {
      title = 'todays_tasks'.tr;
      displayCount = todayCount;
      if (availableCount > 0) {
        customSubtitle = Text(
          'more_available'.trParams({'count': availableCount.toString()}),
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
        );
      } else {
        subtitle =
            'يجب إنجازها اليوم'; // Wait, I didn't add this key. I'll use it directly or add it.
        // Let's just use 'todays_tasks' or similar.
        subtitle = 'todays_tasks'.tr;
      }
    }

    return _buildOverviewCard(
      context,
      title: title,
      count: displayCount,
      subtitle: subtitle,
      icon: Icons.today_rounded,
      color: Theme.of(context).primaryColor,
      onTap: () => Get.toNamed(Routes.todayTasks)?.then((_) => homeController.loadTasks()),
      customSubtitle: customSubtitle,
    );
  }

  Widget _buildRecurringCard(BuildContext context, HomeController homeController) {
    final activeTask = homeController.activeRecurringTask.value;
    final title = activeTask != null
        ? 'task_time'.trParams({'title': activeTask.title})
        : 'daily_overview'.tr;

    return _buildOverviewCard(
      context,
      title: title,
      count: homeController.recurringCompletedCount.value,
      subtitle: '',
      icon: Icons.repeat_rounded,
      color: Colors.indigo.shade700,
      onTap: () => Get.toNamed(Routes.recurringTasks)?.then((_) => homeController.loadTasks()),
      customSubtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'recurring_completed'.trParams({
              'count': homeController.recurringCompletedCount.value.toString(),
            }),
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
          ),
          if (homeController.recurringMissedCount.value > 0)
            Text(
              'tasks_missed'.trParams({
                'count': homeController.recurringMissedCount.value.toString(),
              }),
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context, {
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Widget? customSubtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (customSubtitle != null)
                    customSubtitle
                  else
                    Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}
