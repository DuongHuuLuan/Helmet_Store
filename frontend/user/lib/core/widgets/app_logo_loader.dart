import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:flutter/material.dart';

class AppLogoLoader extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final double? value;
  final String assetPath;

  const AppLogoLoader({
    super.key,
    this.size = 72,
    this.strokeWidth = 4,
    this.value,
    this.assetPath = 'assets/images/logo_royalStore2.png',
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = size - (strokeWidth * 2);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              color: AppColors.primary,
              backgroundColor: AppColors.secondary.withOpacity(0.18),
            ),
          ),
          Container(
            width: innerSize,
            height: innerSize,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}
