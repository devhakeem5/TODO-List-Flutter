import 'package:get/get.dart';

import '../modules/category/controller/category_controller.dart';
import '../modules/home/home_controller.dart';
import '../modules/home/home_view.dart';
import '../modules/onboarding/onboarding_controller.dart';
import '../modules/onboarding/onboarding_view.dart';
import '../modules/settings/controller/settings_controller.dart';
import '../modules/settings/view/settings_view.dart';
import '../modules/task/controller/add_task_controller.dart';
import '../modules/task/view/add_task_view.dart';
import '../modules/task_details/controller/task_details_controller.dart';
import '../modules/task_details/view/task_details_view.dart';
import '../modules/task_list/controller/task_list_controller.dart';
import '../modules/task_list/view/completed_tasks_view.dart';
import '../modules/task_list/view/in_progress_tasks_view.dart';
import '../modules/task_list/view/recurring_tasks_view.dart';
import '../modules/task_list/view/today_tasks_view.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingView(),
      binding: BindingsBuilder(() {
        Get.put(OnboardingController());
      }),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController());
        Get.put(CategoryController());
      }),
    ),
    GetPage(
      name: Routes.addTask,
      page: () => const AddTaskView(),
      binding: BindingsBuilder(() {
        Get.put(AddTaskController());
      }),
    ),
    GetPage(
      name: Routes.taskDetails,
      page: () => const TaskDetailsView(),
      binding: BindingsBuilder(() {
        Get.put(TaskDetailsController());
      }),
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsView(),
      binding: BindingsBuilder(() {
        Get.put(SettingsController());
      }),
    ),
    GetPage(
      name: Routes.todayTasks,
      page: () => const TodayTasksView(),
      binding: BindingsBuilder(() {
        Get.put(TaskListController());
      }),
    ),
    GetPage(
      name: Routes.inProgressTasks,
      page: () => const InProgressTasksView(),
      binding: BindingsBuilder(() {
        Get.put(TaskListController());
      }),
    ),
    GetPage(
      name: Routes.completedTasks,
      page: () => const CompletedTasksView(),
      binding: BindingsBuilder(() {
        Get.put(TaskListController());
      }),
    ),
    GetPage(
      name: Routes.recurringTasks,
      page: () => const RecurringTasksView(),
      binding: BindingsBuilder(() {
        Get.put(TaskListController());
      }),
    ),
  ];
}
