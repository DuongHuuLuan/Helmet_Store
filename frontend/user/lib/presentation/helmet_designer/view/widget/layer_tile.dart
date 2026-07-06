import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_layer.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/helmet_designer/cubit/helmet_designer_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LayerTile extends StatelessWidget {
  final StickerLayer layer;

  const LayerTile(this.layer, {super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HelmetDesignerCubit>().state;
    final isSelected = state.selectedLayerId == layer.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () =>
            context.read<HelmetDesignerCubit>().selectLayer(layer.id),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.light.border),
                ),
                child: _LayerStickerPreview(layer: layer),
              ),
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${layer.zIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          viewImageKeyLabel(layer.viewImageKey),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              isSelected ? 'Đang chọn sticker này' : 'Nhấn để xem rõ sticker',
            ),
            const SizedBox(height: 4),
            Text(
              'Vị trí: (${layer.x.toStringAsFixed(2)}, ${layer.y.toStringAsFixed(2)}) · Tỷ lệ: ${layer.scale.toStringAsFixed(2)}',
            ),
          ],
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: AppColors.secondary)
            : const Icon(Icons.touch_app_outlined),
      ),
    );
  }
}

class _LayerStickerPreview extends StatelessWidget {
  final StickerLayer layer;

  const _LayerStickerPreview({required this.layer});

  @override
  Widget build(BuildContext context) {
    Widget child = Image.network(
      layer.imageUrl,
      fit: BoxFit.contain,
      loadingBuilder:
          (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.image_not_supported, color: Colors.grey),
    );

    if (layer.tintColorValue != null) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Color(layer.tintColorValue!),
          BlendMode.modulate,
        ),
        child: child,
      );
    }

    final widthFactor = (layer.crop.right - layer.crop.left)
        .clamp(0.12, 1.0)
        .toDouble();
    final heightFactor = (layer.crop.bottom - layer.crop.top)
        .clamp(0.12, 1.0)
        .toDouble();
    final alignX = (((layer.crop.left + layer.crop.right) / 2) * 2 - 1)
        .clamp(-1.0, 1.0)
        .toDouble();
    final alignY = (((layer.crop.top + layer.crop.bottom) / 2) * 2 - 1)
        .clamp(-1.0, 1.0)
        .toDouble();

    return ClipRect(
      child: Align(
        alignment: Alignment(alignX, alignY),
        widthFactor: widthFactor,
        heightFactor: heightFactor,
        child: child,
      ),
    );
  }
}
