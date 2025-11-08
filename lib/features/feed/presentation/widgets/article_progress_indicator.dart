import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ArticleProgressIndicator extends StatelessWidget {
  final int totalCount;
  final int currentIndex;

  const ArticleProgressIndicator({
    super.key,
    required this.totalCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        totalCount,
        (index) => Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: index < currentIndex
                  ? AppTheme.primaryBlue
                  : AppTheme.borderGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

