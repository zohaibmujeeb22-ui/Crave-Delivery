import 'package:crave_delivery1/app/app_colors.dart';
import 'package:flutter/material.dart';

class AnimatedPageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const AnimatedPageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final bool isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isActive ? 28 : 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
