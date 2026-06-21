import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_crop.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_layer.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/helmet_designer/cubit/helmet_designer_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/helmet_designer/view/widget/color_chip_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LayerToolbar extends StatelessWidget {
  final StickerLayer layer;
  final List<Color> palette;

  const LayerToolbar({super.key, required this.layer, required this.palette});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HelmetDesignerCubit>();
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.light.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layer đang chọn #${layer.id}',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => cubit.rotateSelectedLayerBy(-0.15),
                icon: const Icon(Icons.rotate_left),
                label: const Text('Xoay trái'),
              ),
              OutlinedButton.icon(
                onPressed: () => cubit.rotateSelectedLayerBy(0.15),
                icon: const Icon(Icons.rotate_right),
                label: const Text('Xoay phải'),
              ),
              OutlinedButton.icon(
                onPressed: () => cubit.resizeSelectedLayerBy(0.9),
                icon: const Icon(Icons.remove),
                label: const Text('Thu nhỏ'),
              ),
              OutlinedButton.icon(
                onPressed: () => cubit.resizeSelectedLayerBy(1.1),
                icon: const Icon(Icons.add),
                label: const Text('Phóng to'),
              ),
              OutlinedButton.icon(
                onPressed: cubit.bringSelectedLayerForward,
                icon: const Icon(Icons.flip_to_front),
                label: const Text('Lên trên'),
              ),
              OutlinedButton.icon(
                onPressed: cubit.removeSelectedLayer,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xóa'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Màu sticker',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ColorChipButton(
                label: 'Gốc',
                isSelected: layer.tintColorValue == null,
                color: null,
                onTap: () => cubit.updateSelectedLayerTint(null),
              ),
              ...palette.map(
                (color) => ColorChipButton(
                  color: color,
                  isSelected: layer.tintColorValue == color.value,
                  onTap: () => cubit.updateSelectedLayerTint(color.value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Cắt ngang (Crop)',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          RangeSlider(
            values: RangeValues(layer.crop.left, layer.crop.right),
            min: 0,
            max: 1,
            divisions: 20,
            labels: RangeLabels(
              layer.crop.left.toStringAsFixed(2),
              layer.crop.right.toStringAsFixed(2),
            ),
            onChanged: (values) {
              final range = _normalizeRange(values);
              cubit.updateSelectedLayerCrop(
                layer.crop.copyWith(left: range.start, right: range.end),
              );
            },
          ),
          Text(
            'Cắt dọc (Crop)',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          RangeSlider(
            values: RangeValues(layer.crop.top, layer.crop.bottom),
            min: 0,
            max: 1,
            divisions: 20,
            labels: RangeLabels(
              layer.crop.top.toStringAsFixed(2),
              layer.crop.bottom.toStringAsFixed(2),
            ),
            onChanged: (values) {
              final range = _normalizeRange(values);
              cubit.updateSelectedLayerCrop(
                layer.crop.copyWith(top: range.start, bottom: range.end),
              );
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => cubit.updateSelectedLayerCrop(StickerCrop()),
              icon: const Icon(Icons.crop_free),
              label: const Text('Đặt lại Crop'),
            ),
          ),
        ],
      ),
    );
  }
}

RangeValues _normalizeRange(RangeValues values, {double minSpan = 0.15}) {
  var start = values.start;
  var end = values.end;
  if (end - start >= minSpan) {
    return values;
  }

  end = (start + minSpan).clamp(0.0, 1.0);
  start = (end - minSpan).clamp(0.0, 1.0);
  return RangeValues(start.toDouble(), end.toDouble());
}
