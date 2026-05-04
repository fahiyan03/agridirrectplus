import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

// Product marker - map এ product location দেখায়
class ProductMapMarker extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const ProductMapMarker({
    super.key,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width:  isSelected ? 44 : 36,
        height: isSelected ? 44 : 36,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? AppColors.accent : AppColors.primary).withValues(alpha: 0.4),
              blurRadius: isSelected ? 10 : 6,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Icon(Icons.eco_rounded, color: Colors.white, size: isSelected ? 22 : 18),
      ),
    );
  }
}

// User location marker - map এ user এর নিজের position দেখায়
class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.info,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 16),
    );
  }
}

// Zone radius indicator - map এ zone এর boundary দেখায়
class ZoneRadiusIndicator extends StatelessWidget {
  final Color color;
  final String label;

  const ZoneRadiusIndicator({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}