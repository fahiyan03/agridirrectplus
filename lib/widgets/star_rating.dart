import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int totalStars;
  final double size;
  final bool showText;

  const StarRating({
    super.key,
    required this.rating,
    this.totalStars = 5,
    this.size = 16,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(totalStars, (i) {
          if (i < rating.floor()) {
            return Icon(Icons.star_rounded, color: AppColors.accent, size: size);
          } else if (i < rating) {
            return Icon(Icons.star_half_rounded, color: AppColors.accent, size: size);
          } else {
            return Icon(Icons.star_border_rounded, color: Colors.grey.shade300, size: size);
          }
        }),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(rating.toStringAsFixed(1),
              style: TextStyle(fontSize: size * 0.75, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ],
    );
  }
}

// Interactive star rating - রিভিউ দেওয়ার সময় ব্যবহার
class InteractiveStarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  const InteractiveStarRating({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () => onRatingChanged(i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              i < rating ? Icons.star_rounded : Icons.star_border_rounded,
              color: AppColors.accent,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}