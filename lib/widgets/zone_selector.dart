import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class ZoneSelector extends StatelessWidget {
  final int selectedZone;
  final ValueChanged<int> onZoneSelected;
  final bool showAll;

  const ZoneSelector({
    super.key,
    required this.selectedZone,
    required this.onZoneSelected,
    this.showAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          if (showAll)
            _ZoneChip(
              label: 'সব',
              zone: 0,
              color: AppColors.primary,
              isSelected: selectedZone == 0,
              onTap: () => onZoneSelected(0),
            ),
          ...zoneConfigs.map((z) => _ZoneChip(
            label: 'জোন ${z.zone}',
            zone: z.zone,
            color: z.color,
            isSelected: selectedZone == z.zone,
            onTap: () => onZoneSelected(z.zone),
          )),
        ],
      ),
    );
  }
}

class _ZoneChip extends StatelessWidget {
  final String label;
  final int zone;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ZoneChip({
    required this.label,
    required this.zone,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}