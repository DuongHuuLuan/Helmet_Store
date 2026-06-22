import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/helmet_designer/view/widget/color_chip_button.dart';
import 'package:flutter/material.dart';

class AiStickerSection extends StatelessWidget {
  final TextEditingController promptController;
  final String selectedStyle;
  final Color? selectedColor;
  final bool removeBackground;
  final List<String> styles;
  final List<Color> palette;
  final bool isGenerating;
  final bool isVoiceBusy;
  final ValueChanged<String> onStyleChanged;
  final ValueChanged<Color?> onColorChanged;
  final ValueChanged<bool> onBackgroundChanged;
  final VoidCallback onGenerate;
  final VoidCallback onToggleVoice;

  const AiStickerSection({
    super.key,
    required this.promptController,
    required this.selectedStyle,
    required this.selectedColor,
    required this.removeBackground,
    required this.styles,
    required this.palette,
    required this.isGenerating,
    required this.isVoiceBusy,
    required this.onStyleChanged,
    required this.onColorChanged,
    required this.onBackgroundChanged,
    required this.onGenerate,
    required this.onToggleVoice,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final voiceButtonLabel = isVoiceBusy ? 'Đang xử lý...' : 'Nhấn để nói';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.light.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tạo sticker bằng AI',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập mô tả ngắn, chọn phong cách và màu chủ đạo. Bạn có thể nhập nội dung hoặc nhấn nút mic để nói.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.light.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chọn Nhấn để nói ở dưới nếu bạn muốn tạo sticker bằng giọng nói, ứng dụng sẽ mở màn hình lắng nghe riêng rồi tự xử lý và tạo sticker cho bạn.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.light.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: promptController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Ví dụ: rồng lửa decal, cáo đua xe, đám mây dễ thương...',
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: styles.map((style) {
              return ChoiceChip(
                label: Text(style),
                selected: selectedStyle == style,
                onSelected: (_) => onStyleChanged(style),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ColorChipButton(
                label: 'Mặc định',
                isSelected: selectedColor == null,
                color: null,
                onTap: () => onColorChanged(null),
              ),
              ...palette.map(
                (color) => ColorChipButton(
                  color: color,
                  isSelected: selectedColor?.value == color.value,
                  onTap: () => onColorChanged(color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: removeBackground,
            onChanged: onBackgroundChanged,
            title: const Text('Tự động tách nền'),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: isGenerating || isVoiceBusy ? null : onGenerate,
                icon: isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('Tạo sticker ngay'),
              ),
              OutlinedButton.icon(
                onPressed: isGenerating || isVoiceBusy ? null : onToggleVoice,
                icon: const Icon(Icons.mic_none_outlined),
                label: Text(voiceButtonLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
