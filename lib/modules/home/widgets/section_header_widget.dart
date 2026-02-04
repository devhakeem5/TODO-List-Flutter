import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeaderWidget({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: Text('see_all'.tr)),
        ],
      ),
    );
  }
}
