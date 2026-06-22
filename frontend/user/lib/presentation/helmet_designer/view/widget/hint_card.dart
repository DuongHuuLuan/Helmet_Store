import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:flutter/material.dart';

class HintCard extends StatelessWidget {
  final String text;
  final bool isError;

  const HintCard({super.key, required this.text, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF0F0) : const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isError ? const Color(0xFFFFC2C2) : AppColors.light.border,
        ),
      ),
      child: Text(text),
    );
  }
}
