import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:flutter/material.dart';

class ColorChipButton extends StatelessWidget {
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;
  final String? label;

  const ColorChipButton({
    super.key,
    required this.isSelected,
    required this.onTap,
    this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.secondary
        : AppColors.light.border;
    final fillColor = color ?? Colors.white;
    final showCheck = isSelected && color != null;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? 0 : 12,
          vertical: label == null ? 0 : 8,
        ),
        width: label == null ? 34 : null,
        height: label == null ? 34 : null,
        decoration: BoxDecoration(
          color: fillColor,
          shape: label == null ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: label == null ? null : BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: label != null
            ? Text(
                label!,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              )
            : showCheck
            ? Icon(
                Icons.check,
                size: 14,
                color: color == const Color(0xFFFFFF)
                    ? AppColors.primary
                    : Colors.white,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
