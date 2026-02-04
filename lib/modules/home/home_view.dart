import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/modules/stats/view/stats_view.dart';

import '../../routes/app_routes.dart';
import '../category/view/category_list_view.dart';
import 'home_controller.dart';
import 'widgets/daily_overview_widget.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/section_header_widget.dart';
import 'widgets/task_item_widget.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async => controller.loadTasks(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80.0), // FAB space
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DailyOverviewWidget(),
                const SizedBox(height: 16),
                _buildDailyRecurringSection(),
                _buildTodaySection(),
                _buildOngoingSection(),
                _buildUpcomingSection(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(Routes.addTask);
        },
        backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDailyRecurringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(title: 'daily_recurring_tasks'.tr),
        Obx(() {
          if (controller.isLoading.value) return const SizedBox.shrink();
          if (controller.recurringTasksToday.isEmpty) {
            return EmptyStateWidget(message: 'no_recurring_today'.tr, icon: Icons.repeat);
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.recurringTasksToday.length,
            itemBuilder: (context, index) {
              final task = controller.recurringTasksToday[index];
              return Obx(
                () => TaskItemWidget(
                  task: task,
                  subtasks: controller.subtasksMap[task.id] ?? [],
                  onTap: (id) => Get.toNamed(
                    Routes.taskDetails,
                    arguments: id,
                  )?.then((_) => controller.loadTasks()),
                  onSubtaskToggle: controller.toggleSubtaskCompletion,
                ),
              );
            },
          );
        }),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      titleSpacing: 16,
      title: Obx(() {
        if (controller.isSearching.value) {
          return TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              border: InputBorder.none,
              hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
            onChanged: controller.setSearchText,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${controller.userName.value}!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM').format(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        );
      }),
      actions: [
        Obx(() {
          if (controller.isSearching.value) {
            return IconButton(
              icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
              onPressed: () {
                controller.toggleSearch();
              },
            );
          }
          return Row(
            children: [
              IconButton(
                icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  controller.toggleSearch();
                },
              ),
              IconButton(
                icon: Icon(Icons.bar_chart, color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  Get.to(() => const StatsView());
                },
              ),
              IconButton(
                icon: Icon(Icons.category_outlined, color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  Get.to(() => const CategoryListView());
                },
              ),
              IconButton(
                icon: Icon(
                  controller.hasActiveFilters ? Icons.filter_list_alt : Icons.filter_list,
                  color: controller.hasActiveFilters
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  Get.bottomSheet(const FilterBottomSheet(), isScrollControlled: true);
                },
              ),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  Get.toNamed(Routes.settings);
                },
              ),
            ],
          );
        }),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTodaySection() {
    return Obx(() {
      bool anyOtherTasks =
          controller.recurringTasksToday.isNotEmpty ||
          controller.ongoingTasks.isNotEmpty ||
          controller.upcomingTasks.isNotEmpty;

      if (controller.todayTasks.isEmpty && anyOtherTasks) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeaderWidget(title: 'todays_tasks'.tr),
          if (controller.isLoading.value)
            const Center(
              child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()),
            )
          else if (controller.todayTasks.isEmpty)
            EmptyStateWidget(message: 'no_tasks_today'.tr, icon: Icons.wb_sunny_outlined)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.todayTasks.length,
              itemBuilder: (context, index) {
                final task = controller.todayTasks[index];
                return Obx(
                  () => TaskItemWidget(
                    task: task,
                    subtasks: controller.subtasksMap[task.id] ?? [],
                    onTap: (id) {
                      Get.toNamed(
                        Routes.taskDetails,
                        arguments: id,
                      )?.then((_) => controller.loadTasks());
                    },
                    onSubtaskToggle: controller.toggleSubtaskCompletion,
                  ),
                );
              },
            ),
        ],
      );
    });
  }

  Widget _buildOngoingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(title: 'ongoing'.tr),
        Obx(() {
          if (!controller.isLoading.value && controller.ongoingTasks.isEmpty) {
            return EmptyStateWidget(message: 'no_ongoing'.tr, icon: Icons.timelapse);
          }

          return SizedBox(
            height: 140, // Horizontal list height
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.ongoingTasks.length,
              itemBuilder: (context, index) {
                final task = controller.ongoingTasks[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: Obx(
                    () => TaskItemWidget(
                      task: task,
                      subtasks: controller.subtasksMap[task.id] ?? [],
                      showSubtasks: false,
                      onTap: (id) => Get.toNamed(
                        Routes.taskDetails,
                        arguments: id,
                      )?.then((_) => controller.loadTasks()),
                      onSubtaskToggle: controller.toggleSubtaskCompletion,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUpcomingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(title: 'upcoming'.tr),
        Obx(() {
          if (!controller.isLoading.value && controller.upcomingTasks.isEmpty) {
            return EmptyStateWidget(message: 'no_upcoming'.tr, icon: Icons.calendar_today_outlined);
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.upcomingTasks.length,
            itemBuilder: (context, index) {
              final task = controller.upcomingTasks[index];
              return Obx(
                () => TaskItemWidget(
                  task: task,
                  subtasks: controller.subtasksMap[task.id] ?? [],
                  onTap: (id) => Get.toNamed(
                    Routes.taskDetails,
                    arguments: id,
                  )?.then((_) => controller.loadTasks()),
                  onSubtaskToggle: controller.toggleSubtaskCompletion,
                ),
              );
            },
          );
        }),
      ],
    );
  }
}
