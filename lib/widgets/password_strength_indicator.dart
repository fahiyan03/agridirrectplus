import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  int _getStrength() {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    return strength;
  }

  Color _getColor(int strength) {
    if (strength <= 1) return AppColors.error;
    if (strength <= 2) return Colors.orange;
    if (strength <= 3) return Colors.yellow.shade700;
    if (strength <= 4) return Colors.lightGreen;
    return AppColors.success;
  }

  String _getLabel(int strength) {
    if (strength <= 1) return 'খুব দুর্বল';
    if (strength <= 2) return 'দুর্বল';
    if (strength <= 3) return 'মাঝারি';
    if (strength <= 4) return 'ভালো';
    return 'শক্তিশালী ✓';
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = _getStrength();
    final color = _getColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),

        // Progress bar
        Row(
          children: List.generate(
            5,
                (i) => Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: i < strength ? color : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Label + remaining
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getLabel(strength),
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (strength < 5)
              Text(
                '${5 - strength}টি শর্ত বাকি',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
          ],
        ),

        const SizedBox(height: 6),

        // Requirements checklist
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _Requirement(
              label: '৮+ অক্ষর',
              met: password.length >= 8,
            ),
            _Requirement(
              label: 'বড় হাতের (A-Z)',
              met: password.contains(RegExp(r'[A-Z]')),
            ),
            _Requirement(
              label: 'ছোট হাতের (a-z)',
              met: password.contains(RegExp(r'[a-z]')),
            ),
            _Requirement(
              label: 'সংখ্যা (0-9)',
              met: password.contains(RegExp(r'[0-9]')),
            ),
            _Requirement(
              label: 'বিশেষ চিহ্ন (!@#)',
              met: password.contains(
                RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Requirement extends StatelessWidget {
  final String label;
  final bool met;

  const _Requirement({
    required this.label,
    required this.met,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 12,
          color: met ? AppColors.success : AppColors.textHint,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: met ? AppColors.success : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}